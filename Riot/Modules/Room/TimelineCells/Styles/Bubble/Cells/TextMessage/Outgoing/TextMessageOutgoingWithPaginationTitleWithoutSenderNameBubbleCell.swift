// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

class TextMessageOutgoingWithPaginationTitleWithoutSenderNameBubbleCell: TextMessageOutgoingWithPaginationTitleBubbleCell {
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderName = false
    }
}
