//
//  SearchViewModelTests.swift
//  smmpTests
//

import Testing
@testable import smmp

@MainActor
struct SearchViewModelTests {

    @Test func queryShorterThanMinLengthDoesNotSearch() async throws {
        let profileRepository = MockSearchProfileRepository()
        let viewModel = makeViewModel(
            profileRepository: profileRepository,
            networkMonitor: NetworkMonitor(testConnection: true)
        )

        viewModel.query = "a"
        try await Task.sleep(nanoseconds: 400_000_000)

        #expect(profileRepository.searchCallCount == 0)
        #expect(!viewModel.hasSearched)
        #expect(viewModel.results.isEmpty)
        #expect(viewModel.showsMinLengthHint)
    }

    @Test func debouncedQueryIssuesSingleSearch() async throws {
        let profileRepository = MockSearchProfileRepository(
            results: [makeUser(id: "user-2", displayName: "Bob")]
        )
        let viewModel = makeViewModel(
            profileRepository: profileRepository,
            sessionService: MockSessionService(currentUser: makeUser(id: "me")),
            networkMonitor: NetworkMonitor(testConnection: true)
        )

        viewModel.query = "bo"
        try await Task.sleep(nanoseconds: 50_000_000)
        viewModel.query = "bob"
        try await Task.sleep(nanoseconds: 400_000_000)

        #expect(profileRepository.searchCallCount == 1)
        #expect(profileRepository.lastSearchPrefix == "bob")
        #expect(viewModel.results.count == 1)
        #expect(viewModel.results.first?.user.id == "user-2")
        #expect(viewModel.results.first?.isSelf == false)
    }

    @Test func offlineQueryDoesNotSearch() async throws {
        let profileRepository = MockSearchProfileRepository()
        let viewModel = makeViewModel(
            profileRepository: profileRepository,
            networkMonitor: NetworkMonitor(testConnection: false)
        )

        viewModel.query = "alice"
        try await Task.sleep(nanoseconds: 400_000_000)

        #expect(profileRepository.searchCallCount == 0)
        #expect(viewModel.isOffline)
        #expect(viewModel.results.isEmpty)
    }

    @Test func toggleFollowUpdatesResultState() async throws {
        let target = makeUser(id: "user-2", displayName: "Bob")
        let profileRepository = MockSearchProfileRepository(results: [target])
        let followRepository = MockSearchFollowRepository(isFollowing: false)
        let viewModel = makeViewModel(
            profileRepository: profileRepository,
            followRepository: followRepository,
            sessionService: MockSessionService(currentUser: makeUser(id: "me")),
            networkMonitor: NetworkMonitor(testConnection: true)
        )

        viewModel.query = "bo"
        try await Task.sleep(nanoseconds: 400_000_000)

        guard let result = viewModel.results.first else {
            Issue.record("Expected a search result before follow toggle")
            return
        }

        #expect(!result.isFollowing)
        await viewModel.toggleFollow(for: result.id)

        #expect(followRepository.followCalls.count == 1)
        #expect(followRepository.followCalls[0].0 == "me")
        #expect(followRepository.followCalls[0].1 == "user-2")
        #expect(viewModel.results.first?.isFollowing == true)
        #expect(!viewModel.showError)
    }

    @Test func canToggleFollowIsFalseWhenOffline() {
        let viewModel = makeViewModel(
            networkMonitor: NetworkMonitor(testConnection: false)
        )
        let result = SearchUserResult(
            user: makeUser(id: "user-2"),
            isFollowing: false,
            isSelf: false
        )

        #expect(!viewModel.canToggleFollow(for: result))
        #expect(viewModel.isOffline)
    }

    // MARK: - Helpers

    private func makeViewModel(
        profileRepository: ProfileRepositoryProtocol = MockSearchProfileRepository(),
        followRepository: FollowRepositoryProtocol = MockSearchFollowRepository(),
        sessionService: MockSessionService = MockSessionService(currentUser: makeUser()),
        networkMonitor: NetworkMonitor = NetworkMonitor(testConnection: true),
        onNavigate: @escaping (SearchRoute) -> Void = { _ in }
    ) -> SearchViewModel {
        SearchViewModel(
            profileRepository: profileRepository,
            followRepository: followRepository,
            sessionService: sessionService,
            networkMonitor: networkMonitor,
            onNavigate: onNavigate
        )
    }
}

// MARK: - Mocks

private final class MockSearchProfileRepository: ProfileRepositoryProtocol {
    let results: [User]
    private(set) var searchCallCount = 0
    private(set) var lastSearchPrefix: String?

    init(results: [User] = []) {
        self.results = results
    }

    func createProfile(uid: String, displayName: String, email: String) async throws -> User {
        makeUser(id: uid, displayName: displayName, email: email)
    }

    func fetchUser(id: String) async throws -> User? {
        makeUser(id: id)
    }

    func updateProfile(
        uid: String,
        displayName: String,
        bio: String?,
        profileImageData: Data?,
        removeProfileImage: Bool
    ) async throws -> User {
        makeUser(id: uid, displayName: displayName, bio: bio)
    }

    func searchUsers(prefix: String) async throws -> [User] {
        searchCallCount += 1
        lastSearchPrefix = prefix
        return results
    }
}

private final class MockSearchFollowRepository: FollowRepositoryProtocol {
    var followingState: Bool
    private(set) var followCalls: [(String, String)] = []
    private(set) var unfollowCalls: [(String, String)] = []

    init(isFollowing: Bool = false) {
        self.followingState = isFollowing
    }

    func follow(currentUserId: String, targetUserId: String) async throws {
        followCalls.append((currentUserId, targetUserId))
        followingState = true
    }

    func unfollow(currentUserId: String, targetUserId: String) async throws {
        unfollowCalls.append((currentUserId, targetUserId))
        followingState = false
    }

    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool {
        followingState
    }

    func fetchFollowing(for userId: String) async throws -> [Follow] { [] }

    func followingIds(for userId: String) async throws -> [String] { [] }
}
