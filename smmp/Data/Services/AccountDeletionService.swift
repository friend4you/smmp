//
//  AccountDeletionService.swift
//  smmp
//

import Foundation

final class AccountDeletionService: AccountDeleting {
    private let postRepository: PostRepositoryProtocol
    private let commentRepository: CommentRepositoryProtocol
    private let followRepository: FollowRepositoryProtocol
    private let blockRepository: BlockRepositoryProtocol
    private let mediaService: MediaServiceProtocol
    private let userDocuments: UserDocumentProtocol
    private let accountDeleter: AuthAccountDeleting
    private let authRepository: AuthRepositoryProtocol

    init(
        postRepository: PostRepositoryProtocol,
        commentRepository: CommentRepositoryProtocol,
        followRepository: FollowRepositoryProtocol,
        blockRepository: BlockRepositoryProtocol,
        mediaService: MediaServiceProtocol,
        userDocuments: UserDocumentProtocol,
        accountDeleter: AuthAccountDeleting,
        authRepository: AuthRepositoryProtocol
    ) {
        self.postRepository = postRepository
        self.commentRepository = commentRepository
        self.followRepository = followRepository
        self.blockRepository = blockRepository
        self.mediaService = mediaService
        self.userDocuments = userDocuments
        self.accountDeleter = accountDeleter
        self.authRepository = authRepository
    }

    func deleteAccount(userId: String) async throws {
        guard !userId.isEmpty else { throw AccountDeletionError.missingUser }

        let posts = try await postRepository.fetchPosts(authorId: userId)
        for post in posts {
            try await postRepository.deletePost(id: post.id, authorId: userId)
        }

        try await commentRepository.deleteCommentsAuthored(by: userId)
        try await postRepository.deleteLikes(byUserId: userId)

        let followingIds = try await followRepository.followingIds(for: userId)
        for followedId in followingIds {
            try await followRepository.unfollow(currentUserId: userId, targetUserId: followedId)
        }

        try await blockRepository.deleteAllBlocks(for: userId)
        try await mediaService.deleteProfileImage(userId: userId)
        try await userDocuments.deleteUserDocument(id: userId)

        try await accountDeleter.deleteCurrentUser()
        try? await authRepository.signOut()
    }
}
