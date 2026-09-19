//
//  AccountDeleting.swift
//  smmp
//

protocol AccountDeleting: AnyObject {
    func deleteAccount(userId: String) async throws
}

enum AccountDeletionError: Error, Equatable {
    case missingUser
}
