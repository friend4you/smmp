//
//  HapticService.swift
//  smmp
//

import UIKit

final class HapticService: HapticServiceProtocol {
    func playLike() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func playFollowToggle() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func playSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
