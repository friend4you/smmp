//
//  SearchRoute.swift
//  smmp
//

import Foundation

enum SearchRoute: AppRoute {
    case search
    case userProfile(userId: String)
    case postDetail(FeedPostItem)
    case editProfile
    case following
}

typealias SearchRouter = Router<SearchRoute>
