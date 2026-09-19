//
//  BlockRepositoryProtocol.swift
//  smmp
//

import Foundation

enum BlockRepositoryError: Error, Equatable {
    case cannotBlockSelf
}

protocol BlockRepositoryProtocol: AnyObject {
    func block(currentUserId: String, targetUserId: String) async throws
    func unblock(currentUserId: String, targetUserId: String) async throws
    func isBlocked(currentUserId: String, targetUserId: String) async throws -> Bool
    func blockedIds(for userId: String) async throws -> Set<String>
    func deleteAllBlocks(for userId: String) async throws
}
