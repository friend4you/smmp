//
//  MediaServiceProtocol.swift
//  smmp
//

import Combine
import UIKit

protocol MediaServiceProtocol: AnyObject {
    var uploadProgressPublisher: AnyPublisher<Double, Never> { get }

    func resizeImage(_ image: UIImage) -> Data?
    func uploadPostImage(_ imageData: Data, postId: String) async throws -> String
    func deletePostImage(postId: String) async throws
}

enum MediaPaths {
    static func postImage(postId: String) -> String {
        "posts/\(postId)/image.jpg"
    }
}
