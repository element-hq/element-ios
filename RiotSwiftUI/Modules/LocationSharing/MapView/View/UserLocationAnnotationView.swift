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
import Mapbox
import SwiftUI

class LocationAnnotationView: MGLUserLocationAnnotationView {
    // MARK: - Constants
    
    private enum Constants {
        static let defaultFrame = CGRect(x: 0, y: 0, width: 46, height: 46)
    }
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: - Setup
    
    override init(annotation: MGLAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier:
            reuseIdentifier)
        frame = Constants.defaultFrame
    }
    
    convenience init(avatarData: AvatarInputProtocol) {
        self.init(annotation: nil, reuseIdentifier: nil)
        addUserMarkerView(with: avatarData)
    }
    
    convenience init(userLocationAnnotation: UserLocationAnnotation) {
        // TODO: Use a reuseIdentifier
        self.init(annotation: userLocationAnnotation, reuseIdentifier: nil)
        
        addUserMarkerView(with: userLocationAnnotation.avatarData)
    }
    
    convenience init(pinLocationAnnotation: PinLocationAnnotation) {
        // TODO: Use a reuseIdentifier
        self.init(annotation: pinLocationAnnotation, reuseIdentifier: nil)
        
        addPinMarkerView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Private
    
    private func addUserMarkerView(with avatarData: AvatarInputProtocol) {
        guard let avatarMarkerView = UIHostingController(rootView: LocationSharingMarkerView(backgroundColor: theme.userColor(for: avatarData.matrixItemId)) {
            AvatarImage(avatarData: avatarData, size: .medium)
                .border()
        }).view else {
            return
        }
        
        addMarkerView(avatarMarkerView)
    }
    
    private func addPinMarkerView() {
        guard let pinMarkerView = UIHostingController(rootView: LocationSharingMarkerView(backgroundColor: theme.colors.accent) {
            Image(uiImage: Asset.Images.locationPinIcon.image)
                .resizable()
                .shapedBorder(color: theme.colors.accent, borderWidth: 3, shape: Circle())
        }).view else {
            return
        }
        
        addMarkerView(pinMarkerView)
    }
    
    private func addMarkerView(_ markerView: UIView) {
        markerView.backgroundColor = .clear
        
        addSubview(markerView)
        
        markerView.frame = bounds
    }
}
