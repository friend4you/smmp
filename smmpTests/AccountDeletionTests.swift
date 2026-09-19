//
//  AccountDeletionTests.swift
//  smmpTests
//

import Combine
import Foundation
import Testing
@testable import smmp

@MainActor
struct AccountDeletionTests {

    @Test func cascadeDeletesAuthLast() async throws {
        let recorder = DeletionRecorder()
        let service = AccountDeletionService(
            postRepository: recorder,
            commentRepository: recorder,
            followRepository: recorder,
            blockRepository: recorder,
            mediaService: recorder,
            userDocuments: recorder,
            accountDeleter: recorder,
            authRepository: recorder
        )

        try await service.deleteAccount(userId: "me")

        #expect(recorder.steps == [
            "fetchPosts",
            "deletePost",
            "deleteComments",
            "deleteLikes",
            "followingIds",
            "unfollow",
            "deleteBlocks",
            "deleteAvatar",
            "deleteUserDoc",
            "deleteAuth",
            "signOut"
        ])
    }

    @Test func cascadeFailureBeforeAuthKeepsAuthUser() async {
        let recorder = DeletionRecorder()
        recorder.failAt = "deleteComments"
        let service = AccountDeletionService(
            postRepository: recorder,
            commentRepository: recorder,
            followRepository: recorder,
            blockRepository: recorder,
            mediaService: recorder,
            userDocuments: recorder,
            accountDeleter: recorder,
            authRepository: recorder
        )

        await #expect(throws: MockAuthError.notConfigured) {
            try await service.deleteAccount(userId: "me")
        }
        #expect(!recorder.steps.contains("deleteAuth"))
        #expect(recorder.steps.contains("deletePost"))
    }

    @Test func confirmationCancelDoesNotDelete() async {
        let deletion = MockAccountDeletionService()
        let reauth = MockAuthReauthenticator()
        let viewModel = ProfileViewModel(
            authRepository: MockAuthRepository(),
            profileRepository: MockDeletionProfileRepository(),
            postRepository: MockFeedPostRepository(),
            localRepository: MockLocalRepository(),
            networkMonitor: MockNetworkMonitor(isConnected: true),
            sessionService: MockSessionService(currentUser: makeUser(id: "me")),
            hapticService: NoOpHapticService(),
            authReauthenticator: reauth,
            accountDeletionService: deletion
        )

        viewModel.requestDeleteAccount()
        #expect(viewModel.showDeleteConfirmation)
        viewModel.cancelDeleteAccount()

        #expect(!viewModel.showDeleteConfirmation)
        #expect(deletion.deletedUserIds.isEmpty)
        #expect(reauth.passwords.isEmpty)
    }

    @Test func offlineDeleteDoesNotStart() async {
        let deletion = MockAccountDeletionService()
        let viewModel = ProfileViewModel(
            authRepository: MockAuthRepository(),
            profileRepository: MockDeletionProfileRepository(),
            postRepository: MockFeedPostRepository(),
            localRepository: MockLocalRepository(),
            networkMonitor: MockNetworkMonitor(isConnected: false),
            sessionService: MockSessionService(currentUser: makeUser(id: "me")),
            hapticService: NoOpHapticService(),
            authReauthenticator: MockAuthReauthenticator(),
            accountDeletionService: deletion
        )

        try? await Task.sleep(nanoseconds: 50_000_000)
        viewModel.requestDeleteAccount()

        #expect(!viewModel.canDeleteAccount)
        #expect(deletion.deletedUserIds.isEmpty)
        #expect(!viewModel.showDeleteConfirmation)
    }
}

private final class DeletionRecorder: PostRepositoryProtocol, CommentRepositoryProtocol, FollowRepositoryProtocol, BlockRepositoryProtocol, MediaServiceProtocol, UserDocumentProtocol, AuthAccountDeleting, AuthRepositoryProtocol, @unchecked Sendable {
    var steps: [String] = []
    var failAt: String?

