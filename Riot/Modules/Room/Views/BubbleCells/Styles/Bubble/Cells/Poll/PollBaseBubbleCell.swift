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

import UIKit

class PollBaseBubbleCell: PollBubbleCell {
    
    // MARK: - Properties
    
    var bubbleBackgroundColor: UIColor?
    
    // MARK: - Overrides

    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        self.update(theme: ThemeService.shared().theme)
    }
        
    override func setupViews() {
        super.setupViews()
        
        self.setupBubbleBackgroundView()
    }
    
    override func addPollView(_ pollView: UIView, on contentView: UIView) {
        super.addPollView(pollView, on: contentView)
        
        self.addBubbleBackgroundViewIfNeeded(for: pollView)
    }
    
    // MARK: - Private
    
    private func addBubbleBackgroundViewIfNeeded(for pollView: UIView) {
        
        guard let messageBubbleBackgroundView = self.getBubbleBackgroundView() else {
            return
        }
        
        self.addBubbleBackgroundView( messageBubbleBackgroundView, to: pollView)
        messageBubbleBackgroundView.backgroundColor = self.bubbleBackgroundColor
    }
    
    private func addBubbleBackgroundView(_ bubbleBackgroundView: RoomMessageBubbleBackgroundView,
                                         to pollView: UIView) {
        
        let topMargin: CGFloat = 2.0
        let leftMargin: CGFloat = 10.0
        let rightMargin: CGFloat = 10.0 // Add extra space for timestamp
        let bottomMargin: CGFloat = 0.0 //
        
        let topAnchor = pollView.topAnchor
        let leadingAnchor = pollView.leadingAnchor
        let trailingAnchor = pollView.trailingAnchor
        let bottomAnchor = pollView.bottomAnchor

        NSLayoutConstraint.activate([
            bubbleBackgroundView.topAnchor.constraint(equalTo: topAnchor, constant: -topMargin),
            bubbleBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -leftMargin),
            bubbleBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: rightMargin),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomMargin)
        ])
    }
        
    private func setupBubbleBackgroundView() {
        let bubbleBackgroundView = RoomMessageBubbleBackgroundView()
        self.bubbleCellContentView?.insertSubview(bubbleBackgroundView, at: 0)
    }
    
    // The extension property MXKRoomBubbleTableViewCell.messageBubbleBackgroundView is not working there even by doing recursion
    private func getBubbleBackgroundView() -> RoomMessageBubbleBackgroundView? {
        guard let contentView = self.bubbleCellContentView else {
            return nil
        }
        
        let foundView = contentView.subviews.first { view in
            return view is RoomMessageBubbleBackgroundView
        }
        return foundView as? RoomMessageBubbleBackgroundView
    }
}

// MARK: - RoomCellTimestampDisplayable
extension PollBaseBubbleCell: TimestampDisplayable {
    
    func addTimestampView(_ timestampView: UIView) {
        guard let messageBubbleBackgroundView = self.getBubbleBackgroundView() else {
            return
        }
        messageBubbleBackgroundView.addTimestampView(timestampView)
    }
    
    func removeTimestampView() {
        guard let messageBubbleBackgroundView = self.getBubbleBackgroundView() else {
            return
        }
        messageBubbleBackgroundView.removeTimestampView()
    }
}
