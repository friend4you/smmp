//
//  FeedAuthorIds.swift
//  smmp
//

import Foundation

enum FeedAuthorIds {
    static let maxQueryAuthorCount = 30

    static func authorIds(currentUserId: String, followingIds: [String]) -> [String] {
        var ids = [currentUserId]
        for followedId in followingIds where ids.count < maxQueryAuthorCount {
            if followedId != currentUserId {
                ids.append(followedId)
            }
        }
        return ids
    }
}
