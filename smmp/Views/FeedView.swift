//
//  FeedView.swift
//  smmp
//

import SwiftUI

struct FeedView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.blue)
                    .opacity(0.5)
                    .ignoresSafeArea()
                Text(.feedTitle)
            }
        }
    }
}

#Preview {
    FeedView()
}
