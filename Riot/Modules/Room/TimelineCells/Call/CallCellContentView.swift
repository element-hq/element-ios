// 
// Copyright 2020 New Vector Ltd
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
import Reusable

class CallCellContentView: UIView {
    
    private enum Constants {
        static let callSummaryWithBottomViewHeight: CGFloat = 20
        static let callSummaryStandaloneViewHeight: CGFloat = 20 + 44
    }
    
    @IBOutlet private weak var paginationTitleView: UIView!
    @IBOutlet private weak var paginationLabel: UILabel!
    @IBOutlet private weak var paginationSeparatorView: UIView!
    
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet weak var avatarImageView: MXKImageView!
    @IBOutlet weak var callerNameLabel: UILabel!
    @IBOutlet weak var callIconView: UIImageView!
    @IBOutlet private weak var callStatusLabel: UILabel!
    @IBOutlet private weak var callSummaryHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bubbleInfoContainer: UIView!
    @IBOutlet weak var bubbleOverlayContainer: UIView!
    @IBOutlet weak var bubbleInfoContainerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var readReceiptsContainerView: UIView!
    @IBOutlet weak var readReceiptsContentView: UIView!
    
    @IBOutlet weak var bottomContainerView: UIView!
    
    /// Inter-item spacing in the main content stack view
    let interItemSpacing: CGFloat = 8
    
    var statusText: String? {
        didSet {
            callStatusLabel.text = statusText
        }
    }
    
    private(set) var theme: Theme = ThemeService.shared().theme
    
    private var showReadReceipts: Bool {
        get {
            return !self.readReceiptsContainerView.isHidden
        } set {
            self.readReceiptsContainerView.isHidden = !newValue
        }
    }
    
    func relayoutCallSummary() {
        if bottomContainerView.subviews.isEmpty {
            callSummaryHeightConstraint.constant = Constants.callSummaryStandaloneViewHeight
        } else {
            callSummaryHeightConstraint.constant = Constants.callSummaryWithBottomViewHeight
        }
    }
    
    func render(_ cellData: MXKCellData) {
        guard let bubbleCellData = cellData as? RoomBubbleCellData else {
            return
        }
        
        if bubbleCellData.isPaginationFirstBubble {
            paginationTitleView.isHidden = false
            paginationLabel.text = bubbleCellData.eventFormatter.dateString(from: bubbleCellData.date, withTime: false)?.uppercased()
        } else {
            paginationTitleView.isHidden = true
        }
        
        avatarImageView.enableInMemoryCache = true
    }

}

extension CallCellContentView: NibLoadable {
    
}

extension CallCellContentView: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        
        paginationLabel.textColor = theme.tintColor
        paginationSeparatorView.backgroundColor = theme.tintColor
        
        bgView.backgroundColor = theme.colors.tile
        callerNameLabel.textColor = theme.textPrimaryColor
        callIconView.tintColor = theme.textSecondaryColor
        callStatusLabel.textColor = theme.textSecondaryColor
        
        if let bottomContainerView = bottomContainerView as? Themable {
            bottomContainerView.update(theme: theme)
        }
    }
    
}

// MARK: - RoomCellReadReceiptsDisplayable

extension CallCellContentView: RoomCellReadReceiptsDisplayable {
    
    func addReadReceiptsView(_ readReceiptsView: UIView) {
        self.readReceiptsContentView.vc_removeAllSubviews()
        self.readReceiptsContentView.vc_addSubViewMatchingParent(readReceiptsView)
        self.showReadReceipts = true
    }
    
    func removeReadReceiptsView() {
        self.showReadReceipts = false
        self.readReceiptsContentView.vc_removeAllSubviews()
    }
}
