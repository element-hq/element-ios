// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
