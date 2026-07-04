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

    let networkMonitor: NetworkMonitor

    let mediaService: MediaService
    let sessionService: SessionService

    let authRepository: AuthRepository
    let localRepository: LocalRepositoryProtocol
    let postRepository: PostRepository
    let profileRepository: ProfileRepository
    let followRepository: FollowRepository
    let commentRepository: CommentRepository
    
    init() {
        let persistence = PersistenceController.shared
        let network = NetworkMonitor()
        let auth = AuthService()
        let media = MediaService()

        self.networkMonitor = network
        self.mediaService = media
        self.sessionService = SessionService()

        self.localRepository = LocalRepository(persistence: persistence)
        self.profileRepository = ProfileRepository(
            networkMonitor: network,
            localRepository: localRepository,
            mediaService: media
        )
        self.authRepository = AuthRepository(authService: auth)
        self.postRepository = PostRepository(
            networkMonitor: network,
            localRepository: localRepository,
            mediaService: media
        )
        self.followRepository = FollowRepository(networkMonitor: network,
                                                 mediaService: media)
        self.commentRepository = CommentRepository(
            networkMonitor: network,
            localRepository: localRepository,
            mediaService: media
        )
    }
}
