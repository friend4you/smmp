//
//  Post.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import Foundation

struct Post {
    var id: String
    var authorId: String
    var text: String?
    var imageURL: String?
    var likeCount: Int
    var commentCount: Int
    var createdAt: Date?
}
