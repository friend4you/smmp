//
//  CommentRowItem.swift
//  smmp
//

import Foundation

struct CommentRowItem: Identifiable, Hashable {
    var id: String { comment.id }

    let comment: Comment
    let author: User

    static func == (lhs: CommentRowItem, rhs: CommentRowItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
