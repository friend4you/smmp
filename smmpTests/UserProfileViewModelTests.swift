//
//  UserProfileViewModelTests.swift
//  smmpTests
//

import Combine
import Testing
@testable import smmp

@MainActor
struct UserProfileViewModelTests {

    @Test func ownProfileModeShowsEditNotFollow() async {
        let user = makeUser(id: "me")
        let viewModel = makeViewModel(
            userId: "me",
            sessionService: MockSessionService(currentUser: user),
            networkMonitor: NetworkMonitor(testConnection: true)
        )

        #expect(viewModel.isOwnProfile)
        #expect(viewModel.showsEditButton)
        #expect(!viewModel.showsFollowButton)
        #expect(viewModel.canToggleFollow == false)
    }

    @Test func otherProfileModeShowsFollowNotEdit() async {
        let viewModel = makeViewModel(
            userId: "other-user",
            sessionService: MockSessionService(currentUser: makeUser(id: "me")),
            networkMonitor: NetworkMonitor(testConnection: true)
        )

        #expect(!viewModel.isOwnProfile)
        #expect(viewModel.showsFollowButton)
        #expect(!viewModel.showsEditButton)
    }

    @Test func loadResolvesFollowStateForOtherUser() async {
        let otherUser = makeUser(id: "other-user", displayName: "Bob")
        let profileRepository = MockUserProfileProfileRepository(user: otherUser)
        let followRepository = MockUserProfileFollowRepository(isFollowing: true)

        let viewModel = makeViewModel(
            userId: "other-user",
            profileRepository: profileRepository,
            followRepository: followRepository,
            sessionService: MockSessionService(currentUser: makeUser(id: "me")),
            networkMonitor: NetworkMonitor(testConnection: true)
        )

        await viewModel.load()

        #expect(viewModel.user?.id == "other-user")
        #expect(viewModel.isFollowing)
        #expect(followRepository.isFollowingCallCount == 1)
    }

    @Test func loadDoesNotResolveFollowStateForOwnProfile() async {
        let user = makeUser(id: "me")
        let followRepository = MockUserProfileFollowRepository(isFollowing: true)

        let viewModel = makeViewModel(
            userId: "me",
            profileRepository: MockUserProfileProfileRepository(user: user),
            followRepository: followRepository,
            sessionService: MockSessionService(currentUser: user),
            networkMonitor: NetworkMonitor(testConnection: true)
        )

        await viewModel.load()

        #expect(viewModel.isOwnProfile)
        #expect(!viewModel.isFollowing)
        #expect(followRepository.isFollowingCallCount == 0)
    }

    @Test func toggleFollowUpdatesStateForOtherUser() async {
        let otherUser = makeUser(id: "other-user", followerCount: 4)
        let followRepository = MockUserProfileFollowRepository(isFollowing: false)

        let viewModel = makeViewModel(
            userId: "other-user",
            profileRepository: MockUserProfileProfileRepository(user: otherUser),
            followRepository: followRepository,
            sessionService: MockSessionService(currentUser: makeUser(id: "me")),
            networkMonitor: NetworkMonitor(testConnection: true)
        )

        await viewModel.load()
        await viewModel.toggleFollow()

        #expect(viewModel.isFollowing)
        #expect(viewModel.user?.followerCount == 5)
        #expect(followRepository.followCalls.count == 1)
        #expect(!viewModel.showError)
    }

    @Test func toggleFollowBlockedWhenOffline() async {
        let otherUser = makeUser(id: "other-user")
        let followRepository = MockUserProfileFollowRepository(isFollowing: false)

        let viewModel = makeViewModel(
            userId: "other-user",
            profileRepository: MockUserProfileProfileRepository(user: otherUser),
            followRepository: followRepository,
            sessionService: MockSessionService(currentUser: makeUser(id: "me")),
            networkMonitor: NetworkMonitor(testConnection: false)
        )

        await viewModel.load()
        await viewModel.toggleFollow()

        #expect(!viewModel.isFollowing)
        #expect(followRepository.followCalls.isEmpty)
        #expect(!viewModel.canToggleFollow)
    }

    @Test func editProfileTappedNavigatesOnlyForOwnProfileWhenOnline() async {
        var didNavigateToEdit = false
        let user = makeUser(id: "me")

        let viewModel = makeViewModel(
            userId: "me",
            sessionService: MockSessionService(currentUser: user),
            networkMonitor: NetworkMonitor(testConnection: true),
            onEditProfile: { didNavigateToEdit = true }
        )

        viewModel.editProfileTapped()

        #expect(didNavigateToEdit)
    }

