//
//  LoginView.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/4/26.
//

import SwiftUI

struct LoginView: View {

    @StateObject private var viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(.logo)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .padding(.horizontal, 24)
            Spacer()

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
                    isDisabled: viewModel.isSubmitting
                ) {
                    viewModel.isPasswordValid = true
                }

                if !viewModel.isPasswordValid {
                    Text(.authValidationPasswordRequired)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            HStack {
                Spacer()
                Button {
                    viewModel.navigateToForgotPassword()
                } label: {
                    Text(.authLoginForgotPassword)
                }
                .font(.subheadline)
                .disabled(viewModel.isSubmitting)
            }

            Button {
                Task {
                    await viewModel.login()
                }
            } label: {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(.authLoginSubmit)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .disabled(viewModel.isSubmitting)

            Button {
                viewModel.navigateToRegister()
            } label: {
                Text(.authRegisterSubmit)
            }
            .disabled(viewModel.isSubmitting)

            Spacer()
        }
        .padding()
        .alert(String(localized: .commonErrorTitle), isPresented: $viewModel.shouldShowErrorMessage) {
            Button(String(localized: .commonOk), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel(
        authRepository: AuthRepository(
            authService: AuthService()
        ),
        localRepository: LocalRepository(persistence: PersistenceController())
    ))
}
