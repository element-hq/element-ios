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

@objc protocol BaseBubbleCellType: Themable {
    var bubbleCellContentView: BubbleCellContentView? { get }
}

/// `BaseBubbleCell` allows a bubble cell that inherits from this class to embed and manage the default room message outer views and add an inner content view.
@objcMembers
class BaseBubbleCell: MXKRoomBubbleTableViewCell, BaseBubbleCellType {
    
    // MARK: - Constants
        
    // MARK: - Properties
    
    private var areViewsSetup: Bool = false
    
    // MARK: Public

    weak var bubbleCellContentView: BubbleCellContentView?
    
    // Overrides
    
    override var bubbleInfoContainer: UIView! {
        get {
            guard let infoContainer = self.bubbleCellContentView?.bubbleInfoContainer else {
                fatalError("[BaseBubbleCell] bubbleInfoContainer should not be used before set")
            }
            return infoContainer
        }
        set {
            super.bubbleInfoContainer = newValue
        }
    }
    
    override var bubbleOverlayContainer: UIView! {
        get {
            guard let overlayContainer = self.bubbleCellContentView?.bubbleOverlayContainer else {
                fatalError("[BaseBubbleCell] bubbleOverlayContainer should not be used before set")
            }
            return overlayContainer
        }
        set {
            super.bubbleInfoContainer = newValue
        }
    }
    
    override var bubbleInfoContainerTopConstraint: NSLayoutConstraint! {
        get {
            guard let infoContainerTopConstraint = self.bubbleCellContentView?.bubbleInfoContainerTopConstraint else {
                fatalError("[BaseBubbleCell] bubbleInfoContainerTopConstraint should not be used before set")
            }
            return infoContainerTopConstraint
        }
        set {
            super.bubbleInfoContainerTopConstraint = newValue
        }
    }
    
    override var pictureView: MXKImageView! {
        get {
            guard let bubbleCellContentView = self.bubbleCellContentView,
                bubbleCellContentView.showSenderInfo else {
                return nil
            }
            
            guard let pictureView = self.bubbleCellContentView?.avatarImageView else {
                fatalError("[BaseBubbleCell] pictureView should not be used before set")
            }
            return pictureView
        }
        set {
            super.pictureView = newValue
        }
    }
    
    override var userNameLabel: UILabel! {
        get {
            guard let bubbleCellContentView = self.bubbleCellContentView,
                bubbleCellContentView.showSenderInfo else {
                return nil
            }
            
            guard let userNameLabel = bubbleCellContentView.userNameLabel else {
                fatalError("[BaseBubbleCell] userNameLabel should not be used before set")
            }
            return userNameLabel
        }
        set {
            super.userNameLabel = newValue
        }
    }
    
    override var userNameTapGestureMaskView: UIView! {
        get {
            guard let bubbleCellContentView = self.bubbleCellContentView,
                bubbleCellContentView.showSenderInfo else {
                return nil
            }
            
            guard let userNameTapGestureMaskView = self.bubbleCellContentView?.userNameTouchMaskView else {
                fatalError("[BaseBubbleCell] userNameTapGestureMaskView should not be used before set")
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
    
    // MARK: - Overrides
    
    override func setupViews() {
        super.setupViews()
        
        let showEncryptionStatus = bubbleCellContentView?.showEncryptionStatus ?? false
        
        if showEncryptionStatus {
            self.setupEncryptionStatusViewTapGestureRecognizer()
        }
    }
    
    override class func defaultReuseIdentifier() -> String! {
        return String(describing: self)
    }
    
    override func didEndDisplay() {
        super.didEndDisplay()
        
        if let bubbleCellReadReceiptsDisplayable = self as? BubbleCellReadReceiptsDisplayable {
            bubbleCellReadReceiptsDisplayable.removeReadReceiptsView()
        }
        
        if let bubbleCellReactionsDisplayable = self as? BubbleCellReactionsDisplayable {
            bubbleCellReactionsDisplayable.removeReactionsView()
        }
    }
    
    override func render(_ cellData: MXKCellData!) {
        // In `MXKRoomBubbleTableViewCell` setupViews() is called in awakeFromNib() that is not called here, so call it only on first render() call
        self.setupViewsIfNeeded()
        
        super.render(cellData)
        
        guard let bubbleCellContentView = self.bubbleCellContentView else {
            return
        }
        
        if let bubbleData = self.bubbleData,
            let paginationDate = bubbleData.date,
            bubbleCellContentView.showPaginationTitle {
            bubbleCellContentView.paginationLabel.text = bubbleData.eventFormatter.dateString(from: paginationDate, withTime: false)?.uppercased()
        }                
        
        if bubbleCellContentView.showEncryptionStatus {
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
        self.bubbleCellContentView?.update(theme: theme)
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
        guard self.bubbleCellContentView == nil else {
            return
        }
        let bubbleCellContentView = BubbleCellContentView.instantiate()
        self.contentView.vc_addSubViewMatchingParent(bubbleCellContentView)
        self.bubbleCellContentView = bubbleCellContentView
    }
    
    // MARK: - BubbleCellReadReceiptsDisplayable
    // Cannot use default implementation with ObjC protocol, if self conforms to BubbleCellReadReceiptsDisplayable method below will be used
    
    func addReadReceiptsView(_ readReceiptsView: UIView) {
        self.bubbleCellContentView?.addReadReceiptsView(readReceiptsView)
    }
    
    func removeReadReceiptsView() {
        self.bubbleCellContentView?.removeReadReceiptsView()
    }
    
    // MARK: - BubbleCellReactionsDisplayable
    // Cannot use default implementation with ObjC protocol, if self conforms to BubbleCellReactionsDisplayable method below will be used
    
    func addReactionsView(_ reactionsView: UIView) {
        self.bubbleCellContentView?.addReactionsView(reactionsView)
    }
    
    func removeReactionsView() {
        self.bubbleCellContentView?.removeReactionsView()
    }
    
    // Encryption status
    
    private func updateEncryptionStatusViewImage() {
        guard let component = self.bubbleData.getFirstBubbleComponentWithDisplay() else {
            return
        }
        self.bubbleCellContentView?.encryptionImageView.image = RoomEncryptedDataBubbleCell.encryptionIcon(for: component)
    }
    
    private func setupEncryptionStatusViewTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleEncryptionStatusContainerViewTap(_:)))
        tapGestureRecognizer.delegate = self
        self.bubbleCellContentView?.encryptionImageView.isUserInteractionEnabled = true
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
