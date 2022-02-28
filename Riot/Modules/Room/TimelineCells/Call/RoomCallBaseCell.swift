// 
// Copyright 2020 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import Reusable

class RoomCallBaseCell: MXKRoomBubbleTableViewCell {
    
    lazy var innerContentView: CallCellContentView = {
        return CallCellContentView.loadFromNib()
    }()
    
    override required init!(style: UITableViewCell.CellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    override func setupViews() {
        super.setupViews()
        
        self.contentView.vc_addSubViewMatchingParent(innerContentView)
    }

    //  Bottom content view. Will be spanned in bottomContainerView
    var bottomContentView: UIView? {
        didSet {
            updateBottomContentView()
        }
    }
    
    var statusText: String? {
        get {
            return innerContentView.statusText
        } set {
            innerContentView.statusText = newValue
        }
    }
    
    private func updateBottomContentView() {
        defer {
            innerContentView.relayoutCallSummary()
        }
        
        innerContentView.bottomContainerView.vc_removeAllSubviews()
        
        guard let bottomContentView = bottomContentView else { return }
        innerContentView.bottomContainerView.vc_addSubViewMatchingParent(bottomContentView)
    }
    
    class func createSizingView() -> RoomCallBaseCell {
        return self.init(style: .default, reuseIdentifier: self.defaultReuseIdentifier())
    }
    
    //  MARK: - Overrides
    
    override var bubbleInfoContainer: UIView! {
        get {
            guard let infoContainer = innerContentView.bubbleInfoContainer else {
                fatalError("[RoomBaseCallBubbleCell] bubbleInfoContainer should not be used before set")
            }
            return infoContainer
        } set {
            super.bubbleInfoContainer = newValue
        }
    }
    
    override var bubbleOverlayContainer: UIView! {
        get {
            guard let overlayContainer = innerContentView.bubbleOverlayContainer else {
                fatalError("[RoomBaseCallBubbleCell] bubbleOverlayContainer should not be used before set")
            }
            return overlayContainer
        } set {
            super.bubbleOverlayContainer = newValue
        }
    }
    
    override var bubbleInfoContainerTopConstraint: NSLayoutConstraint! {
        get {
            guard let infoContainerTopConstraint = innerContentView.bubbleInfoContainerTopConstraint else {
                fatalError("[RoomBaseCallBubbleCell] bubbleInfoContainerTopConstraint should not be used before set")
            }
            return infoContainerTopConstraint
        }
        set {
            super.bubbleInfoContainerTopConstraint = newValue
        }
    }
    
    //  MARK: - MXKCellRendering
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        update(theme: ThemeService.shared().theme)
        
        guard let cellData = cellData else {
            return
        }
        
        innerContentView.render(cellData)
    }
    
    override class func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        guard let cellData = cellData else {
            return 0
        }
        
        let fittingSize = CGSize(width: maxWidth, height: UIView.layoutFittingCompressedSize.height)
        guard let cell = self.init(style: .default, reuseIdentifier: self.defaultReuseIdentifier()) else {
            return 0
        }
        cell.render(cellData)
        
        //  we need to add suitable height manually for read receipts view, as adding of them is not handled in the render method
        var readReceiptsHeight: CGFloat = 0
        if let bubbleCellData = cellData as? RoomBubbleCellData,
           bubbleCellData.showBubbleReceipts,
           bubbleCellData.readReceipts.count > 0 {
            readReceiptsHeight = cell.innerContentView.readReceiptsContainerView.systemLayoutSizeFitting(fittingSize).height
                + cell.innerContentView.interItemSpacing
        }
        
        return cell.contentView.systemLayoutSizeFitting(fittingSize).height + readReceiptsHeight
    }
    
}

extension RoomCallBaseCell: RoomCellReadReceiptsDisplayable {
    
    func addReadReceiptsView(_ readReceiptsView: UIView) {
        innerContentView.addReadReceiptsView(readReceiptsView)
    }
    
    func removeReadReceiptsView() {
        innerContentView.removeReadReceiptsView()
    }
    
}

extension RoomCallBaseCell: Themable {
    
    func update(theme: Theme) {
        innerContentView.update(theme: theme)
        if let themable = bottomContentView as? Themable {
            themable.update(theme: theme)
        }
    }
    
}

extension RoomCallBaseCell: NibReusable {
    
}
