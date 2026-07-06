//
//  AuthAccountDeleting.swift
//  smmp
//

protocol AuthAccountDeleting: AnyObject {
    func deleteCurrentUser() async throws
}
