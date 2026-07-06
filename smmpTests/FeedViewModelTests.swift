//
//  FeedViewModelTests.swift
//  smmpTests
//

import Combine
import Foundation
import Testing
@testable import smmp

@MainActor
struct FeedViewModelTests {

    @Test func optimisticLikeRollsBackOnRepositoryError() async throws {
        let postRepository = MockPostRepository()
        let profileRepository = MockProfileRepository()
        let followRepository = MockFeedFollowRepository()
        let sessionService = MockSessionService(currentUser: makeUser())

        let post = makePost(id: "post-like", likeCount: 2)
        postRepository.postsSubject.send([post])
        postRepository.likePostError = MockPostRepositoryError.likeFailed

        let viewModel = FeedViewModel(
            postRepository: postRepository,
            profileRepository: profileRepository,
            followRepository: followRepository,
            networkMonitor: NetworkMonitor(testConnection: true),
            sessionService: sessionService,
            hapticService: NoOpHapticService()
        )
        viewModel.start()
        try await Task.sleep(nanoseconds: 100_000_000)

        guard let item = viewModel.items.first else {
            Issue.record("Expected feed item before like toggle")
            return
        }

        await viewModel.toggleLike(for: item)

        #expect(viewModel.items.first?.isLikedByCurrentUser == false)
        #expect(viewModel.items.first?.post.likeCount == 2)
        #expect(viewModel.showError)
    }

    @Test func offlineLikeDoesNotCallRepository() async throws {
        let postRepository = MockPostRepository()
        let profileRepository = MockProfileRepository()
        let followRepository = MockFeedFollowRepository()
        let sessionService = MockSessionService(currentUser: makeUser())
        let networkMonitor = MockNetworkMonitor(isConnected: false)

        let post = makePost(id: "post-offline", likeCount: 1)
        postRepository.postsSubject.send([post])

        let viewModel = FeedViewModel(
            postRepository: postRepository,
            profileRepository: profileRepository,
            followRepository: followRepository,
            networkMonitor: networkMonitor,
            sessionService: sessionService,
            hapticService: NoOpHapticService()
        )
        viewModel.start()
        try await Task.sleep(nanoseconds: 100_000_000)

        guard let item = viewModel.items.first else {
            Issue.record("Expected feed item before offline like toggle")
            return
        }

        await viewModel.toggleLike(for: item)

        #expect(postRepository.likeCallCount == 0)
        #expect(postRepository.unlikeCallCount == 0)
        #expect(viewModel.items.first?.isLikedByCurrentUser == false)
        #expect(viewModel.items.first?.post.likeCount == 1)
    }

    @Test func reconnectTriggersFeedReload() async throws {
        let postRepository = MockPostRepository()
        let profileRepository = MockProfileRepository()
        let followRepository = MockFeedFollowRepository()
        let sessionService = MockSessionService(currentUser: makeUser())
        let networkMonitor = MockNetworkMonitor(isConnected: false)

        let viewModel = FeedViewModel(
            postRepository: postRepository,
            profileRepository: profileRepository,
            followRepository: followRepository,
            networkMonitor: networkMonitor,
            sessionService: sessionService,
            hapticService: NoOpHapticService()
        )
        viewModel.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        let initialObserveCount = postRepository.observeFeedCallCount
        networkMonitor.setConnected(true)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(postRepository.observeFeedCallCount > initialObserveCount)
    }

    @Test func showsSkeletonUntilInitialPostsArrive() async throws {
        let postRepository = MockPostRepository()
        let viewModel = FeedViewModel(
            postRepository: postRepository,
            profileRepository: MockProfileRepository(),
            followRepository: MockFeedFollowRepository(),
            networkMonitor: MockNetworkMonitor(isConnected: true),
            sessionService: MockSessionService(currentUser: makeUser()),
            hapticService: NoOpHapticService()
        )

        #expect(!viewModel.hasCompletedInitialLoad)
        #expect(viewModel.items.isEmpty)

        viewModel.start()
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.hasCompletedInitialLoad)
    }

    @Test func isOfflineReflectsInitialConnectivity() {
        let viewModel = FeedViewModel(
            postRepository: MockPostRepository(),
            profileRepository: MockProfileRepository(),
            followRepository: MockFeedFollowRepository(),
            networkMonitor: MockNetworkMonitor(isConnected: false),
            sessionService: MockSessionService(currentUser: makeUser()),
            hapticService: NoOpHapticService()
        )

        viewModel.start()

        #expect(viewModel.isOffline)
    }
}

@MainActor
private enum MockPostRepositoryError: Error {
    case likeFailed
}

@MainActor
private final class MockPostRepository: PostRepositoryProtocol {
    let postsSubject = CurrentValueSubject<[Post], Never>([])
    let likedPostIdsSubject = CurrentValueSubject<Set<String>, Never>([])

    var likePostError: Error?
    private(set) var likeCallCount = 0
    private(set) var unlikeCallCount = 0
    private(set) var observeFeedCallCount = 0

    var postsPublisher: AnyPublisher<[Post], Never> {
        postsSubject.eraseToAnyPublisher()
    }

    var likedPostIdsPublisher: AnyPublisher<Set<String>, Never> {
        likedPostIdsSubject.eraseToAnyPublisher()
    }

    func observeFeed(currentUserId: String, feedAuthorIds: [String]) {
        observeFeedCallCount += 1
        postsSubject.send(postsSubject.value)
    }

    func removeAllListeners() {}

    func refreshFeed(currentUserId: String, feedAuthorIds: [String]) async throws {}

    func loadMorePosts(currentUserId: String) async throws -> Bool { false }

    func fetchPosts(authorId: String) async throws -> [Post] { [] }

    func newPostId() -> String { "new-post-id" }

    func createPost(
        text: String,
        authorId: String,
        postId: String?,
        imageURL: String?
    ) async throws {}

    func deletePost(id: String, authorId: String) async throws {}

    func likePost(id: String, userId: String) async throws {
        likeCallCount += 1
        if let likePostError {
            throw likePostError
        }
    }

    func unlikePost(id: String, userId: String) async throws {
        unlikeCallCount += 1
        if let likePostError {
            throw likePostError
        }
    }

    func likedPostIds(for postIds: [String], userId: String) async -> Set<String> {
        []
    }
}

private struct MockProfileRepository: ProfileRepositoryProtocol {
    func createProfile(uid: String, displayName: String, email: String) async throws -> User {
        makeUser(id: uid, displayName: displayName, email: email)
    }

    func fetchUser(id: String) async throws -> User? {
        makeUser(id: id)
    }

    func updateProfile(
        uid: String,
        displayName: String,
        bio: String?,
        profileImageData: Data?,
        removeProfileImage: Bool
    ) async throws -> User {
        makeUser(id: uid, displayName: displayName, bio: bio)
    }

    func searchUsers(prefix: String) async throws -> [User] {
        []
    }
}

private struct MockFeedFollowRepository: FollowRepositoryProtocol {
    func follow(currentUserId: String, targetUserId: String) async throws {}

    func unfollow(currentUserId: String, targetUserId: String) async throws {}

    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool { false }

    func fetchFollowing(for userId: String) async throws -> [Follow] { [] }

    func followingIds(for userId: String) async throws -> [String] { [] }
}
