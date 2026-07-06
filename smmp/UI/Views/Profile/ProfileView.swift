//
//  ProfileView.swift
//  smmp
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            if let displayName = viewModel.displayName {
                Text(displayName)
                    .font(.title2.bold())

                if let bio = viewModel.bio {
                    Text(bio)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            viewModel.fetchProfile()
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
                profileRepository: ProfileRepository(
                    networkMonitor: NetworkMonitor(),
                    localRepository: LocalRepository(persistence: PersistenceController.shared),
                    mediaService: MediaService(),
                    userDocumentFetcher: FirestoreUserDocumentRepository()),
                sessionService: SessionService(),
                onNavigate: { _ in }
            )
        )
    }
}
