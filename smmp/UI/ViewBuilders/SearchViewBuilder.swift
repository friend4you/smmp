//
//  SearchViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct SearchViewBuilder {
    @ViewBuilder
    func build(_ route: SearchRoute, onNavigate: @escaping (SearchRoute) -> Void) -> some View {
        switch route {
        case .search:
            SearchView()
        }
    }
}
