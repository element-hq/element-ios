// File created from FlowTemplate
// $ createRootCoordinator.sh Spaces/SpaceRoomList ExploreRoom ShowSpaceExploreRoom
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol ExploreRoomCoordinatorBridgePresenterDelegate {
    func exploreRoomCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: ExploreRoomCoordinatorBridgePresenter)
}

/// ExploreRoomCoordinatorBridgePresenter enables to start ExploreRoomCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers). Each bridge should be removed once the underlying Coordinator has
/// been integrated by another Coordinator.
@objcMembers
final class ExploreRoomCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let spaceId: String
    private var coordinator: ExploreRoomCoordinator?
    
    // MARK: Public
    
    weak var delegate: ExploreRoomCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String) {
        self.session = session
        self.spaceId = spaceId
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let exploreRoomCoordinator = ExploreRoomCoordinator(session: self.session, spaceId: self.spaceId)
        exploreRoomCoordinator.delegate = self
        let presentable = exploreRoomCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        viewController.present(presentable, animated: animated, completion: nil)
        exploreRoomCoordinator.start()
        
        self.coordinator = exploreRoomCoordinator
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
}

// MARK: - ExploreRoomCoordinatorDelegate
extension ExploreRoomCoordinatorBridgePresenter: ExploreRoomCoordinatorDelegate {
    func exploreRoomCoordinatorDidComplete(_ coordinator: ExploreRoomCoordinatorType) {
        self.delegate?.exploreRoomCoordinatorBridgePresenterDelegateDidComplete(self)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ExploreRoomCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.delegate?.exploreRoomCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
}
