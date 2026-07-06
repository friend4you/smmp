//
//  SplashView.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/4/26.
//

import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.9

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(.logo)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .padding(.horizontal, 24)
                .opacity(logoOpacity)
                .scaleEffect(logoScale)
            ProgressView()
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                logoOpacity = 1
                logoScale = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
