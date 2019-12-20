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

import Foundation

@objcMembers
class KeyVerificationBaseBubbleCell: MXKRoomBubbleTableViewCell {
    
    // MARK: - Constants
    
    private enum Sizing {
        static var sizes = Set<SizingViewHeight>()
    }
    
    // MARK: - Properties
    
    // MARK: Public
    
    weak var keyVerificationCellInnerContentView: KeyVerificationCellInnerContentView?
    weak var bubbleCellWithoutSenderInfoContentView: BubbleCellWithoutSenderInfoContentView?
    
    override var bubbleInfoContainer: UIView! {
        get {
            guard let infoContainer = self.bubbleCellWithoutSenderInfoContentView?.bubbleInfoContainer else {
                fatalError("[KeyVerificationBaseBubbleCell] bubbleInfoContainer should not be used before set")
            }
            return infoContainer
        }
        set {
            super.bubbleInfoContainer = newValue
        }
    }
    
    override var bubbleOverlayContainer: UIView! {
        get {
            guard let overlayContainer = self.bubbleCellWithoutSenderInfoContentView?.bubbleOverlayContainer else {
                fatalError("[KeyVerificationBaseBubbleCell] bubbleOverlayContainer should not be used before set")
            }
            return overlayContainer
        }
        set {
            super.bubbleInfoContainer = newValue
        }
    }
    
    override var bubbleInfoContainerTopConstraint: NSLayoutConstraint! {
        get {
            guard let infoContainerTopConstraint = self.bubbleCellWithoutSenderInfoContentView?.bubbleInfoContainerTopConstraint else {
                fatalError("[KeyVerificationBaseBubbleCell] bubbleInfoContainerTopConstraint should not be used before set")
            }
            return infoContainerTopConstraint
        }
        set {
            super.bubbleInfoContainerTopConstraint = newValue
        }
    }
    
    // MARK: - Setup
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        
        self.selectionStyle = .none
        self.setupContentView()
        self.update(theme: ThemeService.shared().theme)
        
        super.setupViews()
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.bubbleCellWithoutSenderInfoContentView?.update(theme: theme)
        self.keyVerificationCellInnerContentView?.update(theme: theme)
    }
    
    func buildUserInfoText(with userId: String, userDisplayName: String?) -> String {
        
        let userInfoText: String
        
        if let userDisplayName = userDisplayName {
            userInfoText = "\(userId) (\(userDisplayName))"
        } else {
            userInfoText = userId
        }
        
        return userInfoText
    }
    
    func senderId(from bubbleCellData: MXKRoomBubbleCellData) -> String {
        return bubbleCellData.senderId ?? ""
    }
    
    func senderDisplayName(from bubbleCellData: MXKRoomBubbleCellData) -> String? {
        let senderId = self.senderId(from: bubbleCellData)
        guard let senderDisplayName = bubbleCellData.senderDisplayName, senderId != senderDisplayName else {
            return nil
        }
        return senderDisplayName
    }
    
    class func sizingView() -> MXKRoomBubbleTableViewCell {
        fatalError("[KeyVerificationBaseBubbleCell] Subclass should implement this method")
    }
    
    // TODO: Implement thiscmethod in subclasses
    class func sizingHeightHashValue(from bubbleData: MXKRoomBubbleCellData) -> Int {
        return bubbleData.hashValue
    }
    
    // MARK: - Overrides
    
    override class func defaultReuseIdentifier() -> String! {
        return String(describing: self)
    }
    
    override func didEndDisplay() {
        super.didEndDisplay()
        self.removeReadReceiptsView()
    }
    
    override class func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        guard let cellData = cellData else {
            return 0
        }
        
        guard let roomBubbleCellData = cellData as? MXKRoomBubbleCellData else {
            return 0
        }
        
        let height: CGFloat
        
        let sizingViewHeight = self.findOrCreateSizingViewHeight(from: roomBubbleCellData)
        
        if let cachedHeight = sizingViewHeight.heights[maxWidth] {
            height = cachedHeight
        } else {
            height = self.contentViewHeight(for: roomBubbleCellData, fitting: maxWidth)
            sizingViewHeight.heights[maxWidth] = height
        }
        
        return height
    }
    
    // MARK: - Private
    
    private func setupContentView() {
        if self.bubbleCellWithoutSenderInfoContentView == nil {
            
            let bubbleCellWithoutSenderInfoContentView = BubbleCellWithoutSenderInfoContentView.instantiate()
            
            let innerContentView = KeyVerificationCellInnerContentView.instantiate()
            
            bubbleCellWithoutSenderInfoContentView.innerContentView.vc_addSubViewMatchingParent(innerContentView)
            
            self.contentView.vc_addSubViewMatchingParent(bubbleCellWithoutSenderInfoContentView)
            
            self.bubbleCellWithoutSenderInfoContentView = bubbleCellWithoutSenderInfoContentView
            self.keyVerificationCellInnerContentView = innerContentView
        }
    }
    
    private static func findOrCreateSizingViewHeight(from bubbleData: MXKRoomBubbleCellData) -> SizingViewHeight {
        
        let sizingViewHeight: SizingViewHeight
        let bubbleDataHashValue = bubbleData.hashValue
        
        if let foundSizingViewHeight = self.Sizing.sizes.first(where: { (sizingViewHeight) -> Bool in
            return sizingViewHeight.uniqueIdentifier == bubbleDataHashValue
        }) {
            sizingViewHeight = foundSizingViewHeight
        } else {
            sizingViewHeight = SizingViewHeight(uniqueIdentifier: bubbleDataHashValue)
        }
        
        return sizingViewHeight
    }
    
    private static func contentViewHeight(for cellData: MXKCellData, fitting width: CGFloat) -> CGFloat {
        let sizingView = self.sizingView()
        
        sizingView.render(cellData)
        sizingView.layoutIfNeeded()
        
        let fittingSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let height = sizingView.systemLayoutSizeFitting(fittingSize).height
        
        return height
    }
}

// MARK: - BubbleCellReadReceiptsDisplayable
extension KeyVerificationBaseBubbleCell: BubbleCellReadReceiptsDisplayable {
    
    func addReadReceiptsView(_ readReceiptsView: UIView) {
        self.bubbleCellWithoutSenderInfoContentView?.addReadReceiptsView(readReceiptsView)
    }
    
    func removeReadReceiptsView() {
        self.bubbleCellWithoutSenderInfoContentView?.removeReadReceiptsView()
    }
}
