//
//  PostCardView.swift
//  smmp
//

import SwiftUI

struct PostCardView: View {
    let item: FeedPostItem
    let onLikeTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                authorAvatar

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.author.displayName ?? String(localized: .commonUser))
                        .font(.subheadline.bold())

                    if let createdAt = item.post.createdAt {
                        Text(createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }

            if let text = item.post.text, !text.isEmpty {
                Text(text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 16) {
                Button(action: onLikeTapped) {
                    Label {
                        Text(.feedLikeCount(item.post.likeCount))
                    } icon: {
                        Image(systemName: item.isLikedByCurrentUser ? "heart.fill" : "heart")
                    }
                    .foregroundStyle(item.isLikedByCurrentUser ? .red : .secondary)
                }
                .buttonStyle(.plain)

                Label {
                    Text(.feedCommentCount(item.post.commentCount))
                } icon: {
                    Image(systemName: "bubble.right")
                }
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var authorAvatar: some View {
        if let photoURL = item.author.photoURL, let url = URL(string: photoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    avatarPlaceholder
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 40))
            .foregroundStyle(.secondary)
    }
}
