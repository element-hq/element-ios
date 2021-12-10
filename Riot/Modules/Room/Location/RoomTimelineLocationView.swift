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

class RoomTimelineLocationView: UIView, NibLoadable, MGLMapViewDelegate {

    private struct Constants {
        static let mapHeight: CGFloat = 300.0
        static let mapTilerKey = "bDAfUcrMPWTAB1KB38r6"
        static let mapZoomLevel = 15.0
        static let mapStyleURLString = URL(string: "https://api.maptiler.com/maps/streets/style.json?key=\(Constants.mapTilerKey)")
        static let cellBorderRadius: CGFloat = 1.0
        static let cellCornerRadius: CGFloat = 8.0
    }
    
    // MARK: Properties
    // MARK: - Private
    
    @IBOutlet private var descriptionLabel: UILabel!
    
    private var mapView: MGLMapView!
    private var annotationView: LocationUserMarkerView?
    
    // MARK: - Public
    
    var showUserLocation: Bool {
        get {
            mapView.showsUserLocation
        }
        set {
            mapView.showsUserLocation = newValue
        }
    }
    
    var locationDescription: String? {
        get {
            descriptionLabel.text
        }
        set {
            descriptionLabel.text = newValue
        }
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        mapView = MGLMapView(frame: .zero, styleURL: Constants.mapStyleURLString)
        mapView.delegate = self
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addConstraint(mapView.heightAnchor.constraint(equalToConstant: Constants.mapHeight))
        vc_addSubViewMatchingParent(mapView)
        sendSubviewToBack(mapView)
        
        descriptionLabel.textColor = ThemeService.shared().theme.colors.primaryContent
        descriptionLabel.font = ThemeService.shared().theme.fonts.footnote
        
        clipsToBounds = true
        layer.borderColor = ThemeService.shared().theme.colors.quinaryContent.cgColor
        layer.borderWidth = Constants.cellBorderRadius
        layer.cornerRadius = Constants.cellCornerRadius
    }
    
    // MARK: - Public
    
    public func displayGeoURI(_ geoURI: String,
                              userIdentifier: String,
                              userDisplayName: String,
                              userAvatarURL: String,
                              mediaManager: MXMediaManager) {
        let locationString = geoURI.components(separatedBy: ":").last?.components(separatedBy: ";").first
        
        guard let locationComponents = locationString?.components(separatedBy: ","),
              let latitude = locationComponents.first?.double,
              let longitude = locationComponents.last?.double
        else {
            return
        }
        
        annotationView = LocationUserMarkerView.loadFromNib()
        
        annotationView?.setAvatarData(AvatarViewData(matrixItemId: userIdentifier,
                                                     displayName: userDisplayName,
                                                     avatarUrl: userAvatarURL,
                                                     mediaManager: mediaManager,
                                                     fallbackImage: .matrixItem(userIdentifier, userDisplayName)))
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        if let annotations = mapView.annotations {
            mapView.removeAnnotations(annotations)
        }
        
        mapView.setCenter(location, zoomLevel: Constants.mapZoomLevel, animated: false)
        
        let pointAnnotation = MGLPointAnnotation()
        pointAnnotation.coordinate = location
        mapView.addAnnotation(pointAnnotation)
    }
    
    // MARK: - MGLMapViewDelegate
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return annotationView
    }
}
