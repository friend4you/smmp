//
//  EditProfileView.swift
//  smmp
//

import PhotosUI
import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditProfileViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showDiscardConfirmation = false

    init(viewModel: EditProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    formContent
                }
            }
            .navigationTitle(Text(.profileEdit))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        attemptDismiss()
                    } label: {
                        Text(.commonCancel)
                    }
                    .disabled(viewModel.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveProfile() }
                    } label: {
                        Text(.profileEditSave)
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .alert(
                Text(.commonErrorTitle),
                isPresented: $viewModel.showError,
                presenting: viewModel.errorMessage
            ) { _ in
                Button { viewModel.showError = false } label: {
                    Text(.commonOk)
                }
            } message: { message in
                Text(message)
            }
            .confirmationDialog(
                Text(.profileEditDiscardTitle),
                isPresented: $showDiscardConfirmation,
                titleVisibility: .visible
            ) {
                Button(.profileEditDiscardConfirm, role: .destructive) {
                    dismiss()
                }
                Button(.commonCancel, role: .cancel) {}
            } message: {
                Text(.profileEditDiscardMessage)
            }
            .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
            .task {
                await viewModel.load()
            }
            .onChange(of: selectedPhotoItem) { _, item in
                Task { await loadSelectedPhoto(item) }
            }
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isOffline {
                    OfflineBanner()
                }

                photoSection

                if viewModel.isUploadingPhoto {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: viewModel.uploadProgress)
                        Text(.profileEditUploadProgress(Int(viewModel.uploadProgress * 100)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(.profileEditDisplayName)
                        .font(.subheadline.weight(.medium))

                    TextField(String(localized: .authRegisterDisplayName), text: $viewModel.displayName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isSaving)

                    if !viewModel.isDisplayNameValid {
                        Text(.authValidationDisplayNameRequired)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(.profileEditBio)
                        .font(.subheadline.weight(.medium))

                    TextField(String(localized: .profileEditBioPlaceholder), text: $viewModel.bio, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isSaving)

                    HStack {
                        if viewModel.isBioOverLimit {
                            Text(.profileEditBioTooLong)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        Spacer()
                        Text(.profileEditBioCount(viewModel.bio.count))
                            .font(.caption)
                            .foregroundStyle(viewModel.isBioOverLimit ? .red : .secondary)
                    }
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        VStack(spacing: 12) {
            if let image = viewModel.selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())

                    Button {
                        viewModel.clearSelectedPhoto()
                        selectedPhotoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .offset(x: 4, y: -4)
                    .disabled(viewModel.isSaving)
                }
            } else if viewModel.showsExistingPhoto,
                      let photoURL = viewModel.existingPhotoURL,
                      let url = URL(string: photoURL) {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 120))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())

                    Button {
                        viewModel.removePhoto()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .offset(x: 4, y: -4)
                    .disabled(viewModel.isSaving)
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(.secondary)
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label {
                    Text(.profileEditPhotoPicker)
                } icon: {
                    Image(systemName: "photo")
                }
            }
            .disabled(viewModel.isSaving || viewModel.isOffline)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else {
            return
        }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return
        }

        viewModel.setSelectedImage(image)
    }

    private func attemptDismiss() {
        if viewModel.hasUnsavedChanges {
            showDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func saveProfile() async {
        if await viewModel.save() {
            dismiss()
        }
    }
}

#Preview {
    let network = NetworkMonitor()
    let localRepository = LocalRepository(persistence: PersistenceController.shared)
    let media = MediaService()

    return EditProfileView(
        viewModel: EditProfileViewModel(
            profileRepository: ProfileRepository(
                networkMonitor: network,
                localRepository: localRepository,
                mediaService: media,
                authProfileUpdater: AuthService()
            ),
            mediaService: media,
            sessionService: SessionService(),
            networkMonitor: network
        )
    )
}
