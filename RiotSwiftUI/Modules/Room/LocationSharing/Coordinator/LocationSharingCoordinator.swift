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
import UIKit
import SwiftUI
import Keys

struct LocationSharingCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let roomDataSource: MXKRoomDataSource
    let mediaManager: MXMediaManager
    let avatarData: AvatarInputProtocol
    let location: CLLocationCoordinate2D?
}

final class LocationSharingCoordinator: Coordinator {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: LocationSharingCoordinatorParameters
    private let locationSharingHostingController: UIViewController
    private var _locationSharingViewModel: Any? = nil
    
    @available(iOS 14.0, *)
    fileprivate var locationSharingViewModel: LocationSharingViewModel {
        return _locationSharingViewModel as! LocationSharingViewModel
    }
    
    // MARK: Public
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: LocationSharingCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = LocationSharingViewModel(tileServerMapURL: BuildSettings.tileServerMapURL,
                                                 avatarData: parameters.avatarData,
                                                 location: parameters.location)
        let view = LocationSharingView(context: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.mediaManager))
        
        _locationSharingViewModel = viewModel
        locationSharingHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    func start() {
        guard #available(iOS 14.0, *) else {
            MXLog.error("[LocationSharingCoordinator] start: Invalid iOS version, returning.")
            return
        }
        
        parameters.navigationRouter.present(locationSharingHostingController, animated: true)
        
        locationSharingViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel:
                self.parameters.navigationRouter.dismissModule(animated: true, completion: nil)
            case .share(let latitude, let longitude):
                if let location = self.parameters.location {
                    self.showActivityControllerForLocation(location)
                    return
                }
                
                self.locationSharingViewModel.dispatch(action: .startLoading)
                
                self.parameters.roomDataSource.sendLocation(withLatitude: latitude,
                                                            longitude: longitude,
                                                            description: nil) { [weak self] _ in
                    guard let self = self else { return }
                    
                    self.parameters.navigationRouter.dismissModule(animated: true, completion: nil)
                    self.locationSharingViewModel.dispatch(action: .stopLoading(nil))
                } failure: { [weak self] error in
                    guard let self = self else { return }
                    
                    MXLog.error("[LocationSharingCoordinator] Failed sharing location with error: \(String(describing: error))")
                    self.locationSharingViewModel.dispatch(action: .stopLoading(error))
                }
            }
            
        }
    }
    
    func showActivityControllerForLocation(_ location: CLLocationCoordinate2D) {
        let vc = UIActivityViewController(activityItems: activityItems(location: location),
                                          applicationActivities: [ShareToMapsAppActivity(type: .apple, location: location),
                                                                  ShareToMapsAppActivity(type: .google, location: location)])
        locationSharingHostingController.present(vc, animated: true)
    }
    
    func activityItems(location: CLLocationCoordinate2D) -> [Any] {
        var items = [Any]()
        
        // Make the share sheet show a pretty location thumbnail
        if let url = NSURL(string: "https://maps.apple.com?ll=\(location.latitude),\(location.longitude)") {
            items.append(url)
        }
        
        return items
    }
}

extension UIActivity.ActivityType {
    static let shareToMapsApp = UIActivity.ActivityType("Element.ShareToMapsApp")
}

class ShareToMapsAppActivity: UIActivity {
    
    enum MapsAppType {
        case apple
        case google
    }
    
    let type: MapsAppType
    let location: CLLocationCoordinate2D
    
    private override init() {
        fatalError()
    }
    
    init(type: MapsAppType, location: CLLocationCoordinate2D) {
        self.type = type
        self.location = location
    }
    
    override var activityTitle: String? {
        switch type {
        case .apple:
            return VectorL10n.locationSharingOpenAppleMaps
        case .google:
            return VectorL10n.locationSharingOpenGoogleMaps
        }
    }
    
    var activityCategory: UIActivity.Category {
        return .action
    }
    
    override var activityType: UIActivity.ActivityType {
        return .shareToMapsApp
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        var url: URL?
        switch type {
        case .apple:
            url = URL(string: "https://maps.apple.com?ll=\(location.latitude),\(location.longitude)&q=Pin")
        case .google:
            url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(location.latitude),\(location.longitude)")
        }
        
        guard let url = url else {
            activityDidFinish(false)
            return
        }
        
        UIApplication.shared.open(url, options: [:]) { [weak self] result in
            self?.activityDidFinish(result)
        }
    }
}
