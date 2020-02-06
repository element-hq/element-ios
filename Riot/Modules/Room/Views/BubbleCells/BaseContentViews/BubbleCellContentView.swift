/*
 Copyright 2019 New Vector Ltd
 
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
final class BubbleCellContentView: UIView, NibLoadable {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet weak var bubbleInfoContainer: UIView!
    @IBOutlet weak var bubbleInfoContainerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var innerContentView: UIView!
    
    @IBOutlet weak var readReceiptsContainerView: UIView!
    @IBOutlet weak var readReceiptsContentView: UIView!
    
    @IBOutlet weak var bubbleOverlayContainer: UIView!
    
    @IBOutlet weak var paginationTitleContainerView: UIView!
    @IBOutlet weak var paginationLabel: UILabel!
    @IBOutlet weak var paginationSeparatorView: UIView!
    
    // MARK: Private
    
    private var showReadReceipts: Bool {
        get {
            return !self.readReceiptsContainerView.isHidden
        }
        set {
            self.readReceiptsContainerView.isHidden = !newValue
        }
    }
    
    // MARK: Public
    
    var showPaginationTitle: Bool {
        get {
            return !self.paginationTitleContainerView.isHidden
        }
        set {
            self.paginationTitleContainerView.isHidden = !newValue
        }
    }
    
    // MARK: - Setup
    
    class func instantiate() -> BubbleCellContentView {
        return BubbleCellContentView.loadFromNib()
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.backgroundColor = theme.backgroundColor
        self.paginationLabel.textColor = theme.tintColor
        self.paginationSeparatorView.backgroundColor = theme.tintColor
    }
}

// MARK: - BubbleCellReadReceiptsDisplayable
extension BubbleCellContentView: BubbleCellReadReceiptsDisplayable {
    
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
