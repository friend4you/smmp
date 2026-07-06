//
//  ProfilePostsListSection.swift
//  smmp
//

import SwiftUI

struct ProfilePostsListSection: View {
    let items: [FeedPostItem]
    var isLoading = false
    var isLikeDisabled = false
    let onPostTapped: (FeedPostItem) -> Void
    let onLikeTapped: (FeedPostItem) -> Void

    var body: some View {
        Group {
            if isLoading && items.isEmpty {
                PostListSkeleton(count: 2)
            } else if items.isEmpty {
                ContentUnavailableView {
                    Text(.profilePostsEmptyTitle)
                } description: {
                    Text(.profilePostsEmptyDescription)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        Button {
                            onPostTapped(item)
                        } label: {
                            PostCardView(item: item, isLikeDisabled: isLikeDisabled) {
                                onLikeTapped(item)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview("With posts") {
    let author = {
        var user = User(id: "user-1")
        user.displayName = "Alice"
        return user
    }()

    ScrollView {
        ProfilePostsListSection(
            items: [
                FeedPostItem(
                    post: Post(
                        id: "post-1",
                        authorId: "user-1",
                        text: "First post",
                        imageURL: nil,
                        likeCount: 2,
                        commentCount: 1,
                        createdAt: .now
                    ),
                    author: author,
                    isLikedByCurrentUser: false
                ),
                FeedPostItem(
                    post: Post(
                        id: "post-2",
                        authorId: "user-1",
                        text: "Second post",
                        imageURL: nil,
                        likeCount: 0,
                        commentCount: 0,
                        createdAt: .now
                    ),
                    author: author,
                    isLikedByCurrentUser: true
                )
            ],
            onPostTapped: { _ in },
            onLikeTapped: { _ in }
        )
        .padding()
    }
}

#Preview("Loading") {
    ProfilePostsListSection(
        items: [],
        isLoading: true,
        onPostTapped: { _ in },
        onLikeTapped: { _ in }
    )
    .padding()
}

#Preview("Empty") {
    ProfilePostsListSection(
        items: [],
        onPostTapped: { _ in },
        onLikeTapped: { _ in }
    )
    .padding()
}
