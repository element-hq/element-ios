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

@objc protocol VoiceRecordViewDelegate: NSObjectProtocol {
    func voiceRecordViewExpandedStateDidChange(_ voiceRecordView: VoiceRecordView)
}

@objcMembers
class VoiceRecordView: UIView, Themable {

    @IBOutlet var voiceMessageButton: UIImageView!
    @IBOutlet var voiceMessageButtonTrailingConstraint: NSLayoutConstraint!
    
    weak var delegate: VoiceRecordViewDelegate?
    var isExpanded = false {
        didSet {
            delegate?.voiceRecordViewExpandedStateDidChange(self)
        }
    }
    let expandAnimationDuration = 0.3
    
    private var firstTouchPoint: CGPoint = CGPoint.zero
    private var initialVoiceMessageButtonPadding: CGFloat = 0

    // MARK: - Themable
    
    func update(theme: Theme) {
        voiceMessageButton.tintColor = theme.tintColor
    }
    
    // MARK: - Instanciation
    
    class func instanceFromNib() -> VoiceRecordView {
        let nib = UINib(nibName: "VoiceRecordView", bundle: nil)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? Self else {
          fatalError("The nib \(nib) expected its root view to be of type \(self)")
        }
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initialVoiceMessageButtonPadding = voiceMessageButtonTrailingConstraint.constant
    }
    
    // MARK: - Touch management
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        let point = touches.first?.location(in: self) ?? CGPoint.zero
        firstTouchPoint = CGPoint(x: self.bounds.width - point.x, y: point.y)
        isExpanded = true
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let point = touches.first?.location(in: self) else {
            return
        }
        
        let xDelta = min(firstTouchPoint.x - (self.bounds.width - point.x), 0)
        UIView.animate(withDuration: 0.001) {
            self.voiceMessageButtonTrailingConstraint.constant = self.initialVoiceMessageButtonPadding - xDelta
            self.layoutIfNeeded()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        isExpanded = false
        
        UIView.animate(withDuration: expandAnimationDuration) {
            self.voiceMessageButtonTrailingConstraint.constant = self.initialVoiceMessageButtonPadding
            self.layoutIfNeeded()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        isExpanded = false
        
        UIView.animate(withDuration: expandAnimationDuration) {
            self.voiceMessageButtonTrailingConstraint.constant = self.initialVoiceMessageButtonPadding
            self.layoutIfNeeded()
        }
    }
}
