//
//  FollowErrorMapper.swift
//  smmp
//

import Foundation

enum FollowErrorMapper {
    static func message(for error: Error, fallback: String) -> String {
        guard let error = error as? FollowRepositoryError else {
            return fallback
        }

        switch error {
        case .cannotFollowSelf:
            return String(localized: .followErrorSelf)
        case .followingLimitReached:
            return String(localized: .followErrorLimit)
        }
    }
}
