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

import SwiftUI
import Combine
import Mapbox

@available(iOS 14, *)
struct LocationSharingMapView: UIViewRepresentable {
    
    // MARK: - Constants
    
    private struct Constants {
        static let mapZoomLevel = 15.0
    }
    
    // MARK: - Properties
    
    /// Map style URL (https://docs.mapbox.com/api/maps/styles/)
    let tileServerMapURL: URL
    
    /// Map annotations
    let annotations: [LocationAnnotation]
    
    /// Map annotation to focus on
    let highlightedAnnotation: LocationAnnotation?
    
    /// Current user avatar data, used to replace current location annotation view with the user avatar
    let userAvatarData: AvatarInputProtocol?
    
    /// True to indicate to show and follow current user location
    var showsUserLocation: Bool = false

    /// Last user location if `showsUserLocation` has been enabled
    @Binding var userLocation: CLLocationCoordinate2D?
    
    /// Coordinate of the center of the map
    @Binding var mapCenterCoordinate: CLLocationCoordinate2D?
    
    /// Publish view errors if any
    let errorSubject: PassthroughSubject<LocationSharingViewError, Never>

    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> MGLMapView {
        
        let mapView = self.makeMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MGLMapView, context: Context) {
        
        mapView.vc_removeAllAnnotations()
        mapView.addAnnotations(self.annotations)
        
        if let highlightedAnnotation = self.highlightedAnnotation {
            mapView.setCenter(highlightedAnnotation.coordinate, zoomLevel: Constants.mapZoomLevel, animated: false)
        }
        
        if self.showsUserLocation && mapCenterCoordinate == nil {
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        } else {
            mapView.showsUserLocation = false
            mapView.userTrackingMode = .none
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Private
    
    private func makeMapView() -> MGLMapView {
        let mapView = MGLMapView(frame: .zero, styleURL: tileServerMapURL)

        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        
        return mapView
    }
}

// MARK: - Coordinator
@available(iOS 14, *)
extension LocationSharingMapView {
    
    class Coordinator: NSObject, MGLMapViewDelegate {
        
        // MARK: - Properties

        var locationSharingMapView: LocationSharingMapView
        
        // MARK: - Setup

         init(_ locationSharingMapView: LocationSharingMapView) {
             self.locationSharingMapView = locationSharingMapView
         }
        
        // MARK: - MGLMapViewDelegate
        
        func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
            
            if let userLocationAnnotation = annotation as? UserLocationAnnotation {
                return LocationAnnotationView(userLocationAnnotation: userLocationAnnotation)
            } else if let pinLocationAnnotation = annotation as? PinLocationAnnotation {
                return LocationAnnotationView(pinLocationAnnotation: pinLocationAnnotation)
            } else if annotation is MGLUserLocation && locationSharingMapView.mapCenterCoordinate == nil, let currentUserAvatarData = locationSharingMapView.userAvatarData {
                // Replace default current location annotation view with a UserLocationAnnotatonView when the map is center on user location
                return LocationAnnotationView(avatarData: currentUserAvatarData)
            }

            return nil
        }
        
        func mapViewDidFailLoadingMap(_ mapView: MGLMapView, withError error: Error) {
            locationSharingMapView.errorSubject.send(.failedLoadingMap)
        }
        
        func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
            locationSharingMapView.userLocation = userLocation?.coordinate
        }
        
        func mapView(_ mapView: MGLMapView, didChangeLocationManagerAuthorization manager: MGLLocationManager) {
            guard mapView.showsUserLocation else {
                return
            }
            
            switch manager.authorizationStatus {
            case .restricted:
                fallthrough
            case .denied:
                locationSharingMapView.errorSubject.send(.invalidLocationAuthorization)
            default:
                break
            }
        }
        
        func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
            let mapCenterCoordinate = mapView.centerCoordinate
            // Prevent this function to set pinLocation when the map is openning
            guard let userLocation = locationSharingMapView.userLocation,
                  !userLocation.isEqual(to: mapCenterCoordinate, precision: 0.0000000001) else {
                return
            }
            locationSharingMapView.mapCenterCoordinate = mapCenterCoordinate
        }
    }
}

// MARK: - MGLMapView convenient methods
extension MGLMapView {
    
    func vc_removeAllAnnotations() {
        guard let annotations = self.annotations else {
            return
        }
        self.removeAnnotations(annotations)
    }
}
