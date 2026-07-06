//
//  ProfileRoute.swift
//  smmp
//

import Foundation

enum ProfileRoute: AppRoute {
    case profile
    case editProfile
    case following
    case postDetail(FeedPostItem)
}

typealias ProfileRouter = Router<ProfileRoute>
