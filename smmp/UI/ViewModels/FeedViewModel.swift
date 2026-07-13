//
//  FeedViewModel.swift
//  smmp
//

import Combine
import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published private(set) var items: [FeedPostItem] = []
    @Published private(set) var isOffline = false
    @Published private(set) var hasCompletedInitialLoad = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isRefreshing = false
    @Published var showNewPostsBanner = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published private(set) var scrollToTopRequest = 0

    private let networkMonitor: NetworkMonitorProtocol
    private let postRepository: PostRepositoryProtocol
    private let profileRepository: ProfileRepositoryProtocol
    private let followRepository: FollowRepositoryProtocol
    private let sessionService: SessionServiceProtocol
    private let hapticService: HapticServiceProtocol
    private let onNavigate: (FeedRoute) -> Void

    private var cancellables = Set<AnyCancellable>()
    private var posts: [Post] = []
    private var likedPostIds = Set<String>()
    private var authorCache: [String: User] = [:]
    private var currentUserId: String?
    private var isAtTop = true
    private var acknowledgedTopPostId: String?
    private var hasStarted = false

    init(
        postRepository: PostRepositoryProtocol,
        profileRepository: ProfileRepositoryProtocol,
        followRepository: FollowRepositoryProtocol,
        networkMonitor: NetworkMonitorProtocol,
        sessionService: SessionServiceProtocol,
        hapticService: HapticServiceProtocol,
        onNavigate: @escaping (FeedRoute) -> Void = { _ in }
    ) {
        self.postRepository = postRepository
        self.profileRepository = profileRepository
        self.followRepository = followRepository
        self.networkMonitor = networkMonitor
        self.sessionService = sessionService
        self.hapticService = hapticService
        self.onNavigate = onNavigate
        bindPublishers()
    }

    func showPostDetail(for item: FeedPostItem) {
        onNavigate(.postDetail(item))
    }

    func showAuthorProfile(author: User) {
        onNavigate(.userProfile(userId: author.id, stub: author))
    }

    func start() {
        guard let userId = sessionService.currentUser?.id else { return }
        currentUserId = userId
        isOffline = !networkMonitor.isConnected

        guard !hasStarted else { return }
        hasStarted = true
        hasCompletedInitialLoad = false
        Task { await reloadFeed(userId: userId) }
    }

    func refresh() async {
        guard let userId = currentUserId else { return }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let authorIds = await resolveFeedAuthorIds(for: userId)
            try await postRepository.refreshFeed(currentUserId: userId, feedAuthorIds: authorIds)
        } catch {
            presentError(String(localized: .feedErrorRefresh))
        }
    }

    func loadMoreIfNeeded(currentItem: FeedPostItem) async {
        guard let userId = currentUserId,
              !isLoadingMore,
              currentItem.id == items.last?.id else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        _ = try? await postRepository.loadMorePosts(currentUserId: userId)
    }

    func toggleLike(for item: FeedPostItem) async {
        guard let userId = currentUserId, !isOffline else { return }

        let postId = item.id
        let wasLiked = item.isLikedByCurrentUser
        let previousCount = item.post.likeCount

        applyOptimisticLike(postId: postId, isLiked: !wasLiked)
        hapticService.playLike()

        do {
            if wasLiked {
                try await postRepository.unlikePost(id: postId, userId: userId)
            } else {
                try await postRepository.likePost(id: postId, userId: userId)
            }
        } catch {
            applyOptimisticLike(postId: postId, isLiked: wasLiked, likeCount: previousCount)
            presentError(String(localized: .feedErrorLike))
        }
    }

    func revealNewPosts() {
        isAtTop = true
        acknowledgedTopPostId = posts.first?.id
        showNewPostsBanner = false
        scrollToTopRequest += 1
    }

    func updateScrollAtTop(_ atTop: Bool) {
        isAtTop = atTop
        if atTop {
            acknowledgedTopPostId = posts.first?.id
            showNewPostsBanner = false
        }
    }

    // MARK: - Private

    private func bindPublishers() {
        postRepository.postsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] posts in
                guard let self else { return }
                Task { await self.handlePostsUpdate(posts) }
            }
            .store(in: &cancellables)

        postRepository.likedPostIdsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] likedIds in
                guard let self else { return }
                Task { await self.handleLikedIdsUpdate(likedIds) }
            }
            .store(in: &cancellables)

        ConnectivityBinding.bind(monitor: networkMonitor,
                                 cancellables: &cancellables) { [weak self] isConnected, wasConnected in
            guard let self else { return }
            self.isOffline = !isConnected
            if isConnected, !wasConnected, let userId = self.currentUserId {
                Task { await self.reloadFeed(userId: userId) }
            }
        }
    }

    private func reloadFeed(userId: String) async {
        let authorIds = await resolveFeedAuthorIds(for: userId)
        postRepository.observeFeed(currentUserId: userId, feedAuthorIds: authorIds)
    }

    private func resolveFeedAuthorIds(for userId: String) async -> [String] {
        let followingIds = (try? await followRepository.followingIds(for: userId)) ?? []
        return FeedAuthorIds.authorIds(currentUserId: userId, followingIds: followingIds)
    }

    private func handlePostsUpdate(_ newPosts: [Post]) async {
        guard hasStarted else { return }

        if !isAtTop,
           let newTopId = newPosts.first?.id,
           newTopId != acknowledgedTopPostId {
            showNewPostsBanner = true
        }

        if isAtTop {
            acknowledgedTopPostId = newPosts.first?.id
        }

        posts = newPosts
        await rebuildItems()
        hasCompletedInitialLoad = true
    }

    private func handleLikedIdsUpdate(_ likedIds: Set<String>) async {
        likedPostIds = likedIds
        await rebuildItems()
    }

    private func rebuildItems() async {
        var newItems: [FeedPostItem] = []

        for post in posts {
            let author = await resolveAuthor(id: post.authorId)
            let isLiked = likedPostIds.contains(post.id)
            newItems.append(
                FeedPostItem(
                    post: post,
                    author: author,
                    isLikedByCurrentUser: isLiked
                )
            )
        }

        items = newItems
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

    private func applyOptimisticLike(postId: String, isLiked: Bool, likeCount: Int? = nil) {
        guard let index = items.firstIndex(where: { $0.id == postId }) else { return }

        var item = items[index]
        item.isLikedByCurrentUser = isLiked
        if let likeCount {
            item.post.likeCount = likeCount
        } else {
            item.post.likeCount += isLiked ? 1 : -1
        }
        items[index] = item

        if isLiked {
            likedPostIds.insert(postId)
        } else {
            likedPostIds.remove(postId)
        }
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
