//
//  ForgotPasswordView.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/4/26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: ForgotPasswordViewModel

    init(authRepository: AuthRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: ForgotPasswordViewModel(authRepository: authRepository))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(.authForgotPasswordInstructions)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                TextField(text: $viewModel.email, prompt: Text(.authLoginEmail), label: {})
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(viewModel.isSubmitting)
                    .onChange(of: viewModel.email) {
                        viewModel.isEmailValid = true
                    }

                if !viewModel.isEmailValid {
                    Text(.authValidationEmailInvalid)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Button {
                Task {
                    await viewModel.sendResetEmail()
                }
            } label: {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(.authForgotPasswordSubmit)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .disabled(viewModel.isSubmitting)

            Spacer()
        }
        .padding()
        .navigationTitle(.authForgotPasswordTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(String(localized: .commonErrorTitle), isPresented: $viewModel.shouldShowErrorMessage) {
            Button(String(localized: .commonOk), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert(String(localized: .authForgotPasswordSuccessTitle), isPresented: $viewModel.shouldShowSuccessMessage) {
            Button(String(localized: .commonOk), role: .cancel) {
                dismiss()
            }
        } message: {
            Text(.authForgotPasswordSuccessMessage)
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView(authRepository: AuthRepository(
            authService: AuthService()
        ))
    }
}
