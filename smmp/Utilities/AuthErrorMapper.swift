//
//  AuthErrorMapper.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/4/26.
//

import FirebaseAuth
import Foundation

enum AuthErrorMapper {
    static func message(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }

        switch code {
        case .invalidEmail:
            return String(localized: .authValidationEmailInvalid)
        case .wrongPassword, .invalidCredential:
            return String(localized: .authErrorWrongPassword)
        case .userNotFound:
            return String(localized: .authErrorUserNotFound)
        case .networkError:
            return String(localized: .authErrorNetwork)
        case .tooManyRequests:
            return String(localized: .authErrorTooManyRequests)
        default:
            return error.localizedDescription
        }
    }
}