    var postsPublisher: AnyPublisher<[Post], Never> { Just([]).eraseToAnyPublisher() }
    var likedPostIdsPublisher: AnyPublisher<Set<String>, Never> { Just([]).eraseToAnyPublisher() }
    var uploadProgressPublisher: AnyPublisher<Double, Never> { Just(0).eraseToAnyPublisher() }

    private func record(_ step: String) throws {
        steps.append(step)
        if failAt == step { throw MockAuthError.notConfigured }
    }

    func observeFeed(currentUserId: String, feedAuthorIds: [String]) {}
    func removeAllListeners() {}
    func refreshFeed(currentUserId: String, feedAuthorIds: [String]) async throws {}
    func loadMorePosts(currentUserId: String) async throws -> Bool { false }
    func fetchPosts(authorId: String) async throws -> [Post] {
        try record("fetchPosts")
        return [makePost(id: "post-1", authorId: authorId)]
    }
    func newPostId() -> String { "id" }
    func createPost(text: String, authorId: String, postId: String?, imageURL: String?) async throws {}
    func deletePost(id: String, authorId: String) async throws { try record("deletePost") }
    func likePost(id: String, userId: String) async throws {}
    func unlikePost(id: String, userId: String) async throws {}
    func likedPostIds(for postIds: [String], userId: String) async -> Set<String> { [] }
    func deleteLikes(byUserId userId: String) async throws { try record("deleteLikes") }

    func fetchComments(postId: String) async throws -> [smmp.Comment] { [] }
    func addComment(postId: String, text: String, authorId: String) async throws {}
    func deleteComment(postId: String, commentId: String, authorId: String) async throws {}
    func deleteCommentsAuthored(by userId: String) async throws { try record("deleteComments") }

    func follow(currentUserId: String, targetUserId: String) async throws {}
    func unfollow(currentUserId: String, targetUserId: String) async throws { try record("unfollow") }
    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool { false }
    func fetchFollowing(for userId: String) async throws -> [Follow] { [] }
    func followingIds(for userId: String) async throws -> [String] {
        try record("followingIds")
        return ["other"]
    }

    func block(currentUserId: String, targetUserId: String) async throws {}
    func unblock(currentUserId: String, targetUserId: String) async throws {}
    func isBlocked(currentUserId: String, targetUserId: String) async throws -> Bool { false }
    func blockedIds(for userId: String) async throws -> Set<String> { [] }
    func deleteAllBlocks(for userId: String) async throws { try record("deleteBlocks") }

    func uploadPostImage(_ imageData: Data, postId: String, authorId: String) async throws -> String { "" }
    func deletePostImage(postId: String, authorId: String) async throws {}
    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> String { "" }
    func deleteProfileImage(userId: String) async throws { try record("deleteAvatar") }

    func fetchUserDocument(id: String) async throws -> User? { nil }
    func createUserDocument(id: String, data: [String: Any]) async throws {}
    func updateUserDocument(id: String, data: [String: Any]) async throws {}
    func deleteUserDocument(id: String) async throws { try record("deleteUserDoc") }
    func searchUsers(prefix: String, limit: Int) async throws -> [User] { [] }

    func deleteCurrentUser() async throws { try record("deleteAuth") }
    func login(email: String, password: String) async throws -> User { makeUser() }
    func register(displayName: String, email: String, password: String) async throws -> User { makeUser() }
    func signOut() async throws { try record("signOut") }
    func sendPasswordReset(email: String) async throws {}
}

private struct MockDeletionProfileRepository: ProfileRepositoryProtocol {
    func createProfile(uid: String, displayName: String, email: String) async throws -> User {
        makeUser(id: uid)
    }
    func fetchUser(id: String) async throws -> User? { makeUser(id: id) }
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

@MainActor
private final class MockFeedPostRepository: PostRepositoryProtocol {
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
