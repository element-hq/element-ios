// File created from FlowTemplate
// $ createRootCoordinator.sh Spaces/SpaceMembers SpaceMemberList ShowSpaceMemberList
/*
 Copyright 2021 New Vector Ltd
 
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

@objc protocol SpaceMemberListCoordinatorBridgePresenterDelegate {
    func spaceMemberListCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: SpaceMemberListCoordinatorBridgePresenter)
}

/// SpaceMemberListCoordinatorBridgePresenter enables to start SpaceMemberListCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers). Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class SpaceMemberListCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let spaceId: String
    private var coordinator: SpaceMemberListCoordinator?
    
    // MARK: Public
    
    weak var delegate: SpaceMemberListCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String) {
        self.session = session
        self.spaceId = spaceId
        super.init()
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        let spaceMemberListCoordinator = SpaceMemberListCoordinator(session: self.session, spaceId: self.spaceId)
        spaceMemberListCoordinator.delegate = self
        let presentable = spaceMemberListCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        viewController.present(presentable, animated: animated, completion: nil)
        spaceMemberListCoordinator.start()
        
        self.coordinator = spaceMemberListCoordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
    
    // MARK: - Private
    
    func navigate(to member: MXRoomMember, from sourceView: UIView?) {
        self.coordinator?.presentMemberDetail(with: member, from: sourceView)
    }
}

// MARK: - SpaceMemberListCoordinatorDelegate
extension SpaceMemberListCoordinatorBridgePresenter: SpaceMemberListCoordinatorDelegate {
    func spaceMemberListCoordinatorDidCancel(_ coordinator: SpaceMemberListCoordinatorType) {
        self.delegate?.spaceMemberListCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
    func spaceMemberListCoordinator(_ coordinator: SpaceMemberListCoordinatorType, didSelect member: MXRoomMember, from sourceView: UIView?) {
        self.navigate(to: member, from: sourceView)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension SpaceMemberListCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    
    func spaceMemberListCoordinatorDidComplete(_ presentationController: UIPresentationController) {
        self.delegate?.spaceMemberListCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
}
