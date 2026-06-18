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
                    .padding(.horizontal, 24)
                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    TextField(text: $loginViewModel.email, prompt: Text("Email"), label: {})
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(loginViewModel.isSubmitting)

                    if !loginViewModel.isEmailValid {
                        Text("Please enter a valid email address.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    SecureField("Password", text: $loginViewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .disabled(loginViewModel.isSubmitting)

                    if !loginViewModel.isPasswordValid {
                        Text("Please enter your password.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                HStack {
                    Spacer()
                    NavigationLink("Forgot password?") {
                        ForgotPasswordView()
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
                            Text("Login")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(loginViewModel.isSubmitting)

                NavigationLink("Register") {
                    RegistrationView(viewModel: RegistrationViewModel(
                        authRepository: deps.authRepository,
                        localRepository: deps.localRepository
                    ))
                }
                .disabled(loginViewModel.isSubmitting)

                Spacer()
            }
            .padding()
            .alert("Error", isPresented: $loginViewModel.shouldShowErrorMessage) {
                Button("OK", role: .cancel) {}
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
