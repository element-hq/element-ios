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
import MatrixKit

@objc
enum ThreadRoomTitleViewMode: Int {
    case partial
    case full
}

@objcMembers
class ThreadRoomTitleView: RoomTitleView {
    
    var mode: ThreadRoomTitleViewMode = .full {
        didSet {
            update()
        }
    }
    var threadId: String! {
        didSet {
            updateMode()
        }
    }
    
    //  Container views
    @IBOutlet private weak var partialContainerView: UIView!
    @IBOutlet private weak var fullContainerView: UIView!
    
    //  Individual views
    @IBOutlet private weak var partialTitleLabel: UILabel!
    @IBOutlet private weak var fullCloseButton: UIButton!
    @IBOutlet private weak var fullTitleLabel: UILabel!
    @IBOutlet private weak var fullRoomAvatarView: RoomAvatarView!
    @IBOutlet private weak var fullRoomNameLabel: UILabel!
    @IBOutlet private weak var fullOptionsButton: UIButton!
    
    var closeButton: UIButton {
        return fullCloseButton
    }
    
    override var mxRoom: MXRoom! {
        didSet {
            updateMode()
        }
    }
    
    override class func nib() -> UINib! {
        return UINib(nibName: String(describing: self),
                     bundle: .main)
    }
    
    override func refreshDisplay() {
        partialTitleLabel.text = VectorL10n.roomThreadTitle
        fullTitleLabel.text = VectorL10n.roomThreadTitle
        
        guard let room = mxRoom else {
            //  room not initialized yet
            return
        }
        fullRoomNameLabel.text = room.displayName
        
        let avatarViewData = AvatarViewData(matrixItemId: room.matrixItemId,
                                            displayName: room.displayName,
                                            avatarUrl: room.mxContentUri,
                                            mediaManager: room.mxSession.mediaManager,
                                            fallbackImage: AvatarFallbackImage.matrixItem(room.matrixItemId,
                                                                                          room.displayName))
        fullRoomAvatarView.fill(with: avatarViewData)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        update(theme: ThemeService.shared().theme)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if let superview = superview?.superview {
            NSLayoutConstraint.activate([
                self.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                self.trailingAnchor.constraint(equalTo: superview.trailingAnchor)
            ])
        }
    }
    
    private func updateMode() {
        //  ensure both mxRoom and threadId are set
        guard let room = mxRoom,
              let threadId = threadId else {
            return
        }
        
        if room.mxSession.threadingService.thread(withId: threadId) == nil {
            //  thread not created yet
            mode = .partial
            //  use full mode for every case for now
            //  TODO: Fix in future
            mode = .full
        } else {
            //  thread created before
            mode = .full
        }
    }
    
    private func update() {
        switch mode {
        case .partial:
            partialContainerView.isHidden = false
            fullContainerView.isHidden = true
        case .full:
            partialContainerView.isHidden = true
            fullContainerView.isHidden = false
        }
    }
    
    //  MARK: - Actions
    
    @IBAction private func closeButtonTapped(_ sender: UIButton) {
        let gesture = UITapGestureRecognizer(target: nil, action: nil)
        closeButton.addGestureRecognizer(gesture)
        tapGestureDelegate.roomTitleView(self, recognizeTapGesture: gesture)
        closeButton.removeGestureRecognizer(gesture)
    }
    
    @IBAction private func optionsButtonTapped(_ sender: UIButton) {
        
    }
    
}

extension ThreadRoomTitleView: Themable {
    
    func update(theme: Theme) {
        partialTitleLabel.textColor = theme.colors.primaryContent
        fullCloseButton.tintColor = theme.colors.secondaryContent
        fullTitleLabel.textColor = theme.colors.primaryContent
        fullRoomNameLabel.textColor = theme.colors.secondaryContent
        fullOptionsButton.tintColor = theme.colors.secondaryContent
    }
    
}
