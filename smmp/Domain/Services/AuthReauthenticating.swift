//
//  AuthReauthenticating.swift
//  smmp
//

protocol AuthReauthenticating: AnyObject {
    func reauthenticate(password: String) async throws
}
