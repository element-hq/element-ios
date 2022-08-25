// File created from FlowTemplate
// $ createRootCoordinator.sh CreateRoom CreateRoom EnterNewRoomDetails
/*
 Copyright 2020 New Vector Ltd
 
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
        navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        let segmentedController = SegmentedController.instantiate()
        segmentedController.title = VectorL10n.spacesAddRoom
        tabRouter = SegmentedRouter(segmentedController: segmentedController)
        self.parameters = parameters
    }
    
    // MARK: - Public methods
    
    func start() {
        let createRoomCoordinator = createEnterNewRoomDetailsCoordinator()

        createRoomCoordinator.start()

        add(childCoordinator: createRoomCoordinator)

        if let parentSpace = parentSpace {
            let roomSelectionCoordinator = createRoomSelectorCoordinator(parentSpace: parentSpace)
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
            add(childCoordinator: roomSelectionCoordinator)
            tabRouter.tabs = [
                TabbedRouterTab(title: VectorL10n.newWord, icon: nil, module: createRoomCoordinator),
                TabbedRouterTab(title: VectorL10n.existing, icon: nil, module: roomSelectionCoordinator)
            ]
            navigationRouter.setRootModule(tabRouter)
            Analytics.shared.exploringSpace = parentSpace
        } else {
            navigationRouter.setRootModule(createRoomCoordinator)
        }
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createEnterNewRoomDetailsCoordinator() -> EnterNewRoomDetailsCoordinator {
        let coordinator = EnterNewRoomDetailsCoordinator(session: parameters.session, parentSpace: parentSpace)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createRoomSelectorCoordinator(parentSpace: MXSpace) -> MatrixItemChooserCoordinator {
        let paramaters = MatrixItemChooserCoordinatorParameters(session: parameters.session, viewProvider: AddRoomSelectorViewProvider(), itemsProcessor: AddRoomItemsProcessor(parentSpace: parentSpace))
        let coordinator = MatrixItemChooserCoordinator(parameters: paramaters)
        return coordinator
    }
}

// MARK: - EnterNewRoomDetailsCoordinatorDelegate

extension CreateRoomCoordinator: EnterNewRoomDetailsCoordinatorDelegate {
    func enterNewRoomDetailsCoordinator(_ coordinator: EnterNewRoomDetailsCoordinatorType, didCreateNewRoom room: MXRoom) {
        delegate?.createRoomCoordinator(self, didCreateNewRoom: room)
    }
    
    func enterNewRoomDetailsCoordinatorDidCancel(_ coordinator: EnterNewRoomDetailsCoordinatorType) {
        delegate?.createRoomCoordinatorDidCancel(self)
    }
}
