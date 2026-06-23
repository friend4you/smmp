//
//  PostDetailView.swift
//  smmp
//

import SwiftUI

struct PostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PostDetailViewModel

    init(
        item: FeedPostItem,
        currentUserId: String,
        commentRepository: CommentRepositoryProtocol,
        profileRepository: ProfileRepositoryProtocol,
        postRepository: PostRepositoryProtocol,
        networkMonitor: NetworkMonitor
    ) {
        _viewModel = StateObject(
            wrappedValue: PostDetailViewModel(
                item: item,
                currentUserId: currentUserId,
                commentRepository: commentRepository,
                profileRepository: profileRepository,
                postRepository: postRepository,
                networkMonitor: networkMonitor
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isOffline {
                    offlineBanner
                }

                PostCardView(item: viewModel.postItem) {
                    Task { await viewModel.toggleLike() }
                }

                commentsSection
            }
            .padding()
        }
        .navigationTitle(Text(.feedTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isPostAuthor {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        viewModel.showDeletePostConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            commentComposer
        }
        .refreshable {
            await viewModel.refreshComments()
        }
        .task {
            await viewModel.loadComments()
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .confirmationDialog(
            Text(.postDeleteConfirmTitle),
            isPresented: $viewModel.showDeletePostConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: .postDeleteConfirmAction), role: .destructive) {
                Task { await viewModel.deletePost() }
            }
            Button(String(localized: .commonCancel), role: .cancel) {}
        } message: {
            Text(.postDeleteConfirmMessage)
        }
        .confirmationDialog(
            Text(.commentDeleteConfirmTitle),
            isPresented: Binding(
                get: { viewModel.commentPendingDelete != nil },
                set: { if !$0 { viewModel.commentPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: .commentDeleteConfirmAction), role: .destructive) {
                guard let comment = viewModel.commentPendingDelete else { return }
                Task { await viewModel.deleteComment(comment) }
            }
            Button(String(localized: .commonCancel), role: .cancel) {
                viewModel.commentPendingDelete = nil
            }
        } message: {
            Text(.commentDeleteConfirmMessage)
        }
        .alert(
            Text(.commonErrorTitle),
            isPresented: $viewModel.showError,
            presenting: viewModel.errorMessage
        ) { _ in
            Button(String(localized: .commonOk)) {
                viewModel.showError = false
            }
        } message: { message in
            Text(message)
        }
    }

    @ViewBuilder
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(.commentSectionTitle)
                .font(.headline)

            if viewModel.isLoadingComments && viewModel.commentItems.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.commentItems.isEmpty {
                Text(.commentEmpty)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.commentItems) { comment in
                    CommentRowView(
                        item: comment,
                        canDelete: viewModel.canDeleteComment(comment)
                    ) {
                        viewModel.commentPendingDelete = comment
                    }
                    Divider()
                }
            }
        }
    }

    private var commentComposer: some View {
        HStack(spacing: 12) {
            TextField(
                String(localized: .commentPlaceholder),
                text: $viewModel.commentText,
                axis: .vertical
            )
            .lineLimit(1...4)
            .textFieldStyle(.roundedBorder)
            .disabled(viewModel.isSubmittingComment || viewModel.isOffline)

            Button {
                Task { await viewModel.addComment() }
            } label: {
                Image(systemName: "paperplane.fill")
            }
            .disabled(!viewModel.canSubmitComment)
        }
        .padding()
        .background(.bar)
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
}
