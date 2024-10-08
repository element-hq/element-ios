/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol SpaceChildRoomDetailBridgePresenterDelegate {
    func spaceChildRoomDetailBridgePresenter(_ coordinator: SpaceChildRoomDetailBridgePresenter, didOpenRoomWith roomId: String)
    func spaceChildRoomDetailBridgePresenterDidCancel(_ coordinator: SpaceChildRoomDetailBridgePresenter)
}

/// SpaceChildRoomDetailBridgePresenter enables to start SpaceChildRoomDetailCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers). Each bridge should be removed once the underlying Coordinator has
/// been integrated by another Coordinator.
@objcMembers
final class SpaceChildRoomDetailBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let childInfo: MXSpaceChildInfo
    private var coordinator: SpaceChildRoomDetailCoordinator?
    private lazy var slidingModalPresenter: SlidingModalPresenter = {
        return SlidingModalPresenter()
    }()

    // MARK: Public
    
    weak var delegate: SpaceChildRoomDetailBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, childInfo: MXSpaceChildInfo) {
        self.session = session
        self.childInfo = childInfo
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, sourceView: UIView?, animated: Bool) {
        let coordinator = SpaceChildRoomDetailCoordinator(parameters: SpaceChildRoomDetailCoordinatorParameters(session: session, childInfo: childInfo))
        coordinator.delegate = self
        coordinator.start()
        
        self.coordinator = coordinator
        
        if UIDevice.current.isPhone || sourceView == nil {
            slidingModalPresenter.present(coordinator.toSlidingPresentable(), from: viewController, animated: animated, completion: nil)
        } else {
            let presentable = coordinator.toPresentable()
            presentable.modalPresentationStyle = .popover
            if let sourceView = sourceView, let popoverPresentationController = presentable.popoverPresentationController {
                popoverPresentationController.sourceView = sourceView
                popoverPresentationController.sourceRect = sourceView.bounds
            }

            viewController.present(presentable, animated: true)
        }
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

// MARK: - SpaceChildRoomDetailCoordinatorDelegate
extension SpaceChildRoomDetailBridgePresenter: SpaceChildRoomDetailCoordinatorDelegate {
    func spaceChildRoomDetailCoordinator(_ coordinator: SpaceChildRoomDetailCoordinatorType, didOpenRoomWith roomId: String) {
        delegate?.spaceChildRoomDetailBridgePresenter(self, didOpenRoomWith: roomId)
    }
    
    func spaceChildRoomDetailCoordinatorDidCancel(_ coordinator: SpaceChildRoomDetailCoordinatorType) {
        delegate?.spaceChildRoomDetailBridgePresenterDidCancel(self)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension SpaceChildRoomDetailBridgePresenter: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.spaceChildRoomDetailBridgePresenterDidCancel(self)
    }
}
