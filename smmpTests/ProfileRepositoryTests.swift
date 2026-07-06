//
//  ProfileRepositoryTests.swift
//  smmpTests
//

import Combine
import Foundation
import Testing
import UIKit
@testable import smmp

struct ProfileRepositoryTests {

    @Test func fetchUserReturnsCachedUserWithoutRemoteFetch() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let cachedUser = makeUser(id: "author-1", displayName: "Bob")
        try await localRepository.saveUser(user: cachedUser)

        let fetcher = MockUserDocumentFetcher()
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        let user = try await repository.fetchUser(id: "author-1")

        #expect(user?.id == "author-1")
        #expect(user?.displayName == "Bob")
        #expect(fetcher.fetchCount == 0)
    }

    @Test func fetchUserReturnsNilWhenOfflineAndNotCached() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let fetcher = MockUserDocumentFetcher(user: makeUser(id: "author-2"))
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: false),
            fetcher: fetcher
        )

        let user = try await repository.fetchUser(id: "author-2")

        #expect(user == nil)
        #expect(fetcher.fetchCount == 0)
    }

    @Test func fetchUserFetchesRemoteWhenCacheMissAndOnline() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let remoteUser = makeUser(id: "author-3", displayName: "Carol")
        let fetcher = MockUserDocumentFetcher(user: remoteUser)
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        let user = try await repository.fetchUser(id: "author-3")

        #expect(user?.displayName == "Carol")
        #expect(fetcher.fetchCount == 1)
        let cached = try await localRepository.fetchUser(id: "author-3")
        #expect(cached?.displayName == "Carol")
    }

    @Test func fetchUserDeduplicatesConcurrentFetchesForSameId() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let fetcher = MockUserDocumentFetcher(
            user: makeUser(id: "author-4", displayName: "Dana"),
            delayNanoseconds: 200_000_000
        )
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        async let first = repository.fetchUser(id: "author-4")
        async let second = repository.fetchUser(id: "author-4")
        let users = try await [first, second]

        #expect(users[0]?.displayName == "Dana")
        #expect(users[1]?.displayName == "Dana")
        #expect(fetcher.fetchCount == 1)
    }

    @Test func createProfileWritesFirestoreDocumentAndCachesLocally() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let fetcher = MockUserDocumentFetcher()
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        let user = try await repository.createProfile(
            uid: "user-new",
            displayName: "Alice",
            email: "alice@example.com"
        )

        #expect(user.id == "user-new")
        #expect(user.displayName == "Alice")
        #expect(user.email == "alice@example.com")
        #expect(user.displayNameLower == "alice")
        #expect(user.followerCount == 0)
        #expect(user.followingCount == 0)
        #expect(fetcher.createCount == 1)
        #expect(fetcher.lastCreateId == "user-new")
        #expect(fetcher.lastCreateData?["displayName"] as? String == "Alice")
        #expect(fetcher.lastCreateData?["displayNameLower"] as? String == "alice")
        #expect(fetcher.lastCreateData?["email"] as? String == "alice@example.com")

        let cached = try await localRepository.fetchUser(id: "user-new")
        #expect(cached?.displayName == "Alice")
        #expect(cached?.email == "alice@example.com")
    }

    @Test func createProfilePropagatesWriteErrors() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let fetcher = MockUserDocumentFetcher()
        fetcher.createError = MockAuthError.notConfigured
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        await #expect(throws: MockAuthError.notConfigured) {
            try await repository.createProfile(
                uid: "user-fail",
                displayName: "Bob",
                email: "bob@example.com"
            )
        }

        let cached = try await localRepository.fetchUser(id: "user-fail")
        #expect(cached == nil)
    }

    @Test func updateProfileWritesFirestoreSyncsAuthAndCachesLocally() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let existing = makeUser(
            id: "user-edit",
            displayName: "Old Name",
            bio: "Old bio",
            photoURL: "https://example.com/old.jpg"
        )
        try await localRepository.saveUser(user: existing)

        let fetcher = MockUserDocumentFetcher()
        let authUpdater = MockAuthProfileUpdater()
        let mediaService = MockProfileMediaService()
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher,
            authUpdater: authUpdater,
            mediaService: mediaService
        )

        let updated = try await repository.updateProfile(
            uid: "user-edit",
            displayName: "New Name",
            bio: "New bio",
            profileImageData: nil,
            removeProfileImage: false
        )

        #expect(updated.displayName == "New Name")
        #expect(updated.bio == "New bio")
        #expect(updated.photoURL == "https://example.com/old.jpg")
        #expect(updated.displayNameLower == "new name")
        #expect(fetcher.updateCount == 1)
        #expect(authUpdater.updateCount == 1)
        #expect(authUpdater.lastDisplayName == "New Name")
        #expect(authUpdater.lastPhotoURL?.absoluteString == "https://example.com/old.jpg")
        #expect(mediaService.uploadedUserIds.isEmpty)
    }

    @Test func updateProfileUploadsProfileImageAndDeletesPrevious() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let existing = makeUser(
            id: "user-photo",
            displayName: "Alice",
            photoURL: "https://example.com/old.jpg"
        )
        try await localRepository.saveUser(user: existing)

        let fetcher = MockUserDocumentFetcher()
        let authUpdater = MockAuthProfileUpdater()
        let mediaService = MockProfileMediaService()
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher,
            authUpdater: authUpdater,
            mediaService: mediaService
        )

        let imageData = Data([0xFF, 0xD8, 0xFF])
        let updated = try await repository.updateProfile(
            uid: "user-photo",
            displayName: "Alice",
            bio: nil,
            profileImageData: imageData,
            removeProfileImage: false
        )

        #expect(updated.photoURL == "https://example.com/users/user-photo/avatar.jpg")
        #expect(mediaService.deletedUserIds == ["user-photo"])
        #expect(mediaService.uploadedUserIds == ["user-photo"])
        #expect(mediaService.lastUploadedData == imageData)
        #expect(authUpdater.lastPhotoURL?.absoluteString == "https://example.com/users/user-photo/avatar.jpg")
    }

    @Test func updateProfileRemoveProfileImageDeletesStorageObject() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let existing = makeUser(
            id: "user-remove",
            displayName: "Bob",
            photoURL: "https://example.com/old.jpg"
        )
        try await localRepository.saveUser(user: existing)

        let mediaService = MockProfileMediaService()
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: MockUserDocumentFetcher(),
            mediaService: mediaService
        )

        let updated = try await repository.updateProfile(
            uid: "user-remove",
            displayName: "Bob",
            bio: nil,
            profileImageData: nil,
            removeProfileImage: true
        )

        #expect(updated.photoURL == "")
        #expect(mediaService.deletedUserIds == ["user-remove"])
        #expect(mediaService.uploadedUserIds.isEmpty)
    }

    @Test func updateProfileThrowsWhenUserNotFound() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let fetcher = MockUserDocumentFetcher()
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: false),
            fetcher: fetcher
        )

        await #expect(throws: ProfileRepositoryError.userNotFound) {
            try await repository.updateProfile(
                uid: "missing-user",
                displayName: "Name",
                bio: nil,
                profileImageData: nil,
                removeProfileImage: false
            )
        }
    }

    @Test func searchUsersReturnsEmptyForShortPrefix() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let fetcher = MockUserDocumentFetcher()
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        let results = try await repository.searchUsers(prefix: "a")

        #expect(results.isEmpty)
        #expect(fetcher.searchCount == 0)
    }

    @Test func searchUsersQueriesWithNormalizedPrefixWhenOnline() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let fetcher = MockUserDocumentFetcher(
            searchResults: [
                makeUser(id: "user-1", displayName: "Alice"),
                makeUser(id: "user-2", displayName: "Alvin")
            ]
        )
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        let results = try await repository.searchUsers(prefix: "Al")

        #expect(results.count == 2)
        #expect(fetcher.searchCount == 1)
        #expect(fetcher.lastSearchPrefix == "al")
        #expect(fetcher.lastSearchLimit == 20)
    }

    @Test func searchUsersReturnsEmptyWhenOffline() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        let fetcher = MockUserDocumentFetcher(
            searchResults: [makeUser(id: "user-1", displayName: "Alice")]
        )
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: false),
            fetcher: fetcher
        )

        let results = try await repository.searchUsers(prefix: "alice")

        #expect(results.isEmpty)
        #expect(fetcher.searchCount == 0)
    }

    @Test func fetchUserBackfillsDisplayNameLowerWhenMissing() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        var remoteUser = makeUser(id: "legacy-user", displayName: "Legacy")
        remoteUser.displayNameLower = nil
        let fetcher = MockUserDocumentFetcher(user: remoteUser)
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        let user = try await repository.fetchUser(id: "legacy-user")

        #expect(user?.displayNameLower == "legacy")
        #expect(fetcher.updateCount == 1)
        #expect(fetcher.lastUpdateData?["displayNameLower"] as? String == "legacy")

        let cached = try await localRepository.fetchUser(id: "legacy-user")
        #expect(cached?.displayNameLower == "legacy")
    }

    @Test func fetchUserBackfillsCachedUserMissingDisplayNameLower() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let localRepository = await LocalRepository(persistence: persistence)
        var cachedUser = makeUser(id: "cached-legacy", displayName: "Cached")
        cachedUser.displayNameLower = nil
        try await localRepository.saveUser(user: cachedUser)

        let fetcher = MockUserDocumentFetcher()
        let repository = makeRepository(
            localRepository: localRepository,
            networkMonitor: MockNetworkMonitor(isConnected: true),
            fetcher: fetcher
        )

        let user = try await repository.fetchUser(id: "cached-legacy")

        #expect(user?.displayNameLower == "cached")
        #expect(fetcher.fetchCount == 0)
        #expect(fetcher.updateCount == 1)
    }

    // MARK: - Helpers

    private func makeRepository(
        localRepository: LocalRepository,
        networkMonitor: MockNetworkMonitor,
        fetcher: MockUserDocumentFetcher,
        authUpdater: MockAuthProfileUpdater = MockAuthProfileUpdater(),
        mediaService: MockProfileMediaService = MockProfileMediaService()
    ) -> ProfileRepository {
        ProfileRepository(
            networkMonitor: networkMonitor,
            localRepository: localRepository,
            mediaService: mediaService,
            authProfileUpdater: authUpdater,
            userDocumentFetcher: fetcher
        )
    }
}

