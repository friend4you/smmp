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
    private let userDocumentFetcher: UserDocumentProtocol
    private let inFlightFetches = InFlightUserFetches()

    init(
        networkMonitor: NetworkConnectivityProviding,
        localRepository: LocalRepositoryProtocol,
        mediaService: MediaServiceProtocol,
        userDocumentFetcher: UserDocumentProtocol = FirestoreUserDocumentRepository()
    ) {
        self.networkMonitor = networkMonitor
        self.localRepository = localRepository
        self.mediaService = mediaService
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
        if let cached = try await localRepository.fetchUser(id: id) {
            return cached
        }

        let isOnline = networkMonitor.isConnected
        guard isOnline else { return nil }

        let user = try await inFlightFetches.user(for: id) { [userDocumentFetcher] in
            try await userDocumentFetcher.fetchUserDocument(id: id)
        }
        
        if let fetchedUser = user {
            try await localRepository.saveUser(user: fetchedUser)
        }
        
        return user
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
