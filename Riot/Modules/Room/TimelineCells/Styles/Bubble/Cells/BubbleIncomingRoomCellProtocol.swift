// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol BubbleIncomingRoomCellProtocol: BubbleRoomCellProtocol {
}

extension BubbleIncomingRoomCellProtocol {
    
    // MARK: - Public
    
    func setupBubbleDecorations() {
        self.roomCellContentView?.decorationViewsAlignment = .left
        self.setupDecorationConstraints()
    }
    
    // MARK: - Private
    
    private func setupDecorationConstraints() {
        
        self.setupURLPreviewContentViewContraints()
        self.setupReactionsContentViewContraints()
        self.setupThreadSummaryViewContentViewContraints()
    }
    
    private func setupReactionsContentViewContraints() {
        
        self.roomCellContentView?.reactionsContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.right
    }
    
    private func setupThreadSummaryViewContentViewContraints() {
        self.roomCellContentView?.threadSummaryContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.right
        
        self.roomCellContentView?.threadSummaryContentViewBottomConstraint.constant = BubbleRoomCellLayoutConstants.threadSummaryViewMargins.bottom
    }
    
    private func setupURLPreviewContentViewContraints() {
        self.roomCellContentView?.urlPreviewContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.right
    }
}
