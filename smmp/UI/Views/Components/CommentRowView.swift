//
//  CommentRowView.swift
//  smmp
//

import SwiftUI

struct CommentRowView: View {
    let item: CommentRowItem
    let canDelete: Bool
    let onDeleteTapped: () -> Void
    var onAuthorTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            authorAvatarControl

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.author.displayName ?? String(localized: .commonUser))
                        .font(.subheadline.bold())

                    if let createdAt = item.comment.createdAt {
                        Text(createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    if canDelete {
                        Button(role: .destructive, action: onDeleteTapped) {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let text = item.comment.text, !text.isEmpty {
                    Text(text)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var authorAvatarControl: some View {
        if let onAuthorTap {
            Button(action: onAuthorTap) {
                authorAvatar
            }
            .buttonStyle(.plain)
        } else {
            authorAvatar
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
            .frame(width: 32, height: 32)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 32))
            .foregroundStyle(.secondary)
    }
}
