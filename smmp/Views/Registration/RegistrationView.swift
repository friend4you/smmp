//
//  RegistrationView.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/7/26.
//

import SwiftUI

struct RegistrationView: View {

    @StateObject var viewModel: RegistrationViewModel

    init(viewModel: RegistrationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField(text: $viewModel.displayName, prompt: Text(.authRegisterDisplayName), label: {})
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .disabled(viewModel.isSubmitting)
                        .onChange(of: viewModel.displayName) {
                            viewModel.isDisplayNameValid = true
                        }

                    if !viewModel.isDisplayNameValid {
                        Text(.authValidationDisplayNameRequired)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

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

                VStack(alignment: .leading, spacing: 4) {
                    PasswordField(
                        text: $viewModel.password,
                        prompt: .authLoginPassword,
                        purpose: .newPassword,
                        isDisabled: viewModel.isSubmitting
                    ) {
                        viewModel.isPasswordValid = true
                        viewModel.updatePasswordStrength()
                    }

                    if let strength = viewModel.passwordStrength {
                        Text(passwordStrengthLabel(strength))
                            .font(.caption)
                            .foregroundStyle(passwordStrengthColor(strength))
                    }

                    if !viewModel.isPasswordValid {
                        Text(.authValidationPasswordTooShort)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    PasswordField(
                        text: $viewModel.repeatPassword,
                        prompt: .authLoginRepeatPassword,
                        purpose: .newPassword,
                        isDisabled: viewModel.isSubmitting
                    ) {
                        viewModel.isRepeatPasswordValid = true
                    }

                    if !viewModel.isRepeatPasswordValid {
                        Text(.authValidationPasswordMismatch)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Button {
                    Task {
                        await viewModel.register()
                    }
                } label: {
                    Group {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(.authRegisterSubmit)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(viewModel.isSubmitting)
            }
            .padding()
        }
        .navigationTitle(.authRegisterSubmit)
        .navigationBarTitleDisplayMode(.inline)
        .alert(String(localized: .commonErrorTitle), isPresented: $viewModel.shouldShowErrorMessage) {
            Button(String(localized: .commonOk), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private func passwordStrengthLabel(_ strength: FormValidation.PasswordStrength) -> LocalizedStringResource {
        switch strength {
        case .weak: .authPasswordStrengthWeak
        case .normal: .authPasswordStrengthOk
        case .strong: .authPasswordStrengthStrong
        }
    }

    private func passwordStrengthColor(_ strength: FormValidation.PasswordStrength) -> Color {
        switch strength {
        case .weak: .red
        case .normal: .orange
        case .strong: .green
        }
    }
}
