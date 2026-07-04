//
//  CommentRepositoryError.swift
//  smmp
//

import Foundation

enum CommentRepositoryError: LocalizedError {
    case emptyText
    case unauthorizedDelete
    case commentNotFound

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Comment text cannot be empty."
        case .unauthorizedDelete:
            return "You can only delete your own comments."
        case .commentNotFound:
            return "Comment not found."
        }
    }
}
