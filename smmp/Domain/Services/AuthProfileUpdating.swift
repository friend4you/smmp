//
//  AuthProfileUpdating.swift
//  smmp
//

import Foundation

protocol AuthProfileUpdating: AnyObject {
    func updateAuthProfile(displayName: String?, photoURL: URL?) async throws
}
