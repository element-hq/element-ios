// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

class PollWithoutSenderInfoPlainCell: PollPlainCell {
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderInfo = false
    }
    
}
