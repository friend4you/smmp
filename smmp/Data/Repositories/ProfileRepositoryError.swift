//
//  ProfileRepositoryError.swift
//  smmp
//

import Foundation

enum ProfileRepositoryError: LocalizedError {
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User profile not found."
        }
    }
}
