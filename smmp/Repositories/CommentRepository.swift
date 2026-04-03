//
//  CommentRepository.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

class CommentRepository {
    private let networkMonitor: NetworkMonitor
    private let persistence: PersistenceController
    private let mediaService: MediaServiceProtocol
    
    init(networkMonitor: NetworkMonitor, persistence: PersistenceController, mediaService: MediaServiceProtocol) {
        self.networkMonitor = networkMonitor
        self.persistence = persistence
        self.mediaService = mediaService
    }
}
