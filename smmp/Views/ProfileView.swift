//
//  ProfileView.swift
//  smmp
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject private var sessionService: SessionService

    var body: some View {
        NavigationStack {
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
                        // TODO: Edit profile
                    } label: {
                        Text(.profileEdit)
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        logout()
                    } label: {
                        Label(.profileLogout, systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        }
    }

    private func logout() {
        try? Auth.auth().signOut()
    }
}

#Preview {
    ProfileView()
        .environmentObject(SessionService())
}
