/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import Reusable

/// `RoomCellContentView` is a container view that display the default room message outer views and enables to manage them. Like pagination title, sender info, read receipts, reactions, encryption status.
@objcMembers
final class RoomCellContentView: UIView, NibLoadable {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet weak var paginationTitleContainerView: UIView!
    @IBOutlet weak var paginationLabel: UILabel!
    @IBOutlet weak var paginationSeparatorView: UIView!
    
    @IBOutlet weak var userNameContainerView: UIView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userNameTouchMaskView: UIView!
    
    @IBOutlet weak var userNameLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var userNameLabelBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var avatarContainerView: UIView!
    @IBOutlet weak var avatarImageView: MXKImageView!
    
    @IBOutlet weak var innerContentView: UIView!
    
    @IBOutlet weak var innerContentViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var innerContentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var innerContentViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var innerContentViewBottomContraint: NSLayoutConstraint!
    
    @IBOutlet weak var encryptionStatusContainerView: UIView!
    @IBOutlet weak var encryptionImageView: UIImageView!
    
    @IBOutlet weak var bubbleInfoContainer: UIView!
    @IBOutlet weak var bubbleInfoContainerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var urlPreviewContainerView: UIView!
    @IBOutlet weak var urlPreviewContentView: UIView!
    @IBOutlet weak var urlPreviewContentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var urlPreviewContentViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var readReceiptsContainerView: UIView!
    @IBOutlet weak var readReceiptsContentView: UIView!
    
    @IBOutlet weak var readMarkerContainerView: UIView!
    @IBOutlet weak var readMarkerContentView: UIView!
    
    var readMarkerViewLeadingConstraint: NSLayoutConstraint?
    var readMarkerViewTrailingConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var reactionsContainerView: UIView!
    @IBOutlet weak var reactionsContentView: UIView!
    @IBOutlet weak var reactionsContentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var reactionsContentViewTrailingConstraint: NSLayoutConstraint!

    @IBOutlet weak var threadSummaryContainerView: UIView!
    @IBOutlet weak var threadSummaryContentView: UIView!
    @IBOutlet weak var threadSummaryContentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var threadSummaryContentViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var threadSummaryContentViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bubbleOverlayContainer: UIView!
    
    // MARK: Private
    
    private var showURLPreview: Bool {
        get {
            return !self.urlPreviewContainerView.isHidden
        }
        set {
            self.urlPreviewContainerView.isHidden = !newValue
        }
    }
    
    private var showReadReceipts: Bool {
        get {
            return !self.readReceiptsContainerView.isHidden
        }
        set {
            self.readReceiptsContainerView.isHidden = !newValue
        }
    }
    
    private var showReactions: Bool {
        get {
            return !self.reactionsContainerView.isHidden
        }
        set {
            self.reactionsContainerView.isHidden = !newValue
        }
    }

