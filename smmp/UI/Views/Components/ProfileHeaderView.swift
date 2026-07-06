//
//  ProfileHeaderView.swift
//  smmp
//

import SwiftUI

struct ProfileHeaderView: View {
    let user: User
    let isOwnProfile: Bool
    var onFollowingTapped: (() -> Void)?

    private let avatarSize: CGFloat = 96

    var body: some View {
        VStack(spacing: 12) {
            profileAvatar

            Text(user.displayName ?? String(localized: .commonUser))
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            countsRow
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if let photoURL = user.photoURL, !photoURL.isEmpty, let url = URL(string: photoURL) {
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
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: avatarSize))
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var countsRow: some View {
        HStack(spacing: 24) {
            Text(.profileFollowerCount(user.followerCount))
                .foregroundStyle(.primary)

            if isOwnProfile, let onFollowingTapped {
                Button(action: onFollowingTapped) {
                    Text(.profileFollowingCount(user.followingCount))
                }
                .buttonStyle(.plain)
            } else {
                Text(.profileFollowingCount(user.followingCount))
                    .foregroundStyle(.primary)
            }
        }
        .font(.subheadline)
    }
}

#Preview("Own profile") {
    ProfileHeaderView(
        user: {
            var user = User(id: "user-1")
            user.displayName = "Alice"
            user.bio = "iOS developer"
            user.photoURL = "https://example.com/a.jpg"
            user.followerCount = 12
            user.followingCount = 5
            return user
        }(),
        isOwnProfile: true,
        onFollowingTapped: {}
    )
    .padding()
}

#Preview("Other profile") {
    ProfileHeaderView(
        user: {
            var user = User(id: "user-2")
            user.displayName = "Bob"
            user.bio = "Hello world"
            user.followerCount = 3
            user.followingCount = 8
            return user
        }(),
        isOwnProfile: false
    )
    .padding()
}
