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

import Reusable
import UIKit

/// `RoomCellContentView` is a container view that display the default room message outer views and enables to manage them. Like pagination title, sender info, read receipts, reactions, encryption status.
@objcMembers
final class RoomCellContentView: UIView, NibLoadable {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet var paginationTitleContainerView: UIView!
    @IBOutlet var paginationLabel: UILabel!
    @IBOutlet var paginationSeparatorView: UIView!
    
    @IBOutlet var userNameContainerView: UIView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userNameTouchMaskView: UIView!
    
    @IBOutlet var userNameLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet var userNameLabelBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var avatarContainerView: UIView!
    @IBOutlet var avatarImageView: MXKImageView!
    
    @IBOutlet var innerContentView: UIView!
    
    @IBOutlet var innerContentViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var innerContentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var innerContentViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var innerContentViewBottomContraint: NSLayoutConstraint!
    
    @IBOutlet var encryptionStatusContainerView: UIView!
    @IBOutlet var encryptionImageView: UIImageView!
    
    @IBOutlet var bubbleInfoContainer: UIView!
    @IBOutlet var bubbleInfoContainerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var urlPreviewContainerView: UIView!
    @IBOutlet var urlPreviewContentView: UIView!
    @IBOutlet var urlPreviewContentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var urlPreviewContentViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet var readReceiptsContainerView: UIView!
    @IBOutlet var readReceiptsContentView: UIView!
    
    @IBOutlet var readMarkerContainerView: UIView!
    @IBOutlet var readMarkerContentView: UIView!
    
    var readMarkerViewLeadingConstraint: NSLayoutConstraint?
    var readMarkerViewTrailingConstraint: NSLayoutConstraint?
    
    @IBOutlet var reactionsContainerView: UIView!
    @IBOutlet var reactionsContentView: UIView!
    @IBOutlet var reactionsContentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var reactionsContentViewTrailingConstraint: NSLayoutConstraint!

    @IBOutlet var threadSummaryContainerView: UIView!
    @IBOutlet var threadSummaryContentView: UIView!
    @IBOutlet var threadSummaryContentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var threadSummaryContentViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var threadSummaryContentViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var bubbleOverlayContainer: UIView!
    
    // MARK: Private
    
    private var showURLPreview: Bool {
        get {
            !urlPreviewContainerView.isHidden
        }
        set {
            urlPreviewContainerView.isHidden = !newValue
        }
    }
    
    private var showReadReceipts: Bool {
        get {
            !readReceiptsContainerView.isHidden
        }
        set {
            readReceiptsContainerView.isHidden = !newValue
        }
    }
    
    private var showReactions: Bool {
        get {
            !reactionsContainerView.isHidden
        }
        set {
            reactionsContainerView.isHidden = !newValue
        }
    }

    private var showThreadSummary: Bool {
        get {
            !threadSummaryContainerView.isHidden
        } set {
            threadSummaryContainerView.isHidden = !newValue
        }
    }
    
    // MARK: Public
    
    var showPaginationTitle: Bool {
        get {
            !paginationTitleContainerView.isHidden
        }
        set {
            paginationTitleContainerView.isHidden = !newValue
        }
    }
    
    var showSenderInfo: Bool {
        get {
            showSenderAvatar && showSenderName
        }
        set {
            showSenderAvatar = newValue
            showSenderName = newValue
        }
    }
    
    var showSenderAvatar: Bool {
        get {
            !avatarContainerView.isHidden
        }
        set {
            avatarContainerView.isHidden = !newValue
        }
    }
    
    var showSenderName: Bool {
        get {
            !userNameContainerView.isHidden
        }
        set {
            userNameContainerView.isHidden = !newValue
        }
    }
    
    var showEncryptionStatus: Bool {
        get {
            !encryptionStatusContainerView.isHidden
        }
        set {
            encryptionStatusContainerView.isHidden = !newValue
        }
    }
    
    var showReadMarker: Bool {
        get {
            !readMarkerContainerView.isHidden
        }
        set {
            readMarkerContainerView.isHidden = !newValue
        }
    }
    
    var decorationViewsAlignment: RoomCellDecorationAlignment = .left
    
    // MARK: - Setup
    
    class func instantiate() -> RoomCellContentView {
        RoomCellContentView.loadFromNib()
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        backgroundColor = theme.backgroundColor
        paginationLabel.textColor = theme.tintColor
        paginationSeparatorView.backgroundColor = theme.tintColor
    }
}

