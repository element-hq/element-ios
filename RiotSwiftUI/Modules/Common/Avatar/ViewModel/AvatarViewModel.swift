//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
