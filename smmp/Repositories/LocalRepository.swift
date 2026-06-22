//
//  LocalRepository.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/6/26.
//

import Foundation
import CoreData

protocol LocalRepositoryProtocol {
    func saveUser(user: User) async throws
    func fetchUser(id: String) async throws -> User?
    func savePost(post: Post) async throws
    func savePosts(_ posts: [Post]) async throws
    func fetchPosts() async throws -> [Post]
    func saveComment(comment: Comment) async throws
    func fetchComments(postId: String) async throws -> [Comment]
    func deletePost(id: String) async throws
}

class LocalRepository: LocalRepositoryProtocol {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func saveUser(user: User) async throws {
        let request = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", user.id)
        let existing = try await persistence.fetch(request).first

        if let cdUser = existing {
            try await persistence.write { _ in
                cdUser.update(user: user)
            }
        } else {
            try await persistence.write { context in
                let newUser = CDUser(context: context)
                newUser.update(user: user)
                newUser.cachedAt = Date.now
            }
        }
    }

    func fetchUser(id: String) async throws -> User? {
        let request = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try await persistence.fetch(request).first?.toUser()
    }

    func savePost(post: Post) async throws {
        try await upsertPost(post)
    }

    func savePosts(_ posts: [Post]) async throws {
        guard !posts.isEmpty else { return }

        try await persistence.write { context in
            for post in posts {
                try self.upsertPost(post, in: context)
            }
        }
    }

    func fetchPosts() async throws -> [Post] {
        let request = CDPost.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let results = try await persistence.fetch(request)
        return results.compactMap { $0.toPost() }
    }

    func saveComment(comment: Comment) async throws {
        let request = CDComment.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", comment.id)
        let existing = try await persistence.fetch(request).first

        if let cdComment = existing {
            try await persistence.write { _ in
                cdComment.update(comment: comment)
            }
        } else {
            try await persistence.write { context in
                let newComment = CDComment(context: context)
                newComment.update(comment: comment)
            }
        }
    }

    func fetchComments(postId: String) async throws -> [Comment] {
        let request = CDComment.fetchRequest()
        request.predicate = NSPredicate(format: "postId == %@", postId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let results = try await persistence.fetch(request)
        return results.compactMap { $0.toComment() }
    }

    func deletePost(id: String) async throws {
        let request = CDPost.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        let posts = try await persistence.fetch(request)
        guard !posts.isEmpty else { return }

        try await persistence.write { context in
            posts.forEach { context.delete($0) }
        }
    }

    // MARK: - Private

    private func upsertPost(_ post: Post) async throws {
        let request = CDPost.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", post.id)
        request.fetchLimit = 1
        let existing = try await persistence.fetch(request).first

        if let cdPost = existing {
            try await persistence.write { _ in
                cdPost.update(post: post)
                cdPost.cachedAt = Date.now
            }
        } else {
            try await persistence.write { context in
                let newPost = CDPost(context: context)
                newPost.update(post: post)
                newPost.cachedAt = Date.now
            }
        }
    }

    private func upsertPost(_ post: Post, in context: NSManagedObjectContext) throws {
        let request = CDPost.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", post.id)
        request.fetchLimit = 1
        let cdPost = try context.fetch(request).first ?? CDPost(context: context)
        cdPost.update(post: post)
        cdPost.cachedAt = Date.now
    }
}
