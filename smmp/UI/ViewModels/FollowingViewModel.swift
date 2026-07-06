//
//  FollowingViewModel.swift
//  smmp
//

import Combine
import Foundation

struct FollowingUserRow: Identifiable {
    let user: User
    let followedAt: Date?

    var id: String { user.id }
}

@MainActor
final class FollowingViewModel: ObservableObject {
    @Published private(set) var rows: [FollowingUserRow] = []
    @Published private(set) var isOffline = false
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var unfollowInProgressIds = Set<String>()
    @Published var errorMessage: String?
    @Published var showError = false

    private let followRepository: FollowRepositoryProtocol
    private let profileRepository: ProfileRepositoryProtocol
    private let sessionService: SessionServiceProtocol
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()

    init(
        followRepository: FollowRepositoryProtocol,
        profileRepository: ProfileRepositoryProtocol,
        sessionService: SessionServiceProtocol,
        networkMonitor: NetworkMonitor
    ) {
        self.followRepository = followRepository
        self.profileRepository = profileRepository
        self.sessionService = sessionService
        self.networkMonitor = networkMonitor
        bindNetworkMonitor()
    }

    func load() async {
        guard let currentUserId = sessionService.currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        isOffline = !networkMonitor.isConnected

        guard networkMonitor.isConnected else {
            rows = []
            return
        }

        do {
            let follows = try await followRepository.fetchFollowing(for: currentUserId)
            rows = try await resolveUsers(from: follows)
        } catch {
            presentError(String(localized: .followListErrorLoad))
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await load()
    }

    func canUnfollow(userId: String) -> Bool {
        !isOffline && !unfollowInProgressIds.contains(userId)
    }

    func unfollow(userId: String) async {
        guard canUnfollow(userId: userId),
              let currentUserId = sessionService.currentUser?.id else { return }

        unfollowInProgressIds.insert(userId)
        defer { unfollowInProgressIds.remove(userId) }

        do {
            try await followRepository.unfollow(
                currentUserId: currentUserId,
                targetUserId: userId
            )
            rows.removeAll { $0.id == userId }
            NotificationCenter.default.post(name: .followingDidChange, object: nil)
        } catch {
            presentError(
                FollowErrorMapper.message(
                    for: error,
                    fallback: String(localized: .followErrorGeneric)
                )
            )
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

    private func resolveUsers(from follows: [Follow]) async throws -> [FollowingUserRow] {
        var resolved: [FollowingUserRow] = []

        for follow in follows {
            guard let user = try await profileRepository.fetchUser(id: follow.userId) else {
                continue
            }
            resolved.append(FollowingUserRow(user: user, followedAt: follow.followedAt))
        }

        return resolved
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
