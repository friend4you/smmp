//
//  ProfileRepository.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import Foundation

protocol ProfileRepositoryProtocol {
    func fetchUser(id: String) async throws -> User?
}

final class ProfileRepository: ProfileRepositoryProtocol {
    private let networkMonitor: NetworkConnectivityProviding
    private let localRepository: LocalRepositoryProtocol
    private let persistence: PersistenceController
    private let mediaService: MediaServiceProtocol
    private let userDocumentFetcher: UserDocumentFetching
    private let inFlightFetches = InFlightUserFetches()

    init(
        networkMonitor: NetworkConnectivityProviding,
        localRepository: LocalRepositoryProtocol,
        persistence: PersistenceController,
        mediaService: MediaServiceProtocol,
        userDocumentFetcher: UserDocumentFetching = FirestoreUserDocumentFetcher()
    ) {
        self.networkMonitor = networkMonitor
        self.localRepository = localRepository
        self.persistence = persistence
        self.mediaService = mediaService
        self.userDocumentFetcher = userDocumentFetcher
    }

    func fetchUser(id: String) async throws -> User? {
        if let cached = try await localRepository.fetchUser(id: id) {
            return cached
        }

        let isOnline = networkMonitor.isConnected
        guard isOnline else { return nil }

        return try await inFlightFetches.user(for: id) { [userDocumentFetcher, localRepository] in
            guard let user = try await userDocumentFetcher.fetchUserDocument(id: id) else {
                return nil
            }
            try await localRepository.saveUser(user: user)
            return user
        }
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
