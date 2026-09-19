//
//  ReportRepository.swift
//  smmp
//

import FirebaseFirestore
import Foundation

final class ReportRepository: ReportRepositoryProtocol {
    private let firestore: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    func createReport(_ draft: ReportDraft) async throws -> Report {
        guard !draft.reporterId.isEmpty, !draft.targetId.isEmpty, !draft.targetOwnerId.isEmpty else {
            throw ReportRepositoryError.invalidTarget
        }
        guard draft.reporterId != draft.targetOwnerId else {
            throw ReportRepositoryError.cannotReportOwnContent
        }

        let document = firestore.collection("reports").document()
        var data: [String: Any] = [
            "reporterId": draft.reporterId,
            "targetType": draft.targetType.rawValue,
            "targetId": draft.targetId,
            "targetOwnerId": draft.targetOwnerId,
            "reason": draft.reason.rawValue,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if draft.targetType == .comment, let parentPostId = draft.parentPostId {
            data["parentPostId"] = parentPostId
        }

        try await document.setData(data)

        return Report(
            id: document.documentID,
            reporterId: draft.reporterId,
            targetType: draft.targetType,
            targetId: draft.targetId,
            targetOwnerId: draft.targetOwnerId,
            parentPostId: draft.parentPostId,
            reason: draft.reason
        )
    }
}
