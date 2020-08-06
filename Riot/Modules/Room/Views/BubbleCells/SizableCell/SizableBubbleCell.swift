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

@objc protocol SizableBaseBubbleCellType: BaseBubbleCellType {
    static func sizingViewHeightHashValue(from bubbleCellData: MXKRoomBubbleCellData) -> Int
}

/// `SizableBaseBubbleCell` allows a cell using Auto Layout that inherits from this class to automatically return the height of the cell and cache the result.
@objcMembers
class SizableBaseBubbleCell: BaseBubbleCell, SizableBaseBubbleCellType {
    
    // MARK: - Constants
    
    private static let sizingViewHeightStore = SizingViewHeightStore()
    private static var sizingViews: [String: SizableBaseBubbleCell] = [:]
    private static let sizingReactionsView = BubbleReactionsView()
    
    private static let reactionsViewSizer = BubbleReactionsViewSizer()
    private static let reactionsViewModelBuilder = BubbleReactionsViewModelBuilder()

    private class var sizingView: SizableBaseBubbleCell {
        let sizingView: SizableBaseBubbleCell
        
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
        
    // MARK - SizableBaseBubbleCellType
    
    // Each sublcass should override this method, to indicate a unique identifier for a view height.
    // This means that the value should change if there is some data that modify the cell height.
    class func sizingViewHeightHashValue(from bubbleCellData: MXKRoomBubbleCellData) -> Int {
        // TODO: Improve default hash value computation:
        // - Implement RoomBubbleCellData hash
        // - Handle reactions
        return bubbleCellData.hashValue
    }
    
    // MARK: - Private
    
    class func createSizingView() -> SizableBaseBubbleCell {
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
        
        let fittingSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        var height = sizingView.systemLayoutSizeFitting(fittingSize).height
        
        // Add read receipt height if needed
        if let roomBubbleCellData = cellData as? RoomBubbleCellData, let readReceipts = roomBubbleCellData.readReceipts, readReceipts.count > 0, sizingView is BubbleCellReadReceiptsDisplayable {
            height+=RoomBubbleCellLayout.readReceiptsViewHeight
        }
        
        // Add reactions view height if needed
        if sizingView is BubbleCellReactionsDisplayable,
            let roomBubbleCellData = cellData as? RoomBubbleCellData,
            let bubbleReactionsViewModel = self.reactionsViewModelBuilder.buildForFirstVisibleComponent(of: roomBubbleCellData) {
            
            let reactionWidth = sizingView.bubbleCellContentView?.reactionsContentView.frame.width ?? roomBubbleCellData.maxTextViewWidth
            
            let reactionsHeight = self.reactionsViewSizer.height(for: bubbleReactionsViewModel, fittingWidth: reactionWidth)
            height+=reactionsHeight
        }
        
        return height
    }         
}
