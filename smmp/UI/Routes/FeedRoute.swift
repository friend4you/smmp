//
//  FeedRoute.swift
//  smmp
//

import Foundation

enum FeedRoute: AppRoute {
    case feed
    case postDetail(FeedPostItem)
}

typealias FeedRouter = Router<FeedRoute>
