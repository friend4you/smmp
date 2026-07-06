//
//  PostRepositoryTests.swift
//  smmpTests
//

import Combine
import Testing
@testable import smmp

struct PostRepositoryTests {

    @Test func observeFeedLoadsCachedPostsWhenOffline() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let cachedPost = makePost(id: "post-offline", authorId: "user-1", text: "Cached")
        try await localRepository.savePost(post: cachedPost)

        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockPostNetworkMonitor(isConnected: false)
        )

        var received: [Post] = []
        let cancellable = repository.postsPublisher.sink { received = $0 }

        repository.observeFeed(currentUserId: "user-1", feedAuthorIds: ["user-1"])
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(received.count == 1)
        #expect(received.first?.id == "post-offline")
        cancellable.cancel()
    }

    @Test func offlineFeedFiltersPostsOutsideFollowGraph() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        try await localRepository.savePost(post: makePost(id: "own-post", authorId: "user-1"))
        try await localRepository.savePost(post: makePost(id: "followed-post", authorId: "user-2"))
        try await localRepository.savePost(post: makePost(id: "stranger-post", authorId: "user-3"))

        let network = MockPostNetworkMonitor(isConnected: true)
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: network
        )
        let authorIds = FeedAuthorIds.authorIds(currentUserId: "user-1", followingIds: ["user-2"])

        repository.observeFeed(currentUserId: "user-1", feedAuthorIds: authorIds)
        try await Task.sleep(nanoseconds: 100_000_000)

        network.isConnected = false
        var offlineReceived: [Post] = []
        let cancellable = repository.postsPublisher.sink { offlineReceived = $0 }

        repository.observeFeed(currentUserId: "user-1", feedAuthorIds: authorIds)
        try await Task.sleep(nanoseconds: 100_000_000)

        let offlineIds = Set(offlineReceived.map(\.id))
        #expect(offlineIds.contains("own-post"))
        #expect(offlineIds.contains("followed-post"))
        #expect(!offlineIds.contains("stranger-post"))
        cancellable.cancel()
    }

    @Test func feedAuthorIdsAlwaysIncludesSelfAndCapsAtFirestoreLimit() {
        let followingIds = (1...35).map { "user-\($0)" }

        let authorIds = FeedAuthorIds.authorIds(currentUserId: "me", followingIds: followingIds)

        #expect(authorIds.first == "me")
        #expect(authorIds.count == 30)
        #expect(authorIds.filter { $0 == "me" }.count == 1)
    }

    @Test func feedAuthorIdsIncludesOnlySelfWhenFollowingNobody() {
        let authorIds = FeedAuthorIds.authorIds(currentUserId: "me", followingIds: [])

        #expect(authorIds == ["me"])
    }

    @Test func createPostRejectsEmptyText() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockPostNetworkMonitor(isConnected: true)
        )

        await #expect(throws: PostRepositoryError.emptyText) {
            try await repository.createPost(text: "   ", authorId: "user-1", postId: nil, imageURL: nil)
        }
    }

    @Test func createPostRejectsTextOver280Characters() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockPostNetworkMonitor(isConnected: true)
        )

        let longText = String(repeating: "a", count: 281)
        await #expect(throws: PostRepositoryError.textTooLong) {
            try await repository.createPost(text: longText, authorId: "user-1", postId: nil, imageURL: nil)
        }
    }

    @Test func removeAllListenersClearsPublishedPosts() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        try await localRepository.savePost(post: makePost())

        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockPostNetworkMonitor(isConnected: false)
        )

        repository.observeFeed(currentUserId: "user-1", feedAuthorIds: ["user-1"])
        try await Task.sleep(nanoseconds: 100_000_000)
        repository.removeAllListeners()

        var received: [Post] = []
        let cancellable = repository.postsPublisher.sink { received = $0 }
        #expect(received.isEmpty)
        cancellable.cancel()
    }

    // MARK: - Helpers

    private func makeRepository(
        localRepository: LocalRepository,
        networkMonitor: MockPostNetworkMonitor
    ) -> PostRepository {
        PostRepository(
            networkMonitor: networkMonitor,
            localRepository: localRepository,
            mediaService: MediaService()
        )
    }
}

private final class MockPostNetworkMonitor: NetworkConnectivityProviding {
    var isConnected: Bool

    init(isConnected: Bool) {
        self.isConnected = isConnected
    }
}
