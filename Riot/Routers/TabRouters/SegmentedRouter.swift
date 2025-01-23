// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class SegmentedRouter: NSObject, TabbedRouterType {
    
    // MARK: - Private
    
    let segmentedController: SegmentedController
    
    /// Returns the presentables associated to each view controller
    var tabs: [TabbedRouterTab] = [] {
        didSet {
            segmentedController.tabs = tabs.compactMap({ tab in
                let viewController = tab.module.toPresentable()
                
                guard viewController is UITabBarController == false else {
                    return nil
                }
                
                return SegmentedControllerTab(title: tab.title, viewController: viewController)
            })
        }
    }
    
    init(segmentedController: SegmentedController = SegmentedController.instantiate()) {
        self.segmentedController = segmentedController
    }

    // MARK: - Public
    
    func presentModule(_ module: Presentable, animated: Bool, completion: (() -> Void)?) {
        MXLog.debug("[SegmentedRouter] Present \(module)")
        segmentedController.present(module.toPresentable(), animated: animated, completion: nil)
    }
    
    func dismissModule(animated: Bool, completion: (() -> Void)?) {
        MXLog.debug("[SegmentedRouter] dismiss")
        segmentedController.dismiss(animated: animated, completion: completion)
    }

    func toPresentable() -> UIViewController {
        return segmentedController
    }
    
    
}
