//
//  FeedRoute.swift
//  smmp
//

import Foundation

enum FeedRoute: AppRoute {
    case postDetail(FeedPostItem)
}

typealias FeedRouter = Router<FeedRoute>
