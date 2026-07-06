//
//  RevealablePasswordField.swift
//  smmp
//

import SwiftUI
import UIKit

enum RevealablePasswordFieldPurpose {
    case login
    case newPassword
}

struct PasswordField: View {
    @Binding var text: String
    let prompt: LocalizedStringResource
    var purpose: RevealablePasswordFieldPurpose = .login
    var isDisabled: Bool = false
    var onChange: (() -> Void)?

    @State private var isRevealed = false

    private let revealButtonWidth: CGFloat = 36

    private var textContentType: UITextContentType {
        switch purpose {
        case .login: .password
        case .newPassword: .newPassword
        }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isRevealed {
                    TextField(text: $text, prompt: Text(prompt), label: {})
                } else {
                    SecureField(prompt, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(textContentType)
            .padding(.trailing, revealButtonWidth)

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.body)
                    .frame(width: revealButtonWidth, height: revealButtonWidth)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel(
                isRevealed
                    ? String(localized: .commonAccessibilityHidePassword)
                    : String(localized: .commonAccessibilityShowPassword)
            )
        }
        .textFieldStyle(.roundedBorder)
        .disabled(isDisabled)
        .onChange(of: text) {
            onChange?()
        }
    }
}
