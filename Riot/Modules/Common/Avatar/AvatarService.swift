//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import MatrixSDK
import Combine
import DesignKit

/**
 Provides a simple api to retrieve and cache avatar images
 */
protocol AvatarServiceType {
    @available(iOS 14.0, *)
    func avatarImage(inputData: AvatarInputType) -> AnyPublisher<UIImage?, Never>
}

enum AvatarServiceError: Error {
    case pathNotfound
    case loadingImageFailed(Error?)
}

class AvatarService: AvatarServiceType {
    
    private enum Constants {
        static let mimeType = "image/jpeg"
        static let thumbnailMethod = MXThumbnailingMethodCrop
        static let avatarDownloadSize = AvatarSize.xxLarge.size
    }
    
    private let avatarGenerator: AvatarGenerator
    private let mediaManager: MXMediaManager
    
    init(avatarGenerator: AvatarGenerator, mediaManager: MXMediaManager) {
        self.avatarGenerator = avatarGenerator
        self.mediaManager = mediaManager
    }
    
    /**
     Given an avatar inpute this function returns a publisher of UIImage.
     If possible to retrieve the actualy image it will from network or cache.
     While waiting ont he netowrk or if one can't be retrieved it will return the generated acatar.
     
    - Parameter inputData: data required to fetch the avatar or generate the image
    - Returns: A publisher of UIImage? that doesn't error(always possible to generate the image)
     */
    @available(iOS 14.0, *)
    func avatarImage(inputData: AvatarInputType) -> AnyPublisher<UIImage?, Never> {
        
        let generatedAvatar = AvatarGenerator.generateAvatar(forMatrixItem: inputData.itemId, withDisplayName: inputData.displayName)
        guard let mxContentUri = inputData.mxContentUri else {
            // No content URI just complete with the generated avatar
            return Just(generatedAvatar)
                .eraseToAnyPublisher()
        }
        
        let cachePath = MXMediaManager.thumbnailCachePath(
            forMatrixContentURI: mxContentUri,
            andType: Constants.mimeType,
            inFolder: nil, 
            toFitViewSize: Constants.avatarDownloadSize,
            with: Constants.thumbnailMethod)
        
        if let image = MXMediaManager.loadThroughCache(withFilePath: cachePath),
           let imageUp = Self.orientImageUp(image: image) {
            // Already cached, complete with the avatar
            return Just(imageUp)
                .eraseToAnyPublisher()
        }
        
        let future = Future<UIImage?, Error> { promise in
            self.mediaManager.downloadThumbnail(
                fromMatrixContentURI: mxContentUri,
                withType: Constants.mimeType,
                inFolder: nil,
                toFitViewSize: Constants.avatarDownloadSize,
                with: Constants.thumbnailMethod) { path in
                guard let path = path else {
                    promise(.failure(AvatarServiceError.pathNotfound))
                    return
                }
                
                guard let image = MXMediaManager.loadThroughCache(withFilePath: path),
                      let imageUp = Self.orientImageUp(image: image) else {
                    promise(.failure(AvatarServiceError.loadingImageFailed(nil)))
                    return
                }
                promise(.success(imageUp))
            } failure: { error in
                promise(.failure(AvatarServiceError.loadingImageFailed(error)))
            }
        }
        // First publish the generated avatar and then complete with the retrieved one
        // In the case of an error retreiving the avatar also return generated one.
        return future
            .prepend(generatedAvatar)
            .catch { _ -> Just<UIImage?> in
                MXLog.error("[AvatarService] Failed to retrieve avatar.")
                // TODO: Report non-fatal error when we have Sentry or similar.
                return Just(generatedAvatar)
            }
            .eraseToAnyPublisher()
    }
    
    private static func orientImageUp(image: UIImage) -> UIImage? {
        guard let image = image.cgImage else { return nil }
        return UIImage(cgImage: image, scale: 1.0, orientation: .up)
    }
}
