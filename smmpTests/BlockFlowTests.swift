//
//  BlockFlowTests.swift
//  smmpTests
//

import Combine
import Foundation
import Testing
@testable import smmp

@MainActor
struct BlockFlowTests {

    @Test func blockedAuthorIsOmittedFromFeed() async throws {
        let postRepository = MockFeedPostRepository()
        let blockRepository = MockBlockRepository()
        blockRepository.blockedIdsValue = ["blocked-user"]
        postRepository.postsSubject.send([
            makePost(id: "visible", authorId: "user-1"),
            makePost(id: "hidden", authorId: "blocked-user")
        ])

        let viewModel = FeedViewModel(
            postRepository: postRepository,
            profileRepository: MockFeedProfileRepository(),
            followRepository: MockFeedFollowRepository(),
            blockRepository: blockRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            sessionService: MockSessionService(currentUser: makeUser(id: "user-1")),
            hapticService: NoOpHapticService()
        )
        viewModel.start()
        try await Task.sleep(nanoseconds: 150_000_000)

        #expect(viewModel.items.map(\.id) == ["visible"])
    }

    @Test func unblockRestoresBlockedAuthorInFeed() async throws {
        let postRepository = MockFeedPostRepository()
        let blockRepository = MockBlockRepository()
        blockRepository.blockedIdsValue = ["blocked-user"]
        let posts = [
            makePost(id: "visible", authorId: "user-1"),
            makePost(id: "hidden", authorId: "blocked-user")
        ]
        postRepository.postsSubject.send(posts)

        let viewModel = FeedViewModel(
            postRepository: postRepository,
            profileRepository: MockFeedProfileRepository(),
            followRepository: MockFeedFollowRepository(),
            blockRepository: blockRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            sessionService: MockSessionService(currentUser: makeUser(id: "user-1")),
            hapticService: NoOpHapticService()
        )
        viewModel.start()
        try await Task.sleep(nanoseconds: 150_000_000)
        #expect(viewModel.items.map(\.id) == ["visible"])

        blockRepository.blockedIdsValue.remove("blocked-user")
        NotificationCenter.default.post(name: .blockedUsersDidChange, object: nil)
        postRepository.postsSubject.send(posts)
        try await Task.sleep(nanoseconds: 150_000_000)

        #expect(Set(viewModel.items.map(\.id)) == Set(["visible", "hidden"]))
    }

    @Test func selfBlockIsRejected() async {
        let blocks = MockBlockRepository()
        let viewModel = UserProfileViewModel(
            userId: "me",
            profileRepository: MockFeedProfileRepository(),
            postRepository: MockFeedPostRepository(),
            followRepository: MockFeedFollowRepository(),
            blockRepository: blocks,
            reportRepository: MockReportRepository(),
            localRepository: MockLocalRepository(),
            networkMonitor: MockNetworkMonitor(isConnected: true),
            sessionService: MockSessionService(currentUser: makeUser(id: "me")),
            hapticService: NoOpHapticService(),
            onPostDetail: { _ in },
            onEditProfile: {},
            onFollowing: {}
        )

        await viewModel.toggleBlock()

        #expect(blocks.blockCalls.isEmpty)
        #expect(!viewModel.canToggleBlock)
    }
}

@MainActor
private final class MockFeedPostRepository: PostRepositoryProtocol {
    let postsSubject = CurrentValueSubject<[Post], Never>([])
    var postsPublisher: AnyPublisher<[Post], Never> { postsSubject.eraseToAnyPublisher() }
    var likedPostIdsPublisher: AnyPublisher<Set<String>, Never> { Just([]).eraseToAnyPublisher() }
    func observeFeed(currentUserId: String, feedAuthorIds: [String]) {
        postsSubject.send(postsSubject.value)
    }
    func removeAllListeners() {}
    func refreshFeed(currentUserId: String, feedAuthorIds: [String]) async throws {}
    func loadMorePosts(currentUserId: String) async throws -> Bool { false }
    func fetchPosts(authorId: String) async throws -> [Post] { [] }
    func newPostId() -> String { "id" }
    func createPost(text: String, authorId: String, postId: String?, imageURL: String?) async throws {}
    func deletePost(id: String, authorId: String) async throws {}
    func likePost(id: String, userId: String) async throws {}
    func unlikePost(id: String, userId: String) async throws {}
    func likedPostIds(for postIds: [String], userId: String) async -> Set<String> { [] }
}

private struct MockFeedProfileRepository: ProfileRepositoryProtocol {
    func createProfile(uid: String, displayName: String, email: String) async throws -> User {
        makeUser(id: uid, displayName: displayName, email: email)
    }
    func fetchUser(id: String) async throws -> User? { makeUser(id: id) }
    func updateProfile(
        uid: String,
        displayName: String,
        bio: String?,
        profileImageData: Data?,
        removeProfileImage: Bool
    ) async throws -> User {
        makeUser(id: uid, displayName: displayName, bio: bio)
    }
    func searchUsers(prefix: String) async throws -> [User] { [] }
}

private final class MockFeedFollowRepository: FollowRepositoryProtocol {
    func follow(currentUserId: String, targetUserId: String) async throws {}
    func unfollow(currentUserId: String, targetUserId: String) async throws {}
    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool { false }
    func fetchFollowing(for userId: String) async throws -> [Follow] { [] }
    func followingIds(for userId: String) async throws -> [String] { ["blocked-user"] }
}
