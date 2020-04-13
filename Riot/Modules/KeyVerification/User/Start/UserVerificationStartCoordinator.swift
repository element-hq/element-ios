// File created from ScreenTemplate
// $ createScreen.sh Start UserVerificationStart
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

final class UserVerificationStartCoordinator: UserVerificationStartCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let roomMember: MXRoomMember
    
    private var userVerificationStartViewModel: UserVerificationStartViewModelType
    private let userVerificationStartViewController: UserVerificationStartViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: UserVerificationStartCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, roomMember: MXRoomMember) {
        self.session = session
        self.roomMember = roomMember
        
        let userVerificationStartViewModel = UserVerificationStartViewModel(session: self.session, roomMember: self.roomMember)
        let userVerificationStartViewController = UserVerificationStartViewController.instantiate(with: userVerificationStartViewModel)
        self.userVerificationStartViewModel = userVerificationStartViewModel
        self.userVerificationStartViewController = userVerificationStartViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.userVerificationStartViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.userVerificationStartViewController
    }
}

// MARK: - UserVerificationStartViewModelCoordinatorDelegate
extension UserVerificationStartCoordinator: UserVerificationStartViewModelCoordinatorDelegate {
    
    func userVerificationStartViewModel(_ viewModel: UserVerificationStartViewModelType, otherDidAcceptRequest request: MXKeyVerificationRequest) {
        self.delegate?.userVerificationStartCoordinator(self, otherDidAcceptRequest: request)
    }
    
    func userVerificationStartViewModelDidCancel(_ viewModel: UserVerificationStartViewModelType) {
        self.delegate?.userVerificationStartCoordinatorDidCancel(self)
    }
}
