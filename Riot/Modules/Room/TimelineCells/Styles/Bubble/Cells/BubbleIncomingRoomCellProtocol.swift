// 
// Copyright 2021 New Vector Ltd
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
