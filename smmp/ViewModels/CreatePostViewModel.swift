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
    @Published var errorMessage: String?
    @Published var showError = false

    private let postRepository: PostRepositoryProtocol
    private let mediaService: MediaServiceProtocol
    private let networkMonitor: NetworkMonitor
    private var progressCancellable: AnyCancellable?

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
        isValid && !isSubmitting && networkMonitor.isConnected
    }

    var isOffline: Bool {
        !networkMonitor.isConnected
    }

    init(
        postRepository: PostRepositoryProtocol,
        mediaService: MediaServiceProtocol,
        networkMonitor: NetworkMonitor
    ) {
        self.postRepository = postRepository
        self.mediaService = mediaService
        self.networkMonitor = networkMonitor
        progressCancellable = mediaService.uploadProgressPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.uploadProgress, on: self)
    }

    func removeSelectedImage() {
        selectedImage = nil
        uploadProgress = 0
    }

    @discardableResult
    func submit(authorId: String) async -> Bool {
        showError = false

        guard networkMonitor.isConnected else {
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
            try await postRepository.refreshFeed(currentUserId: authorId)
            text = ""
            selectedImage = nil
            return true
        } catch {
            if uploadedImageURL != nil {
                try? await mediaService.deletePostImage(postId: postId)
            }
            presentError(PostErrorMapper.message(for: error, fallback: String(localized: .postErrorCreate)))
            return false
        }
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
