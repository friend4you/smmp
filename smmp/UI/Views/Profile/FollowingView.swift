//
//  FollowingView.swift
//  smmp
//

import SwiftUI

struct FollowingView: View {
    var body: some View {
        ContentUnavailableView {
            Text(.followListTitle)
        } description: {
            Text(.followListPlaceholder)
        }
        .navigationTitle(Text(.followListTitle))
    }
}

#Preview {
    NavigationStack {
        FollowingView()
    }
}
