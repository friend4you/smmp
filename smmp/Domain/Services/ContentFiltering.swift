//
//  ContentFiltering.swift
//  smmp
//

import Foundation

protocol ContentFiltering: Sendable {
    func containsDeniedContent(_ text: String) -> Bool
}

struct ContentFilter: ContentFiltering {
    static let `default` = ContentFilter()

    private let deniedWords: [String]

    init(deniedWords: [String] = ContentFilter.defaultDeniedWords) {
        self.deniedWords = deniedWords.map { $0.lowercased() }
    }

    func containsDeniedContent(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        for word in deniedWords {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            if trimmed.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                return true
            }
        }
        return false
    }

    /// Minimum viable English denylist for App Store Guideline 1.2. Extend as needed.
    static let defaultDeniedWords = [
        "asshole",
        "bitch",
        "cunt",
        "faggot",
        "fuck",
        "nigger",
        "retard",
        "shit"
    ]
}
