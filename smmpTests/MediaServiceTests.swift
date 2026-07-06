//
//  MediaServiceTests.swift
//  smmpTests
//

import Combine
import Testing
import UIKit
@testable import smmp

struct MediaServiceTests {

    @Test func resizeScalesLandscapeImageToMaxLongEdge() {
        let service = MediaService()
        let image = makeTestImage(width: 2160, height: 1080)

        let data = service.resizeImage(image)
        let resized = UIImage(data: data!)

        #expect(data != nil)
        #expect(resized != nil)
        #expect(resized!.size.width == 1080)
        #expect(resized!.size.height == 540)
        #expect(isJPEG(data!))
    }

    @Test func resizeScalesPortraitImageToMaxLongEdge() {
        let service = MediaService()
        let image = makeTestImage(width: 800, height: 1600)

        let data = service.resizeImage(image)
        let resized = UIImage(data: data!)

        #expect(data != nil)
        #expect(resized!.size.width == 540)
        #expect(resized!.size.height == 1080)
    }

    @Test func resizeKeepsSmallImagesUnscaled() {
        let service = MediaService()
        let image = makeTestImage(width: 400, height: 300)

        let data = service.resizeImage(image)
        let resized = UIImage(data: data!)

        #expect(resized!.size.width == 400)
        #expect(resized!.size.height == 300)
    }

    @Test func postImagePathUsesExpectedStorageLocation() {
        #expect(MediaPaths.postImage(postId: "abc123") == "posts/abc123/image.jpg")
    }

    @Test func profileImagePathUsesExpectedStorageLocation() {
        #expect(MediaPaths.profileImage(userId: "user-42") == "users/user-42/avatar.jpg")
    }

    @Test func mockMediaServiceRecordsUploadAndDeletePaths() async throws {
        let mock = MockMediaService()

        _ = try await mock.uploadPostImage(Data([0xFF, 0xD8, 0xFF]), postId: "post-1")
        try await mock.deletePostImage(postId: "post-1")

        #expect(mock.uploadedPostIds == ["post-1"])
        #expect(mock.deletedPostIds == ["post-1"])
        #expect(mock.uploadProgressPublisher.value == 1)
    }

    @Test func mockMediaServiceRecordsProfileImageUploadAndDelete() async throws {
        let mock = MockMediaService()

        let url = try await mock.uploadProfileImage(Data([0xFF, 0xD8, 0xFF]), userId: "user-1")
        try await mock.deleteProfileImage(userId: "user-1")

        #expect(url == "https://example.com/users/user-1/avatar.jpg")
        #expect(mock.uploadedProfileUserIds == ["user-1"])
        #expect(mock.deletedProfileUserIds == ["user-1"])
    }
}

private func makeTestImage(width: CGFloat, height: CGFloat) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
    return renderer.image { context in
        UIColor.blue.setFill()
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
}

private func isJPEG(_ data: Data) -> Bool {
    data.starts(with: [0xFF, 0xD8, 0xFF])
}

private final class MockMediaService: MediaServiceProtocol {
    private let progressSubject = CurrentValueSubject<Double, Never>(0)

    private(set) var uploadedPostIds: [String] = []
    private(set) var deletedPostIds: [String] = []
    private(set) var uploadedProfileUserIds: [String] = []
    private(set) var deletedProfileUserIds: [String] = []

    var uploadProgressPublisher: AnyPublisher<Double, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    func resizeImage(_ image: UIImage) -> Data? {
        image.jpegData(compressionQuality: 0.8)
    }

    func uploadPostImage(_ imageData: Data, postId: String) async throws -> String {
        uploadedPostIds.append(postId)
        progressSubject.send(1)
        return "https://example.com/\(postId)/image.jpg"
    }

    func deletePostImage(postId: String) async throws {
        deletedPostIds.append(postId)
    }

    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> String {
        uploadedProfileUserIds.append(userId)
        progressSubject.send(1)
        return "https://example.com/users/\(userId)/avatar.jpg"
    }

    func deleteProfileImage(userId: String) async throws {
        deletedProfileUserIds.append(userId)
    }
}

private extension AnyPublisher where Output == Double, Failure == Never {
    var value: Double {
        var result = 0.0
        let cancellable = sink { result = $0 }
        cancellable.cancel()
        return result
    }
}
