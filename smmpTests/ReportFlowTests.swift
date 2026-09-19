//
//  ReportFlowTests.swift
//  smmpTests
//

import Combine
import Foundation
import Testing
@testable import smmp

@MainActor
struct ReportFlowTests {

    @Test func ownPostIsNotReportable() {
        let item = makeFeedPostItem(
            post: makePost(authorId: "me"),
            author: makeUser(id: "me")
        )
        let viewModel = PostDetailViewModel(
            item: item,
            currentUserId: "me",
            commentRepository: MockPostDetailCommentRepository(),
            profileRepository: MockPostDetailProfileRepository(),
            postRepository: MockPostDetailPostRepository(),
            reportRepository: MockReportRepository(),
            blockRepository: MockBlockRepository(),
            networkMonitor: MockNetworkMonitor(isConnected: true),
            hapticService: NoOpHapticService()
        )

        #expect(!viewModel.canReportPost)
    }

    @Test func reportingAnotherUsersPostCreatesPayload() async {
        let reports = MockReportRepository()
        let item = makeFeedPostItem(
            post: makePost(id: "post-9", authorId: "other"),
            author: makeUser(id: "other")
        )
        let viewModel = PostDetailViewModel(
            item: item,
            currentUserId: "me",
            commentRepository: MockPostDetailCommentRepository(),
            profileRepository: MockPostDetailProfileRepository(),
            postRepository: MockPostDetailPostRepository(),
            reportRepository: reports,
            blockRepository: MockBlockRepository(),
            networkMonitor: MockNetworkMonitor(isConnected: true),
            hapticService: NoOpHapticService()
        )

        await viewModel.reportPost(reason: .spam)

        #expect(reports.createdDrafts.count == 1)
        #expect(reports.createdDrafts.first?.targetType == .post)
        #expect(reports.createdDrafts.first?.targetId == "post-9")
        #expect(reports.createdDrafts.first?.reporterId == "me")
        #expect(reports.createdDrafts.first?.reason == .spam)
        #expect(viewModel.showReportConfirmation)
    }

    @Test func cannotReportOwnProfile() {
        let viewModel = UserProfileViewModel(
            userId: "me",
            profileRepository: MockPostDetailProfileRepository(),
            postRepository: MockPostDetailPostRepository(),
            followRepository: MockUserProfileFollowRepository(),
            blockRepository: MockBlockRepository(),
            reportRepository: MockReportRepository(),
            localRepository: MockLocalRepository(),
            networkMonitor: MockNetworkMonitor(isConnected: true),
            sessionService: MockSessionService(currentUser: makeUser(id: "me")),
            hapticService: NoOpHapticService(),
            onPostDetail: { _ in },
            onEditProfile: {},
            onFollowing: {}
        )

        #expect(!viewModel.canReportProfile)
        #expect(viewModel.isOwnProfile)
    }

    @Test func offlineReportDoesNotCreateDocument() async {
        let reports = MockReportRepository()
        let item = makeFeedPostItem(
            post: makePost(authorId: "other"),
            author: makeUser(id: "other")
        )
        let viewModel = PostDetailViewModel(
            item: item,
            currentUserId: "me",
            commentRepository: MockPostDetailCommentRepository(),
            profileRepository: MockPostDetailProfileRepository(),
            postRepository: MockPostDetailPostRepository(),
            reportRepository: reports,
            blockRepository: MockBlockRepository(),
            networkMonitor: MockNetworkMonitor(isConnected: false),
            hapticService: NoOpHapticService()
        )

        await viewModel.reportPost(reason: .harassment)

        #expect(reports.createdDrafts.isEmpty)
        #expect(!viewModel.canReportPost)
    }
}

private final class MockPostDetailPostRepository: PostRepositoryProtocol {
    var postsPublisher: AnyPublisher<[Post], Never> { Just([]).eraseToAnyPublisher() }
    var likedPostIdsPublisher: AnyPublisher<Set<String>, Never> { Just([]).eraseToAnyPublisher() }
    func observeFeed(currentUserId: String, feedAuthorIds: [String]) {}
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

private final class MockPostDetailCommentRepository: CommentRepositoryProtocol {
    func fetchComments(postId: String) async throws -> [smmp.Comment] { [] }
    func addComment(postId: String, text: String, authorId: String) async throws {}
    func deleteComment(postId: String, commentId: String, authorId: String) async throws {}
}

private struct MockPostDetailProfileRepository: ProfileRepositoryProtocol {
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

private final class MockUserProfileFollowRepository: FollowRepositoryProtocol {
    func follow(currentUserId: String, targetUserId: String) async throws {}
    func unfollow(currentUserId: String, targetUserId: String) async throws {}
    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool { false }
    func fetchFollowing(for userId: String) async throws -> [Follow] { [] }
    func followingIds(for userId: String) async throws -> [String] { [] }
}
