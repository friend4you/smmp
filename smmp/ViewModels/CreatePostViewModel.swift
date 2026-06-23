//
//  CreatePostViewModel.swift
//  smmp
//

import Combine
import Foundation

@MainActor
final class CreatePostViewModel: ObservableObject {
    static let maxTextLength = 280

    @Published var text = ""
    @Published private(set) var isSubmitting = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let postRepository: PostRepositoryProtocol
    private let networkMonitor: NetworkMonitor

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

    var canSubmit: Bool {
        isValid && !isSubmitting && networkMonitor.isConnected
    }

    var isOffline: Bool {
        !networkMonitor.isConnected
    }

    init(postRepository: PostRepositoryProtocol, networkMonitor: NetworkMonitor) {
        self.postRepository = postRepository
        self.networkMonitor = networkMonitor
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
        defer { isSubmitting = false }

        do {
            try await postRepository.createPost(text: text, authorId: authorId)
            try await postRepository.refreshFeed(currentUserId: authorId)
            text = ""
            return true
        } catch {
            presentError(PostErrorMapper.message(for: error, fallback: String(localized: .postErrorCreate)))
            return false
        }
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
