//
//  AppDependencies.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import Foundation
import Combine

@MainActor
final class AppDependencies: ObservableObject {

    let authService: AuthServiceProtocol
    let mediaService: MediaServiceProtocol
    let networkMonitor: NetworkMonitor
    let sessionService: SessionService

    let persistenceController: PersistenceController

    let authRepository: AuthRepository
    let postRepository: PostRepository
    let profileRepository: ProfileRepository
    let followRepository: FollowRepository
    let commentRepository: CommentRepository

    init() {
        let persistence = PersistenceController.shared
        let network = NetworkMonitor()
        let auth = AuthService()
        let media = MediaService()

        self.persistenceController = persistence
        self.networkMonitor = network
        self.authService = auth
        self.mediaService = media
        self.sessionService = SessionService()

        self.authRepository = AuthRepository(authService: auth)
        self.postRepository = PostRepository(networkMonitor: network, persistence: persistence, mediaService: media)
        self.profileRepository = ProfileRepository(networkMonitor: network, persistence: persistence, mediaService: media)
        self.followRepository = FollowRepository(networkMonitor: network, persistence: persistence, mediaService: media)
        self.commentRepository = CommentRepository(networkMonitor: network, persistence: persistence, mediaService: media)
    }
}
