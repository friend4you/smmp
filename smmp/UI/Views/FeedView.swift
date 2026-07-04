//
//  FeedView.swift
//  smmp
//

import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel

    init(viewModel: FeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .top) {
            feedList

            if viewModel.showNewPostsBanner {
                newPostsBanner
            }
        }
        .navigationTitle(Text(.feedTitle))
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
        .onAppear {
            viewModel.start()
        }
    }

    @ViewBuilder
    private var feedList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.isOffline {
                        offlineBanner
                    }

                    if viewModel.items.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.items) { item in
                            Button {
                                viewModel.showPostDetail(for: item)
                            } label: {
                                PostCardView(item: item) {
                                    Task { await viewModel.toggleLike(for: item) }
                                }
                            }
                            .buttonStyle(.plain)
                            .id(item.id)
                            .task {
                                await viewModel.loadMoreIfNeeded(currentItem: item)
                            }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y <= 4
            } action: { _, isAtTop in
                viewModel.updateScrollAtTop(isAtTop)
            }
            .onChange(of: viewModel.scrollToTopRequest) { _, _ in
                guard let firstId = viewModel.items.first?.id else { return }
                withAnimation {
                    proxy.scrollTo(firstId, anchor: .top)
                }
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

    private var emptyState: some View {
        ContentUnavailableView(
            label: { Text(.feedEmptyTitle) },
            description: { Text(.feedEmptyDescription) }
        )
        .padding(.top, 48)
    }

    private var newPostsBanner: some View {
        Button {
            viewModel.revealNewPosts()
        } label: {
            Text(.feedNewPostsBanner)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .clipShape(Capsule())
                .shadow(radius: 4)
        }
        .padding(.top, 8)
        .zIndex(1)
    }
}

#Preview {
    NavigationStack {
        FeedView(
            viewModel: FeedViewModel(
                postRepository: PostRepository(
                    networkMonitor: NetworkMonitor(),
                    localRepository: LocalRepository(persistence: PersistenceController.shared),
                    mediaService: MediaService()
                ),
                profileRepository: ProfileRepository(
                    networkMonitor: NetworkMonitor(),
                    localRepository: LocalRepository(persistence: PersistenceController.shared),
                    mediaService: MediaService()
                ),
                networkMonitor: NetworkMonitor(),
                sessionService: SessionService()
            )
        )
    }
    .environmentObject(SessionService())
}
