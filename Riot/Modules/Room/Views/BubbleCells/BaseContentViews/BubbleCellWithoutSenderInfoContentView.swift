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
final class BubbleCellWithoutSenderInfoContentView: UIView, NibLoadable {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet weak var bubbleInfoContainer: UIView!
    @IBOutlet weak var bubbleInfoContainerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var innerContentView: UIView!
    
    @IBOutlet weak var readReceiptsContainerView: UIView!
    @IBOutlet weak var readReceiptsContentView: UIView!
    
    @IBOutlet weak var bubbleOverlayContainer: UIView!
    
    // MARK: Private
    
    private var showReadReceipts: Bool {
        get {
            return self.readReceiptsContainerView.isHidden
        }
        set {
            self.readReceiptsContainerView.isHidden = !newValue
        }
    }
    
    // MARK: - Setup
    
    class func instantiate() -> BubbleCellWithoutSenderInfoContentView {
        return BubbleCellWithoutSenderInfoContentView.loadFromNib()
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.backgroundColor = theme.backgroundColor
    }
}

// MARK: - BubbleCellReadReceiptsDisplayable
extension BubbleCellWithoutSenderInfoContentView: BubbleCellReadReceiptsDisplayable {
    
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
