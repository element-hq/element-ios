/*
Copyright 2020 New Vector Ltd

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

@objc protocol BaseRoomCellProtocol: Themable {
    var roomCellContentView: RoomCellContentView? { get }
}

/// `BaseRoomCell` allows a room cell that inherits from this class to embed and manage the default room message outer views and add an inner content view.
@objcMembers
class BaseRoomCell: MXKRoomBubbleTableViewCell, BaseRoomCellProtocol {
    
    // MARK: - Constants
        
    // MARK: - Properties
    
    private var areViewsSetup: Bool = false
    
    // MARK: Public

    weak var roomCellContentView: RoomCellContentView?
    
    private(set) var theme: Theme?
    
    // Overrides
    
    override var bubbleInfoContainer: UIView! {
        get {
            guard let infoContainer = self.roomCellContentView?.bubbleInfoContainer else {
                fatalError("[BaseRoomCell] bubbleInfoContainer should not be used before set")
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
                fatalError("[BaseRoomCell] bubbleOverlayContainer should not be used before set")
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
                fatalError("[BaseRoomCell] bubbleInfoContainerTopConstraint should not be used before set")
            }
            return infoContainerTopConstraint
        }
        set {
            super.bubbleInfoContainerTopConstraint = newValue
        }
    }
    
    override var pictureView: MXKImageView! {
        get {
            guard let roomCellContentView = self.roomCellContentView,
                roomCellContentView.showSenderAvatar else {
                return nil
            }
            
            guard let pictureView = self.roomCellContentView?.avatarImageView else {
                fatalError("[BaseRoomCell] pictureView should not be used before set")
            }
            return pictureView
        }
        set {
            super.pictureView = newValue
        }
    }
    
    override var userNameLabel: UILabel! {
        get {
            guard let roomCellContentView = self.roomCellContentView, roomCellContentView.showSenderName  else {
                return nil
            }
            
            guard let userNameLabel = roomCellContentView.userNameLabel else {
                fatalError("[BaseRoomCell] userNameLabel should not be used before set")
            }
            return userNameLabel
        }
        set {
            super.userNameLabel = newValue
        }
    }
    
    override var userNameTapGestureMaskView: UIView! {
        get {
            guard let roomCellContentView = self.roomCellContentView,
                roomCellContentView.showSenderName else {
                return nil
            }
            
            guard let userNameTapGestureMaskView = self.roomCellContentView?.userNameTouchMaskView else {
                fatalError("[BaseRoomCell] userNameTapGestureMaskView should not be used before set")
            }
            return userNameTapGestureMaskView
        }
        set {
            super.userNameTapGestureMaskView = newValue
        }
    }
    
    // MARK: - Setup
            
    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func commonInit() {
        self.selectionStyle = .none
        self.setupContentView()
        self.update(theme: ThemeService.shared().theme)
    }
    
    // MARK: - Public
    
    func removeDecorationViews() {
        if let bubbleCellReadReceiptsDisplayable = self as? BubbleCellReadReceiptsDisplayable {
            bubbleCellReadReceiptsDisplayable.removeReadReceiptsView()
        }
        
        if let bubbleCellReactionsDisplayable = self as? RoomCellReactionsDisplayable {
            bubbleCellReactionsDisplayable.removeReactionsView()
        }

        if let bubbleCellThreadSummaryDisplayable = self as? BubbleCellThreadSummaryDisplayable {
            bubbleCellThreadSummaryDisplayable.removeThreadSummaryView()
        }
        
        if let timestampDisplayable = self as? TimestampDisplayable {
            timestampDisplayable.removeTimestampView()
        }
        
        if let urlPreviewDisplayable = self as? RoomCellURLPreviewDisplayable {
            urlPreviewDisplayable.removeURLPreviewView()
        }
    }
    
    // MARK: - Overrides
    
    override var isTextViewNeedsPositioningVerticalSpace: Bool {
        return false
    }
    
    override func setupViews() {
        super.setupViews()
        
        let showEncryptionStatus = roomCellContentView?.showEncryptionStatus ?? false
        
        if showEncryptionStatus {
            self.setupEncryptionStatusViewTapGestureRecognizer()
        }
    }
    
    override class func defaultReuseIdentifier() -> String! {
        return String(describing: self)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.removeDecorationViews()
    }
    
    override func render(_ cellData: MXKCellData!) {
        // In `MXKRoomBubbleTableViewCell` setupViews() is called in awakeFromNib() that is not called here, so call it only on first render() call
        self.setupViewsIfNeeded()
        
        super.render(cellData)
        
        guard let roomCellContentView = self.roomCellContentView else {
            return
        }
        
        if let bubbleData = self.bubbleData,
            let paginationDate = bubbleData.date,
            roomCellContentView.showPaginationTitle {
            roomCellContentView.paginationLabel.text = bubbleData.eventFormatter.dateString(from: paginationDate, withTime: false)?.uppercased()
        }                
        
        if roomCellContentView.showEncryptionStatus {
            self.updateEncryptionStatusViewImage()
        }
        
        self.updateUserNameColor()
    }
    
    override func customizeRendering() {
        super.customizeRendering()
        self.updateUserNameColor()
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        self.theme = theme
        self.roomCellContentView?.update(theme: theme)
    }
    
    // MARK: - Private

    private func setupViewsIfNeeded() {
        guard self.areViewsSetup == false else {
            return
        }
        self.setupViews()
        self.areViewsSetup = true
    }
        
    private func setupContentView() {
        guard self.roomCellContentView == nil else {
            return
        }
        let roomCellContentView = RoomCellContentView.instantiate()
        self.contentView.vc_addSubViewMatchingParent(roomCellContentView)
        self.roomCellContentView = roomCellContentView
    }
    
    // MARK: - RoomCellURLPreviewDisplayable
    // Cannot use default implementation with ObjC protocol, if self conforms to BubbleCellReadReceiptsDisplayable method below will be used
    
    func addURLPreviewView(_ urlPreviewView: UIView) {
        self.roomCellContentView?.addURLPreviewView(urlPreviewView)
        
        // tmpSubviews is used for touch detection in MXKRoomBubbleTableViewCell
        self.addTemporarySubview(urlPreviewView)
    }
    
    func removeURLPreviewView() {
        self.roomCellContentView?.removeURLPreviewView()
    }
    
    // MARK: - BubbleCellReadReceiptsDisplayable
    // Cannot use default implementation with ObjC protocol, if self conforms to BubbleCellReadReceiptsDisplayable method below will be used
    
    func addReadReceiptsView(_ readReceiptsView: UIView) {
        self.roomCellContentView?.addReadReceiptsView(readReceiptsView)
        
        // tmpSubviews is used for touch detection in MXKRoomBubbleTableViewCell
        self.addTemporarySubview(readReceiptsView)
    }
    
    func removeReadReceiptsView() {
        self.roomCellContentView?.removeReadReceiptsView()
    }
    
    // MARK: - BubbleCellReactionsDisplayable
    // Cannot use default implementation with ObjC protocol, if self conforms to BubbleCellReactionsDisplayable method below will be used
    
    func addReactionsView(_ reactionsView: UIView) {
        self.roomCellContentView?.addReactionsView(reactionsView)
        
        // tmpSubviews is used for touch detection in MXKRoomBubbleTableViewCell
        self.addTemporarySubview(reactionsView)
    }
    
    func removeReactionsView() {
        self.roomCellContentView?.removeReactionsView()
    }

    // MARK: - BubbleCellThreadSummaryDisplayable

    func addThreadSummaryView(_ threadSummaryView: ThreadSummaryView) {
        self.roomCellContentView?.addThreadSummaryView(threadSummaryView)
        
        // tmpSubviews is used for touch detection in MXKRoomBubbleTableViewCell
        self.addTemporarySubview(threadSummaryView)
    }

    func removeThreadSummaryView() {
        self.roomCellContentView?.removeThreadSummaryView()
    }
    
    // Encryption status
    
    private func updateEncryptionStatusViewImage() {
        guard let component = self.bubbleData.getFirstBubbleComponentWithDisplay() else {
            return
        }
        self.roomCellContentView?.encryptionImageView.image = RoomEncryptedDataBubbleCell.encryptionIcon(for: component)
    }
    
    private func setupEncryptionStatusViewTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleEncryptionStatusContainerViewTap(_:)))
        tapGestureRecognizer.delegate = self
        self.roomCellContentView?.encryptionImageView.isUserInteractionEnabled = true
    }
    
    @objc private func handleEncryptionStatusContainerViewTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let delegate = self.delegate else {
            return
        }
        
        guard let component = self.bubbleData.getFirstBubbleComponentWithDisplay() else {
            return
        }
                
        let userInfo: [AnyHashable: Any]?
        
        if let tappedEvent = component.event {
            userInfo = [kMXKRoomBubbleCellEventKey: tappedEvent]
        } else {
            userInfo = nil
        }
                
        delegate.cell(self, didRecognizeAction: kRoomEncryptedDataBubbleCellTapOnEncryptionIcon, userInfo: userInfo)
    }
}
