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
