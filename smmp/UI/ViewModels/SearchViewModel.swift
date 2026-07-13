//
//  SearchViewModel.swift
//  smmp
//

import Combine
import Foundation

struct SearchUserResult: Identifiable {
    let user: User
    var isFollowing: Bool
    let isSelf: Bool

    var id: String { user.id }
}

@MainActor
final class SearchViewModel: ObservableObject {
    static let minQueryLength = 2
    static let debounceInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300)

    @Published var query = ""
    @Published private(set) var results: [SearchUserResult] = []
    @Published private(set) var isOffline = false
    @Published private(set) var isSearching = false
    @Published private(set) var hasSearched = false
    @Published private(set) var followInProgressIds = Set<String>()
    @Published var errorMessage: String?
    @Published var showError = false

    private let profileRepository: ProfileRepositoryProtocol
    private let followRepository: FollowRepositoryProtocol
    private let sessionService: SessionServiceProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let hapticService: HapticServiceProtocol
    private let onNavigate: (SearchRoute) -> Void

    private var cancellables = Set<AnyCancellable>()
    private var activeSearchID = 0

    init(
        profileRepository: ProfileRepositoryProtocol,
        followRepository: FollowRepositoryProtocol,
        sessionService: SessionServiceProtocol,
        networkMonitor: NetworkMonitorProtocol,
        hapticService: HapticServiceProtocol,
        onNavigate: @escaping (SearchRoute) -> Void = { _ in }
    ) {
        self.profileRepository = profileRepository
        self.followRepository = followRepository
        self.sessionService = sessionService
        self.networkMonitor = networkMonitor
        self.hapticService = hapticService
        self.onNavigate = onNavigate
        isOffline = !networkMonitor.isConnected
        bindNetworkMonitor()
        bindQuery()
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var showsNoResults: Bool {
        hasSearched && results.isEmpty && trimmedQuery.count >= Self.minQueryLength && !isOffline
    }

    var showsMinLengthHint: Bool {
        !trimmedQuery.isEmpty
            && trimmedQuery.count < Self.minQueryLength
            && !isOffline
    }

    func openProfile(user: User) {
        onNavigate(.userProfile(userId: user.id, stub: user))
    }

    func canToggleFollow(for result: SearchUserResult) -> Bool {
        !result.isSelf && !isOffline && !followInProgressIds.contains(result.id)
    }

    func toggleFollow(for userId: String) async {
        guard let index = results.firstIndex(where: { $0.id == userId }),
              canToggleFollow(for: results[index]),
              let currentUserId = sessionService.currentUser?.id else { return }

        followInProgressIds.insert(userId)
        defer { followInProgressIds.remove(userId) }

        let wasFollowing = results[index].isFollowing

        do {
            if wasFollowing {
                try await followRepository.unfollow(
                    currentUserId: currentUserId,
                    targetUserId: userId
                )
            } else {
                try await followRepository.follow(
                    currentUserId: currentUserId,
                    targetUserId: userId
                )
            }

            results[index].isFollowing = !wasFollowing
            hapticService.playFollowToggle()
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
        ConnectivityBinding.bind(monitor: networkMonitor, cancellables: &cancellables) { [weak self] isConnected, _ in
            guard let self else { return }
            self.isOffline = !isConnected

            if !isConnected {
                self.results = []
                self.hasSearched = false
                return
            }

            if self.trimmedQuery.count >= Self.minQueryLength {
                Task { await self.performSearch(query: self.trimmedQuery) }
            }
        }
    }

    private func bindQuery() {
        $query
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(for: Self.debounceInterval, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] trimmed in
                Task { await self?.performSearch(query: trimmed) }
            }
            .store(in: &cancellables)
    }

    private func performSearch(query: String) async {
        activeSearchID += 1
        let searchID = activeSearchID

        isOffline = !networkMonitor.isConnected

        guard !isOffline else {
            results = []
            hasSearched = false
            return
        }

        guard query.count >= Self.minQueryLength else {
            results = []
            hasSearched = false
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            let users = try await profileRepository.searchUsers(prefix: query)
            guard searchID == activeSearchID else { return }

            guard let currentUserId = sessionService.currentUser?.id else {
                results = []
                hasSearched = true
                return
            }

            var searchResults: [SearchUserResult] = []
            for user in users {
                let isSelf = user.id == currentUserId
                let isFollowing: Bool
                if isSelf {
                    isFollowing = false
                } else {
                    isFollowing = try await followRepository.isFollowing(
                        currentUserId: currentUserId,
                        targetUserId: user.id
                    )
                }
                searchResults.append(
                    SearchUserResult(user: user, isFollowing: isFollowing, isSelf: isSelf)
                )
            }

            guard searchID == activeSearchID else { return }
            results = searchResults
            hasSearched = true
        } catch {
            guard searchID == activeSearchID else { return }
            results = []
            hasSearched = true
            presentError(String(localized: .searchErrorLoad))
        }
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
