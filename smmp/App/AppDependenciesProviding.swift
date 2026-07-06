//
//  AppDependenciesProviding.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/5/26.
//

import Foundation

protocol AppDependenciesProviding: ObservableObject {
    var networkMonitor: any NetworkMonitorProtocol { get }
    var mediaService: MediaServiceProtocol { get }
    var sessionService: SessionServiceProtocol { get }
    var authRepository: AuthRepositoryProtocol { get }
    var localRepository: LocalRepositoryProtocol { get }
    var postRepository: PostRepositoryProtocol { get }
    var profileRepository: ProfileRepositoryProtocol { get }
    var followRepository: FollowRepositoryProtocol { get }
    var commentRepository: CommentRepositoryProtocol { get }
}
