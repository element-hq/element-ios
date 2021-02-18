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

class RoomBaseCallBubbleCell: MXKRoomBubbleTableViewCell {
    
    fileprivate lazy var innerContentView: CallBubbleCellBaseContentView = {
        return CallBubbleCellBaseContentView.loadFromNib()
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
        
        self.contentView.vc_removeAllSubviews()
        self.contentView.vc_addSubViewMatchingParent(innerContentView)
        
        updateBottomContentView()
    }

    //  Properties to override
    private(set) var bottomContentView: UIView?
    
    func updateBottomContentView() {
        innerContentView.bottomContainerView.vc_removeAllSubviews()
        
        guard let bottomContentView = bottomContentView else { return }
        innerContentView.bottomContainerView.vc_addSubViewMatchingParent(bottomContentView)
    }
    
    class func createSizingView() -> RoomBaseCallBubbleCell {
        return self.init(style: .default, reuseIdentifier: self.defaultReuseIdentifier())
    }
    
    //  MARK: - Overrides
    
    override var bubbleOverlayContainer: UIView! {
        get {
            guard let overlayContainer = innerContentView.bubbleOverlayContainer else {
                fatalError("[RoomBaseCallBubbleCell] bubbleOverlayContainer should not be used before set")
            }
            return overlayContainer
        }
        set {
            super.bubbleOverlayContainer = newValue
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
        
        return cell.contentView.systemLayoutSizeFitting(fittingSize).height
    }
    
}

extension RoomBaseCallBubbleCell: Themable {
    
    func update(theme: Theme) {
        innerContentView.update(theme: theme)
    }
    
}

extension RoomBaseCallBubbleCell: NibLoadable, Reusable {
    
}
