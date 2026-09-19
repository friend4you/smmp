//
//  LegalConfiguration.swift
//  smmp
//

import Foundation

/// Hosted legal URLs and support email. Replace these values before App Store submission.
struct LegalConfiguration: Equatable, Sendable {
    let privacyPolicyURL: URL
    let termsOfUseURL: URL
    let supportEmail: String

    init(
        privacyPolicyURL: URL,
        termsOfUseURL: URL,
        supportEmail: String
    ) {
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfUseURL = termsOfUseURL
        self.supportEmail = supportEmail
    }

    static let current = LegalConfiguration(
        privacyPolicyURL: URL(string: "https://example.com/privacy")!,
        termsOfUseURL: URL(string: "https://example.com/terms")!,
        supportEmail: "support@example.com"
    )

    var supportMailtoURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        return components.url
    }
}
