//
//  CDComment+CoreDataClass.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//
//

public import Foundation
public import CoreData

public typealias CDCommentCoreDataClassSet = NSSet

@objc(CDComment)
public class CDComment: NSManagedObject {

    func update(comment: Comment) {
        id = comment.id
        postId = comment.postId
        authorId = comment.authorId
        text = comment.text
        createdAt = comment.createdAt
    }

    func toComment() -> Comment? {
        guard let id, let postId, let authorId else { return nil }

        return Comment(
            id: id,
            postId: postId,
            authorId: authorId,
            text: text,
            createdAt: createdAt
        )
    }
}
