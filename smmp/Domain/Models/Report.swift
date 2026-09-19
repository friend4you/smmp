//
//  Report.swift
//  smmp
//

import Foundation

enum ReportTargetType: String, Sendable {
    case post
    case comment
    case user
}

enum ReportReason: String, CaseIterable, Identifiable, Sendable {
    case spam
    case harassment
    case hateSpeech
    case sexualContent
    case other

    var id: String { rawValue }

    var localizedTitle: LocalizedStringResource {
        switch self {
        case .spam: .reportReasonSpam
        case .harassment: .reportReasonHarassment
        case .hateSpeech: .reportReasonHateSpeech
        case .sexualContent: .reportReasonSexualContent
        case .other: .reportReasonOther
        }
    }
}

struct Report: Equatable, Sendable {
    let id: String
    let reporterId: String
    let targetType: ReportTargetType
    let targetId: String
    let targetOwnerId: String
    let parentPostId: String?
    let reason: ReportReason
}

struct ReportDraft: Equatable, Sendable {
    let reporterId: String
    let targetType: ReportTargetType
    let targetId: String
    let targetOwnerId: String
    let parentPostId: String?
    let reason: ReportReason
}
