/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import MatrixSDK
import SwiftUI

@objc protocol SizableBaseRoomCellType: BaseRoomCellProtocol {
    static func sizingViewHeightHashValue(from bubbleCellData: MXKRoomBubbleCellData) -> Int
}

/// `SizableBaseRoomCell` allows a cell using Auto Layout that inherits from this class to automatically return the height of the cell and cache the result.
@objcMembers
class SizableBaseRoomCell: BaseRoomCell, SizableBaseRoomCellType {
    
    // MARK: - Constants
    
    private static let sizingViewHeightStore = SizingViewHeightStore()
    private static var sizingViews: [String: SizableBaseRoomCell] = [:]
    private static let sizingReactionsView = RoomReactionsView()
    
    private static let reactionsViewSizer = RoomReactionsViewSizer()
    private static let reactionsViewModelBuilder = RoomReactionsViewModelBuilder()
    
    private static let urlPreviewViewSizer = URLPreviewViewSizer()
    private var contentVC: UIViewController?

    private class var sizingView: SizableBaseRoomCell {
        let sizingView: SizableBaseRoomCell
        
        let reuseIdentifier: String = self.defaultReuseIdentifier()

        if let cachedSizingView = self.sizingViews[reuseIdentifier] {
            sizingView = cachedSizingView
        } else {
            sizingView = self.createSizingView()
            self.sizingViews[reuseIdentifier] = sizingView
        }
        return sizingView
    }        
    
    // MARK: - Overrides
    
    override class func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        guard let cellData = cellData else {
            return 0
        }
        
        guard let roomBubbleCellData = cellData as? MXKRoomBubbleCellData else {
            return 0
        }
        
