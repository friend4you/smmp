//
//  OfflineBanner.swift
//  smmp
//

import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        Text(.feedOfflineBanner)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    OfflineBanner()
        .padding()
}