// MARK: - Mocks

private final class MockNetworkMonitor: NetworkConnectivityProviding {
    var isConnected: Bool

    init(isConnected: Bool) {
        self.isConnected = isConnected
    }
}

private final class MockUserDocumentFetcher: UserDocumentProtocol, @unchecked Sendable {
    private(set) var fetchCount = 0
    private(set) var createCount = 0
    private(set) var updateCount = 0
    private(set) var searchCount = 0
    private(set) var lastCreateId: String?
    private(set) var lastCreateData: [String: Any]?
    private(set) var lastUpdateId: String?
    private(set) var lastUpdateData: [String: Any]?
    private(set) var lastSearchPrefix: String?
    private(set) var lastSearchLimit: Int?
    var createError: Error?
    private let user: User?
    private let searchResults: [User]
    private let delayNanoseconds: UInt64

    init(
        user: User? = nil,
        searchResults: [User] = [],
        delayNanoseconds: UInt64 = 0
    ) {
        self.user = user
        self.searchResults = searchResults
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchUserDocument(id: String) async throws -> User? {
        fetchCount += 1
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return user
    }

    func createUserDocument(id: String, data: [String: Any]) async throws {
        createCount += 1
        lastCreateId = id
        lastCreateData = data
        if let createError {
            throw createError
        }
    }

    func updateUserDocument(id: String, data: [String: Any]) async throws {
        updateCount += 1
        lastUpdateId = id
        lastUpdateData = data
    }

    func searchUsers(prefix: String, limit: Int) async throws -> [User] {
        searchCount += 1
        lastSearchPrefix = prefix
        lastSearchLimit = limit
        return searchResults
    }
}

private final class MockAuthProfileUpdater: AuthProfileUpdating {
    private(set) var updateCount = 0
    private(set) var lastDisplayName: String?
    private(set) var lastPhotoURL: URL?

    func updateAuthProfile(displayName: String?, photoURL: URL?) async throws {
        updateCount += 1
        lastDisplayName = displayName
        lastPhotoURL = photoURL
    }
}

private final class MockProfileMediaService: MediaServiceProtocol {
    private let progressSubject = CurrentValueSubject<Double, Never>(0)

    private(set) var uploadedUserIds: [String] = []
    private(set) var deletedUserIds: [String] = []
    private(set) var lastUploadedData: Data?

    var uploadProgressPublisher: AnyPublisher<Double, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    func resizeImage(_ image: UIImage) -> Data? {
        image.jpegData(compressionQuality: 0.8)
    }

    func uploadPostImage(_ imageData: Data, postId: String) async throws -> String {
        ""
    }

    func deletePostImage(postId: String) async throws {}

    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> String {
        uploadedUserIds.append(userId)
        lastUploadedData = imageData
        progressSubject.send(1)
        return "https://example.com/users/\(userId)/avatar.jpg"
    }

    func deleteProfileImage(userId: String) async throws {
        deletedUserIds.append(userId)
    }
}