        return self.height(for: roomBubbleCellData, fitting: maxWidth)
    }
    
    override func prepareForReuse() {
        cleanContentVC()

        super.prepareForReuse()
    }
        
    // MARK - SizableBaseRoomCellType
    
    // Each sublcass should override this method, to indicate a unique identifier for a view height.
    // This means that the value should change if there is some data that modify the cell height.
    class func sizingViewHeightHashValue(from bubbleCellData: MXKRoomBubbleCellData) -> Int {
        // TODO: Improve default hash value computation:
        // - Implement RoomBubbleCellData hash
        // - Handle reactions
        return bubbleCellData.hashValue
    }
    
    // MARK: - Private
    
    class func createSizingView() -> SizableBaseRoomCell {
        return self.init(style: .default, reuseIdentifier: self.defaultReuseIdentifier())
    }
    
    private class func height(for roomBubbleCellData: MXKRoomBubbleCellData, fitting width: CGFloat) -> CGFloat {
        // FIXME: Size cache is disabled for the moment waiting for a better default `sizingViewHeightHashValue` implementation.
        
//        let height: CGFloat
//
//        let sizingViewHeight = self.findOrCreateSizingViewHeight(from: roomBubbleCellData)
//
//        if let cachedHeight = sizingViewHeight.heights[width] {
//            height = cachedHeight
//        } else {
//            height = self.contentViewHeight(for: roomBubbleCellData, fitting: width)
//            sizingViewHeight.heights[width] = height
//        }
//
//        return height
        
        return self.contentViewHeight(for: roomBubbleCellData, fitting: width)
    }
    
    private static func findOrCreateSizingViewHeight(from bubbleData: MXKRoomBubbleCellData) -> SizingViewHeight {
        let bubbleDataHashValue = self.sizingViewHeightHashValue(from: bubbleData)
        return self.sizingViewHeightStore.findOrCreateSizingViewHeight(from: bubbleDataHashValue)
    }
    
    private static func contentViewHeight(for cellData: MXKCellData, fitting width: CGFloat) -> CGFloat {
        let sizingView = self.sizingView
        
        sizingView.didEndDisplay()
        
        sizingView.render(cellData)
        
        sizingView.setNeedsLayout()
        sizingView.layoutIfNeeded()
        
        if let contentVC = sizingView.contentVC as? UIHostingController<AnyView> {
            contentVC.view.invalidateIntrinsicContentSize()
        }

        let fittingSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        var height = sizingView.systemLayoutSizeFitting(fittingSize).height
        
        // Add read receipt height if needed
        if let roomBubbleCellData = cellData as? RoomBubbleCellData, let readReceipts = roomBubbleCellData.readReceipts, readReceipts.count > 0, sizingView is RoomCellReadReceiptsDisplayable {
            height+=PlainRoomCellLayoutConstants.readReceiptsViewHeight
        }
        
        // Add reactions view height if needed
        if sizingView is RoomCellReactionsDisplayable,
            let roomBubbleCellData = cellData as? RoomBubbleCellData,
            let reactionsViewModel = self.reactionsViewModelBuilder.buildForFirstVisibleComponent(of: roomBubbleCellData) {
            
            let reactionWidth = sizingView.roomCellContentView?.reactionsContentView.frame.width ?? roomBubbleCellData.maxTextViewWidth
            
            let reactionsHeight = self.reactionsViewSizer.height(for: reactionsViewModel, fittingWidth: reactionWidth)
            height+=reactionsHeight
        }

        // Add thread summary view height if needed
        if sizingView is RoomCellThreadSummaryDisplayable,
           let roomBubbleCellData = cellData as? RoomBubbleCellData,
           roomBubbleCellData.hasThreadRoot {
            
            let bottomMargin = sizingView.roomCellContentView?.threadSummaryContentViewBottomConstraint.constant ?? 0
            
            height += PlainRoomCellLayoutConstants.threadSummaryViewHeight
            height += bottomMargin
        }
        
        // Add URL preview view height if needed
        if sizingView is RoomCellURLPreviewDisplayable,
            let roomBubbleCellData = cellData as? RoomBubbleCellData, let firstBubbleComponent =
            roomBubbleCellData.getFirstBubbleComponentWithDisplay(), firstBubbleComponent.showURLPreview, let urlPreviewData = firstBubbleComponent.urlPreviewData as? URLPreviewData {
            
            let urlPreviewMaxWidth = sizingView.roomCellContentView?.urlPreviewContentView.frame.width ?? roomBubbleCellData.maxTextViewWidth
            
            let urlPreviewHeight = self.urlPreviewViewSizer.height(for: urlPreviewData, fittingWidth: urlPreviewMaxWidth)
            height+=urlPreviewHeight
        }
        
        // Add read marker view height if needed
        // Note: We cannot check if readMarkerView property is set here. Extra non needed height can be added
        if sizingView is RoomCellReadMarkerDisplayable,
            let roomBubbleCellData = cellData as? RoomBubbleCellData, let firstBubbleComponent =
            roomBubbleCellData.getFirstBubbleComponentWithDisplay(),
           let eventId = firstBubbleComponent.event.eventId, let room = roomBubbleCellData.mxSession.room(withRoomId: roomBubbleCellData.roomId), let readMarkerEventId = room.accountData.readMarkerEventId, eventId == readMarkerEventId {
            
            height+=PlainRoomCellLayoutConstants.readMarkerViewHeight
        }
        
        return height
    }
    
    private func cleanContentVC() {
        contentVC?.removeFromParent()
        contentVC?.view.removeFromSuperview()
        contentVC?.didMove(toParent: nil)
        contentVC = nil
    }
    
    // MARK: - Public
    
    func addContentViewController(_ controller: UIViewController, on contentView: UIView) {
        controller.view.invalidateIntrinsicContentSize()
        
        cleanContentVC()

        let parent = vc_parentViewController
        parent?.addChild(controller)
        contentView.vc_addSubViewMatchingParent(controller.view)
        controller.didMove(toParent: parent)

        contentVC = controller
    }
}
