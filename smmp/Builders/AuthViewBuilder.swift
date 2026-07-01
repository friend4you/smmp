//
//  AuthViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct AuthViewBuilder {
    let deps: AppDependencies

    func buildLogin(onNavigate: @escaping (AuthRoute) -> Void) -> LoginView {
        LoginView(
            viewModel: LoginViewModel(
                authRepository: deps.authRepository,
                localRepository: deps.localRepository,
                onNavigate: onNavigate
            )
        )
    }

    func buildRegistration(onNavigate: @escaping (AuthRoute) -> Void) -> RegistrationView {
        RegistrationView(
            viewModel: RegistrationViewModel(
                authRepository: deps.authRepository,
                localRepository: deps.localRepository,
                onNavigate: onNavigate
            )
        )
    }

    func buildForgotPassword(onNavigate: @escaping (AuthRoute) -> Void) -> ForgotPasswordView {
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
