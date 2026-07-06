//
//  ProfileViewModel.swift
//  smmp
//

import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var items: [FeedPostItem] = []
    @Published private(set) var isOffline = false
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let authRepository: AuthRepositoryProtocol
    private let profileRepository: ProfileRepositoryProtocol
    private let postRepository: PostRepositoryProtocol
    private let localRepository: LocalRepositoryProtocol
    private let networkMonitor: NetworkMonitor
    private let sessionService: SessionServiceProtocol
    private let onNavigate: (ProfileRoute) -> Void

    private var likedPostIds = Set<String>()
    private var cancellables = Set<AnyCancellable>()

    var canEditProfile: Bool {
        !isOffline
    }

    init(
        authRepository: AuthRepositoryProtocol,
        profileRepository: ProfileRepositoryProtocol,
        postRepository: PostRepositoryProtocol,
        localRepository: LocalRepositoryProtocol,
        networkMonitor: NetworkMonitor,
        sessionService: SessionServiceProtocol,
        onNavigate: @escaping (ProfileRoute) -> Void = { _ in }
    ) {
        self.authRepository = authRepository
        self.profileRepository = profileRepository
        self.postRepository = postRepository
        self.localRepository = localRepository
        self.networkMonitor = networkMonitor
        self.sessionService = sessionService
        self.onNavigate = onNavigate
        bindNetworkMonitor()
        bindProfileUpdates()
        bindFollowingUpdates()
    }

    func load() async {
        guard let userId = sessionService.currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        isOffline = !networkMonitor.isConnected

        do {
            let profile = try await profileRepository.fetchUser(id: userId)
            user = profile

            let posts: [Post]
            if networkMonitor.isConnected {
                posts = try await postRepository.fetchPosts(authorId: userId)
            } else {
                posts = try await loadCachedPosts(for: userId)
            }

            if networkMonitor.isConnected {
                likedPostIds = await postRepository.likedPostIds(
                    for: posts.map(\.id),
                    userId: userId
                )
            }

            rebuildItems(posts: posts)
        } catch {
            presentError(String(localized: .profileErrorLoad))
        }
    }

    func refresh() async {
        guard sessionService.currentUser?.id != nil else { return }

        isRefreshing = true
        defer { isRefreshing = false }

        await load()
    }

    func followingTapped() {
        onNavigate(.following)
    }

    func showPostDetail(for item: FeedPostItem) {
        onNavigate(.postDetail(item))
    }

    func editProfileTapped() {
        guard canEditProfile else { return }
        onNavigate(.editProfile)
    }

    func logout() async {
        try? await authRepository.signOut()
    }

    func toggleLike(for item: FeedPostItem) async {
        guard let userId = sessionService.currentUser?.id, !isOffline else { return }

        let postId = item.id
        let wasLiked = item.isLikedByCurrentUser
        let previousCount = item.post.likeCount

        applyOptimisticLike(postId: postId, isLiked: !wasLiked)

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

    // MARK: - Private

    private func bindNetworkMonitor() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOffline = !isConnected
            }
            .store(in: &cancellables)
    }

    private func bindProfileUpdates() {
        NotificationCenter.default.publisher(for: .profileDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.load() }
            }
            .store(in: &cancellables)
    }

    private func bindFollowingUpdates() {
        NotificationCenter.default.publisher(for: .followingDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.load() }
            }
            .store(in: &cancellables)
    }

    private func loadCachedPosts(for userId: String) async throws -> [Post] {
        try await localRepository.fetchPosts()
            .filter { $0.authorId == userId }
    }

    private func rebuildItems(posts: [Post]) {
        guard let author = user else {
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
