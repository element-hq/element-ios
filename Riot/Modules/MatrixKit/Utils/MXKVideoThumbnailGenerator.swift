/*
 Copyright 2019 The Matrix.org Foundation C.I.C
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit
import AVFoundation

/// MXKVideoThumbnailGenerator is a utility class to generate a thumbnail image from a video file.
@objcMembers
public class MXKVideoThumbnailGenerator: NSObject {
    
    public static let shared = MXKVideoThumbnailGenerator()
    
    // MARK - Public
    
    /// Generate thumbnail image from a video URL.
    /// Note: Do not make `maximumSize` optional with default nil value for Objective-C compatibility.
    ///
    /// - Parameters:
    ///   - url: Video URL.
    ///   - maximumSize: Maximum dimension for generated thumbnail image.
    /// - Returns: Thumbnail image or nil.
    public func generateThumbnail(from url: URL, with maximumSize: CGSize) -> UIImage? {
        let finalSize: CGSize? = maximumSize != .zero ? maximumSize : nil
        return self.generateThumbnail(from: url, with: finalSize)
    }    
    
    /// Generate thumbnail image from a video URL.
    ///
    /// - Parameter url: Video URL.
    /// - Returns: Thumbnail image or nil.
    public func generateThumbnail(from url: URL) -> UIImage? {
        return generateThumbnail(from: url, with: nil)
    }
    
    // MARK - Private
    
    /// Generate thumbnail image from a video URL.
    ///
    /// - Parameters:
    ///   - url: Video URL.
    ///   - maximumSize: Maximum dimension for generated thumbnail image or nil to keep video dimension.
    /// - Returns: Thumbnail image or nil.
    private func generateThumbnail(from url: URL, with maximumSize: CGSize?) -> UIImage? {
        let thumbnailImage: UIImage?
        
        let asset = AVAsset(url: url)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        if let maximumSize = maximumSize {
            assetImageGenerator.maximumSize = maximumSize
        }
        do {
            // Generate thumbnail from first video image
            let image = try assetImageGenerator.copyCGImage(at: .zero, actualTime: nil)
            thumbnailImage = UIImage(cgImage: image)
        } catch {
            MXLog.error("[MXKVideoThumbnailGenerator] generateThumbnail:", context: error)
            thumbnailImage = nil
        }
        
        return thumbnailImage
    }
}
