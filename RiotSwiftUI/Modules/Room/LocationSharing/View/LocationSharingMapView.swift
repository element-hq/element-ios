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
    private struct Constants {
        static let mapZoomLevel = 15.0
    }
    
    let tileServerMapURL: URL
    let avatarData: AvatarInputProtocol
    let location: CLLocationCoordinate2D?
    
    let errorSubject: PassthroughSubject<LocationSharingViewError, Never>
    @Binding var userLocation: CLLocationCoordinate2D?
        
    func makeUIView(context: Context) -> some UIView {
        let mapView = MGLMapView(frame: .zero, styleURL: tileServerMapURL)
        mapView.delegate = context.coordinator
        
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        
        if let location = location {
            mapView.setCenter(location, zoomLevel: Constants.mapZoomLevel, animated: false)
            
            let pointAnnotation = MGLPointAnnotation()
            pointAnnotation.coordinate = location
            mapView.addAnnotation(pointAnnotation)
        } else {
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    func makeCoordinator() -> LocationSharingMapViewCoordinator {
        LocationSharingMapViewCoordinator(avatarData: avatarData,
                                          errorSubject: errorSubject,
                                          userLocation: $userLocation)
    }
}

@available(iOS 14, *)
class LocationSharingMapViewCoordinator: NSObject, MGLMapViewDelegate {
    
    private let avatarData: AvatarInputProtocol
    private let errorSubject: PassthroughSubject<LocationSharingViewError, Never>
    @Binding private var userLocation: CLLocationCoordinate2D?
    
    init(avatarData: AvatarInputProtocol,
         errorSubject: PassthroughSubject<LocationSharingViewError, Never>,
         userLocation: Binding<CLLocationCoordinate2D?>) {
        self.avatarData = avatarData
        self.errorSubject = errorSubject
        self._userLocation = userLocation
    }
    
    // MARK: - MGLMapViewDelegate
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return UserLocationAnnotatonView(avatarData: avatarData)
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MGLMapView, withError error: Error) {
        errorSubject.send(.failedLoadingMap)
    }
    
    func mapView(_ mapView: MGLMapView, didFailToLocateUserWithError error: Error) {
        guard mapView.showsUserLocation else {
            return
        }
        
        errorSubject.send(.failedLocatingUser)
    }
    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        self.userLocation = userLocation?.coordinate
    }
    
    func mapView(_ mapView: MGLMapView, didChangeLocationManagerAuthorization manager: MGLLocationManager) {
        guard mapView.showsUserLocation else {
            return
        }
        
        switch manager.authorizationStatus {
        case .restricted:
            fallthrough
        case .denied:
            errorSubject.send(.invalidLocationAuthorization)
        default:
            break
        }
    }
}

@available(iOS 14, *)
private class UserLocationAnnotatonView: MGLUserLocationAnnotationView {
    
    init(avatarData: AvatarInputProtocol) {
        super.init(frame: .zero)
        
        guard let avatarImageView = UIHostingController(rootView: LocationSharingUserMarkerView(avatarData: avatarData)).view else {
            return
        }
        
        addSubview(avatarImageView)
        
        addConstraints([topAnchor.constraint(equalTo: avatarImageView.topAnchor),
                        leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
                        bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
                        trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor)])
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
