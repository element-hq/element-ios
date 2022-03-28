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
import SwiftUI
import Mapbox

@available(iOS 14, *)
class UserLocationAnnotatonView: MGLUserLocationAnnotationView {
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: - Setup
    
    init(avatarData: AvatarInputProtocol) {
        super.init(frame: .zero)
        
        self.addUserMarkerView(with: avatarData)
    }
    
    init(userLocationAnnotation: UserLocationAnnotation) {
        
        // TODO: Use a reuseIdentifier
        super.init(annotation: userLocationAnnotation, reuseIdentifier: nil)
        
        self.addUserMarkerView(with: userLocationAnnotation.avatarData)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Private
    
    private func addUserMarkerView(with avatarData: AvatarInputProtocol) {
        
        guard let avatarImageView = UIHostingController(rootView: LocationSharingMarkerView(backgroundColor: theme.userColor(for: avatarData.matrixItemId)) {
            AvatarImage(avatarData: avatarData, size: .medium)
                .border()
        }).view else {
            return
        }
        
        addSubview(avatarImageView)
        
        addConstraints([topAnchor.constraint(equalTo: avatarImageView.topAnchor),
                        leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
                        bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
                        trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor)])
    }
}
