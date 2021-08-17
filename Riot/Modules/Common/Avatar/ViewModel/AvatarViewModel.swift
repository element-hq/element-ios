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

/**
Simple ViewModel that supports loading an avatar image of a particular size
 as specified in DesignKit and delivering the UIImage to the UI if possible.
 */
@available(iOS 14.0, *)
class AvatarViewModel: InjectableObject, ObservableObject {
    
    @Inject var avatarService: AvatarServiceType
    
    @Published private(set) var viewState = AvatarViewState()
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadAvatar(mxContentUri: String?, avatarSize: AvatarSize) {
        guard let mxContentUri = mxContentUri else { return }
        avatarService.avatarImage(mxContentUri: mxContentUri, avatarSize: avatarSize)
            .sink { error in
                MXLog.error("[AvatarService] Failed to retrieve avatar.")
                // TODO: Report non-fatal error when we have Sentry or similar.
            } receiveValue: { image in
                self.viewState.avatarImage = image
            }
            .store(in: &cancellables)
    }
    
}
