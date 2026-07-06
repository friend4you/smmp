//
//  FeedRoute.swift
//  smmp
//

import Foundation

enum FeedRoute: AppRoute {
    case feed
    case userProfile(userId: String, stub: User?)
    case postDetail(FeedPostItem)
    case editProfile
    case following
}

typealias FeedRouter = Router<FeedRoute>
