//
//  CDPost+CoreDataClass.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//
//

public import Foundation
public import CoreData

public typealias CDPostCoreDataClassSet = NSSet

@objc(CDPost)
public class CDPost: NSManagedObject {

    func update(post: Post) {
        id = post.id
        authorId = post.authorId
        text = post.text
        imageURL = post.imageURL
        likeCount = Int64(post.likeCount)
        commentCount = Int64(post.commentCount)
        createdAt = post.createdAt
    }

    func toPost() -> Post? {
        guard let id, let authorId else { return nil }

        return Post(
            id: id,
            authorId: authorId,
            text: text,
            imageURL: imageURL,
            likeCount: Int(likeCount),
            commentCount: Int(commentCount),
            createdAt: createdAt
        )
    }
}
