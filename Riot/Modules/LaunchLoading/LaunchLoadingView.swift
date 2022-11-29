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
    @IBOutlet private weak var statusLabel: UILabel!
    
    private var animationTimeline: Timeline_1!
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()
    
    // MARK: - Setup
    
    static func instantiate(syncProgress: MXSessionSyncProgress?) -> LaunchLoadingView {
        let view = LaunchLoadingView.loadFromNib()
        syncProgress?.delegate = view
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let animationTimeline = Timeline_1(view: self.animationView, duration: LaunchAnimation.duration, repeatCount: LaunchAnimation.repeatCount)
        animationTimeline.play()
        self.animationTimeline = animationTimeline
        
        self.statusLabel.isHidden = !MXSDKOptions.sharedInstance().enableSyncProgress
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.backgroundColor = theme.backgroundColor
        self.animationView.backgroundColor = theme.backgroundColor
    }
}

extension LaunchLoadingView: MXSessionSyncProgressDelegate {
    func sessionDidUpdateSyncState(_ state: MXSessionSyncState) {
        guard MXSDKOptions.sharedInstance().enableSyncProgress else {
            return
        }
        
        // Sync may be doing a lot of heavy work on the main thread and the status text
        // does not update reliably enough without explicitly refreshing
        CATransaction.begin()
        statusLabel.text = statusText(for: state)
        CATransaction.commit()
    }
    
    private func statusText(for state: MXSessionSyncState) -> String {
        switch state {
        case .serverSyncing(let attempts):
            if attempts > 1, let nth = numberFormatter.string(from: NSNumber(value: attempts)) {
                return VectorL10n.launchLoadingServerSyncingNthAttempt(nth)
            } else {
                return VectorL10n.launchLoadingServerSyncing
            }
        case .processingResponse(let progress):
            let percent = Int(floor(progress * 100))
            return VectorL10n.launchLoadingProcessingResponse("\(percent)")
        }
    }
}
