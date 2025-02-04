//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Mapbox
import SwiftUI

/*
 Behavior mode of the current user's location, can be hidden, only shown and shown following the user
 */
enum ShowUserLocationMode {
    case follow
    case show
    case hide
}

struct LocationSharingMapView: UIViewRepresentable {
    // MARK: - Constants
    
    private enum Constants {
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
    
    /// Behavior mode of the current user's location, can be hidden, only shown and shown following the user
    var showsUserLocationMode: ShowUserLocationMode = .hide
    
    /// True to indicate that a touch on user annotation can show a callout
    var userAnnotationCanShowCallout = false

    /// Last user location if `showsUserLocation` has been enabled
    @Binding var userLocation: CLLocationCoordinate2D?
    
    /// Coordinate of the center of the map
    @Binding var mapCenterCoordinate: CLLocationCoordinate2D?
    
    /// Called when an annotation callout view is tapped
    var onCalloutTap: ((MGLAnnotation) -> Void)?
    
    /// Publish view errors if any
    let errorSubject: PassthroughSubject<LocationSharingViewError, Never>
    
    /// Called when the user pan on the map
    var userDidPan: (() -> Void)?

    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> MGLMapView {
        let mapView = makeMapView()
        mapView.delegate = context.coordinator
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.didPan))
        panGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(panGesture)
        return mapView
    }
    
    func updateUIView(_ mapView: MGLMapView, context: Context) {
        mapView.vc_removeAllAnnotations()
        mapView.addAnnotations(annotations)
        
        /*
            if there is an highlighted annotation,
            and the current user's location it's either hidden or only shown,
            we can center to the highlighted annotation
         */
        if let highlightedAnnotation = highlightedAnnotation, showsUserLocationMode != .follow {
            mapView.setCenter(highlightedAnnotation.coordinate, zoomLevel: Constants.mapZoomLevel, animated: true)
        }
        
        switch showsUserLocationMode {
        case .follow:
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        case .show:
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .none
        case .hide:
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

extension LocationSharingMapView {
    class Coordinator: NSObject, MGLMapViewDelegate, UIGestureRecognizerDelegate {
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
            } else if annotation is MGLUserLocation {
                if let currentUserAvatarData = locationSharingMapView.userAvatarData {
                    // Replace default current location annotation view with a UserLocationAnnotatonView when the map is center on user location
                    return LocationAnnotationView(avatarData: currentUserAvatarData)
                } else {
                    return LocationAnnotationView(userPinLocationAnnotation: annotation)
                }
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
            locationSharingMapView.mapCenterCoordinate = mapView.centerCoordinate
        }
        
        // MARK: Callout
                
        func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
            annotation is UserLocationAnnotation && locationSharingMapView.userAnnotationCanShowCallout
        }
        
        func mapView(_ mapView: MGLMapView, calloutViewFor annotation: MGLAnnotation) -> MGLCalloutView? {
            if let userLocationAnnotation = annotation as? UserLocationAnnotation {
                return UserAnnotationCalloutView(userLocationAnnotation: userLocationAnnotation)
            }
            
            return nil
        }
         
        func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
            locationSharingMapView.onCalloutTap?(annotation)
            // Hide the callout
            mapView.deselectAnnotation(annotation, animated: true)
        }
        
        // MARK: UIGestureRecognizer
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            gestureRecognizer is UIPanGestureRecognizer
        }
        
        @objc
        func didPan() {
            locationSharingMapView.userDidPan?()
        }
    }
}

// MARK: - MGLMapView convenient methods

extension MGLMapView {
    func vc_removeAllAnnotations() {
        guard let annotations = annotations else {
            return
        }
        removeAnnotations(annotations)
    }
}
