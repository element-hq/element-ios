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

import Combine
import DesignKit
import Foundation

/// Simple ViewModel that supports loading an avatar image
final class AvatarViewModel: ObservableObject {
    private let avatarService: AvatarServiceProtocol
    
    init(avatarService: AvatarServiceProtocol) {
        self.avatarService = avatarService
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func placeholderAvatar(matrixItemId: String,
                     displayName: String?,
                     colorCount: Int) -> AvatarViewState {
        let placeholderViewModel = PlaceholderAvatarViewModel(displayName: displayName,
                                                              matrixItemId: matrixItemId,
                                                              colorCount: colorCount)
        
        return .placeholder(placeholderViewModel.firstCharacterCapitalized, placeholderViewModel.stableColorIndex)
    }
    
    /// Load an avatar
    /// - Parameters:
    ///   - mxContentUri: The matrix content URI of the avatar.
    ///   - matrixItemId: The id of the matrix item represented by the avatar.
    ///   - displayName: Display name of the avatar.
    ///   - colorCount: The count of total avatar colors used to generate the stable color index.
    ///   - avatarSize: The size of the avatar to fetch (as defined within DesignKit).
    func loadAvatar(mxContentUri: String?,
                    matrixItemId: String,
                    displayName: String?,
                    colorCount: Int,
                    avatarSize: AvatarSize,
                    avatarCompletion: @escaping (AvatarViewState) -> Void) {
        guard let mxContentUri = mxContentUri, mxContentUri.count > 0 else {
            avatarCompletion(placeholderAvatar(matrixItemId: matrixItemId, displayName: displayName, colorCount: colorCount))
            return
        }
        
        avatarService.avatarImage(mxContentUri: mxContentUri, avatarSize: avatarSize)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                UILog.error("[AvatarService] Failed to retrieve avatar", context: error)
                // No need to call the completion, there's nothing we can do and the error is logged.
            } receiveValue: { image in
                avatarCompletion(.avatar(image))
            }
            .store(in: &cancellables)
    }
}

extension AvatarViewModel {
    static func withMockedServices() -> AvatarViewModel {
        .init(avatarService: MockAvatarService.example)
    }
}
