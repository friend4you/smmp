//
//  PostCardView.swift
//  smmp
//

import SwiftUI

enum PostImageDisplayStyle {
    case feed
    case detail
}

struct PostCardView: View {
    let item: FeedPostItem
    var imageDisplayStyle: PostImageDisplayStyle = .feed
    let onLikeTapped: () -> Void
    var onAuthorTap: (() -> Void)? = nil
    var onPostTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            authorHeader

            if let text = item.post.text, !text.isEmpty {
                postBody(text)
            }

            postImage

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
    private var authorHeader: some View {
        if let onAuthorTap {
            Button(action: onAuthorTap) {
                authorHeaderContent
            }
            .buttonStyle(.plain)
        } else {
            authorHeaderContent
        }
    }

    private var authorHeaderContent: some View {
        HStack(spacing: 12) {
            authorAvatar

            VStack(alignment: .leading, spacing: 2) {
                Text(item.author.displayName ?? String(localized: .commonUser))
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                if let createdAt = item.post.createdAt {
                    Text(createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func postBody(_ text: String) -> some View {
        if let onPostTap {
            Button(action: onPostTap) {
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        } else {
            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var postImage: some View {
        if let imageURL = item.post.imageURL, let url = URL(string: imageURL) {
            Group {
                if let onPostTap {
                    Button(action: onPostTap) {
                        postImageContent(url: url)
                    }
                    .buttonStyle(.plain)
                } else {
                    postImageContent(url: url)
                }
            }
        }
    }

    @ViewBuilder
    private func postImageContent(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: imageDisplayStyle == .feed ? 240 : nil)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .failure:
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: imageDisplayStyle == .feed ? 120 : 160)
            @unknown default:
                EmptyView()
            }
        }
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
