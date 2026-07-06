//
//  PostRepository.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import Combine
import FirebaseFirestore
import Foundation

final class PostRepository: PostRepositoryProtocol {
    private let networkMonitor: NetworkConnectivityProviding
    private let localRepository: LocalRepositoryProtocol
    private let mediaService: MediaServiceProtocol
    private let firestore: Firestore

    private let postsSubject = CurrentValueSubject<[Post], Never>([])
    private let likedPostIdsSubject = CurrentValueSubject<Set<String>, Never>([])

    private var listeners: [String: ListenerRegistration] = [:]
    private let listenersLock = NSLock()

    private var listenerPosts: [Post] = []
    private var paginatedPosts: [Post] = []
    private var paginationCursor: DocumentSnapshot?
    private var hasMorePages = true
    private var observedUserId: String?

    private let pageSize = 20
    private let maxTextLength = 280
    private let batchDeleteSize = 500

    var postsPublisher: AnyPublisher<[Post], Never> {
        postsSubject.eraseToAnyPublisher()
    }

    var likedPostIdsPublisher: AnyPublisher<Set<String>, Never> {
        likedPostIdsSubject.eraseToAnyPublisher()
    }

    init(
        networkMonitor: NetworkConnectivityProviding,
        localRepository: LocalRepositoryProtocol,
        mediaService: MediaServiceProtocol,
        firestore: Firestore = Firestore.firestore()
    ) {
        self.networkMonitor = networkMonitor
        self.localRepository = localRepository
        self.mediaService = mediaService
        self.firestore = firestore
    }
    
    // MARK: - Private feed helpers

    private func feedQuery() -> Query {
        firestore.collection("posts")
            .order(by: "createdAt", descending: true)
    }

    private func attachFeedListener(currentUserId: String) {
        let query = feedQuery().limit(to: pageSize)

        let registration = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self, error == nil, let snapshot else { return }
            Task {
                await self.handleFeedSnapshot(snapshot, currentUserId: currentUserId)
            }
        }

        storeListener(key: "feed", registration: registration)
    }

    private func handleFeedSnapshot(_ snapshot: QuerySnapshot, currentUserId: String) async {
        let posts = snapshot.documents.compactMap { Post(document: $0) }
        try? await localRepository.savePosts(posts)

        listenerPosts = posts
        if let lastDocument = snapshot.documents.last {
            paginationCursor = lastDocument
        }
        if snapshot.documents.count < pageSize {
            hasMorePages = false
        }

        publishMergedPosts()
        await refreshLikedState(for: posts, userId: currentUserId, mergeWithExisting: false)
    }

    private func loadOfflineFeed() async throws {
        let posts = try await localRepository.fetchPosts()
        listenerPosts = []
        paginatedPosts = posts
        postsSubject.send(posts)
    }

    private func resetPagination() {
        paginatedPosts = []
        paginationCursor = nil
        hasMorePages = true
    }

    private func mergePosts() -> [Post] {
        var byId: [String: Post] = [:]
        for post in paginatedPosts { byId[post.id] = post }
        for post in listenerPosts { byId[post.id] = post }
        return byId.values.sorted {
            ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
        }
    }

    private func publishMergedPosts() {
        postsSubject.send(mergePosts())
    }

    private func removePostFromPublishedState(id: String) {
        listenerPosts.removeAll { $0.id == id }
        paginatedPosts.removeAll { $0.id == id }
        publishMergedPosts()

        var likedIds = likedPostIdsSubject.value
        likedIds.remove(id)
        likedPostIdsSubject.send(likedIds)
    }

    private func refreshLikedState(
        for posts: [Post],
        userId: String,
        mergeWithExisting: Bool
    ) async {
        let fetched = await fetchLikedPostIds(for: posts.map(\.id), userId: userId)
        if mergeWithExisting {
            likedPostIdsSubject.send(likedPostIdsSubject.value.union(fetched))
        } else {
            likedPostIdsSubject.send(fetched)
        }
    }

    private func fetchLikedPostIds(for postIds: [String], userId: String) async -> Set<String> {
        await withTaskGroup(of: (String, Bool).self) { group in
            for postId in postIds {
                group.addTask { [firestore] in
                    let document = try? await firestore
                        .collection("posts")
                        .document(postId)
                        .collection("likes")
                        .document(userId)
                        .getDocument()
                    return (postId, document?.exists == true)
                }
            }

            var likedIds = Set<String>()
            for await (postId, isLiked) in group where isLiked {
                likedIds.insert(postId)
            }
            return likedIds
        }
    }

    private func deleteCollection(_ collection: CollectionReference) async throws {
        while true {
            let snapshot = try await collection.limit(to: batchDeleteSize).getDocuments()
            guard !snapshot.documents.isEmpty else { return }

            let batch = firestore.batch()
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()

            if snapshot.documents.count < batchDeleteSize {
                return
            }
        }
    }
}

