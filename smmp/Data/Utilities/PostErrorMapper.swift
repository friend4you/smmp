//
//  PostErrorMapper.swift
//  smmp
//

import Foundation

enum PostErrorMapper {
    static func message(for error: Error, fallback: String) -> String {
        guard let error = error as? PostRepositoryError else {
            return fallback
        }

        switch error {
        case .emptyText:
            return String(localized: .postValidationEmpty)
        case .textTooLong:
            return String(localized: .postValidationTooLong)
        case .unauthorizedDelete:
            return String(localized: .postErrorUnauthorizedDelete)
        case .postNotFound:
            return String(localized: .postErrorNotFound)
        }
    }
}
