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
    @Published private(set) var isOffline = false
    @Published private(set) var isLoadingComments = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var isSubmittingComment = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showDeletePostConfirmation = false
    @Published var commentPendingDelete: CommentRowItem?
    @Published private(set) var shouldDismiss = false
    @Published var showReportSheet = false
    @Published var commentPendingReport: CommentRowItem?
    @Published var showReportConfirmation = false

    private let commentRepository: CommentRepositoryProtocol
    private let profileRepository: ProfileRepositoryProtocol
    private let postRepository: PostRepositoryProtocol
    private let reportRepository: ReportRepositoryProtocol
    private let blockRepository: BlockRepositoryProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let hapticService: HapticServiceProtocol
    private let contentFilter: ContentFiltering
    private let onAuthorTap: (User) -> Void
    private var authorCache: [String: User] = [:]
    private let currentUserId: String
    private var blockedIds = Set<String>()
    private var cancellables = Set<AnyCancellable>()
    private var isScreenActive = false

    var isPostAuthor: Bool {
        postItem.post.authorId == currentUserId
    }

    var canSubmitComment: Bool {
        !trimmedCommentText.isEmpty && !isSubmittingComment && !isOffline
    }

    var canDeletePost: Bool {
        isPostAuthor && !isOffline
    }

    var canReportPost: Bool {
        !isPostAuthor && !isOffline
    }

    var showReportCommentSheet: Bool {
        get { commentPendingReport != nil }
        set { if !newValue { commentPendingReport = nil } }
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
        reportRepository: ReportRepositoryProtocol,
        blockRepository: BlockRepositoryProtocol,
        networkMonitor: NetworkMonitorProtocol,
        hapticService: HapticServiceProtocol,
        contentFilter: ContentFiltering = ContentFilter.default,
        onAuthorTap: @escaping (User) -> Void = { _ in }
    ) {
        self.postItem = item
        self.currentUserId = currentUserId
        self.commentRepository = commentRepository
        self.profileRepository = profileRepository
        self.postRepository = postRepository
        self.reportRepository = reportRepository
        self.blockRepository = blockRepository
        self.networkMonitor = networkMonitor
        self.hapticService = hapticService
        self.contentFilter = contentFilter
        self.onAuthorTap = onAuthorTap
        authorCache[item.author.id] = item.author
        isOffline = !networkMonitor.isConnected
        bindConnectivity()
    }

    func onAppear() {
        isScreenActive = true
    }

    func onDisappear() {
        isScreenActive = false
    }

    func showAuthorProfile(authorId: String) {
        let user = authorCache[authorId] ?? User(id: authorId)
        onAuthorTap(user)
    }

    func canDeleteComment(_ item: CommentRowItem) -> Bool {
        item.comment.authorId == currentUserId && !isOffline
    }

    func canReportComment(_ item: CommentRowItem) -> Bool {
        item.comment.authorId != currentUserId && !isOffline
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

        if contentFilter.containsDeniedContent(trimmedCommentText) {
            presentError(String(localized: .contentFilterError))
            return
        }

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
        guard !isOffline else { return }

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

    func reportPost(reason: ReportReason) async {
        guard canReportPost else {
            if isOffline {
                presentError(String(localized: .reportErrorOffline))
            }
            return
        }

        do {
            _ = try await reportRepository.createReport(
                ReportDraft(
                    reporterId: currentUserId,
                    targetType: .post,
                    targetId: postItem.post.id,
                    targetOwnerId: postItem.post.authorId,
                    parentPostId: nil,
                    reason: reason
                )
            )
            showReportConfirmation = true
        } catch {
            presentError(reportErrorMessage(for: error))
        }
    }

    func reportComment(_ item: CommentRowItem, reason: ReportReason) async {
        guard canReportComment(item) else {
            if isOffline {
                presentError(String(localized: .reportErrorOffline))
            }
            return
        }

        do {
            _ = try await reportRepository.createReport(
                ReportDraft(
                    reporterId: currentUserId,
                    targetType: .comment,
                    targetId: item.comment.id,
                    targetOwnerId: item.comment.authorId,
                    parentPostId: item.comment.postId,
                    reason: reason
                )
            )
            commentPendingReport = nil
            showReportConfirmation = true
        } catch {
            presentError(reportErrorMessage(for: error))
        }
    }

    func deletePost() async {
        guard !isOffline else { return }

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
        guard !isOffline else { return }

        let postId = postItem.post.id
        let wasLiked = postItem.isLikedByCurrentUser
        let previousCount = postItem.post.likeCount

        applyOptimisticLike(isLiked: !wasLiked)
        hapticService.playLike()

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

    private func bindConnectivity() {
        ConnectivityBinding.bind(monitor: networkMonitor,
                                 cancellables: &cancellables) { [weak self] isConnected, wasConnected in
            guard let self else { return }
            self.isOffline = !isConnected
            if isConnected, !wasConnected, self.isScreenActive {
                Task { await self.fetchComments() }
            }
        }
    }

    private func fetchComments() async {
        if networkMonitor.isConnected {
            blockedIds = (try? await blockRepository.blockedIds(for: currentUserId)) ?? blockedIds
        }

        do {
            let comments = try await commentRepository.fetchComments(postId: postItem.post.id)
            var items: [CommentRowItem] = []

            for comment in comments where !blockedIds.contains(comment.authorId) {
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

    private func reportErrorMessage(for error: Error) -> String {
        if error as? ReportRepositoryError == .cannotReportOwnContent {
            return String(localized: .reportErrorGeneric)
        }
        return String(localized: .reportErrorGeneric)
    }
}
