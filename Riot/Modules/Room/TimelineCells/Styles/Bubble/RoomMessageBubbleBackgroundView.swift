// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.masksToBounds = true
        self.layer.cornerRadius = BubbleRoomCellLayoutConstants.bubbleCornerRadius
    }
    
    // MARK: - Public
    
    @discardableResult
    func updateHeight(_ height: CGFloat) -> Bool {
        if let heightConstraint = self.heightConstraint {
            
            guard heightConstraint.constant != height else {
                return false
            }
            
            heightConstraint.constant = height
            
            return true
        } else {
            let heightConstraint = self.heightAnchor.constraint(equalToConstant: height)
            heightConstraint.isActive = true
            self.heightConstraint = heightConstraint
            
            return true
        }
    }
}

// MARK: - TimestampDisplayable
extension RoomMessageBubbleBackgroundView: TimestampDisplayable {
    
    func addTimestampView(_ timestampView: UIView) {
        
        self.removeTimestampView()
        
        self.addTimestampView(timestampView, rightMargin: BubbleRoomCellLayoutConstants.bubbleTimestampViewMargins.right, bottomMargin: BubbleRoomCellLayoutConstants.bubbleTimestampViewMargins.bottom)
        self.timestampView = timestampView
    }
    
    func removeTimestampView() {
        self.timestampView?.removeFromSuperview()
    }
    
    func addTimestampView(_ timestampView: UIView,
                          rightMargin: CGFloat,
                          bottomMargin: CGFloat) {
        timestampView.translatesAutoresizingMaskIntoConstraints = false
                
        self.addSubview(timestampView)
        
        let trailingConstraint = timestampView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -rightMargin)

        let bottomConstraint = timestampView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -bottomMargin)

        NSLayoutConstraint.activate([
            trailingConstraint,
            bottomConstraint
        ])
    }
}
