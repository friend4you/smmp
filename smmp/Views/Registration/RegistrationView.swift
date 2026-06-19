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
        VStack(spacing: 16) {
            TextField(text: $viewModel.email, prompt: Text(.authLoginEmail), label: {})
                .textFieldStyle(.roundedBorder)
            TextField(text: $viewModel.password, prompt: Text(.authLoginPassword), label: {})
                .textFieldStyle(.roundedBorder)
            TextField(text: $viewModel.repeatPassword, prompt: Text(.authLoginRepeatPassword), label: {})
                .textFieldStyle(.roundedBorder)
            Button {
                Task {
                    await viewModel.register()
                }
            } label: {
                Text(.authRegisterSubmit)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
