// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/SpaceChildRoomDetail ShowSpaceChildRoomDetail
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
import UIKit

final class ShowSpaceChildRoomDetailCoordinator: ShowSpaceChildRoomDetailCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let childInfo: MXSpaceChildInfo
    private var showSpaceChildRoomDetailViewModel: ShowSpaceChildRoomDetailViewModelType
    private let showSpaceChildRoomDetailViewController: ShowSpaceChildRoomDetailViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ShowSpaceChildRoomDetailCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, childInfo: MXSpaceChildInfo) {
        self.session = session
        self.childInfo = childInfo
        
        let showSpaceChildRoomDetailViewModel = ShowSpaceChildRoomDetailViewModel(session: self.session, childInfo: childInfo)
        let showSpaceChildRoomDetailViewController = ShowSpaceChildRoomDetailViewController.instantiate(with: showSpaceChildRoomDetailViewModel)
        self.showSpaceChildRoomDetailViewModel = showSpaceChildRoomDetailViewModel
        self.showSpaceChildRoomDetailViewController = showSpaceChildRoomDetailViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.showSpaceChildRoomDetailViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.showSpaceChildRoomDetailViewController
    }
    
    func toSlidingPresentable() -> UIViewController & SlidingModalPresentable {
        return self.showSpaceChildRoomDetailViewController
    }
}

// MARK: - ShowSpaceChildRoomDetailViewModelCoordinatorDelegate
extension ShowSpaceChildRoomDetailCoordinator: ShowSpaceChildRoomDetailViewModelCoordinatorDelegate {
    func showSpaceChildRoomDetailViewModelDidComplete(_ viewModel: ShowSpaceChildRoomDetailViewModelType) {
        self.delegate?.showSpaceChildRoomDetailCoordinatorDidComplete(self)
    }
    
    func showSpaceChildRoomDetailViewModelDidCancel(_ viewModel: ShowSpaceChildRoomDetailViewModelType) {
        self.delegate?.showSpaceChildRoomDetailCoordinatorDidCancel(self)
    }
}
