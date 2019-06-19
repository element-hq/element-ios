/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

@objcMembers
final class RoomContextualMenuPresenter: NSObject {
    
    // MARK: - Constants
    
    private enum Constants {
        static let animationDuration: TimeInterval = 0.3
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private weak var roomContextualMenuViewController: RoomContextualMenuViewController?
    
    // MARK: Public
    
    var isPresenting: Bool {
        return self.roomContextualMenuViewController != nil
    }
    
    // MARK: - Public
        
    func present(roomContextualMenuViewController: RoomContextualMenuViewController,
                 from viewController: UIViewController,
                 on view: UIView,
                 animated: Bool,
                 completion: (() -> Void)?) {
        guard self.roomContextualMenuViewController == nil else {
            return
        }
        
        roomContextualMenuViewController.view.alpha = 0
        
        viewController.vc_addChildViewController(viewController: roomContextualMenuViewController, onView: view)
        
        self.roomContextualMenuViewController = roomContextualMenuViewController
        
        roomContextualMenuViewController.hideMenuToolbar()
        roomContextualMenuViewController.view.layoutIfNeeded()
        
        let animationInstructions: (() -> Void) = {
            roomContextualMenuViewController.showMenuToolbar()
            roomContextualMenuViewController.view.alpha = 1
            roomContextualMenuViewController.view.layoutIfNeeded()
        }
        
        if animated {
            UIView.animate(withDuration: Constants.animationDuration, animations: {
                animationInstructions()
            }, completion: { completed in
                completion?()
            })
        } else {
            animationInstructions()
            completion?()
        }
    }
    
    func hideContextualMenu(animated: Bool, completion: (() -> Void)?) {
        guard let roomContextualMenuViewController = self.roomContextualMenuViewController else {
            return
        }
        
        let animationInstructions: (() -> Void) = {
            roomContextualMenuViewController.hideMenuToolbar()
            roomContextualMenuViewController.view.alpha = 0
            roomContextualMenuViewController.view.layoutIfNeeded()
        }
        
        let animationCompletionInstructions: (() -> Void) = {
            roomContextualMenuViewController.vc_removeFromParent()

            // TODO: To remove once the retain cycle caused by reactionsMenuViewModel is fixed
            self.roomContextualMenuViewController = nil

            completion?()
        }
        
        if animated {
            UIView.animate(withDuration: Constants.animationDuration, animations: {
                animationInstructions()
            }, completion: { completed in
                animationCompletionInstructions()
            })
        } else {
            animationInstructions()
            animationCompletionInstructions()
        }
    }
    
    func showReactionsMenu(reactionsMenuViewModel: ReactionsMenuViewModel, aroundFrame frame: CGRect) {
        self.roomContextualMenuViewController?.showReactionsMenu(withViewModel: reactionsMenuViewModel, aroundFrame: frame)
    }
}
