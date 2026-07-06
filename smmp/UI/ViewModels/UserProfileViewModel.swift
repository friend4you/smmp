//
//  UserProfileViewModel.swift
//  smmp
//

import Combine
import Foundation

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var items: [FeedPostItem] = []
    @Published private(set) var isFollowing = false
    @Published private(set) var isOffline = false
    @Published private(set) var hasCompletedInitialLoad = false
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var isFollowActionInProgress = false
    @Published var errorMessage: String?
    @Published var showError = false

    let userId: String

    private let userStub: User?
    private let profileRepository: ProfileRepositoryProtocol
    private let postRepository: PostRepositoryProtocol
    private let followRepository: FollowRepositoryProtocol
    private let localRepository: LocalRepositoryProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let sessionService: SessionServiceProtocol
    private let hapticService: HapticServiceProtocol
    private let onPostDetail: (FeedPostItem) -> Void
    private let onEditProfile: () -> Void
    private let onFollowing: () -> Void

    private var likedPostIds = Set<String>()
    private var cancellables = Set<AnyCancellable>()
    private var isScreenActive = false

    var isOwnProfile: Bool {
        sessionService.currentUser?.id == userId
    }

    var showsFollowButton: Bool {
        !isOwnProfile
    }

    var showsEditButton: Bool {
        isOwnProfile
    }

    var canEditProfile: Bool {
        isOwnProfile && !isOffline
    }

    var canToggleFollow: Bool {
        !isOwnProfile && !isOffline && !isFollowActionInProgress
    }

    init(
        userId: String,
        userStub: User? = nil,
        profileRepository: ProfileRepositoryProtocol,
        postRepository: PostRepositoryProtocol,
        followRepository: FollowRepositoryProtocol,
        localRepository: LocalRepositoryProtocol,
        networkMonitor: NetworkMonitorProtocol,
        sessionService: SessionServiceProtocol,
        hapticService: HapticServiceProtocol = HapticService(),
        onPostDetail: @escaping (FeedPostItem) -> Void,
        onEditProfile: @escaping () -> Void,
        onFollowing: @escaping () -> Void
    ) {
        self.userId = userId
        self.userStub = userStub
        self.profileRepository = profileRepository
        self.postRepository = postRepository
        self.followRepository = followRepository
        self.localRepository = localRepository
        self.networkMonitor = networkMonitor
        self.sessionService = sessionService
        self.hapticService = hapticService
        self.onPostDetail = onPostDetail
        self.onEditProfile = onEditProfile
        self.onFollowing = onFollowing
        bindNetworkMonitor()
        bindProfileUpdates()
        bindFollowingUpdates()
    }

    func onAppear() {
        isScreenActive = true
    }

    func onDisappear() {
        isScreenActive = false
    }

    func load() async {
        isLoading = true
        hasCompletedInitialLoad = false
        defer {
            isLoading = false
            hasCompletedInitialLoad = true
        }

        isOffline = !networkMonitor.isConnected

        do {
            let profile = try await profileRepository.fetchUser(id: userId)
            user = profile ?? (isOffline ? userStub : nil)

            let posts: [Post]
            if networkMonitor.isConnected {
                posts = try await postRepository.fetchPosts(authorId: userId)
            } else {
                posts = try await loadCachedPosts()
            }

            if let currentUserId = sessionService.currentUser?.id, networkMonitor.isConnected {
                likedPostIds = await postRepository.likedPostIds(
                    for: posts.map(\.id),
                    userId: currentUserId
                )

                if !isOwnProfile {
                    isFollowing = try await followRepository.isFollowing(
                        currentUserId: currentUserId,
                        targetUserId: userId
                    )
                }
            }

            rebuildItems(posts: posts)
        } catch {
            if isOffline, user == nil {
                user = userStub
                if let cachedPosts = try? await loadCachedPosts() {
                    rebuildItems(posts: cachedPosts)
                    return
                }
            }
            presentError(String(localized: .profileErrorLoad))
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await load()
    }

    func followingTapped() {
        guard isOwnProfile else { return }
        onFollowing()
    }

    func showPostDetail(for item: FeedPostItem) {
        onPostDetail(item)
    }

    func editProfileTapped() {
        guard canEditProfile else { return }
        onEditProfile()
    }

    func toggleFollow() async {
        guard canToggleFollow,
              let currentUserId = sessionService.currentUser?.id else { return }

        isFollowActionInProgress = true
        defer { isFollowActionInProgress = false }

        let wasFollowing = isFollowing

        do {
            if wasFollowing {
                try await followRepository.unfollow(
                    currentUserId: currentUserId,
                    targetUserId: userId
                )
                isFollowing = false
                adjustFollowerCount(by: -1)
            } else {
                try await followRepository.follow(
                    currentUserId: currentUserId,
                    targetUserId: userId
                )
                isFollowing = true
                adjustFollowerCount(by: 1)
            }
            hapticService.playFollowToggle()
        } catch {
            presentError(
                FollowErrorMapper.message(
                    for: error,
                    fallback: String(localized: .followErrorGeneric)
                )
            )
        }
    }

    func toggleLike(for item: FeedPostItem) async {
        guard let currentUserId = sessionService.currentUser?.id, !isOffline else { return }

        let postId = item.id
        let wasLiked = item.isLikedByCurrentUser
        let previousCount = item.post.likeCount

        applyOptimisticLike(postId: postId, isLiked: !wasLiked)
        hapticService.playLike()

        do {
            if wasLiked {
                try await postRepository.unlikePost(id: postId, userId: currentUserId)
            } else {
                try await postRepository.likePost(id: postId, userId: currentUserId)
            }
        } catch {
            applyOptimisticLike(postId: postId, isLiked: wasLiked, likeCount: previousCount)
            presentError(String(localized: .feedErrorLike))
        }
    }

    // MARK: - Private

    private func bindNetworkMonitor() {
        ConnectivityBinding.bind(monitor: networkMonitor, cancellables: &cancellables) { [weak self] isConnected, wasConnected in
            guard let self else { return }
            self.isOffline = !isConnected
            if isConnected, !wasConnected, self.isScreenActive {
                Task { await self.load() }
            }
        }
    }

    private func bindProfileUpdates() {
        NotificationCenter.default.publisher(for: .profileDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.isOwnProfile else { return }
                Task { await self.load() }
            }
            .store(in: &cancellables)
    }

    private func bindFollowingUpdates() {
        NotificationCenter.default.publisher(for: .followingDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.isOwnProfile else { return }
                Task { await self.load() }
            }
            .store(in: &cancellables)
    }

    private func loadCachedPosts() async throws -> [Post] {
        try await localRepository.fetchPosts()
            .filter { $0.authorId == userId }
    }

    private func rebuildItems(posts: [Post]) {
        guard let author = user ?? userStub else {
            items = []
            return
        }

        items = posts.map { post in
            FeedPostItem(
                post: post,
                author: author,
                isLikedByCurrentUser: likedPostIds.contains(post.id)
            )
        }
    }

    private func adjustFollowerCount(by delta: Int) {
        guard var profile = user else { return }
        profile.followerCount = max(0, profile.followerCount + delta)
        user = profile
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
