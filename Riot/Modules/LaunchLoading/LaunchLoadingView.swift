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
    
    // MARK: - Constants
    
    private enum LaunchAnimation {
        static let duration: TimeInterval = 3.0
        static let repeatCount = Float.greatestFiniteMagnitude
    }
    
    // MARK: - Properties
    
    @IBOutlet private weak var animationView: ElementView!
    @IBOutlet private weak var progressContainer: UIStackView!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var statusLabel: UILabel!
    
    private var animationTimeline: Timeline_1!
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()
    
    // MARK: - Setup
    
    static func instantiate(startupProgress: MXSessionStartupProgress?) -> LaunchLoadingView {
        let view = LaunchLoadingView.loadFromNib()
        startupProgress?.delegate = view
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let animationTimeline = Timeline_1(view: self.animationView, duration: LaunchAnimation.duration, repeatCount: LaunchAnimation.repeatCount)
        animationTimeline.play()
        self.animationTimeline = animationTimeline
        
        progressContainer.isHidden = true
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.backgroundColor = theme.backgroundColor
        self.animationView.backgroundColor = theme.backgroundColor
    }
}

extension LaunchLoadingView: MXSessionStartupProgressDelegate {
    func sessionDidUpdateStartupProgress(state: MXSessionStartupProgress.State) {
        update(with: state)
        
    }
    
    private func update(with state: MXSessionStartupProgress.State) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.update(with: state)
            }
            return
        }
        
        // Sync may be doing a lot of heavy work on the main thread and the status text
        // does not update reliably enough without explicitly refreshing
        CATransaction.begin()
        progressContainer.isHidden = false
        progressView.progress = Float(state.progress)
        statusLabel.text = state.showDelayWarning ? VectorL10n.launchLoadingDelayWarning : VectorL10n.launchLoadingGeneric
        CATransaction.commit()
    }
}
