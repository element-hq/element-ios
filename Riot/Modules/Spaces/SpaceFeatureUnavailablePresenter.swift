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

/// SpaceFeatureUnavailablePresenter enables to present modals for unavailable space features
@objcMembers
final class SpaceFeatureUnavailablePresenter: NSObject {
    
    // MARK: - Constants
    
    // MARK: - Properties
            
    // MARK: Private
    
    private weak var presentingViewController: UIViewController?
        
    // MARK: - Public
    
    func presentUnavailableFeature(from presentingViewController: UIViewController,
                                   animated: Bool) {
        
        let spaceFeatureUnavailableVC = SpaceFeatureUnaivableViewController.instantiate()
        
        let navigationVC = RiotNavigationController(rootViewController: spaceFeatureUnavailableVC)
        
        spaceFeatureUnavailableVC.navigationItem.rightBarButtonItem = MXKBarButtonItem(title: VectorL10n.ok, style: .plain, action: { [weak navigationVC] in
            navigationVC?.dismiss(animated: true)
        })
                        
        navigationVC.modalPresentationStyle = .formSheet
        presentingViewController.present(navigationVC, animated: animated, completion: nil)
    }
}
