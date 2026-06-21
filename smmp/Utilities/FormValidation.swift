//
//  FormValidation.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/4/26.
//

import Foundation

enum FormValidation {
    static let minimumPasswordLength = 6

    private static let emailPattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#

    enum PasswordStrength {
        case weak
        case normal
        case strong
    }

    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.range(
            of: emailPattern,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    static func isValidPassword(_ password: String) -> Bool {
        password.count >= minimumPasswordLength
    }

    static func passwordStrength(_ password: String) -> PasswordStrength? {
        guard !password.isEmpty else { return nil }

        if password.count < minimumPasswordLength {
            return .weak
        }

        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasDigit = password.rangeOfCharacter(from: .decimalDigits) != nil

        if password.count >= 10 && hasLetter && hasDigit {
            return .strong
        }
        if hasLetter && hasDigit {
            return .normal
        }
        return .weak
    }
}
