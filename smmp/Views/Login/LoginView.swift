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
                

            }
            .padding()
        }
    }
}

#Preview {
    LoginView(loginViewModel: LoginViewModel(authRepository: AuthRepository(authService: AuthService()), localRepository: LocalRepository(persistence: PersistenceController())))
}
