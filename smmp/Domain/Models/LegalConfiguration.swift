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
        privacyPolicyURL: URL(string: "https://smmp-b0138.web.app/privacy")!,
        termsOfUseURL: URL(string: "https://smmp-b0138.web.app/terms")!,
        supportEmail: "vlad.arsenyuk@gmail.com"
    )

    var supportMailtoURL: URL? {
        URL(string: "mailto:\(supportEmail)")
    }
}
