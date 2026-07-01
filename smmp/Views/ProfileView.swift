//
//  ProfileView.swift
//  smmp
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var sessionService: SessionService
    @StateObject private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            if let user = sessionService.currentUser {
                Text(user.displayName ?? String(localized: .commonUser))
                    .font(.title2.bold())

                if let bio = user.bio {
                    Text(bio)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.editProfileTapped()
                } label: {
                    Text(.profileEdit)
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    Task {
                        await viewModel.logout()
                    }
                } label: {
                    Label(.profileLogout, systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(
            viewModel: ProfileViewModel(
                authRepository: AuthRepository(authService: AuthService()),
                postRepository: PostRepository(
                    networkMonitor: NetworkMonitor(),
                    localRepository: LocalRepository(persistence: PersistenceController.shared),
                    persistence: PersistenceController.shared,
                    mediaService: MediaService()
                )
            )
        )
    }
    .environmentObject(SessionService())
}