// MARK: - RoomCellReadReceiptsDisplayable

extension RoomCellContentView: RoomCellReadReceiptsDisplayable {
    func addReadReceiptsView(_ readReceiptsView: UIView) {
        readReceiptsContentView.vc_removeAllSubviews()
        readReceiptsContentView.vc_addSubViewMatchingParent(readReceiptsView)
        showReadReceipts = true
    }
    
    func removeReadReceiptsView() {
        showReadReceipts = false
        readReceiptsContentView.vc_removeAllSubviews()
    }
}

// MARK: - RoomCellReactionsDisplayable

extension RoomCellContentView: RoomCellReactionsDisplayable {
    func addReactionsView(_ reactionsView: UIView) {
        reactionsContentView.vc_removeAllSubviews()
        
        // Update reactions alignment according to current decoration alignment
        if let reactionsView = reactionsView as? RoomReactionsView {
            let reactionsAlignment: RoomReactionsViewAlignment
            
            switch decorationViewsAlignment {
            case .left:
                reactionsAlignment = .left
            case .right:
                reactionsAlignment = .right
            }
                        
            reactionsView.alignment = reactionsAlignment
        }
        
        reactionsContentView.vc_addSubViewMatchingParent(reactionsView)
        
        showReactions = true
    }
    
    func removeReactionsView() {
        showReactions = false
        reactionsContentView.vc_removeAllSubviews()
    }
}

// MARK: - RoomCellThreadSummaryDisplayable

extension RoomCellContentView: RoomCellThreadSummaryDisplayable {
    func addThreadSummaryView(_ threadSummaryView: ThreadSummaryView) {
        guard let containerView = threadSummaryContentView else {
            return
        }
        
        containerView.vc_removeAllSubviews()
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(threadSummaryView)
        
        let leadingConstraint: NSLayoutConstraint
        let trailingConstraint: NSLayoutConstraint
        
        if decorationViewsAlignment == .right {
            leadingConstraint = threadSummaryView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor)
            trailingConstraint = threadSummaryView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        } else {
            leadingConstraint = threadSummaryView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            trailingConstraint = threadSummaryView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor)
        }
        
        NSLayoutConstraint.activate([
            leadingConstraint,
            threadSummaryView.topAnchor.constraint(equalTo: containerView.topAnchor),
            threadSummaryView.heightAnchor.constraint(equalToConstant: PlainRoomCellLayoutConstants.threadSummaryViewHeight),
            threadSummaryView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            trailingConstraint
        ])
        
        showThreadSummary = true
    }

    func removeThreadSummaryView() {
        showThreadSummary = false
        threadSummaryContentView.vc_removeAllSubviews()
    }
}

// MARK: - RoomCellURLPreviewDisplayable

extension RoomCellContentView: RoomCellURLPreviewDisplayable {
    func addURLPreviewView(_ urlPreviewView: UIView) {
        guard let containerView = urlPreviewContentView else {
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
        
        if decorationViewsAlignment == .right {
            leadingConstraint = urlPreviewView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor)
            trailingConstraint = urlPreviewView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        } else {
            leadingConstraint = urlPreviewView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            trailingConstraint = urlPreviewView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor)
        }
        
        NSLayoutConstraint.activate([
            leadingConstraint,
            urlPreviewView.topAnchor.constraint(equalTo: containerView.topAnchor),
            urlPreviewView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            trailingConstraint
        ])
        
        showURLPreview = true
    }
    
    func removeURLPreviewView() {
        showURLPreview = false
        urlPreviewContentView.vc_removeAllSubviews()
    }
}

// MARK: - RoomCellReadMarkerDisplayable

extension RoomCellContentView: RoomCellReadMarkerDisplayable {
    func addReadMarkerView(_ readMarkerView: UIView) {
        guard let containerView = readMarkerContainerView else {
            return
        }
        
        readMarkerContentView.vc_removeAllSubviews()
        
        readMarkerView.translatesAutoresizingMaskIntoConstraints = false
        
        readMarkerContentView.addSubview(readMarkerView)
        
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
        
        readMarkerViewLeadingConstraint = leadingConstraint
        readMarkerViewTrailingConstraint = trailingConstraint
        
        showReadMarker = true
    }
    
    func removeReadMarkerView() {
        showReadMarker = false
        readMarkerContentView.vc_removeAllSubviews()
    }
}
