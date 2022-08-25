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
class KeyVerificationBaseCell: MXKRoomBubbleTableViewCell {
    // MARK: - Constants
    
    private enum Sizing {
        static var sizes = Set<SizingViewHeight>()
    }
    
    // MARK: - Properties
    
    // MARK: Public
    
    weak var keyVerificationCellInnerContentView: KeyVerificationCellInnerContentView?

    weak var roomCellContentView: RoomCellContentView?
    
    override var bubbleInfoContainer: UIView! {
        get {
            guard let infoContainer = self.roomCellContentView?.bubbleInfoContainer else {
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
            guard let overlayContainer = self.roomCellContentView?.bubbleOverlayContainer else {
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
            guard let infoContainerTopConstraint = self.roomCellContentView?.bubbleInfoContainerTopConstraint else {
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
        commonInit()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        selectionStyle = .none
        setupContentView()
        update(theme: ThemeService.shared().theme)
        
        super.setupViews()
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        roomCellContentView?.update(theme: theme)
        keyVerificationCellInnerContentView?.update(theme: theme)
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
        bubbleCellData.senderId ?? ""
    }
    
    func senderDisplayName(from bubbleCellData: MXKRoomBubbleCellData) -> String? {
        let senderId = senderId(from: bubbleCellData)
        guard let senderDisplayName = bubbleCellData.senderDisplayName, senderId != senderDisplayName else {
            return nil
        }
        return senderDisplayName
    }
    
    class func sizingView() -> KeyVerificationBaseCell {
        fatalError("[KeyVerificationBaseBubbleCell] Subclass should implement this method")
    }
    
    class func sizingViewHeightHashValue(from bubbleCellData: MXKRoomBubbleCellData) -> Int {
        var hasher = Hasher()
        
        let sizingView = sizingView()
        sizingView.render(bubbleCellData)
        
        // Add cell class name
        hasher.combine(defaultReuseIdentifier())
        
        if let keyVerificationCellInnerContentView = sizingView.keyVerificationCellInnerContentView {
            // Add other user info
            if let otherUserInfo = keyVerificationCellInnerContentView.otherUserInfo {
                hasher.combine(otherUserInfo)
            }
            
            // Add request status text
            if keyVerificationCellInnerContentView.isRequestStatusHidden == false,
               let requestStatusText = sizingView.keyVerificationCellInnerContentView?.requestStatusText {
                hasher.combine(requestStatusText)
            }
        }
        
        return hasher.finalize()
    }
    
    // MARK: - Overrides
    
    override class func defaultReuseIdentifier() -> String! {
        String(describing: self)
    }
    
    override func didEndDisplay() {
        super.didEndDisplay()
        removeReadReceiptsView()
    }
    
    override class func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        guard let cellData = cellData else {
            return 0
        }
        
        guard let roomBubbleCellData = cellData as? MXKRoomBubbleCellData else {
            return 0
        }
        
        let height: CGFloat
        
        let sizingViewHeight = findOrCreateSizingViewHeight(from: roomBubbleCellData)
        
        if let cachedHeight = sizingViewHeight.heights[maxWidth] {
            height = cachedHeight
        } else {
            height = contentViewHeight(for: roomBubbleCellData, fitting: maxWidth)
            sizingViewHeight.heights[maxWidth] = height
        }
        
        return height
    }
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        if let bubbleData = bubbleData,
           let roomCellContentView = roomCellContentView,
           let paginationDate = bubbleData.date,
           roomCellContentView.showPaginationTitle {
            roomCellContentView.paginationLabel.text = bubbleData.eventFormatter.dateString(from: paginationDate, withTime: false)?.uppercased()
        }
    }
    
    // MARK: - Private
    
    private func setupContentView() {
        if roomCellContentView == nil {
            let roomCellContentView = RoomCellContentView.instantiate()
            
            let innerContentView = KeyVerificationCellInnerContentView.instantiate()
            
            roomCellContentView.innerContentView.vc_addSubViewMatchingParent(innerContentView)
            
            contentView.vc_addSubViewMatchingParent(roomCellContentView)
            
            self.roomCellContentView = roomCellContentView
            keyVerificationCellInnerContentView = innerContentView
        }
    }
    
    private static func findOrCreateSizingViewHeight(from bubbleData: MXKRoomBubbleCellData) -> SizingViewHeight {
        let sizingViewHeight: SizingViewHeight
        let bubbleDataHashValue = bubbleData.hashValue
        
        if let foundSizingViewHeight = Sizing.sizes.first(where: { sizingViewHeight -> Bool in
            sizingViewHeight.uniqueIdentifier == bubbleDataHashValue
        }) {
            sizingViewHeight = foundSizingViewHeight
        } else {
            sizingViewHeight = SizingViewHeight(uniqueIdentifier: bubbleDataHashValue)
        }
        
        return sizingViewHeight
    }
    
    private static func contentViewHeight(for cellData: MXKCellData, fitting width: CGFloat) -> CGFloat {
        let sizingView = sizingView()
        
        sizingView.render(cellData)
        sizingView.layoutIfNeeded()
        
        let fittingSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        var height = sizingView.systemLayoutSizeFitting(fittingSize).height
        
        if let roomBubbleCellData = cellData as? RoomBubbleCellData, let readReceipts = roomBubbleCellData.readReceipts, readReceipts.count > 0 {
            height += PlainRoomCellLayoutConstants.readReceiptsViewHeight
        }
        
        return height
    }
}

// MARK: - RoomCellReadReceiptsDisplayable

extension KeyVerificationBaseCell: RoomCellReadReceiptsDisplayable {
    func addReadReceiptsView(_ readReceiptsView: UIView) {
        roomCellContentView?.addReadReceiptsView(readReceiptsView)
    }
    
    func removeReadReceiptsView() {
        roomCellContentView?.removeReadReceiptsView()
    }
}
