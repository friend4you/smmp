//
//  CommentErrorMapper.swift
//  smmp
//

import Foundation

enum CommentErrorMapper {
    static func message(for error: Error, fallback: String) -> String {
        guard let error = error as? CommentRepositoryError else {
            return fallback
        }

        switch error {
        case .emptyText:
            return String(localized: .commentValidationEmpty)
        case .unauthorizedDelete:
            return String(localized: .commentErrorUnauthorizedDelete)
        case .commentNotFound:
            return String(localized: .commentErrorNotFound)
        }
    }
}
