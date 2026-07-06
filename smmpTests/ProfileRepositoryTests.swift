//
//  ProfileRepositoryTests.swift
//  smmpTests
//

import Foundation
import Testing
@testable import smmp

struct ProfileRepositoryTests {

    @Test func fetchUserReturnsCachedUserWithoutRemoteFetch() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let cachedUser = makeUser(id: "author-1", displayName: "Bob")
        try await localRepository.saveUser(user: cachedUser)

        let fetcher = MockUserDocumentFetcher()
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        let user = try await repository.fetchUser(id: "author-1")

        #expect(user?.id == "author-1")
        #expect(user?.displayName == "Bob")
        #expect(fetcher.fetchCount == 0)
    }

    @Test func fetchUserReturnsNilWhenOfflineAndNotCached() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let fetcher = MockUserDocumentFetcher(user: makeUser(id: "author-2"))
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: false),
            fetcher: fetcher
        )

        let user = try await repository.fetchUser(id: "author-2")

        #expect(user == nil)
        #expect(fetcher.fetchCount == 0)
    }

    @Test func fetchUserFetchesRemoteWhenCacheMissAndOnline() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let remoteUser = makeUser(id: "author-3", displayName: "Carol")
        let fetcher = MockUserDocumentFetcher(user: remoteUser)
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        let user = try await repository.fetchUser(id: "author-3")

        #expect(user?.displayName == "Carol")
        #expect(fetcher.fetchCount == 1)
        let cached = try await localRepository.fetchUser(id: "author-3")
        #expect(cached?.displayName == "Carol")
    }

    @Test func fetchUserDeduplicatesConcurrentFetchesForSameId() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let fetcher = MockUserDocumentFetcher(
            user: makeUser(id: "author-4", displayName: "Dana"),
            delayNanoseconds: 200_000_000
        )
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        async let first = repository.fetchUser(id: "author-4")
        async let second = repository.fetchUser(id: "author-4")
        let users = try await [first, second]

        #expect(users[0]?.displayName == "Dana")
        #expect(users[1]?.displayName == "Dana")
        #expect(fetcher.fetchCount == 1)
    }

    @Test func createProfileWritesFirestoreDocumentAndCachesLocally() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let fetcher = MockUserDocumentFetcher()
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        let user = try await repository.createProfile(
            uid: "user-new",
            displayName: "Alice",
            email: "alice@example.com"
        )

        #expect(user.id == "user-new")
        #expect(user.displayName == "Alice")
        #expect(user.email == "alice@example.com")
        #expect(user.displayNameLower == "alice")
        #expect(user.followerCount == 0)
        #expect(user.followingCount == 0)
        #expect(fetcher.createCount == 1)
        #expect(fetcher.lastCreateId == "user-new")
        #expect(fetcher.lastCreateData?["displayName"] as? String == "Alice")
        #expect(fetcher.lastCreateData?["displayNameLower"] as? String == "alice")
        #expect(fetcher.lastCreateData?["email"] as? String == "alice@example.com")

        let cached = try await localRepository.fetchUser(id: "user-new")
        #expect(cached?.displayName == "Alice")
        #expect(cached?.email == "alice@example.com")
    }

    @Test func createProfilePropagatesWriteErrors() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let fetcher = MockUserDocumentFetcher()
        fetcher.createError = MockAuthError.notConfigured
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        await #expect(throws: MockAuthError.notConfigured) {
            try await repository.createProfile(
                uid: "user-fail",
                displayName: "Bob",
                email: "bob@example.com"
            )
        }

        let cached = try await localRepository.fetchUser(id: "user-fail")
        #expect(cached == nil)
    }

    // MARK: - Helpers

    private func makeRepository(
        localRepository: LocalRepository,
        networkMonitor: MockNetworkMonitor,
        fetcher: MockUserDocumentFetcher
    ) -> ProfileRepository {
        ProfileRepository(
            networkMonitor: networkMonitor,
            localRepository: localRepository,
            mediaService: MediaService(),
            userDocumentFetcher: fetcher
        )
    }
}

// MARK: - Mocks

private final class MockNetworkMonitor: NetworkConnectivityProviding {
    var isConnected: Bool

    init(isConnected: Bool) {
        self.isConnected = isConnected
    }
}

private final class MockUserDocumentFetcher: UserDocumentProtocol, @unchecked Sendable {
    private(set) var fetchCount = 0
    private(set) var createCount = 0
    private(set) var lastCreateId: String?
    private(set) var lastCreateData: [String: Any]?
    var createError: Error?
    private let user: User?
    private let delayNanoseconds: UInt64

    init(user: User? = nil, delayNanoseconds: UInt64 = 0) {
        self.user = user
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchUserDocument(id: String) async throws -> User? {
        fetchCount += 1
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return user
    }

    func createUserDocument(id: String, data: [String: Any]) async throws {
        createCount += 1
        lastCreateId = id
        lastCreateData = data
        if let createError {
            throw createError
        }
    }
}
