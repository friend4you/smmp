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
                TextField(text: $loginViewModel.email, prompt: Text("Email"), label: {})
                    .textFieldStyle(.roundedBorder)
                TextField(text: $loginViewModel.password, prompt: Text("Password"), label: {})
                    .textFieldStyle(.roundedBorder)
                Button("Login") {
                    Task {
                        await loginViewModel.login()
                    }
                }
                        .buttonStyle(.glassProminent)
                
                NavigationLink("Register") {
                    RegistrationView(viewModel: RegistrationViewModel(authRepository: deps.authRepository, localRepository: deps.localRepository))
                }
                Spacer()

                Text("Or login with other methods")
                HStack {
                    Image(.googleIcon)
                        .resizable()
                        .scaledToFit()
                    Image(.appleIcon)
                        .resizable()
                        .scaledToFit()
                }
                .frame(height: 40)
            }
            .padding()
        }
    }
}

#Preview {
    LoginView(loginViewModel: LoginViewModel(authRepository: AuthRepository(authService: AuthService()), localRepository: LocalRepository(persistence: PersistenceController())))
}
