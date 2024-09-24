// File created from FlowTemplate
// $ createRootCoordinator.sh CreateRoom CreateRoom EnterNewRoomDetails
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import UIKit

@objcMembers
class CreateRoomCoordinatorParameter: NSObject {
    /// Instance of the current MXSession
    let session: MXSession
    
    /// Instance of the parent space. `nil` if home space
    let parentSpace: MXSpace?
    
    init(session: MXSession,
         parentSpace: MXSpace?) {
        self.session = session
        self.parentSpace = parentSpace
    }
}

@objcMembers
final class CreateRoomCoordinator: CreateRoomCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let tabRouter: TabbedRouterType
    private let parameters: CreateRoomCoordinatorParameter
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: CreateRoomCoordinatorDelegate?
    
    var parentSpace: MXSpace? {
        parameters.parentSpace
    }
    
    // MARK: - Setup
    
    init(parameters: CreateRoomCoordinatorParameter) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        let segmentedController = SegmentedController.instantiate()
        segmentedController.title = VectorL10n.spacesAddRoom
        self.tabRouter = SegmentedRouter(segmentedController: segmentedController)
        self.parameters = parameters
    }
    
    // MARK: - Public methods
    
    func start() {

        let createRoomCoordinator = self.createEnterNewRoomDetailsCoordinator()

        createRoomCoordinator.start()

        self.add(childCoordinator: createRoomCoordinator)

        if let parentSpace = self.parentSpace {
            let roomSelectionCoordinator = self.createRoomSelectorCoordinator(parentSpace: parentSpace)
            roomSelectionCoordinator.completion = { [weak self] result in
                guard let self = self else {
                    return
                }
                
                switch result {
                case .done(let selectedItemIds):
                    self.delegate?.createRoomCoordinator(self, didAddRoomsWithIds: selectedItemIds)
                default:
                    self.delegate?.createRoomCoordinatorDidCancel(self)
                }
            }
            roomSelectionCoordinator.start()
            self.add(childCoordinator: roomSelectionCoordinator)
            self.tabRouter.tabs = [
                TabbedRouterTab(title: VectorL10n.newWord, icon: nil, module: createRoomCoordinator),
                TabbedRouterTab(title: VectorL10n.existing, icon: nil, module: roomSelectionCoordinator)
            ]
            self.navigationRouter.setRootModule(self.tabRouter)
            Analytics.shared.exploringSpace = parentSpace
        } else {
            self.navigationRouter.setRootModule(createRoomCoordinator)
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createEnterNewRoomDetailsCoordinator() -> EnterNewRoomDetailsCoordinator {
        let coordinator = EnterNewRoomDetailsCoordinator(session: self.parameters.session, parentSpace: self.parentSpace)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createRoomSelectorCoordinator(parentSpace: MXSpace) -> MatrixItemChooserCoordinator {
        let paramaters = MatrixItemChooserCoordinatorParameters(session: self.parameters.session, viewProvider: AddRoomSelectorViewProvider(), itemsProcessor: AddRoomItemsProcessor(parentSpace: parentSpace))
        let coordinator = MatrixItemChooserCoordinator(parameters: paramaters)
        return coordinator
    }
}

// MARK: - EnterNewRoomDetailsCoordinatorDelegate
extension CreateRoomCoordinator: EnterNewRoomDetailsCoordinatorDelegate {
    
    func enterNewRoomDetailsCoordinator(_ coordinator: EnterNewRoomDetailsCoordinatorType, didCreateNewRoom room: MXRoom) {
        self.delegate?.createRoomCoordinator(self, didCreateNewRoom: room)
    }
    
    func enterNewRoomDetailsCoordinatorDidCancel(_ coordinator: EnterNewRoomDetailsCoordinatorType) {
        self.delegate?.createRoomCoordinatorDidCancel(self)
    }
}
