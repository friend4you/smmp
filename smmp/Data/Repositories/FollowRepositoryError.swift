//
//  FollowRepositoryError.swift
//  smmp
//

import Foundation

enum FollowRepositoryError: LocalizedError {
    case cannotFollowSelf
    case followingLimitReached

    var errorDescription: String? {
        switch self {
        case .cannotFollowSelf:
            return "You cannot follow yourself."
        case .followingLimitReached:
            return "You can follow at most 30 users."
        }
    }
}
