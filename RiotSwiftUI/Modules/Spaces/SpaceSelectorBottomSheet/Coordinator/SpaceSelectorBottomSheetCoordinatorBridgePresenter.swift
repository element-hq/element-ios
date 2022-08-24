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

import Foundation

@objc protocol SpaceSelectorBottomSheetCoordinatorBridgePresenterDelegate {
    func spaceSelectorBottomSheetCoordinatorBridgePresenterDidCancel(_ coordinatorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter)
    func spaceSelectorBottomSheetCoordinatorBridgePresenterDidSelectHome(_ coordinatorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter)
    func spaceSelectorBottomSheetCoordinatorBridgePresenter(_ coordinatorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter, didSelectSpaceWithId spaceId: String)
    func spaceSelectorBottomSheetCoordinatorBridgePresenter(_ coordinatorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter, didCreateSpaceWithinSpaceWithId parentSpaceId: String?)
}

/// `SpaceSelectorBottomSheetCoordinatorBridgePresenter` enables to start `SpaceSelectorBottomSheetCoordinator` from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class SpaceSelectorBottomSheetCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let selectedSpaceId: String?
    private let showHomeSpace: Bool
    private var coordinator: SpaceSelectorBottomSheetCoordinator?
    
    // MARK: Public
    
    weak var delegate: SpaceSelectorBottomSheetCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, selectedSpaceId: String?, showHomeSpace: Bool) {
        self.session = session
        self.selectedSpaceId = selectedSpaceId
        self.showHomeSpace = showHomeSpace
        
        super.init()
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        let parameters = SpaceSelectorBottomSheetCoordinatorParameters(session: session, selectedSpaceId: selectedSpaceId, showHomeSpace: showHomeSpace)
        let coordinator = SpaceSelectorBottomSheetCoordinator(parameters: parameters)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel:
                self.delegate?.spaceSelectorBottomSheetCoordinatorBridgePresenterDidCancel(self)
            case .homeSelected:
                self.delegate?.spaceSelectorBottomSheetCoordinatorBridgePresenterDidSelectHome(self)
            case .spaceSelected(let item):
                self.delegate?.spaceSelectorBottomSheetCoordinatorBridgePresenter(self, didSelectSpaceWithId: item.id)
            case .createSpace(let parentSpaceId):
                self.delegate?.spaceSelectorBottomSheetCoordinatorBridgePresenter(self, didCreateSpaceWithinSpaceWithId: parentSpaceId)
            case .spaceJoined(let spaceId):
                self.delegate?.spaceSelectorBottomSheetCoordinatorBridgePresenter(self, didSelectSpaceWithId: spaceId)
            }
        }
        let presentable = coordinator.toPresentable()
        viewController.present(presentable, animated: animated, completion: nil)
        coordinator.start()
        
        self.coordinator = coordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            completion?()
        }
    }
}

