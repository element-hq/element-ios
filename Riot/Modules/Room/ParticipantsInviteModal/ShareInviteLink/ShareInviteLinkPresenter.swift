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

/// ShareInviteLinkPresenter enables to share room alias to someone else
@objcMembers
final class ShareInviteLinkPresenter: NSObject {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Private
    
    private weak var presentingViewController: UIViewController?
    private weak var sourceView: UIView?
    
    // MARK: - Public
    
    func present(for room: MXRoom,
                 from viewController: UIViewController,
                 sourceView: UIView?,
                 animated: Bool) {
        
        self.presentingViewController = viewController
        self.sourceView = sourceView
        
        self.shareInvite(from: room)
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        self.presentingViewController?.dismiss(animated: animated, completion: completion)
    }
    
    // MARK: - Private
    
    private func shareInvite(from room: MXRoom) {
        
        let shareText = self.buildShareText(with: room)
        
        // Set up activity view controller
        let activityItems: [Any] = [ shareText ]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        self.present(activityViewController, animated: true)
    }
    
    private func buildShareText(with room: MXRoom) -> String {
        let roomAliasOrId: String
        if let alias = room.summary?.aliases?.first {
            roomAliasOrId = alias
        } else {
            roomAliasOrId = room.matrixItemId
        }
        
        if room.summary?.roomType == .space {
            return VectorL10n.shareInviteLinkSpaceText(MXTools.permalink(toRoom: roomAliasOrId))
        } else {
            return VectorL10n.shareInviteLinkRoomText(MXTools.permalink(toRoom: roomAliasOrId))
        }
    }
    
    private func present(_ viewController: UIViewController, animated: Bool) {
        
        // Configure source view when view controller is presented with a popover
        if let sourceView = self.sourceView, let popoverPresentationController = viewController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceView.bounds
        }
        
        self.presentingViewController?.present(viewController, animated: animated, completion: nil)
    }
}
