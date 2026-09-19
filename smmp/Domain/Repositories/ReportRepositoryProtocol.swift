//
//  ReportRepositoryProtocol.swift
//  smmp
//

import Foundation

enum ReportRepositoryError: Error, Equatable {
    case cannotReportOwnContent
    case invalidTarget
}

protocol ReportRepositoryProtocol: AnyObject {
    func createReport(_ draft: ReportDraft) async throws -> Report
}