    private var showThreadSummary: Bool {
        get {
            return !self.threadSummaryContainerView.isHidden
        } set {
            self.threadSummaryContainerView.isHidden = !newValue
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
    
    var showSenderInfo: Bool {
        get {
            return self.showSenderAvatar && self.showSenderName
        }
        set {
            self.showSenderAvatar = newValue
            self.showSenderName = newValue
        }
    }
    
    var showSenderAvatar: Bool {
        get {
            return !self.avatarContainerView.isHidden
        }
        set {
            self.avatarContainerView.isHidden = !newValue
        }
    }
    
    var showSenderName: Bool {
        get {
            return !self.userNameContainerView.isHidden
        }
        set {
            self.userNameContainerView.isHidden = !newValue
        }
    }
    
    var showEncryptionStatus: Bool {
        get {
            return !self.encryptionStatusContainerView.isHidden
        }
        set {
            self.encryptionStatusContainerView.isHidden = !newValue
        }
    }
    
    var showReadMarker: Bool {
        get {
            return !self.readMarkerContainerView.isHidden
        }
        set {
            self.readMarkerContainerView.isHidden = !newValue
        }
    }
    
    var decorationViewsAlignment: RoomCellDecorationAlignment = .left
    
    // MARK: - Setup
    
    class func instantiate() -> RoomCellContentView {
        return RoomCellContentView.loadFromNib()
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.backgroundColor = theme.backgroundColor
        self.paginationLabel.textColor = theme.tintColor
        self.paginationSeparatorView.backgroundColor = theme.tintColor
    }
}

// MARK: - RoomCellReadReceiptsDisplayable
extension RoomCellContentView: RoomCellReadReceiptsDisplayable {
    
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

// MARK: - RoomCellReactionsDisplayable
extension RoomCellContentView: RoomCellReactionsDisplayable {
    
    func addReactionsView(_ reactionsView: UIView) {
        self.reactionsContentView.vc_removeAllSubviews()
        
        // Update reactions alignment according to current decoration alignment
        if let reactionsView = reactionsView as? RoomReactionsView {
            
            let reactionsAlignment: RoomReactionsViewAlignment
            
            switch self.decorationViewsAlignment {
            case .left:
                reactionsAlignment = .left
            case .right:
                reactionsAlignment = .right
            }
                        
            reactionsView.alignment = reactionsAlignment
        }
        
        self.reactionsContentView.vc_addSubViewMatchingParent(reactionsView)
        
        self.showReactions = true
    }
    
    func removeReactionsView() {
        self.showReactions = false
        self.reactionsContentView.vc_removeAllSubviews()
    }
}

// MARK: - RoomCellThreadSummaryDisplayable
extension RoomCellContentView: RoomCellThreadSummaryDisplayable {
    
    func addThreadSummaryView(_ threadSummaryView: ThreadSummaryView) {
        
        guard let containerView = self.threadSummaryContentView else {
            return
        }
        
        containerView.vc_removeAllSubviews()
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(threadSummaryView)
        
        let leadingConstraint: NSLayoutConstraint
        let trailingConstraint: NSLayoutConstraint
        
        if self.decorationViewsAlignment == .right {
            leadingConstraint = threadSummaryView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor)
            trailingConstraint = threadSummaryView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        } else {
            leadingConstraint = threadSummaryView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            trailingConstraint =             threadSummaryView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor)
        }
        
        NSLayoutConstraint.activate([
            leadingConstraint,
            threadSummaryView.topAnchor.constraint(equalTo: containerView.topAnchor),
            threadSummaryView.heightAnchor.constraint(equalToConstant: PlainRoomCellLayoutConstants.threadSummaryViewHeight),
            threadSummaryView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            trailingConstraint
        ])
        
        self.showThreadSummary = true
    }

    func removeThreadSummaryView() {
        self.showThreadSummary = false
        self.threadSummaryContentView.vc_removeAllSubviews()
    }
}

// MARK: - RoomCellURLPreviewDisplayable
extension RoomCellContentView: RoomCellURLPreviewDisplayable {

    func addURLPreviewView(_ urlPreviewView: UIView) {
        
        guard let containerView = self.urlPreviewContentView else {
            return
        }
        
        containerView.vc_removeAllSubviews()
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(urlPreviewView)
        
        if let urlPreviewView = urlPreviewView as? URLPreviewView {
            urlPreviewView.availableWidth = containerView.frame.width
        }
        
        let leadingConstraint: NSLayoutConstraint
        let trailingConstraint: NSLayoutConstraint
        
        if self.decorationViewsAlignment == .right {
            leadingConstraint = urlPreviewView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor)
            trailingConstraint = urlPreviewView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        } else {
            leadingConstraint = urlPreviewView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            trailingConstraint =             urlPreviewView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor)
        }
        
        NSLayoutConstraint.activate([
            leadingConstraint,
            urlPreviewView.topAnchor.constraint(equalTo: containerView.topAnchor),
            urlPreviewView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            trailingConstraint
        ])
        
        self.showURLPreview = true
    }
    
    func removeURLPreviewView() {
        self.showURLPreview = false
        self.urlPreviewContentView.vc_removeAllSubviews()
    }
}

// MARK: - RoomCellReadMarkerDisplayable
extension RoomCellContentView: RoomCellReadMarkerDisplayable {
    
    func addReadMarkerView(_ readMarkerView: UIView) {
        guard let containerView = self.readMarkerContainerView else {
            return
        }
        
        self.readMarkerContentView.vc_removeAllSubviews()
        
        readMarkerView.translatesAutoresizingMaskIntoConstraints = false
        
        self.readMarkerContentView.addSubview(readMarkerView)
        
        // Force read marker constraints
        let topConstraint = readMarkerView.topAnchor.constraint(equalTo: containerView.topAnchor)
        
        let leadingConstraint = readMarkerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        
        let trailingConstraint = readMarkerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        
        let heightConstraint = readMarkerView.heightAnchor.constraint(equalToConstant: PlainRoomCellLayoutConstants.readMarkerViewHeight)
        
        let bottomContraint = readMarkerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        
        NSLayoutConstraint.activate([topConstraint,
                                     leadingConstraint,
                                     trailingConstraint,
                                     heightConstraint,
                                     bottomContraint])
        
        self.readMarkerViewLeadingConstraint = leadingConstraint
        self.readMarkerViewTrailingConstraint = trailingConstraint
        
        self.showReadMarker = true
    }
    
    func removeReadMarkerView() {
        self.showReadMarker = false
        self.readMarkerContentView.vc_removeAllSubviews()
    }
}
