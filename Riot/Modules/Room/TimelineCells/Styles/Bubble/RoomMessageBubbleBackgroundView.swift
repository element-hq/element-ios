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
import UIKit

class RoomMessageBubbleBackgroundView: UIView {
    // MARK: - Properties
    
    private var heightConstraint: NSLayoutConstraint?
    fileprivate weak var timestampView: UIView?
    
    // MARK: - Setup
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.masksToBounds = true
        layer.cornerRadius = BubbleRoomCellLayoutConstants.bubbleCornerRadius
    }
    
    // MARK: - Public
    
    @discardableResult
    func updateHeight(_ height: CGFloat) -> Bool {
        if let heightConstraint = heightConstraint {
            guard heightConstraint.constant != height else {
                return false
            }
            
            heightConstraint.constant = height
            
            return true
        } else {
            let heightConstraint = heightAnchor.constraint(equalToConstant: height)
            heightConstraint.isActive = true
            self.heightConstraint = heightConstraint
            
            return true
        }
    }
}

// MARK: - TimestampDisplayable

extension RoomMessageBubbleBackgroundView: TimestampDisplayable {
    func addTimestampView(_ timestampView: UIView) {
        removeTimestampView()
        
        addTimestampView(timestampView, rightMargin: BubbleRoomCellLayoutConstants.bubbleTimestampViewMargins.right, bottomMargin: BubbleRoomCellLayoutConstants.bubbleTimestampViewMargins.bottom)
        self.timestampView = timestampView
    }
    
    func removeTimestampView() {
        timestampView?.removeFromSuperview()
    }
    
    func addTimestampView(_ timestampView: UIView,
                          rightMargin: CGFloat,
                          bottomMargin: CGFloat) {
        timestampView.translatesAutoresizingMaskIntoConstraints = false
                
        addSubview(timestampView)
        
        let trailingConstraint = timestampView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -rightMargin)

        let bottomConstraint = timestampView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomMargin)

        NSLayoutConstraint.activate([
            trailingConstraint,
            bottomConstraint
        ])
    }
}
