//
//  NewPostView.swift
//  smmp
//

import SwiftUI

struct NewPostView: View {
    @EnvironmentObject private var sessionService: SessionService
    @StateObject private var viewModel: CreatePostViewModel
    @Binding private var selectedTab: Tab

    init(
        postRepository: PostRepositoryProtocol,
        networkMonitor: NetworkMonitor,
        selectedTab: Binding<Tab>
    ) {
        _viewModel = StateObject(
            wrappedValue: CreatePostViewModel(
                postRepository: postRepository,
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

    private func submitPost() async {
        guard let userId = sessionService.currentUser?.id else { return }

        if await viewModel.submit(authorId: userId) {
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
        networkMonitor: NetworkMonitor(),
        selectedTab: .constant(.newPost)
    )
    .environmentObject(SessionService())
}
