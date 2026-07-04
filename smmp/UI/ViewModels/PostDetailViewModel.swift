//
//  PostDetailViewModel.swift
//  smmp
//

import Combine
import Foundation

@MainActor
final class PostDetailViewModel: ObservableObject {
    @Published var postItem: FeedPostItem
    @Published private(set) var commentItems: [CommentRowItem] = []
    @Published var commentText = ""
    @Published private(set) var isLoadingComments = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var isSubmittingComment = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showDeletePostConfirmation = false
    @Published var commentPendingDelete: CommentRowItem?
    @Published private(set) var shouldDismiss = false

    private let commentRepository: CommentRepositoryProtocol
    private let profileRepository: ProfileRepositoryProtocol
    private let postRepository: PostRepositoryProtocol
    private let networkMonitor: NetworkMonitor
    private var authorCache: [String: User] = [:]
    private let currentUserId: String

    var isPostAuthor: Bool {
        postItem.post.authorId == currentUserId
    }

    var isOffline: Bool {
        !networkMonitor.isConnected
    }

    var canSubmitComment: Bool {
        !trimmedCommentText.isEmpty && !isSubmittingComment && networkMonitor.isConnected
    }

    private var trimmedCommentText: String {
        commentText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(
        item: FeedPostItem,
        currentUserId: String,
        commentRepository: CommentRepositoryProtocol,
        profileRepository: ProfileRepositoryProtocol,
        postRepository: PostRepositoryProtocol,
        networkMonitor: NetworkMonitor
    ) {
        self.postItem = item
        self.currentUserId = currentUserId
        self.commentRepository = commentRepository
        self.profileRepository = profileRepository
        self.postRepository = postRepository
        self.networkMonitor = networkMonitor
        authorCache[item.author.id] = item.author
    }

    func canDeleteComment(_ item: CommentRowItem) -> Bool {
        item.comment.authorId == currentUserId
    }

    func loadComments() async {
        guard !isLoadingComments else { return }

        isLoadingComments = true
        defer { isLoadingComments = false }

        await fetchComments()
    }

    func refreshComments() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await fetchComments()
    }

    func addComment() async {
        guard canSubmitComment else { return }

        isSubmittingComment = true
        defer { isSubmittingComment = false }

        do {
            try await commentRepository.addComment(
                postId: postItem.post.id,
                text: commentText,
                authorId: currentUserId
            )
            commentText = ""
            postItem.post.commentCount += 1
            await fetchComments()
        } catch {
            presentError(CommentErrorMapper.message(for: error, fallback: String(localized: .commentErrorAdd)))
        }
    }

    func deleteComment(_ item: CommentRowItem) async {
        do {
            try await commentRepository.deleteComment(
                postId: item.comment.postId,
                commentId: item.comment.id,
                authorId: currentUserId
            )
            commentItems.removeAll { $0.id == item.id }
            postItem.post.commentCount = max(0, postItem.post.commentCount - 1)
            commentPendingDelete = nil
        } catch {
            presentError(CommentErrorMapper.message(for: error, fallback: String(localized: .commentErrorDelete)))
        }
    }

    func deletePost() async {
        do {
            try await postRepository.deletePost(
                id: postItem.post.id,
                authorId: currentUserId
            )
            shouldDismiss = true
        } catch {
            presentError(PostErrorMapper.message(for: error, fallback: String(localized: .postErrorDelete)))
        }
    }

    func toggleLike() async {
        let postId = postItem.post.id
        let wasLiked = postItem.isLikedByCurrentUser
        let previousCount = postItem.post.likeCount

        applyOptimisticLike(isLiked: !wasLiked)

        do {
            if wasLiked {
                try await postRepository.unlikePost(id: postId, userId: currentUserId)
            } else {
                try await postRepository.likePost(id: postId, userId: currentUserId)
            }
        } catch {
            applyOptimisticLike(isLiked: wasLiked, likeCount: previousCount)
            presentError(String(localized: .feedErrorLike))
        }
    }

    // MARK: - Private

    private func fetchComments() async {
        do {
            let comments = try await commentRepository.fetchComments(postId: postItem.post.id)
            var items: [CommentRowItem] = []

            for comment in comments {
                let author = await resolveAuthor(id: comment.authorId)
                items.append(CommentRowItem(comment: comment, author: author))
            }

            commentItems = items
        } catch {
            presentError(String(localized: .commentErrorLoad))
        }
    }

    private func resolveAuthor(id: String) async -> User {
        if let cached = authorCache[id] {
            return cached
        }

        if let user = try? await profileRepository.fetchUser(id: id) {
            authorCache[id] = user
            return user
        }

        let placeholder = User(id: id)
        authorCache[id] = placeholder
        return placeholder
    }

    private func applyOptimisticLike(isLiked: Bool, likeCount: Int? = nil) {
        postItem.isLikedByCurrentUser = isLiked
        if let likeCount {
            postItem.post.likeCount = likeCount
        } else {
            postItem.post.likeCount += isLiked ? 1 : -1
        }
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
