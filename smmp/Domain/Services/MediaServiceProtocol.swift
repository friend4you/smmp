//
//  MediaServiceProtocol.swift
//  smmp
//

import Combine
import UIKit

protocol MediaServiceProtocol: AnyObject {
    var uploadProgressPublisher: AnyPublisher<Double, Never> { get }
    
    func uploadPostImage(_ imageData: Data, postId: String, authorId: String) async throws -> String
    func deletePostImage(postId: String, authorId: String) async throws
    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> String
    func deleteProfileImage(userId: String) async throws
}

enum MediaPaths {
    static func postImage(authorId: String, postId: String) -> String {
        "posts/\(authorId)/\(postId)/image.jpg"
    }

    static func profileImage(userId: String) -> String {
        "users/\(userId)/avatar.jpg"
    }
}
