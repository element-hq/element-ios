/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
        self.roomCellContentView?.update(theme: theme)
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
    
    class func sizingView() -> KeyVerificationBaseCell {
        fatalError("[KeyVerificationBaseBubbleCell] Subclass should implement this method")       
    }
    
    class func sizingViewHeightHashValue(from bubbleCellData: MXKRoomBubbleCellData) -> Int {
        
        var hasher = Hasher()
        
        let sizingView = self.sizingView()
        sizingView.render(bubbleCellData)
        
        // Add cell class name
        hasher.combine(self.defaultReuseIdentifier())
        
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
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        if let bubbleData = self.bubbleData,
            let roomCellContentView = self.roomCellContentView,
            let paginationDate = bubbleData.date,
            roomCellContentView.showPaginationTitle {
            roomCellContentView.paginationLabel.text = bubbleData.eventFormatter.dateString(from: paginationDate, withTime: false)?.uppercased()
        }
    }
    
    // MARK: - Private
    
    private func setupContentView() {
        if self.roomCellContentView == nil {
            
            let roomCellContentView = RoomCellContentView.instantiate()
            
            let innerContentView = KeyVerificationCellInnerContentView.instantiate()
            
            roomCellContentView.innerContentView.vc_addSubViewMatchingParent(innerContentView)
            
            self.contentView.vc_addSubViewMatchingParent(roomCellContentView)
            
            self.roomCellContentView = roomCellContentView
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
        var height = sizingView.systemLayoutSizeFitting(fittingSize).height
        
        if let roomBubbleCellData = cellData as? RoomBubbleCellData, let readReceipts = roomBubbleCellData.readReceipts, readReceipts.count > 0 {
            height+=PlainRoomCellLayoutConstants.readReceiptsViewHeight
        }
        
        return height
    }
}

// MARK: - RoomCellReadReceiptsDisplayable
extension KeyVerificationBaseCell: RoomCellReadReceiptsDisplayable {
    
    func addReadReceiptsView(_ readReceiptsView: UIView) {
        self.roomCellContentView?.addReadReceiptsView(readReceiptsView)
    }
    
    func removeReadReceiptsView() {
        self.roomCellContentView?.removeReadReceiptsView()
    }
}
