/*
Copyright 2020 Vector Creations Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import UIKit
import Reusable

@objcMembers
final class LaunchLoadingView: UIView, NibLoadable, Themable {
    
    // MARK: - Properties
    
    @IBOutlet private weak var animationView: ElementView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    
    // MARK: - Setup
    
    static func instantiate() -> LaunchLoadingView {
        let view = LaunchLoadingView.loadFromNib()
        let timeline = Timeline_1(view: view.animationView, duration: 3)
        timeline.play()
        return view
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        //self.backgroundColor = theme.backgroundColor
        //self.logoImageView.tintColor = theme.tintColor
        //self.activityIndicatorView.color = theme.tabBarUnselectedItemTintColor
    }
}
