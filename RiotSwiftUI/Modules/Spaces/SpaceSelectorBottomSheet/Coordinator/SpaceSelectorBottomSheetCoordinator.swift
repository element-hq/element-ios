//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum SpaceSelectorBottomSheetCoordinatorResult {
    case cancel
    case homeSelected
    case spaceSelected(_ item: SpaceSelectorListItemData)
    case createSpace(_ parentSpaceId: String?)
    case spaceJoined(_ spaceId: String)
}

struct SpaceSelectorBottomSheetCoordinatorParameters {
    let session: MXSession
    let selectedSpaceId: String?
    let showHomeSpace: Bool
    
    init(session: MXSession,
         selectedSpaceId: String? = nil,
         showHomeSpace: Bool = false) {
        self.session = session
        self.selectedSpaceId = selectedSpaceId
        self.showHomeSpace = showHomeSpace
    }
}

final class SpaceSelectorBottomSheetCoordinator: NSObject, Coordinator, Presentable {
    // MARK: - Properties
    
    private let parameters: SpaceSelectorBottomSheetCoordinatorParameters
    
    private let navigationRouter: NavigationRouterType
    private var spaceIdStack: [String]
    
    private weak var roomDetailCoordinator: SpaceChildRoomDetailCoordinator?

    // MARK: - Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((SpaceSelectorBottomSheetCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SpaceSelectorBottomSheetCoordinatorParameters,
         navigationRouter: NavigationRouterType = NavigationRouter(navigationController: RiotNavigationController())) {
        self.parameters = parameters
        self.navigationRouter = navigationRouter
        spaceIdStack = []
        
        super.init()
        
        setupNavigationRouter()
    }
    
    // MARK: - Public
    
    func start() {
        Analytics.shared.trackScreen(.spaceBottomSheet)
        push(createSpaceSelectorCoordinator(parentSpaceId: nil))
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
    }
    
    // MARK: - Private
    
    private func setupNavigationRouter() {
        guard #available(iOS 15.0, *) else { return }
        
        guard let sheetController = navigationRouter.toPresentable().sheetPresentationController else {
            MXLog.debug("[SpaceSelectorBottomSheetCoordinator] setup: no sheetPresentationController found")
            return
        }
        
        sheetController.detents = [.medium(), .large()]
        sheetController.prefersGrabberVisible = true
        sheetController.selectedDetentIdentifier = .medium
        sheetController.prefersScrollingExpandsWhenScrolledToEdge = true
        
        navigationRouter.toPresentable().presentationController?.delegate = self
    }

    private func push(_ coordinator: Coordinator & Presentable) {
        if navigationRouter.modules.isEmpty {
            navigationRouter.setRootModule(coordinator)
        } else {
            navigationRouter.push(coordinator.toPresentable(), animated: true) { [weak self] in
                guard let self = self else { return }
                
                self.remove(childCoordinator: coordinator)
                if coordinator is SpaceSelectorCoordinator {
                    self.spaceIdStack.removeLast()
                }
            }
        }
    }
    
    private func createSpaceSelectorCoordinator(parentSpaceId: String?) -> SpaceSelectorCoordinator {
        let parameters = SpaceSelectorCoordinatorParameters(session: parameters.session,
                                                            parentSpaceId: parentSpaceId,
                                                            selectedSpaceId: parameters.selectedSpaceId,
                                                            showHomeSpace: parameters.showHomeSpace,
                                                            showCancel: navigationRouter.modules.isEmpty)
        let coordinator = SpaceSelectorCoordinator(parameters: parameters)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel:
                self.completion?(.cancel)
            case .homeSelected:
                self.trackSpaceSelection(with: nil)
                self.completion?(.homeSelected)
            case .spaceSelected(let item):
                if item.isJoined {
                    self.trackSpaceSelection(with: item.id)
                    self.completion?(.spaceSelected(item))
                } else {
                    self.push(self.createSpaceDetailCoordinator(forSpaceWithId: item.id))
                }
            case .spaceDisclosure(let item):
                Analytics.shared.viewRoomTrigger = .spaceBottomSheet
                self.push(self.createSpaceSelectorCoordinator(parentSpaceId: item.id))
            case .createSpace(let parentSpaceId):
                self.completion?(.createSpace(parentSpaceId))
            }
        }
        
        coordinator.start()
        
        add(childCoordinator: coordinator)

        if let spaceId = parentSpaceId {
            spaceIdStack.append(spaceId)
        }
        
        return coordinator
    }
    
    private func createSpaceDetailCoordinator(forSpaceWithId spaceId: String) -> SpaceDetailCoordinator {
        let parameters = SpaceDetailCoordinatorParameters(spaceId: spaceId, session: parameters.session, showCancel: false)
        let coordinator = SpaceDetailCoordinator(parameters: parameters)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            
            self.remove(childCoordinator: coordinator)
            switch result {
            case .join:
                self.completion?(.spaceJoined(spaceId))
            case .open, .cancel, .dismiss:
                self.navigationRouter.popModule(animated: true)
            }
        }
        
        coordinator.start()
        
        add(childCoordinator: coordinator)

        return coordinator
    }
    
    private func trackSpaceSelection(with spaceId: String?) {
        guard parameters.selectedSpaceId != spaceId else {
            Analytics.shared.trackInteraction(.spacePanelSelectedSpace)
            return
        }
        
        if spaceIdStack.isEmpty {
            Analytics.shared.trackInteraction(.spacePanelSwitchSpace)
        } else {
            Analytics.shared.trackInteraction(.spacePanelSwitchSubSpace)
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension SpaceSelectorBottomSheetCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        completion?(.cancel)
    }
}
