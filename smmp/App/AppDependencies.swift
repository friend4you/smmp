//
//  AppDependencies.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import Foundation
import Combine

@MainActor
final class AppDependencies: AppDependenciesProviding {

    let networkMonitor: NetworkMonitorProtocol
    let hapticService: HapticServiceProtocol

    let mediaService: MediaServiceProtocol
    let sessionService: SessionServiceProtocol

    let contentFilter: ContentFiltering
    let legalConfiguration: LegalConfiguration

    let authRepository: AuthRepositoryProtocol
    let accountDeleter: AuthAccountDeleting
    let authReauthenticator: AuthReauthenticating
    let localRepository: LocalRepositoryProtocol
    let postRepository: PostRepositoryProtocol
    let profileRepository: ProfileRepositoryProtocol
    let followRepository: FollowRepositoryProtocol
    let commentRepository: CommentRepositoryProtocol
    let reportRepository: ReportRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol
    let accountDeletionService: AccountDeleting
    
    init() {
        let persistence = PersistenceController.shared
        let network = NetworkMonitor()
        let auth = AuthService()
        let media = MediaService()
        let contentFilter = ContentFilter.default
        let legalConfiguration = LegalConfiguration.current

        self.networkMonitor = network
        self.hapticService = HapticService()
        self.mediaService = media
        self.sessionService = SessionService()
        self.contentFilter = contentFilter
        self.legalConfiguration = legalConfiguration

        self.localRepository = LocalRepository(persistence: persistence)
        self.profileRepository = ProfileRepository(
            networkMonitor: network,
            localRepository: localRepository,
            mediaService: media,
            authProfileUpdater: auth
        )
        self.accountDeleter = auth
        self.authReauthenticator = auth
        self.authRepository = AuthRepository(authService: auth)
        self.followRepository = FollowRepository(profileRepository: profileRepository)
        self.postRepository = PostRepository(
            networkMonitor: network,
            localRepository: localRepository,
            mediaService: media
        )
        self.commentRepository = CommentRepository(
            networkMonitor: network,
            localRepository: localRepository,
            mediaService: media
        )
        self.reportRepository = ReportRepository()
        self.blockRepository = BlockRepository()
        self.accountDeletionService = AccountDeletionService(
            postRepository: postRepository,
            commentRepository: commentRepository,
            followRepository: followRepository,
            blockRepository: blockRepository,
            mediaService: media,
            userDocuments: FirestoreUserDocumentRepository(),
            accountDeleter: auth,
            authRepository: authRepository
        )
    }
}
