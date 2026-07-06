//
//  FeedViewModelTests.swift
//  smmpTests
//

import Combine
import Foundation
import Testing
@testable import smmp

@MainActor
struct FeedViewModelTests {

    @Test func optimisticLikeRollsBackOnRepositoryError() async throws {
        let postRepository = MockPostRepository()
        let profileRepository = MockProfileRepository()
        let followRepository = MockFeedFollowRepository()
        let sessionService = MockSessionService(currentUser: makeUser())

        let post = makePost(id: "post-like", likeCount: 2)
        postRepository.postsSubject.send([post])
        postRepository.likePostError = MockPostRepositoryError.likeFailed

        let viewModel = FeedViewModel(
            postRepository: postRepository,
            profileRepository: profileRepository,
            followRepository: followRepository,
            networkMonitor: NetworkMonitor(),
            sessionService: sessionService
        )
        viewModel.start()
        try await Task.sleep(nanoseconds: 100_000_000)

        guard let item = viewModel.items.first else {
            Issue.record("Expected feed item before like toggle")
            return
        }

        await viewModel.toggleLike(for: item)

        #expect(viewModel.items.first?.isLikedByCurrentUser == false)
        #expect(viewModel.items.first?.post.likeCount == 2)
        #expect(viewModel.showError)
    }
}

@MainActor
private enum MockPostRepositoryError: Error {
    case likeFailed
}

@MainActor
private final class MockPostRepository: PostRepositoryProtocol {
    let postsSubject = CurrentValueSubject<[Post], Never>([])
    let likedPostIdsSubject = CurrentValueSubject<Set<String>, Never>([])

    var likePostError: Error?

    var postsPublisher: AnyPublisher<[Post], Never> {
        postsSubject.eraseToAnyPublisher()
    }

    var likedPostIdsPublisher: AnyPublisher<Set<String>, Never> {
        likedPostIdsSubject.eraseToAnyPublisher()
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

    func likePost(id: String, userId: String) async throws {
        if let likePostError {
            throw likePostError
        }
    }

    func unlikePost(id: String, userId: String) async throws {
        if let likePostError {
            throw likePostError
        }
    }
}

private struct MockProfileRepository: ProfileRepositoryProtocol {
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
        []
    }
}

private struct MockFeedFollowRepository: FollowRepositoryProtocol {
    func follow(currentUserId: String, targetUserId: String) async throws {}

    func unfollow(currentUserId: String, targetUserId: String) async throws {}

    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool { false }

    func fetchFollowing(for userId: String) async throws -> [Follow] { [] }

    func followingIds(for userId: String) async throws -> [String] { [] }
}
