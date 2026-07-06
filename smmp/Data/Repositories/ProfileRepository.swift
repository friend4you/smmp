//
//  ProfileRepository.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import Foundation
import FirebaseFirestore

final class ProfileRepository: ProfileRepositoryProtocol {
    private let networkMonitor: NetworkConnectivityProviding
    private let localRepository: LocalRepositoryProtocol
    private let mediaService: MediaServiceProtocol
    private let authProfileUpdater: AuthProfileUpdating
    private let userDocumentFetcher: UserDocumentProtocol
    private let inFlightFetches = InFlightUserFetches()

    private let searchResultLimit = 20
    private let minimumSearchLength = 2

    init(
        networkMonitor: NetworkConnectivityProviding,
        localRepository: LocalRepositoryProtocol,
        mediaService: MediaServiceProtocol,
        authProfileUpdater: AuthProfileUpdating,
        userDocumentFetcher: UserDocumentProtocol = FirestoreUserDocumentRepository()
    ) {
        self.networkMonitor = networkMonitor
        self.localRepository = localRepository
        self.mediaService = mediaService
        self.authProfileUpdater = authProfileUpdater
        self.userDocumentFetcher = userDocumentFetcher
    }

    func createProfile(uid: String, displayName: String, email: String) async throws -> User {
        var user = User(id: uid)
        user.displayName = displayName
        user.email = email
        user.bio = ""
        user.photoURL = ""
        user.followerCount = 0
        user.followingCount = 0
        user.displayNameLower = User.displayNameLower(from: displayName)

        var data = user.firestoreWriteData(includeEmail: true)
        data["createdAt"] = FieldValue.serverTimestamp()

        try await userDocumentFetcher.createUserDocument(id: uid, data: data)
        try await localRepository.saveUser(user: user)
        return user
    }

    func fetchUser(id: String) async throws -> User? {
        if var cached = try await localRepository.fetchUser(id: id) {
            return await backfillDisplayNameLowerIfNeeded(user: cached, id: id)
        }

        let isOnline = networkMonitor.isConnected
        guard isOnline else { return nil }

        let user = try await inFlightFetches.user(for: id) { [userDocumentFetcher] in
            try await userDocumentFetcher.fetchUserDocument(id: id)
        }

        if var fetchedUser = user {
            fetchedUser = await backfillDisplayNameLowerIfNeeded(user: fetchedUser, id: id)
            try await localRepository.saveUser(user: fetchedUser)
            return fetchedUser
        }

        return user
    }

    func updateProfile(
        uid: String,
        displayName: String,
        bio: String?,
        photoURL: String?
    ) async throws -> User {
        guard var user = try await fetchUser(id: uid) else {
            throw ProfileRepositoryError.userNotFound
        }

        user.displayName = displayName
        user.bio = bio
        user.photoURL = photoURL
        user.displayNameLower = User.displayNameLower(from: displayName)

        let data = user.firestoreWriteData()
        try await userDocumentFetcher.updateUserDocument(id: uid, data: data)

        let photoURLObject = photoURL.flatMap { URL(string: $0) }
        try await authProfileUpdater.updateAuthProfile(
            displayName: displayName,
            photoURL: photoURLObject
        )

        try await localRepository.saveUser(user: user)
        return user
    }

    func searchUsers(prefix: String) async throws -> [User] {
        let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minimumSearchLength else { return [] }
        guard networkMonitor.isConnected else { return [] }

        let normalizedPrefix = trimmed.lowercased()
        return try await userDocumentFetcher.searchUsers(
            prefix: normalizedPrefix,
            limit: searchResultLimit
        )
    }

    // MARK: - Private

    private func backfillDisplayNameLowerIfNeeded(user: User, id: String) async -> User {
        guard user.displayNameLower == nil,
              let displayName = user.displayName,
              !displayName.isEmpty,
              let lower = User.displayNameLower(from: displayName),
              networkMonitor.isConnected else {
            return user
        }

        var updated = user
        updated.displayNameLower = lower
        try? await userDocumentFetcher.updateUserDocument(id: id, data: ["displayNameLower": lower])
        try? await localRepository.saveUser(user: updated)
        return updated
    }
}

// MARK: - In-flight deduplication

private actor InFlightUserFetches {
    private var tasks: [String: Task<User?, Error>] = [:]

    func user(
        for id: String,
        fetch: @escaping @Sendable () async throws -> User?
    ) async throws -> User? {
        if let existing = tasks[id] {
            return try await existing.value
        }

        let task = Task { try await fetch() }
        tasks[id] = task

        do {
            let user = try await task.value
            tasks[id] = nil
            return user
        } catch {
            tasks[id] = nil
            throw error
        }
    }
}
