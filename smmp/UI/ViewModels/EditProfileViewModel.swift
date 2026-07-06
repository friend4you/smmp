//
//  EditProfileViewModel.swift
//  smmp
//

import Combine
import Foundation
import UIKit

@MainActor
final class EditProfileViewModel: ObservableObject {
    static let maxBioLength = 160

    @Published var displayName = ""
    @Published var bio = ""
    @Published var selectedImage: UIImage?
    @Published private(set) var isPhotoRemoved = false
    @Published private(set) var isSaving = false
    @Published private(set) var uploadProgress: Double = 0
    @Published private(set) var isLoading = false
    @Published private(set) var existingPhotoURL: String?
    @Published var errorMessage: String?
    @Published var showError = false

    private let profileRepository: ProfileRepositoryProtocol
    private let mediaService: MediaServiceProtocol
    private let sessionService: SessionServiceProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let onSaved: () -> Void
    private var progressCancellable: AnyCancellable?

    private var initialDisplayName = ""
    private var initialBio = ""
    private var hadInitialPhoto = false

    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedBio: String {
        bio.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isDisplayNameValid: Bool {
        !trimmedDisplayName.isEmpty
    }

    var isBioOverLimit: Bool {
        bio.count > Self.maxBioLength
    }

    var isValid: Bool {
        isDisplayNameValid && !isBioOverLimit
    }

    var isOffline: Bool {
        !networkMonitor.isConnected
    }

    var canSave: Bool {
        isValid && hasUnsavedChanges && !isSaving && !isOffline
    }

    var isUploadingPhoto: Bool {
        isSaving && selectedImage != nil && uploadProgress < 1
    }

    var hasUnsavedChanges: Bool {
        trimmedDisplayName != initialDisplayName
            || trimmedBio != initialBio
            || selectedImage != nil
            || isPhotoRemoved
    }

    var showsExistingPhoto: Bool {
        !isPhotoRemoved && selectedImage == nil && !(existingPhotoURL?.isEmpty ?? true)
    }

    init(
        profileRepository: ProfileRepositoryProtocol,
        mediaService: MediaServiceProtocol,
        sessionService: SessionServiceProtocol,
        networkMonitor: NetworkMonitorProtocol,
        onSaved: @escaping () -> Void = {}
    ) {
        self.profileRepository = profileRepository
        self.mediaService = mediaService
        self.sessionService = sessionService
        self.networkMonitor = networkMonitor
        self.onSaved = onSaved
        progressCancellable = mediaService.uploadProgressPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.uploadProgress, on: self)
    }

    func load() async {
        guard let userId = sessionService.currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        guard let user = try? await profileRepository.fetchUser(id: userId) else {
            presentError(String(localized: .profileErrorLoad))
            return
        }

        displayName = user.displayName ?? ""
        bio = user.bio ?? ""
        existingPhotoURL = user.photoURL
        selectedImage = nil
        isPhotoRemoved = false

        initialDisplayName = trimmedDisplayName
        initialBio = trimmedBio
        hadInitialPhoto = !(user.photoURL?.isEmpty ?? true)
    }

    func setSelectedImage(_ image: UIImage) {
        selectedImage = image
        isPhotoRemoved = false
    }

    func removePhoto() {
        selectedImage = nil
        isPhotoRemoved = true
    }

    func clearSelectedPhoto() {
        selectedImage = nil
        isPhotoRemoved = hadInitialPhoto
    }

    @discardableResult
    func save() async -> Bool {
        guard let userId = sessionService.currentUser?.id else { return false }
        showError = false

        guard networkMonitor.isConnected else {
            presentError(String(localized: .profileEditErrorOffline))
            return false
        }

        guard isValid else { return false }
        guard hasUnsavedChanges else { return true }

        isSaving = true
        uploadProgress = 0
        defer {
            isSaving = false
            uploadProgress = 0
        }

        var profileImageData: Data?
        if let selectedImage {
            guard let imageData = mediaService.resizeImage(selectedImage) else {
                presentError(String(localized: .postImageErrorResize))
                return false
            }
            profileImageData = imageData
        }

        let shouldRemovePhoto = isPhotoRemoved && selectedImage == nil

        do {
            _ = try await profileRepository.updateProfile(
                uid: userId,
                displayName: trimmedDisplayName,
                bio: trimmedBio.isEmpty ? nil : trimmedBio,
                profileImageData: profileImageData,
                removeProfileImage: shouldRemovePhoto
            )
            NotificationCenter.default.post(name: .profileDidUpdate, object: nil)
            onSaved()
            return true
        } catch {
            presentError(String(localized: .profileEditErrorSave))
            return false
        }
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
