//
//  ProfileRoute.swift
//  smmp
//

import Foundation

enum ProfileRoute: AppRoute {
    case profile
    case editProfile
}

typealias ProfileRouter = Router<ProfileRoute>
