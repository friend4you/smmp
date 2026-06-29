//
//  NewPostView.swift
//  smmp
//

import PhotosUI
import SwiftUI

struct NewPostView: View {
    @EnvironmentObject private var sessionService: SessionService
    @StateObject private var viewModel: CreatePostViewModel
    @Binding private var selectedTab: Tab
    @State private var selectedPhotoItem: PhotosPickerItem?

    init(
        postRepository: PostRepositoryProtocol,
        mediaService: MediaServiceProtocol,
        networkMonitor: NetworkMonitor,
        selectedTab: Binding<Tab>
    ) {
        _viewModel = StateObject(
            wrappedValue: CreatePostViewModel(
                postRepository: postRepository,
                mediaService: mediaService,
                networkMonitor: networkMonitor
            )
        )
        _selectedTab = selectedTab
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isOffline {
                    offlineBanner
                }

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.text)
                        .frame(minHeight: 160)
                        .disabled(viewModel.isSubmitting)

                    if viewModel.text.isEmpty {
                        Text(.postNewPlaceholder)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 1)
                }

                imageSection

                if viewModel.isUploadingImage {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: viewModel.uploadProgress)
                        Text(.postImageUploadProgress(Int(viewModel.uploadProgress * 100)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    if viewModel.isOverLimit {
                        Text(.postValidationTooLong)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Spacer()

                    Text(.postNewCharacterCount(viewModel.characterCount))
                        .font(.caption)
                        .foregroundStyle(viewModel.isOverLimit ? .red : .secondary)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle(Text(.postNewTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await submitPost() }
                    } label: {
                        Text(.postNewSubmit)
                    }
                    .disabled(!viewModel.canSubmit)
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
            .onChange(of: selectedPhotoItem) { _, item in
                Task { await loadSelectedPhoto(item) }
            }
        }
    }

    @ViewBuilder
    private var imageSection: some View {
        if let image = viewModel.selectedImage {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    viewModel.removeSelectedImage()
                    selectedPhotoItem = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.6))
                }
                .padding(8)
                .disabled(viewModel.isSubmitting)
            }
        } else {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label {
                    Text(.postImagePicker)
                } icon: {
                    Image(systemName: "photo")
                }
            }
            .disabled(viewModel.isSubmitting)
        }
    }

    private var offlineBanner: some View {
        Text(.feedOfflineBanner)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else {
            viewModel.removeSelectedImage()
            return
        }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            viewModel.removeSelectedImage()
            return
        }

        viewModel.selectedImage = image
    }

    private func submitPost() async {
        guard let userId = sessionService.currentUser?.id else { return }

        if await viewModel.submit(authorId: userId) {
            selectedPhotoItem = nil
            selectedTab = .feed
        }
    }
}

#Preview {
    NewPostView(
        postRepository: PostRepository(
            networkMonitor: NetworkMonitor(),
            localRepository: LocalRepository(persistence: PersistenceController.shared),
            persistence: PersistenceController.shared,
            mediaService: MediaService()
        ),
        mediaService: MediaService(),
        networkMonitor: NetworkMonitor(),
        selectedTab: .constant(.newPost)
    )
    .environmentObject(SessionService())
}
