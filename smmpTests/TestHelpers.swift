//
//  TestHelpers.swift
//  smmpTests
//

import Combine
import Foundation
@testable import smmp

func makeUser(
    id: String = "user-1",
    displayName: String? = "Alice",
    email: String? = "alice@example.com",
    bio: String? = "Hello",
    photoURL: String? = "https://example.com/a.jpg",
    followerCount: Int = 0,
    followingCount: Int = 0,
    displayNameLower: String? = nil
) -> User {
    var user = User(id: id)
    user.displayName = displayName
    user.email = email
    user.bio = bio
    user.photoURL = photoURL
    user.followerCount = followerCount
    user.followingCount = followingCount
    user.displayNameLower = displayNameLower ?? User.displayNameLower(from: displayName)
    return user
}

func makePost(
    id: String = "post-1",
    authorId: String = "user-1",
    text: String? = "Hello feed",
    imageURL: String? = nil,
    likeCount: Int = 0,
    commentCount: Int = 0,
    createdAt: Date? = Date(timeIntervalSince1970: 1_700_000_000)
) -> Post {
    Post(
        id: id,
        authorId: authorId,
        text: text,
        imageURL: imageURL,
        likeCount: likeCount,
        commentCount: commentCount,
        createdAt: createdAt
    )
}

func makeComment(
    id: String = "comment-1",
    postId: String = "post-1",
    authorId: String = "user-2",
    text: String? = "Nice post",
    createdAt: Date? = Date(timeIntervalSince1970: 1_700_000_100)
) -> Comment {
    Comment(
        id: id,
        postId: postId,
        authorId: authorId,
        text: text,
        createdAt: createdAt
    )
}

func makeFeedPostItem(
    post: Post = makePost(),
    author: User = makeUser(),
    isLikedByCurrentUser: Bool = false
) -> FeedPostItem {
    FeedPostItem(
        post: post,
        author: author,
        isLikedByCurrentUser: isLikedByCurrentUser
    )
}

@MainActor
final class MockNetworkMonitor: NetworkMonitorProtocol {
    let subject: CurrentValueSubject<Bool, Never>

    var isConnected: Bool {
        get { subject.value }
        set { subject.send(newValue) }
    }

    var connectionType: ConnectionType = .unknown

    var connectivityPublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    init(isConnected: Bool) {
        subject = CurrentValueSubject(isConnected)
    }

    func setConnected(_ connected: Bool) {
        subject.send(connected)
    }
}

final class MockBlockRepository: BlockRepositoryProtocol {
    var blockedIdsValue = Set<String>()
    var blockError: Error?
    private(set) var blockCalls: [(String, String)] = []
    private(set) var unblockCalls: [(String, String)] = []
    private(set) var deleteAllCallCount = 0

    func block(currentUserId: String, targetUserId: String) async throws {
        if let blockError { throw blockError }
        guard currentUserId != targetUserId else { throw BlockRepositoryError.cannotBlockSelf }
        blockCalls.append((currentUserId, targetUserId))
        blockedIdsValue.insert(targetUserId)
    }

    func unblock(currentUserId: String, targetUserId: String) async throws {
        if let blockError { throw blockError }
        unblockCalls.append((currentUserId, targetUserId))
        blockedIdsValue.remove(targetUserId)
    }

    func isBlocked(currentUserId: String, targetUserId: String) async throws -> Bool {
        blockedIdsValue.contains(targetUserId)
    }

    func blockedIds(for userId: String) async throws -> Set<String> {
        blockedIdsValue
    }

    func deleteAllBlocks(for userId: String) async throws {
        deleteAllCallCount += 1
        blockedIdsValue.removeAll()
    }
}

final class MockReportRepository: ReportRepositoryProtocol {
    var createError: Error?
    private(set) var createdDrafts: [ReportDraft] = []

    func createReport(_ draft: ReportDraft) async throws -> Report {
        if let createError { throw createError }
        guard draft.reporterId != draft.targetOwnerId else {
            throw ReportRepositoryError.cannotReportOwnContent
        }
        createdDrafts.append(draft)
        return Report(
            id: "report-\(createdDrafts.count)",
            reporterId: draft.reporterId,
            targetType: draft.targetType,
            targetId: draft.targetId,
            targetOwnerId: draft.targetOwnerId,
            parentPostId: draft.parentPostId,
            reason: draft.reason
        )
    }
}

final class MockAuthReauthenticator: AuthReauthenticating {
    var error: Error?
    private(set) var passwords: [String] = []

    func reauthenticate(password: String) async throws {
        passwords.append(password)
        if let error { throw error }
    }
}

final class MockAccountDeletionService: AccountDeleting {
    var error: Error?
    private(set) var deletedUserIds: [String] = []

    func deleteAccount(userId: String) async throws {
        if let error { throw error }
        deletedUserIds.append(userId)
    }
}

struct DenyingContentFilter: ContentFiltering {
    func containsDeniedContent(_ text: String) -> Bool { true }
}

struct AllowingContentFilter: ContentFiltering {
    func containsDeniedContent(_ text: String) -> Bool { false }
}