    @Test func partialOfflineProfileUsesStubWhenFetchReturnsNil() async {
        let stub = makeUser(id: "other-user", displayName: "Bob from Feed")
        let cachedPost = makePost(id: "cached-post", authorId: "other-user", text: "Cached")
        let localRepository = MockLocalRepository(posts: [cachedPost])

        let viewModel = makeViewModel(
            userId: "other-user",
            userStub: stub,
            profileRepository: MockUserProfileProfileRepository(user: nil),
            postRepository: MockUserProfilePostRepository(),
            localRepository: localRepository,
            sessionService: MockSessionService(currentUser: makeUser(id: "me")),
            networkMonitor: NetworkMonitor(testConnection: false)
        )

        await viewModel.load()

        #expect(viewModel.user?.displayName == "Bob from Feed")
        #expect(viewModel.items.count == 1)
        #expect(viewModel.items.first?.post.text == "Cached")
    }

    // MARK: - Helpers

    private func makeViewModel(
        userId: String,
        userStub: User? = nil,
        profileRepository: ProfileRepositoryProtocol = MockUserProfileProfileRepository(),
        postRepository: PostRepositoryProtocol = MockUserProfilePostRepository(),
        followRepository: FollowRepositoryProtocol = MockUserProfileFollowRepository(),
        localRepository: LocalRepositoryProtocol = MockLocalRepository(),
        sessionService: MockSessionService = MockSessionService(currentUser: makeUser()),
        networkMonitor: NetworkMonitor = NetworkMonitor(testConnection: true),
        onPostDetail: @escaping (FeedPostItem) -> Void = { _ in },
        onEditProfile: @escaping () -> Void = {},
        onFollowing: @escaping () -> Void = {}
    ) -> UserProfileViewModel {
        UserProfileViewModel(
            userId: userId,
            userStub: userStub,
            profileRepository: profileRepository,
            postRepository: postRepository,
            followRepository: followRepository,
            localRepository: localRepository,
            networkMonitor: networkMonitor,
            sessionService: sessionService,
            onPostDetail: onPostDetail,
            onEditProfile: onEditProfile,
            onFollowing: onFollowing
        )
    }
}

// MARK: - Mocks

private final class MockUserProfileProfileRepository: ProfileRepositoryProtocol {
    let user: User?

    init(user: User? = makeUser()) {
        self.user = user
    }

    func createProfile(uid: String, displayName: String, email: String) async throws -> User {
        makeUser(id: uid, displayName: displayName, email: email)
    }

    func fetchUser(id: String) async throws -> User? {
        user
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

    func searchUsers(prefix: String) async throws -> [User] { [] }
}

private final class MockUserProfilePostRepository: PostRepositoryProtocol {
    var postsPublisher: AnyPublisher<[Post], Never> {
        Just([]).eraseToAnyPublisher()
    }

    var likedPostIdsPublisher: AnyPublisher<Set<String>, Never> {
        Just([]).eraseToAnyPublisher()
    }

    func observeFeed(currentUserId: String, feedAuthorIds: [String]) {}

    func removeAllListeners() {}

    func refreshFeed(currentUserId: String, feedAuthorIds: [String]) async throws {}

    func loadMorePosts(currentUserId: String) async throws -> Bool { false }

    func fetchPosts(authorId: String) async throws -> [Post] { [] }

    func newPostId() -> String { "new-post-id" }

    func createPost(
        text: String,
        authorId: String,
        postId: String?,
        imageURL: String?
    ) async throws {}

    func deletePost(id: String, authorId: String) async throws {}

    func likePost(id: String, userId: String) async throws {}

    func unlikePost(id: String, userId: String) async throws {}

    func likedPostIds(for postIds: [String], userId: String) async -> Set<String> { [] }
}

private final class MockUserProfileFollowRepository: FollowRepositoryProtocol {
    var followingState: Bool
    private(set) var isFollowingCallCount = 0
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
        isFollowingCallCount += 1
        return followingState
    }

    func fetchFollowing(for userId: String) async throws -> [Follow] { [] }

    func followingIds(for userId: String) async throws -> [String] { [] }
}
