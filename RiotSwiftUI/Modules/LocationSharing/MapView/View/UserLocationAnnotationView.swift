//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    convenience init(userPinLocationAnnotation: MGLAnnotation) {
        self.init(annotation: userPinLocationAnnotation, reuseIdentifier: "userPinLocation")
        
        addPinView()
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
    
    private func addPinView() {
        guard let pinView = UIHostingController(rootView: Image(uiImage: Asset.Images.locationMarkerIcon.image)
            .resizable()
            .foregroundColor(theme.colors.accent)).view else {
            return
        }
        
        addMarkerView(pinView)
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
