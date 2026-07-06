//
//  UserDocumentProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

protocol UserDocumentProtocol: Sendable {
    func fetchUserDocument(id: String) async throws -> User?
    func createUserDocument(id: String, data: [String: Any]) async throws
    func updateUserDocument(id: String, data: [String: Any]) async throws
    func searchUsers(prefix: String, limit: Int) async throws -> [User]
}
