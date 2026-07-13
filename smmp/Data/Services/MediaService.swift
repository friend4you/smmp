//
//  MediaService.swift
//  smmp
//

import Combine
import FirebaseStorage
import UIKit

enum MediaServiceError: Error {
    case resizeFailed
    case uploadFailed(underlying: Error)
    case invalidDownloadURL
}

final class MediaService: MediaServiceProtocol {
    static let maxLongEdge: CGFloat = 1080
    static let jpegQuality: CGFloat = 0.8

    private let storage: Storage
    private let progressSubject = CurrentValueSubject<Double, Never>(0)

    var uploadProgressPublisher: AnyPublisher<Double, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    init(storage: Storage = Storage.storage()) {
        self.storage = storage
    }

    func uploadPostImage(_ imageData: Data, postId: String) async throws -> String {
        try await uploadImage(imageData, at: MediaPaths.postImage(postId: postId))
    }

    func deletePostImage(postId: String) async throws {
        try await deleteStorageObject(at: MediaPaths.postImage(postId: postId))
    }

    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> String {
        try await uploadImage(imageData, at: MediaPaths.profileImage(userId: userId))
    }

    func deleteProfileImage(userId: String) async throws {
        try await deleteStorageObject(at: MediaPaths.profileImage(userId: userId))
    }

    // MARK: - Private

    private func uploadImage(_ imageData: Data, at path: String) async throws -> String {
        progressSubject.send(0)

        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = ref.putData(imageData, metadata: metadata)

            uploadTask.observe(.progress) { [weak self] snapshot in
                guard let progress = snapshot.progress else { return }
                let total = max(progress.totalUnitCount, 1)
                let fraction = Double(progress.completedUnitCount) / Double(total)
                self?.progressSubject.send(fraction)
            }

            uploadTask.observe(.success) { [weak self] _ in
                ref.downloadURL { url, error in
                    if let error {
                        continuation.resume(throwing: MediaServiceError.uploadFailed(underlying: error))
                        return
                    }
                    guard let url else {
                        continuation.resume(throwing: MediaServiceError.invalidDownloadURL)
                        return
                    }
                    self?.progressSubject.send(1)
                    continuation.resume(returning: url.absoluteString)
                }
            }

            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    continuation.resume(throwing: MediaServiceError.uploadFailed(underlying: error))
                }
            }
        }
    }

    private func deleteStorageObject(at path: String) async throws {
        let ref = storage.reference().child(path)
        do {
            try await ref.delete()
        } catch let error as NSError where error.domain == StorageErrorDomain
            && error.code == StorageErrorCode.objectNotFound.rawValue {
            return
        } catch {
            throw error
        }
    }
}
