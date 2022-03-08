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

import UIKit

@objcMembers
final class KeyVerificationIncomingRequestApprovalWithPaginationTitleCell: KeyVerificationIncomingRequestApprovalCell {
    
    // MARK: - Constants
    
    private enum Sizing {
        static let view = KeyVerificationIncomingRequestApprovalWithPaginationTitleCell(style: .default, reuseIdentifier: nil)
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
