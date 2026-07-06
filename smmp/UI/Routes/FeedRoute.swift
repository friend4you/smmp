//
//  FeedRoute.swift
//  smmp
//

import Foundation

enum FeedRoute: AppRoute {
    case feed
    case userProfile(userId: String)
    case postDetail(FeedPostItem)
    case editProfile
    case following
}

typealias FeedRouter = Router<FeedRoute>
