//
//  FormValidation.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/4/26.
//

import Foundation

enum FormValidation {
    private static let emailPattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#

    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.range(
            of: emailPattern,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }
}
