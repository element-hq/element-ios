// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
