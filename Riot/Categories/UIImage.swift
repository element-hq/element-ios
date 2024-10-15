/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

extension UIImage {
    
    class func vc_image(from color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UIGraphicsBeginImageContext(size)
        image?.draw(in: rect)
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    @objc func vc_tintedImage(usingColor tintColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let drawRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)

        self.draw(in: drawRect)
        tintColor.set()
        UIRectFillUsingBlendMode(drawRect, .sourceAtop)
        let tintedImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage
    }
    
    @objc func vc_withAlpha(_ alpha: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero, blendMode: .normal, alpha: alpha)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // Based on https://stackoverflow.com/a/31314494
    @objc func vc_resized(with targetSize: CGSize) -> UIImage? {
        let originalRenderingMode = self.renderingMode
        let size = self.size

        let widthRatio  = targetSize.width/size.width
        let heightRatio = targetSize.height/size.height

        // Figure out what our orientation is, and use that to form the rectangle
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        let rect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage?.withRenderingMode(originalRenderingMode)
    }
    
    @objc func vc_notRenderedImage() -> UIImage {
        if let cgImage = cgImage {
            return NotRenderedImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
        } else if let ciImage = ciImage {
            return NotRenderedImage(ciImage: ciImage, scale: UIScreen.main.scale, orientation: .up)
        }
        return self
    }
    
    //  inline class to disable rendering
    private class NotRenderedImage: UIImage {
        override func withRenderingMode(_ renderingMode: UIImage.RenderingMode) -> UIImage {
            return self
        }
    }
}
