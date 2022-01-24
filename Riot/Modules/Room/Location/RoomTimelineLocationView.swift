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

import UIKit
import Reusable
import Mapbox

class RoomTimelineLocationView: UIView, NibLoadable, Themable, MGLMapViewDelegate {

    // MARK: - Constants
    
    private struct Constants {
        static let mapHeight: CGFloat = 300.0
        static let mapZoomLevel = 15.0
        static let cellBorderRadius: CGFloat = 1.0
        static let cellCornerRadius: CGFloat = 8.0
    }
    
    // MARK: - Properties
    // MARK: Private
    
    @IBOutlet private var descriptionContainerView: UIView!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var descriptionIcon: UIImageView!
    
    private var mapView: MGLMapView!
    private var annotationView: LocationMarkerView?
    
    // MARK: Public
    
    var locationDescription: String? {
        get {
            descriptionLabel.text
        }
        set {
            descriptionLabel.text = newValue
            descriptionContainerView.isHidden = (newValue?.count ?? 0 == 0)
        }
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        mapView = MGLMapView(frame: .zero, styleURL: BuildSettings.tileServerMapURL)
        mapView.delegate = self
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        mapView.isUserInteractionEnabled = false
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addConstraint(mapView.heightAnchor.constraint(equalToConstant: Constants.mapHeight))
        vc_addSubViewMatchingParent(mapView)
        sendSubviewToBack(mapView)
        
        clipsToBounds = true
        layer.borderWidth = Constants.cellBorderRadius
        layer.cornerRadius = Constants.cellCornerRadius
    }
    
    // MARK: - Public
    
    public func displayLocation(_ location: CLLocationCoordinate2D, userAvatarData: AvatarViewData? = nil) {
        
        annotationView = LocationMarkerView.loadFromNib()
        
        if let userAvatarData = userAvatarData {
            annotationView?.setAvatarData(userAvatarData)
        }
        
        if let annotations = mapView.annotations {
            mapView.removeAnnotations(annotations)
        }
        
        mapView.setCenter(location, zoomLevel: Constants.mapZoomLevel, animated: false)
        
        let pointAnnotation = MGLPointAnnotation()
        pointAnnotation.coordinate = location
        mapView.addAnnotation(pointAnnotation)
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        descriptionLabel.textColor = theme.colors.primaryContent
        descriptionLabel.font = theme.fonts.footnote
        descriptionIcon.tintColor = theme.colors.accent
        layer.borderColor = theme.colors.quinaryContent.cgColor
    }
    
    // MARK: - MGLMapViewDelegate
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return annotationView
    }
}
