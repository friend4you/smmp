//
//  LocalRepositoryTests.swift
//  smmpTests
//

import CoreData
import Testing
@testable import smmp

struct LocalRepositoryTests {

    private func fetchUser(id: String, persistence: PersistenceController) async throws -> CDUser? {
        let request = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try await persistence.fetch(request).first
    }

    @Test func saveUserCreatesNewRecord() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)
        let user = makeUser()

        try await repository.saveUser(user: user)

        let stored = try await fetchUser(id: user.id, persistence: persistence)
        let id = await user.id
        let displayName = await user.displayName
        let bio = await user.bio
        let photoURL = await user.photoURL
        
        #expect(stored != nil)
        #expect(stored?.id == id)
        #expect(stored?.displayName == displayName)
        #expect(stored?.bio == bio)
        #expect(stored?.photoURL == photoURL)
    }

    @Test func saveUserUpdatesExistingRecord() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)
        let original = makeUser(displayName: "Alice")
        try await repository.saveUser(user: original)

        let updated = makeUser(displayName: "Alicia")
        try await repository.saveUser(user: updated)

        let request = CDUser.fetchRequest()
        let results = try await persistence.fetch(request)
        #expect(results.count == 1)
        #expect(results.first?.displayName == "Alicia")
    }

    @Test func saveUserSetsCachedAtOnInsert() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)

        try await repository.saveUser(user: makeUser())

        let stored = try await fetchUser(id: "user-1", persistence: persistence)
        #expect(stored?.cachedAt != nil)
    }

    @Test func saveUserDoesNotDuplicateOnSecondSave() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)
        let user = makeUser()

        try await repository.saveUser(user: user)
        try await repository.saveUser(user: user)

        let results = try await persistence.fetch(CDUser.fetchRequest())
        #expect(results.count == 1)
    }

    // MARK: - Posts

    @Test func savePostCreatesNewRecord() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)
        let post = makePost()

        try await repository.savePost(post: post)

        let stored = try await repository.fetchPosts()
        #expect(stored.count == 1)
        #expect(stored.first?.id == post.id)
        #expect(stored.first?.text == post.text)
    }

    @Test func savePostUpdatesExistingRecord() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)
        try await repository.savePost(post: makePost(text: "First"))

        try await repository.savePost(post: makePost(text: "Updated"))

        let results = try await persistence.fetch(CDPost.fetchRequest())
        #expect(results.count == 1)
        #expect(results.first?.text == "Updated")
    }

    @Test func fetchPostsReturnsNewestFirst() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)
        let older = makePost(
            id: "post-old",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let newer = makePost(
            id: "post-new",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000)
        )

        try await repository.savePosts([older, newer])

        let posts = try await repository.fetchPosts()
        #expect(posts.map(\.id) == ["post-new", "post-old"])
    }

    @Test func savePostsUpsertsWithoutDuplicates() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)

        try await repository.savePosts([makePost(likeCount: 1)])
        try await repository.savePosts([makePost(likeCount: 5)])

        let results = try await persistence.fetch(CDPost.fetchRequest())
        #expect(results.count == 1)
        #expect(results.first?.likeCount == 5)
    }

    // MARK: - Comments

    @Test func saveCommentCreatesNewRecord() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)
        let comment = makeComment()

        try await repository.saveComment(comment: comment)

        let stored = try await repository.fetchComments(postId: comment.postId)
        #expect(stored.count == 1)
        #expect(stored.first?.id == comment.id)
    }

    @Test func fetchCommentsReturnsChronologicalOrder() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)
        let first = makeComment(
            id: "comment-1",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let second = makeComment(
            id: "comment-2",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000)
        )

        try await repository.saveComment(comment: second)
        try await repository.saveComment(comment: first)

        let comments = try await repository.fetchComments(postId: "post-1")
        #expect(comments.map(\.id) == ["comment-1", "comment-2"])
    }

    @Test func fetchCommentsFiltersByPostId() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)

        try await repository.saveComment(comment: makeComment(id: "c-1", postId: "post-a"))
        try await repository.saveComment(comment: makeComment(id: "c-2", postId: "post-b"))

        let comments = try await repository.fetchComments(postId: "post-a")
        #expect(comments.count == 1)
        #expect(comments.first?.id == "c-1")
    }

    // MARK: - User cache read

    @Test func fetchUserReturnsCachedUser() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)
        let user = makeUser()

        try await repository.saveUser(user: user)

        let cached = try await repository.fetchUser(id: user.id)
        #expect(cached?.id == user.id)
        #expect(cached?.displayName == user.displayName)
        #expect(cached?.email == user.email)
    }

    @Test func fetchUserReturnsNilWhenNotCached() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)

        let cached = try await repository.fetchUser(id: "missing-user")
        #expect(cached == nil)
    }
}
