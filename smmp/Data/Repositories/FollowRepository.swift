//
//  FollowRepository.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

class FollowRepository: FollowRepositoryProtocol {
    private let networkMonitor: NetworkMonitor
    private let mediaService: MediaServiceProtocol
    
    init(networkMonitor: NetworkMonitor,
         mediaService: MediaServiceProtocol) {
        self.networkMonitor = networkMonitor
        self.mediaService = mediaService
    }
}
