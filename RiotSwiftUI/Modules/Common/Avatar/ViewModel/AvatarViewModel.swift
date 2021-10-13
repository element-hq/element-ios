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
import Combine
import DesignKit

@available(iOS 14.0, *)
/// Simple ViewModel that supports loading an avatar image
class AvatarViewModel: InjectableObject, ObservableObject {
    
    @Inject var avatarService: AvatarServiceProtocol
    
    @Published private(set) var viewState = AvatarViewState.empty
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Load an avatar
    /// - Parameters:
    ///   - mxContentUri: The matrix content URI of the avatar.
    ///   - matrixItemId: The id of the matrix item represented by the avatar.
    ///   - displayName: Display name of the avatar.
    ///   - colorCount: The count of total avatar colors used to generate the stable color index.
    ///   - avatarSize: The size of the avatar to fetch (as defined within DesignKit).
    func loadAvatar(
        mxContentUri: String?,
        matrixItemId: String,
        displayName: String?,
        colorCount: Int,
        avatarSize: AvatarSize) {
        
        self.viewState = .placeholder(
            firstCharacterCapitalized(displayName),
            stableColorIndex(matrixItemId: matrixItemId, colorCount: colorCount)
        )
        
        guard let mxContentUri = mxContentUri, mxContentUri.count > 0 else {
            return
        }
        
        avatarService.avatarImage(mxContentUri: mxContentUri, avatarSize: avatarSize)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                UILog.error("[AvatarService] Failed to retrieve avatar: \(error)")
            } receiveValue: { image in
                self.viewState = .avatar(image)
            }
            .store(in: &cancellables)
    }
    
    /// Get the first character of a string capialized or else an empty string.
    /// - Parameter string: The input string to get the capitalized letter from.
    /// - Returns: The capitalized first letter.
    private func firstCharacterCapitalized(_ string: String?) -> String {
        guard let character = string?.first else {
            return ""
        }
        return String(character).capitalized
    }
    
    /// Provides the same color each time for a specified matrixId
    ///
    /// Same algorithm as in AvatarGenerator.
    /// - Parameters:
    ///   - matrixItemId: the matrix id used as input to create the stable index.
    ///   - colorCount: The number of total colors we want to index in to.
    /// - Returns: The stable index.
    private func stableColorIndex(matrixItemId: String, colorCount: Int) -> Int {
        // Sum all characters
        let sum = matrixItemId.utf8
            .map({ UInt($0) })
            .reduce(0, +)
        // modulo the color count
        return Int(sum) % colorCount
    }
    
}
