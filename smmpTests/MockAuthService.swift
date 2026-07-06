//
//  MockAuthService.swift
//  smmpTests
//

@testable import smmp

final class MockAuthService: AuthServiceProtocol {
    var loginResult: Result<User, Error>?
    var registerResult: Result<User, Error>?
    var signOutError: Error?
    var sendPasswordResetError: Error?

    private(set) var loginCallCount = 0
    private(set) var registerCallCount = 0
    private(set) var lastRegisterDisplayName: String?
    private(set) var lastRegisterEmail: String?
    private(set) var lastRegisterPassword: String?
    private(set) var sendPasswordResetEmail: String?

    func login(email: String, password: String) async throws -> User {
        loginCallCount += 1
        switch loginResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        case .none:
            throw MockAuthError.notConfigured
        }
    }

    func register(displayName: String, email: String, password: String) async throws -> User {
        registerCallCount += 1
        lastRegisterDisplayName = displayName
        lastRegisterEmail = email
        lastRegisterPassword = password
        switch registerResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        case .none:
            throw MockAuthError.notConfigured
        }
    }

    func signOut() async throws {
        if let signOutError {
            throw signOutError
        }
    }

    func sendPasswordReset(email: String) async throws {
        sendPasswordResetEmail = email
        if let sendPasswordResetError {
            throw sendPasswordResetError
        }
    }
}

enum MockAuthError: Error {
    case notConfigured
}

final class MockAuthRepository: AuthRepositoryProtocol {
    var loginResult: Result<User, Error>?
    var registerResult: Result<User, Error>?
    var signOutError: Error?
    var sendPasswordResetError: Error?

    private(set) var loginCallCount = 0
    private(set) var registerCallCount = 0
    private(set) var lastRegisterDisplayName: String?
    private(set) var lastRegisterEmail: String?

    func login(email: String, password: String) async throws -> User {
        loginCallCount += 1
        switch loginResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        case .none:
            throw MockAuthError.notConfigured
        }
    }

    func register(displayName: String, email: String, password: String) async throws -> User {
        registerCallCount += 1
        lastRegisterDisplayName = displayName
        lastRegisterEmail = email
        switch registerResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        case .none:
            throw MockAuthError.notConfigured
        }
    }

    func signOut() async throws {
        if let signOutError {
            throw signOutError
        }
    }

    func sendPasswordReset(email: String) async throws {
        if let sendPasswordResetError {
            throw sendPasswordResetError
        }
    }
}

final class MockLocalRepository: LocalRepositoryProtocol {
    private(set) var savedUsers: [User] = []
    private(set) var savedPosts: [Post] = []
    private(set) var savedComments: [Comment] = []
    var usersById: [String: User] = [:]

    init(posts: [Post] = []) {
        savedPosts = posts
    }

    func saveUser(user: User) async throws {
        savedUsers.append(user)
        usersById[user.id] = user
    }

    func fetchUser(id: String) async throws -> User? {
        usersById[id]
    }

    func savePost(post: Post) async throws {
        savedPosts.append(post)
    }

    func savePosts(_ posts: [Post]) async throws {
        savedPosts.append(contentsOf: posts)
    }

    func fetchPosts() async throws -> [Post] {
        savedPosts
    }

    func saveComment(comment: Comment) async throws {
        savedComments.append(comment)
    }

    func fetchComments(postId: String) async throws -> [Comment] {
        savedComments.filter { $0.postId == postId }
    }

    func deleteComment(id: String) async throws {
        savedComments.removeAll { $0.id == id }
    }

    func deletePost(id: String) async throws {}
}
