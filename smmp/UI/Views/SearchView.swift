//
//  SearchView.swift
//  smmp
//

import SwiftUI

struct SearchView: View {
    var body: some View {
        Text(.searchTitle)
            .navigationTitle(Text(.searchTitle))
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
}
