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
                    Text(user.displayName ?? "User")
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
                    Button("Edit") {
                        // TODO: Edit profile
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        logout()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
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
