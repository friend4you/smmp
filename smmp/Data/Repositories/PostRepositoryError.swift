//
//  PostRepositoryError.swift
//  smmp
//

import Foundation

enum PostRepositoryError: LocalizedError {
    case emptyText
    case textTooLong
    case unauthorizedDelete
    case postNotFound

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Post text cannot be empty."
        case .textTooLong:
            return "Post text cannot exceed 280 characters."
        case .unauthorizedDelete:
            return "You can only delete your own posts."
        case .postNotFound:
            return "Post not found."
        }
    }
}
