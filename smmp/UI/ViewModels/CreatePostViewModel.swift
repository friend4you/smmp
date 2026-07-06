//
//  CreatePostViewModel.swift
//  smmp
//

import Combine
import Foundation
import UIKit

@MainActor
final class CreatePostViewModel: ObservableObject {
    static let maxTextLength = 280

    @Published var text = ""
    @Published var selectedImage: UIImage?
    @Published private(set) var isSubmitting = false
    @Published private(set) var uploadProgress: Double = 0
    @Published private(set) var isOffline = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let postRepository: PostRepositoryProtocol
    private let followRepository: FollowRepositoryProtocol
    private let mediaService: MediaServiceProtocol
    private let sessionService: SessionServiceProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let hapticService: HapticServiceProtocol
    private let onPostCreated: () -> Void
    private var progressCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var characterCount: Int {
        text.count
    }

    var isOverLimit: Bool {
        text.count > Self.maxTextLength
    }

    var isValid: Bool {
        !trimmedText.isEmpty && !isOverLimit
    }

    var isUploadingImage: Bool {
        isSubmitting && selectedImage != nil && uploadProgress < 1
    }

    var canSubmit: Bool {
        isValid && !isSubmitting && !isOffline
    }

    init(
        postRepository: PostRepositoryProtocol,
        followRepository: FollowRepositoryProtocol,
        mediaService: MediaServiceProtocol,
        sessionService: SessionServiceProtocol,
        networkMonitor: NetworkMonitorProtocol,
        hapticService: HapticServiceProtocol = HapticService(),
        onPostCreated: @escaping () -> Void = {}
    ) {
        self.postRepository = postRepository
        self.followRepository = followRepository
        self.mediaService = mediaService
        self.sessionService = sessionService
        self.networkMonitor = networkMonitor
        self.hapticService = hapticService
        self.onPostCreated = onPostCreated
        isOffline = !networkMonitor.isConnected
        bindConnectivity()
        progressCancellable = mediaService.uploadProgressPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.uploadProgress, on: self)
    }

    func removeSelectedImage() {
        selectedImage = nil
        uploadProgress = 0
    }

    @discardableResult
    func submit() async -> Bool {
        guard let authorId = sessionService.currentUser?.id else { return false }
        showError = false

        guard !isOffline else {
            presentError(String(localized: .postErrorOffline))
            return false
        }

        guard isValid else { return false }

        isSubmitting = true
        uploadProgress = 0
        defer {
            isSubmitting = false
            uploadProgress = 0
        }

        let postId = postRepository.newPostId()
        var uploadedImageURL: String?

        if let image = selectedImage {
            guard let imageData = mediaService.resizeImage(image) else {
                presentError(String(localized: .postImageErrorResize))
                return false
            }

            do {
                uploadedImageURL = try await mediaService.uploadPostImage(imageData, postId: postId)
            } catch {
                presentError(String(localized: .postImageErrorUpload))
                return false
            }
        }

        do {
            try await postRepository.createPost(
                text: text,
                authorId: authorId,
                postId: postId,
                imageURL: uploadedImageURL
            )
            let followingIds = (try? await followRepository.followingIds(for: authorId)) ?? []
            let feedAuthorIds = FeedAuthorIds.authorIds(
                currentUserId: authorId,
                followingIds: followingIds
            )
            try await postRepository.refreshFeed(currentUserId: authorId, feedAuthorIds: feedAuthorIds)
            text = ""
            selectedImage = nil
            hapticService.playSuccess()
            onPostCreated()
            return true
        } catch {
            if uploadedImageURL != nil {
                try? await mediaService.deletePostImage(postId: postId)
            }
            presentError(PostErrorMapper.message(for: error, fallback: String(localized: .postErrorCreate)))
            return false
        }
    }

    private func bindConnectivity() {
        ConnectivityBinding.bind(monitor: networkMonitor, cancellables: &cancellables) { [weak self] isConnected, _ in
            self?.isOffline = !isConnected
        }
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
