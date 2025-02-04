// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class PollBaseBubbleCell: PollPlainCell {
    
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
    
    override func addContentViewController(_ controller: UIViewController, on contentView: UIView) {
        super.addContentViewController(controller, on: contentView)
        
        self.addBubbleBackgroundViewIfNeeded(for: controller.view)
    }
    
    // MARK: - Private
    
    private func addBubbleBackgroundViewIfNeeded(for pollView: UIView) {
        
        guard let messageBubbleBackgroundView = self.getBubbleBackgroundView() else {
            return
        }
        
        self.addBubbleBackgroundView(messageBubbleBackgroundView, to: pollView)
        messageBubbleBackgroundView.backgroundColor = self.bubbleBackgroundColor
    }
    
    private func addBubbleBackgroundView(_ bubbleBackgroundView: RoomMessageBubbleBackgroundView,
                                         to pollView: UIView) {
        
        let topMargin = BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.top
        let leftMargin = BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.left
        let rightMargin = BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.right
        let bottomMargin = BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.bottom
        
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
        self.roomCellContentView?.insertSubview(bubbleBackgroundView, at: 0)
    }
    
    // The extension property MXKRoomBubbleTableViewCell.messageBubbleBackgroundView is not working there even by doing recursion
    private func getBubbleBackgroundView() -> RoomMessageBubbleBackgroundView? {
        guard let contentView = self.roomCellContentView else {
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
