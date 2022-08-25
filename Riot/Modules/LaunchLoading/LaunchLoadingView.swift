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

import Reusable
import UIKit

@objcMembers
final class LaunchLoadingView: UIView, NibLoadable, Themable {
    // MARK: - Constants
    
    private enum LaunchAnimation {
        static let duration: TimeInterval = 3.0
        static let repeatCount = Float.greatestFiniteMagnitude
    }
    
    // MARK: - Properties
    
    @IBOutlet private var animationView: ElementView!
    private var animationTimeline: Timeline_1!
    
    // MARK: - Setup
    
    static func instantiate() -> LaunchLoadingView {
        let view = LaunchLoadingView.loadFromNib()
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let animationTimeline = Timeline_1(view: animationView, duration: LaunchAnimation.duration, repeatCount: LaunchAnimation.repeatCount)
        animationTimeline.play()
        self.animationTimeline = animationTimeline
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        backgroundColor = theme.backgroundColor
        animationView.backgroundColor = theme.backgroundColor
    }
}
