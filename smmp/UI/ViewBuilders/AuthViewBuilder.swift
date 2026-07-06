//
//  AuthViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct AuthViewBuilder {
    let deps: AppDependenciesProviding

    private func buildLogin(onNavigate: @escaping (AuthRoute) -> Void) -> LoginView {
        LoginView(
            viewModel: LoginViewModel(
                authRepository: deps.authRepository,
                localRepository: deps.localRepository,
                onNavigate: onNavigate
            )
        )
    }

    private func buildRegistration(onNavigate: @escaping (AuthRoute) -> Void) -> RegistrationView {
        RegistrationView(
            viewModel: RegistrationViewModel(
                authRepository: deps.authRepository,
                localRepository: deps.localRepository,
                onNavigate: onNavigate
            )
        )
    }

    private func buildForgotPassword(onNavigate: @escaping (AuthRoute) -> Void) -> ForgotPasswordView {
        ForgotPasswordView(
            viewModel: ForgotPasswordViewModel(
                authRepository: deps.authRepository,
                onNavigate: onNavigate
            )
        )
    }

    @ViewBuilder
    func build(_ route: AuthRoute, onNavigate: @escaping (AuthRoute) -> Void) -> some View {
        switch route {
        case .login:
            buildLogin(onNavigate: onNavigate)
        case .register:
            buildRegistration(onNavigate: onNavigate)
        case .forgotPassword:
            buildForgotPassword(onNavigate: onNavigate)
        }
    }
}
