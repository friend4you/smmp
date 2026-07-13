//
//  UIImage+Extensions.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/13/26.
//

import UIKit

extension UIImage {
    func resizeImage() -> Data? {
        let size = self.size
        let longEdge = max(size.width, size.height)
        guard longEdge > 0 else { return nil }

        let scale = longEdge > MediaService.maxLongEdge ? MediaService.maxLongEdge / longEdge : 1
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: MediaService.jpegQuality)
    }
}
