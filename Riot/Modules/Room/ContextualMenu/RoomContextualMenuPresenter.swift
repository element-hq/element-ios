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
    
    private enum AnimationDurations {
        static let showMenu: TimeInterval = 0.15
        static let showMenuFromSingleTap: TimeInterval = 0.1
        static let hideMenu: TimeInterval = 0.2
        static let selectedReaction: TimeInterval = 0.15
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private weak var roomContextualMenuViewController: RoomContextualMenuViewController?
    
    // MARK: Public
    
    var isPresenting: Bool {
        return self.roomContextualMenuViewController?.parent != nil
    }
    
    // MARK: - Public

    func present(roomContextualMenuViewController: RoomContextualMenuViewController,
                 from viewController: UIViewController,
                 on view: UIView,
                 contentToReactFrame: CGRect, // Not nullable for compatibility with Obj-C
                 fromSingleTapGesture usedSingleTapGesture: Bool,
                 animated: Bool,
                 completion: (() -> Void)?) {
        guard self.isPresenting == false else {
            return
        }
        
        viewController.vc_addChildViewController(viewController: roomContextualMenuViewController, onView: view)
        
        self.roomContextualMenuViewController = roomContextualMenuViewController
        
        roomContextualMenuViewController.contentToReactFrame = contentToReactFrame
        
        roomContextualMenuViewController.hideMenuToolbar()
        roomContextualMenuViewController.prepareReactionsMenuAnimations()
        roomContextualMenuViewController.hideReactionsMenu()
        
        roomContextualMenuViewController.view.layoutIfNeeded()
        
        let animationInstructions: (() -> Void) = {
            roomContextualMenuViewController.showMenuToolbar()
            roomContextualMenuViewController.showReactionsMenu()
            roomContextualMenuViewController.view.layoutIfNeeded()
        }
        
        if animated {
            let animationDuration = usedSingleTapGesture ? AnimationDurations.showMenuFromSingleTap : AnimationDurations.showMenu
            
            UIView.animate(withDuration: animationDuration, animations: {
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
        guard let roomContextualMenuViewController = self.roomContextualMenuViewController, self.isPresenting else {
            completion?()
            return
        }
        
        let animationInstructions: (() -> Void) = {
            roomContextualMenuViewController.hideMenuToolbar()
            roomContextualMenuViewController.hideReactionsMenu()
            roomContextualMenuViewController.view.layoutIfNeeded()
        }
        
        let animationCompletionInstructions: (() -> Void) = {
            roomContextualMenuViewController.vc_removeFromParent()
            self.roomContextualMenuViewController = nil
            completion?()
        }
        
        if animated {
            if roomContextualMenuViewController.shouldPerformTappedReactionAnimation {
                UIView.animate(withDuration: AnimationDurations.selectedReaction, animations: {
                    roomContextualMenuViewController.selectedReactionAnimationsIntructionsPart1()
                }, completion: { _ in
                    UIView.animate(withDuration: AnimationDurations.hideMenu, animations: {
                        roomContextualMenuViewController.selectedReactionAnimationsIntructionsPart2()
                        animationInstructions()
                    }, completion: { completed in
                        animationCompletionInstructions()
                    })
                })
            } else {
                UIView.animate(withDuration: AnimationDurations.hideMenu, animations: {
                    animationInstructions()
                }, completion: { completed in
                    animationCompletionInstructions()
                })
            }
        } else {
            animationInstructions()
            animationCompletionInstructions()
        }
    }
}
