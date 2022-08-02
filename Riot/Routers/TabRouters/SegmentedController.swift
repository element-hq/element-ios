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

struct SegmentedControllerTab {
    let title: String?
    let viewController: UIViewController
}

class SegmentedController: UIViewController, Themable {
    
    // MARK: Outlets
    
    @IBOutlet private var segmentedControl: UISegmentedControl!
    @IBOutlet private var contentView: UIView!
    
    // MARK: Private
    
    private var currentController: UIViewController? {
        didSet {
            if let viewController = oldValue {
                viewController.vc_removeFromParent(animated: true)
            }
            
            if let viewController = currentController {
                vc_addChildViewController(viewController: viewController, onView: contentView, animated: true)
                
                // Needed for swiftUI as navigation items are loaded while loading the view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.navigationItem.rightBarButtonItem = viewController.navigationItem.rightBarButtonItem
                    self.navigationItem.rightBarButtonItems = viewController.navigationItem.rightBarButtonItems
                    self.navigationItem.leftBarButtonItem = viewController.navigationItem.leftBarButtonItem
                    self.navigationItem.leftBarButtonItems = viewController.navigationItem.leftBarButtonItems
                    if self.title == nil {
                        self.navigationItem.title = viewController.navigationItem.title
                        self.navigationItem.titleView = viewController.navigationItem.titleView
                    }
                }
            }
        }
    }
    private var theme: Theme!
    
    // MARK: Properties
    
    var tabs: [SegmentedControllerTab] = [] {
        didSet {
            if isViewLoaded {
                populateSegmentedControl()
            }
        }
    }
    
    // MARK: Setup
    
    class func instantiate() -> SegmentedController {
        let storyboard = UIStoryboard(name: "SegmentedController", bundle: nil)
        let viewController = storyboard.instantiateInitialViewController() as? SegmentedController ?? SegmentedController()
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateSegmentedControl()
        update(theme: theme)
        registerThemeServiceDidChangeThemeNotification()
    }

    // MARK: Actions
    
    @IBAction private func segmentDidChange(sender: UISegmentedControl) {
        self.currentController = tabs[sender.selectedSegmentIndex].viewController
    }
    
    // MARK: Themable
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.theme = ThemeService.shared().theme
        self.update(theme: self.theme)
    }

    func update(theme: Theme) {
        self.view.backgroundColor = theme.baseColor
        self.contentView.backgroundColor = theme.baseColor
    }
    
    // MARK: Private
    
    private func populateSegmentedControl() {
        segmentedControl.removeAllSegments()
        for tab in tabs {
            let title = tab.title ?? tab.viewController.tabBarItem.title ?? tab.viewController.title
            segmentedControl.insertSegment(withTitle: title, at: segmentedControl.numberOfSegments, animated: false)
        }
        
        if segmentedControl.numberOfSegments > 0 {
            segmentedControl.selectedSegmentIndex = 0
            self.currentController = tabs.first?.viewController
        }
    }
    
}
