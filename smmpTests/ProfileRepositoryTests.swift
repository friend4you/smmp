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

    // MARK: - Helpers

    private func makeRepository(
        localRepository: LocalRepository,
        networkMonitor: MockNetworkMonitor,
        fetcher: MockUserDocumentFetcher
    ) -> ProfileRepository {
        ProfileRepository(
            networkMonitor: networkMonitor,
            localRepository: localRepository,
            persistence: PersistenceController(inMemory: true),
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

private final class MockUserDocumentFetcher: UserDocumentFetching, @unchecked Sendable {
    private(set) var fetchCount = 0
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
}
