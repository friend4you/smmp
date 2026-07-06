//
//  SessionServiceProtocol.swift
//  smmp
//

import Foundation

enum AuthSession {
    case idle
    case loading
    case success
    case failure
}

@MainActor
protocol SessionServiceProtocol: AnyObject {
    var currentUser: User? { get }
    var sessionState: AuthSession { get }
    var isAuthenticated: Bool { get }
}
