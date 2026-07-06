//
//  PostDetailViewModelTests.swift
//  smmpTests
//

import Combine
import Testing
@testable import smmp

@MainActor
struct PostDetailViewModelTests {

    @Test func offlineLikeDoesNotCallRepository() async {
        let postRepository = MockPostDetailPostRepository()
        let item = makeFeedPostItem(post: makePost(likeCount: 3))

        let viewModel = makeViewModel(
            item: item,
            postRepository: postRepository,
            networkMonitor: MockNetworkMonitor(isConnected: false)
        )

        await viewModel.toggleLike()

        #expect(postRepository.likeCallCount == 0)
        #expect(viewModel.postItem.isLikedByCurrentUser == false)
        #expect(viewModel.postItem.post.likeCount == 3)
    }

    @Test func offlineDeletePostDoesNotCallRepository() async {
        let postRepository = MockPostDetailPostRepository()
        let item = makeFeedPostItem(
            post: makePost(authorId: "me"),
            author: makeUser(id: "me")
        )

        let viewModel = makeViewModel(
            item: item,
            currentUserId: "me",
            postRepository: postRepository,
            networkMonitor: MockNetworkMonitor(isConnected: false)
        )

        await viewModel.deletePost()

        #expect(postRepository.deleteCallCount == 0)
        #expect(viewModel.shouldDismiss == false)
    }

    @Test func offlineAddCommentDoesNotCallRepository() async {
        let commentRepository = MockPostDetailCommentRepository()
        let item = makeFeedPostItem()

        let viewModel = makeViewModel(
            item: item,
            commentRepository: commentRepository,
            networkMonitor: MockNetworkMonitor(isConnected: false)
        )
        viewModel.commentText = "Hello"

        await viewModel.addComment()

        #expect(commentRepository.addCommentCallCount == 0)
        #expect(viewModel.commentText == "Hello")
    }

    @Test func offlineDeleteCommentDoesNotCallRepository() async {
        let comment = makeComment(authorId: "me")
        let commentRepository = MockPostDetailCommentRepository(comments: [comment])
        let item = makeFeedPostItem()

        let viewModel = makeViewModel(
            item: item,
            currentUserId: "me",
            commentRepository: commentRepository,
            networkMonitor: MockNetworkMonitor(isConnected: false)
        )

        await viewModel.loadComments()
        guard let commentItem = viewModel.commentItems.first else {
            Issue.record("Expected comment item")
            return
        }

        await viewModel.deleteComment(commentItem)

        #expect(commentRepository.deleteCommentCallCount == 0)
        #expect(viewModel.commentItems.count == 1)
    }

    @Test func isOfflineUpdatesFromConnectivityPublisher() {
        let networkMonitor = MockNetworkMonitor(isConnected: true)
        let viewModel = makeViewModel(
            item: makeFeedPostItem(),
            networkMonitor: networkMonitor
        )

        #expect(viewModel.isOffline == false)

        networkMonitor.setConnected(false)

        #expect(viewModel.isOffline == true)
    }

    // MARK: - Helpers

    private func makeViewModel(
        item: FeedPostItem,
        currentUserId: String = "me",
        commentRepository: CommentRepositoryProtocol = MockPostDetailCommentRepository(),
        profileRepository: ProfileRepositoryProtocol = MockPostDetailProfileRepository(),
        postRepository: PostRepositoryProtocol = MockPostDetailPostRepository(),
        networkMonitor: MockNetworkMonitor = MockNetworkMonitor(isConnected: true)
    ) -> PostDetailViewModel {
        PostDetailViewModel(
            item: item,
            currentUserId: currentUserId,
            commentRepository: commentRepository,
            profileRepository: profileRepository,
            postRepository: postRepository,
            networkMonitor: networkMonitor,
            hapticService: NoOpHapticService()
        )
    }
}

// MARK: - Mocks

private final class MockPostDetailPostRepository: PostRepositoryProtocol {
    private(set) var likeCallCount = 0
    private(set) var deleteCallCount = 0

    var postsPublisher: AnyPublisher<[Post], Never> {
        Just([]).eraseToAnyPublisher()
    }

    var likedPostIdsPublisher: AnyPublisher<Set<String>, Never> {
        Just([]).eraseToAnyPublisher()
    }

    func observeFeed(currentUserId: String, feedAuthorIds: [String]) {}

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

    func deletePost(id: String, authorId: String) async throws {
        deleteCallCount += 1
    }

    func likePost(id: String, userId: String) async throws {
        likeCallCount += 1
    }

    func unlikePost(id: String, userId: String) async throws {}

    func likedPostIds(for postIds: [String], userId: String) async -> Set<String> { [] }
}

private final class MockPostDetailCommentRepository: CommentRepositoryProtocol {
    private let comments: [Comment]
    private(set) var addCommentCallCount = 0
    private(set) var deleteCommentCallCount = 0

    init(comments: [Comment] = []) {
        self.comments = comments
    }

    func fetchComments(postId: String) async throws -> [Comment] { comments }

    func addComment(postId: String, text: String, authorId: String) async throws {
        addCommentCallCount += 1
    }

    func deleteComment(postId: String, commentId: String, authorId: String) async throws {
        deleteCommentCallCount += 1
    }
}

private struct MockPostDetailProfileRepository: ProfileRepositoryProtocol {
    func createProfile(uid: String, displayName: String, email: String) async throws -> User {
        makeUser(id: uid)
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
        makeUser(id: uid)
    }

    func searchUsers(prefix: String) async throws -> [User] { [] }
}
