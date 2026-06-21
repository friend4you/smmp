//
//  SplashView.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/4/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(.logo)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .padding(.horizontal, 24)
            ProgressView()
            Spacer()
        }
    }
}

#Preview {
    SplashView()
}
