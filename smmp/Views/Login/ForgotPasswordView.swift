//
//  ForgotPasswordView.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/4/26.
//

import SwiftUI

struct ForgotPasswordView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text(.authForgotPasswordInstructions)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle(.authForgotPasswordTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
