//
//  HapticServiceProtocol.swift
//  smmp
//

import Foundation

protocol HapticServiceProtocol: Sendable {
    func playLike()
    func playFollowToggle()
    func playSuccess()
}

struct NoOpHapticService: HapticServiceProtocol {
    func playLike() {}
    func playFollowToggle() {}
    func playSuccess() {}
}
