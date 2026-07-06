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
        let cachedPost = makePost(id: "post-offline", text: "Cached")
        try await localRepository.savePost(post: cachedPost)

        let repository = PostRepository(
            networkMonitor: MockNetworkMonitor(isConnected: false),
            localRepository: localRepository,
            mediaService: MediaService()
        )

        var received: [Post] = []
        let cancellable = repository.postsPublisher.sink { received = $0 }

        repository.observeFeed(currentUserId: "user-1")
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(received.count == 1)
        #expect(received.first?.id == "post-offline")
        cancellable.cancel()
    }

    @Test func createPostRejectsEmptyText() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let repository = PostRepository(
            networkMonitor: MockNetworkMonitor(isConnected: true),
            localRepository: localRepository,
            mediaService: MediaService()
        )

        await #expect(throws: PostRepositoryError.emptyText) {
            try await repository.createPost(text: "   ", authorId: "user-1", postId: nil, imageURL: nil)
        }
    }

    @Test func createPostRejectsTextOver280Characters() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let repository = PostRepository(
            networkMonitor: MockNetworkMonitor(isConnected: true),
            localRepository: localRepository,
            mediaService: MediaService()
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

        let repository = PostRepository(
            networkMonitor: MockNetworkMonitor(isConnected: false),
            localRepository: localRepository,
            mediaService: MediaService()
        )

        repository.observeFeed(currentUserId: "user-1")
        try await Task.sleep(nanoseconds: 100_000_000)
        repository.removeAllListeners()

        var received: [Post] = []
        let cancellable = repository.postsPublisher.sink { received = $0 }
        #expect(received.isEmpty)
        cancellable.cancel()
    }
}

private final class MockNetworkMonitor: NetworkConnectivityProviding {
    var isConnected: Bool

    init(isConnected: Bool) {
        self.isConnected = isConnected
    }
}
