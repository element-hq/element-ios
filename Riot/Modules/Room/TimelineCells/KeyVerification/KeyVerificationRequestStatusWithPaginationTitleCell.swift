/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

@objcMembers
final class KeyVerificationRequestStatusWithPaginationTitleCell: KeyVerificationRequestStatusCell {
    
    // MARK: - Constants
    
    private enum Sizing {
        static let view = KeyVerificationRequestStatusWithPaginationTitleCell(style: .default, reuseIdentifier: nil)
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
        guard let roomCellContentView = self.roomCellContentView else {
            fatalError("[KeyVerificationRequestStatusWithPaginationTitleCell] roomCellContentView should not be nil")
        }
        
        roomCellContentView.showPaginationTitle = true
    }
    
    // MARK: - Overrides
    
    override class func sizingView() -> KeyVerificationBaseCell {
        return self.Sizing.view
    }
}
