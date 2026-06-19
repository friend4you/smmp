//
//  LoginView.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/4/26.
//

import SwiftUI

struct LoginView: View {

    @EnvironmentObject private var deps: AppDependencies
    @StateObject private var loginViewModel: LoginViewModel

    init(loginViewModel: LoginViewModel) {
        _loginViewModel = StateObject(wrappedValue: loginViewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .padding(.horizontal, 24)
                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    TextField(text: $loginViewModel.email, prompt: Text(.authLoginEmail), label: {})
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(loginViewModel.isSubmitting)
                        .onChange(of: loginViewModel.email) {
                            loginViewModel.isEmailValid = true
                        }

                    if !loginViewModel.isEmailValid {
                        Text(.authValidationEmailInvalid)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    SecureField(.authLoginPassword, text: $loginViewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .disabled(loginViewModel.isSubmitting)
                        .onChange(of: loginViewModel.password) {
                            loginViewModel.isPasswordValid = true
                        }

                    if !loginViewModel.isPasswordValid {
                        Text(.authValidationPasswordRequired)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                HStack {
                    Spacer()
                    NavigationLink {
                        ForgotPasswordView()
                    } label: {
                        Text(.authLoginForgotPassword)
                    }
                    .font(.subheadline)
                    .disabled(loginViewModel.isSubmitting)
                }

                Button {
                    Task {
                        await loginViewModel.login()
                    }
                } label: {
                    Group {
                        if loginViewModel.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(.authLoginSubmit)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(loginViewModel.isSubmitting)

                NavigationLink {
                    RegistrationView(viewModel: RegistrationViewModel(
                        authRepository: deps.authRepository,
                        localRepository: deps.localRepository
                    ))
                } label: {
                    Text(.authRegisterSubmit)
                }
                .disabled(loginViewModel.isSubmitting)

                Spacer()
            }
            .padding()
            .alert(String(localized: .commonErrorTitle), isPresented: $loginViewModel.shouldShowErrorMessage) {
                Button(String(localized: .commonOk), role: .cancel) {}
            } message: {
                Text(loginViewModel.errorMessage)
            }
        }
    }
}

#Preview {
    LoginView(loginViewModel: LoginViewModel(
        authRepository: AuthRepository(authService: AuthService()),
        localRepository: LocalRepository(persistence: PersistenceController())
    ))
}
