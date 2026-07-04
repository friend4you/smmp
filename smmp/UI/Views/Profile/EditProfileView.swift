//
//  EditProfileView.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

import SwiftUI

struct EditProfileView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(label: { Text(.profileEdit) })
                .navigationTitle(Text(.profileEdit))
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
