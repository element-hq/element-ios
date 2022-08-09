// File created from ScreenTemplate
// $ createScreen.sh Rooms/ShowDirectory ShowDirectory
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

import Foundation
import UIKit

final class ShowDirectoryCoordinator: ShowDirectoryCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let dataSource: PublicRoomsDirectoryDataSource
    private var showDirectoryViewModel: ShowDirectoryViewModelType
    private let showDirectoryViewController: ShowDirectoryViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ShowDirectoryCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, dataSource: PublicRoomsDirectoryDataSource) {
        self.session = session
        self.dataSource = dataSource
        
        let showDirectoryViewModel = ShowDirectoryViewModel(session: self.session, dataSource: dataSource)
        let showDirectoryViewController = ShowDirectoryViewController.instantiate(with: showDirectoryViewModel)
        showDirectoryViewController.view.clipsToBounds = false
        self.showDirectoryViewModel = showDirectoryViewModel
        self.showDirectoryViewController = showDirectoryViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.showDirectoryViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.showDirectoryViewController
    }
    
    // MARK: - Private
    
    private func createDirectoryServerPickerViewController() -> DirectoryServerPickerViewController {
        let controller = DirectoryServerPickerViewController()
        controller.finalizeInit()
        let dataSource: MXKDirectoryServersDataSource = MXKDirectoryServersDataSource(matrixSession: session)
        dataSource.finalizeInitialization()
        dataSource.roomDirectoryServers = BuildSettings.publicRoomsDirectoryServers
        
        controller.display(with: dataSource) { [weak self] (cellData) in
            guard let self = self else { return }
            guard let cellData = cellData else { return }
            
            self.showDirectoryViewModel.updatePublicRoomsDataSource(with: cellData)
        }
        
        return controller
    }
}

// MARK: - ShowDirectoryViewModelCoordinatorDelegate
extension ShowDirectoryCoordinator: ShowDirectoryViewModelCoordinatorDelegate {
    func showDirectoryViewModel(_ viewModel: ShowDirectoryViewModelType, didSelectRoomWithIdOrAlias roomIdOrAlias: String) {
        self.delegate?.showDirectoryCoordinator(self, didSelectRoomWithIdOrAlias: roomIdOrAlias)
    }
    
    func showDirectoryViewModelDidSelect(_ viewModel: ShowDirectoryViewModelType, room: MXPublicRoom) {
        self.delegate?.showDirectoryCoordinator(self, didSelectRoom: room)
    }
    
    func showDirectoryViewModelDidTapCreateNewRoom(_ viewModel: ShowDirectoryViewModelType) {
        self.delegate?.showDirectoryCoordinatorDidTapCreateNewRoom(self)
    }
    
    func showDirectoryViewModelDidCancel(_ viewModel: ShowDirectoryViewModelType) {
        self.delegate?.showDirectoryCoordinatorDidCancel(self)
    }
    
    func showDirectoryViewModelWantsToShowDirectoryServerPicker(_ viewModel: ShowDirectoryViewModelType) {
        let controller = self.createDirectoryServerPickerViewController()
        self.delegate?.showDirectoryCoordinatorWantsToShow(self, viewController: controller)
    }
}