// MARK: - Feed observation
extension PostRepository {
    func observeFeed(currentUserId: String) {
        observedUserId = currentUserId

        guard networkMonitor.isConnected else {
            Task { try? await loadOfflineFeed() }
            return
        }

        resetPagination()
        attachFeedListener(currentUserId: currentUserId)
    }

    func removeAllListeners() {
        listenersLock.lock()
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
        listenersLock.unlock()

        listenerPosts = []
        paginatedPosts = []
        paginationCursor = nil
        hasMorePages = true
        observedUserId = nil
        postsSubject.send([])
        likedPostIdsSubject.send([])
    }

    func refreshFeed(currentUserId: String) async throws {
        observedUserId = currentUserId

        guard networkMonitor.isConnected else {
            try await loadOfflineFeed()
            return
        }

        resetPagination()
        removeListener(key: "feed")
        attachFeedListener(currentUserId: currentUserId)
    }

    @discardableResult
    func loadMorePosts(currentUserId: String) async throws -> Bool {
        guard networkMonitor.isConnected, hasMorePages else { return false }
        
        guard let cursor = paginationCursor else {
            hasMorePages = false
            return false
        }
        
        let snapshot = try await feedQuery()
            .start(afterDocument: cursor)
            .limit(to: pageSize)
            .getDocuments()
        
        guard !snapshot.documents.isEmpty else {
            hasMorePages = false
            return false
        }
        
        paginationCursor = snapshot.documents.last
        if snapshot.documents.count < pageSize {
            hasMorePages = false
        }
        
        let newPosts = snapshot.documents.compactMap { Post(document: $0) }
        try await localRepository.savePosts(newPosts)
        
        let existingIds = Set(mergePosts().map(\.id))
        paginatedPosts.append(contentsOf: newPosts.filter { !existingIds.contains($0.id) })
        
        publishMergedPosts()
        await refreshLikedState(for: newPosts, userId: currentUserId, mergeWithExisting: true)
        return hasMorePages
    }
}

// MARK: - Writes
extension PostRepository {
    func newPostId() -> String {
        firestore.collection("posts").document().documentID
    }

    func createPost(
        text: String,
        authorId: String,
        postId: String? = nil,
        imageURL: String? = nil
    ) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PostRepositoryError.emptyText }
        guard trimmed.count <= maxTextLength else { throw PostRepositoryError.textTooLong }

        let documentId = postId ?? firestore.collection("posts").document().documentID
        let document = firestore.collection("posts").document(documentId)
        var data: [String: Any] = [
            "authorId": authorId,
            "text": trimmed,
            "likeCount": 0,
            "commentCount": 0,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let imageURL, !imageURL.isEmpty {
            data["imageURL"] = imageURL
        } else {
            data["imageURL"] = NSNull()
        }
        try await document.setData(data)
    }

    func deletePost(id: String, authorId: String) async throws {
        let postRef = firestore.collection("posts").document(id)
        let snapshot = try await postRef.getDocument()

        guard snapshot.exists else { throw PostRepositoryError.postNotFound }
        guard snapshot.data()?["authorId"] as? String == authorId else {
            throw PostRepositoryError.unauthorizedDelete
        }

        try? await mediaService.deletePostImage(postId: id)

        try await deleteCollection(postRef.collection("likes"))
        try await deleteCollection(postRef.collection("comments"))
        try await postRef.delete()

        try await localRepository.deletePost(id: id)
        removePostFromPublishedState(id: id)
    }

    func likePost(id: String, userId: String) async throws {
        let postRef = firestore.collection("posts").document(id)
        let likeRef = postRef.collection("likes").document(userId)
        let batch = firestore.batch()
        batch.setData(["likedAt": FieldValue.serverTimestamp()], forDocument: likeRef)
        batch.updateData(["likeCount": FieldValue.increment(Int64(1))], forDocument: postRef)
        try await batch.commit()

        var likedIds = likedPostIdsSubject.value
        likedIds.insert(id)
        likedPostIdsSubject.send(likedIds)
    }

    func unlikePost(id: String, userId: String) async throws {
        let postRef = firestore.collection("posts").document(id)
        let likeRef = postRef.collection("likes").document(userId)
        let batch = firestore.batch()
        batch.deleteDocument(likeRef)
        batch.updateData(["likeCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
        try await batch.commit()

        var likedIds = likedPostIdsSubject.value
        likedIds.remove(id)
        likedPostIdsSubject.send(likedIds)
    }
}

// MARK: - Listener registry
extension PostRepository {
    private func storeListener(key: String, registration: ListenerRegistration) {
        listenersLock.lock()
        listeners[key]?.remove()
        listeners[key] = registration
        listenersLock.unlock()
    }

    private func removeListener(key: String) {
        listenersLock.lock()
        listeners[key]?.remove()
        listeners.removeValue(forKey: key)
        listenersLock.unlock()
    }
}
