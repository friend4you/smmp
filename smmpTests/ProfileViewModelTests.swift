//
//  ProfileViewModelTests.swift
//  smmpTests
//

import Combine
import Testing
@testable import smmp

@MainActor
struct ProfileViewModelTests {

    @Test func loadPopulatesProfileAndPosts() async {
        let user = makeUser(id: "me", displayName: "Me")
        let post = makePost(id: "post-1", authorId: "me")
        let profileRepository = MockProfileViewProfileRepository(user: user)
        let postRepository = MockProfileViewPostRepository(posts: [post])
        let localRepository = MockLocalRepository()
        let sessionService = MockSessionService(currentUser: user)

        let viewModel = makeViewModel(
            profileRepository: profileRepository,
            postRepository: postRepository,
            localRepository: localRepository,
            sessionService: sessionService,
            networkMonitor: NetworkMonitor(testConnection: true)
        )

        await viewModel.load()

        #expect(viewModel.user?.id == "me")
        #expect(viewModel.items.count == 1)
        #expect(viewModel.items.first?.id == "post-1")
        #expect(postRepository.fetchPostsCallCount == 1)
    }

    @Test func loadShowsErrorOnFailure() async {
        let user = makeUser(id: "me")
        let profileRepository = MockProfileViewProfileRepository(user: user, fetchError: MockProfileViewError.loadFailed)
        let sessionService = MockSessionService(currentUser: user)

        let viewModel = makeViewModel(
            profileRepository: profileRepository,
            sessionService: sessionService,
            networkMonitor: NetworkMonitor(testConnection: true)
        )

        await viewModel.load()

        #expect(viewModel.showError)
        #expect(viewModel.user == nil)
    }

    @Test func editProfileTappedNavigatesWhenOnline() async {
        let user = makeUser(id: "me")
        var navigatedRoute: ProfileRoute?
        let viewModel = makeViewModel(
            sessionService: MockSessionService(currentUser: user),
            networkMonitor: NetworkMonitor(testConnection: true),
            onNavigate: { navigatedRoute = $0 }
        )

        viewModel.editProfileTapped()

        #expect(navigatedRoute == .editProfile)
    }

    @Test func editProfileTappedDoesNotNavigateWhenOffline() async {
        let user = makeUser(id: "me")
        var navigatedRoute: ProfileRoute?
        let viewModel = makeViewModel(
            sessionService: MockSessionService(currentUser: user),
            networkMonitor: NetworkMonitor(testConnection: false),
            onNavigate: { navigatedRoute = $0 }
        )

        try? await Task.sleep(nanoseconds: 50_000_000)
        viewModel.editProfileTapped()

        #expect(navigatedRoute == nil)
        #expect(!viewModel.canEditProfile)
    }

    @Test func loadUsesCachedPostsWhenOffline() async {
        let user = makeUser(id: "me")
        let cachedPost = makePost(id: "cached-post", authorId: "me")
        let otherPost = makePost(id: "other-post", authorId: "someone-else")
        let profileRepository = MockProfileViewProfileRepository(user: user)
        let postRepository = MockProfileViewPostRepository(posts: [])
        let localRepository = MockLocalRepository()
        try? await localRepository.savePosts([cachedPost, otherPost])

        let viewModel = makeViewModel(
            profileRepository: profileRepository,
            postRepository: postRepository,
            localRepository: localRepository,
            sessionService: MockSessionService(currentUser: user),
            networkMonitor: NetworkMonitor(testConnection: false)
        )

        await viewModel.load()

        #expect(viewModel.items.count == 1)
        #expect(viewModel.items.first?.id == "cached-post")
        #expect(postRepository.fetchPostsCallCount == 0)
        #expect(viewModel.isOffline)
    }

    // MARK: - Helpers

    private func makeViewModel(
        profileRepository: ProfileRepositoryProtocol = MockProfileViewProfileRepository(user: makeUser()),
        postRepository: PostRepositoryProtocol = MockProfileViewPostRepository(),
        localRepository: LocalRepositoryProtocol = MockLocalRepository(),
        sessionService: MockSessionService = MockSessionService(currentUser: makeUser()),
        networkMonitor: NetworkMonitor = NetworkMonitor(testConnection: true),
        onNavigate: @escaping (ProfileRoute) -> Void = { _ in }
    ) -> ProfileViewModel {
        ProfileViewModel(
            authRepository: MockAuthRepository(),
            profileRepository: profileRepository,
            postRepository: postRepository,
            localRepository: localRepository,
            networkMonitor: networkMonitor,
            sessionService: sessionService,
            onNavigate: onNavigate
        )
    }
}

// MARK: - Mocks

private enum MockProfileViewError: Error {
    case loadFailed
}

private final class MockProfileViewProfileRepository: ProfileRepositoryProtocol {
    let user: User?
    let fetchError: Error?

    init(user: User? = makeUser(), fetchError: Error? = nil) {
        self.user = user
        self.fetchError = fetchError
    }

    func createProfile(uid: String, displayName: String, email: String) async throws -> User {
        makeUser(id: uid, displayName: displayName, email: email)
    }

    func fetchUser(id: String) async throws -> User? {
        if let fetchError { throw fetchError }
        return user
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

private final class MockProfileViewPostRepository: PostRepositoryProtocol {
    let posts: [Post]
    private(set) var fetchPostsCallCount = 0

    init(posts: [Post] = []) {
        self.posts = posts
    }

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

    func fetchPosts(authorId: String) async throws -> [Post] {
        fetchPostsCallCount += 1
        return posts
    }

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
