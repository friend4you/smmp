//
//  AuthRoute.swift
//  smmp
//

import Foundation

enum AuthRoute: AppRoute {
    case login
    case register
    case forgotPassword
}

typealias AuthRouter = Router<AuthRoute>
