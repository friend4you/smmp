//
//  MediaServiceProtocol.swift
//  smmp
//

import Combine
import UIKit

protocol MediaServiceProtocol: AnyObject {
    var uploadProgressPublisher: AnyPublisher<Double, Never> { get }
    
    func uploadPostImage(_ imageData: Data, postId: String) async throws -> String
    func deletePostImage(postId: String) async throws
    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> String
    func deleteProfileImage(userId: String) async throws
}

enum MediaPaths {
    static func postImage(postId: String) -> String {
        "posts/\(postId)/image.jpg"
    }

    static func profileImage(userId: String) -> String {
        "users/\(userId)/avatar.jpg"
    }
}
