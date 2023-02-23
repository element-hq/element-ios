// 
// Copyright 2022 New Vector Ltd
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

class VoiceBroadcastPlaybackBubbleCell: VoiceBroadcastPlaybackPlainCell {
    
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
    
    private func addBubbleBackgroundViewIfNeeded(for voiceBroadcastView: UIView) {
        
        guard let messageBubbleBackgroundView = self.getBubbleBackgroundView() else {
            return
        }
        
        self.addBubbleBackgroundView( messageBubbleBackgroundView, to: voiceBroadcastView)
        messageBubbleBackgroundView.backgroundColor = self.bubbleBackgroundColor
    }
    
    private func addBubbleBackgroundView(_ bubbleBackgroundView: RoomMessageBubbleBackgroundView,
                                         to voiceBroadcastView: UIView) {
        
        // TODO: VB update margins attributes
        let topMargin = BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.top
        let leftMargin = BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.left
        let rightMargin = BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.right
        let bottomMargin = BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.bottom
        
        let topAnchor = voiceBroadcastView.topAnchor
        let leadingAnchor = voiceBroadcastView.leadingAnchor
        let trailingAnchor = voiceBroadcastView.trailingAnchor
        let bottomAnchor = voiceBroadcastView.bottomAnchor

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
extension VoiceBroadcastPlaybackBubbleCell: TimestampDisplayable {
    
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
