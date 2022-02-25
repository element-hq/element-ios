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

class ThreadViewController: RoomViewController {
    
    // MARK: Private
    
    private(set) var threadId: String!
    
    private var permalink: String? {
        guard let threadId = threadId else { return nil }
        return MXTools.permalink(toEvent: threadId, inRoom: roomDataSource.roomId)
    }
    
    class func instantiate(withThreadId threadId: String,
                           configuration: RoomDisplayConfiguration) -> ThreadViewController {
        let threadVC = ThreadViewController.instantiate(with: configuration)
        threadVC.threadId = threadId
        return threadVC
    }
    
    override class func nib() -> UINib! {
        //  reuse 'RoomViewController.xib' file as the nib
        return UINib(nibName: String(describing: RoomViewController.self), bundle: .main)
    }
    
    override func finalizeInit() {
        super.finalizeInit()
        
        self.saveProgressTextInput = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let threadId = threadId else { return }
        mainSession?.threadingService.markThreadAsRead(threadId)
    }
    
    override func setRoomTitleViewClass(_ roomTitleViewClass: AnyClass!) {
        super.setRoomTitleViewClass(ThreadRoomTitleView.self)
        
        guard let threadTitleView = self.titleView as? ThreadRoomTitleView else {
            return
        }
        
        threadTitleView.mode = .specificThread(threadId: threadId)
    }
    
    override func onButtonPressed(_ sender: Any) {
        if let sender = sender as? UIBarButtonItem, sender == navigationItem.rightBarButtonItem {
            showThreadActions()
            return
        }
        super.onButtonPressed(sender)
    }
    
    override func sendTypingNotification(_ typing: Bool, timeout notificationTimeoutMS: UInt) {
        // no-op
    }

    private func showThreadActions() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let viewInRoomAction = UIAlertAction(title: VectorL10n.roomEventActionViewInRoom,
                                             style: .default,
                                             handler: { [weak self] action in
                                                guard let self = self else { return }
                                                self.delegate?.roomViewController(self,
                                                                                  showRoomWithId: self.roomDataSource.roomId,
                                                                                  eventId: self.threadId)
                                             })
        alertController.addAction(viewInRoomAction)
        
        let copyLinkAction = UIAlertAction(title: VectorL10n.threadCopyLinkToThread,
                                           style: .default,
                                           handler: { [weak self] action in
                                            guard let self = self else { return }
                                            self.copyPermalink()
                                           })
        alertController.addAction(copyLinkAction)
        
        let shareAction = UIAlertAction(title: VectorL10n.roomEventActionShare,
                                        style: .default,
                                        handler: { [weak self] action in
                                            guard let self = self else { return }
                                            self.sharePermalink()
                                        })
        alertController.addAction(shareAction)
        
        alertController.addAction(UIAlertAction(title: VectorL10n.cancel,
                                                style: .cancel,
                                                handler: nil))
        
        alertController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func copyPermalink() {
        guard let permalink = permalink, let url = URL(string: permalink) else {
            return
        }
        
        MXKPasteboardManager.shared.pasteboard.url = url
        view.vc_toast(message: VectorL10n.roomEventCopyLinkInfo,
                      image: Asset.Images.linkIcon.image,
                      additionalMargin: self.roomInputToolbarContainerHeightConstraint.constant)
    }
    
    private func sharePermalink() {
        guard let permalink = permalink else {
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [permalink],
                                                  applicationActivities: nil)
        activityVC.modalTransitionStyle = .coverVertical
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityVC, animated: true, completion: nil)
    }
    
}
