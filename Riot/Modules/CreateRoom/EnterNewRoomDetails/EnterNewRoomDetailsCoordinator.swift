// File created from ScreenTemplate
// $ createScreen.sh CreateRoom/EnterNewRoomDetails EnterNewRoomDetails
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

final class EnterNewRoomDetailsCoordinator: EnterNewRoomDetailsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let parentSpace: MXSpace?
    private var enterNewRoomDetailsViewModel: EnterNewRoomDetailsViewModelType
    private let enterNewRoomDetailsViewController: EnterNewRoomDetailsViewController
    
    private lazy var singleImagePickerPresenter: SingleImagePickerPresenter = {
        let presenter = SingleImagePickerPresenter(session: session)
        presenter.delegate = self
        return presenter
    }()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: EnterNewRoomDetailsCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, parentSpace: MXSpace?) {
        self.session = session
        self.parentSpace = parentSpace
        
        let enterNewRoomDetailsViewModel = EnterNewRoomDetailsViewModel(session: self.session, parentSpace: self.parentSpace)
        let enterNewRoomDetailsViewController = EnterNewRoomDetailsViewController.instantiate(with: enterNewRoomDetailsViewModel)
        self.enterNewRoomDetailsViewModel = enterNewRoomDetailsViewModel
        self.enterNewRoomDetailsViewController = enterNewRoomDetailsViewController
    }
    
    // MARK: - Public methods
    
    func start() {
        self.enterNewRoomDetailsViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.enterNewRoomDetailsViewController
    }
}

// MARK: - EnterNewRoomDetailsViewModelCoordinatorDelegate
extension EnterNewRoomDetailsCoordinator: EnterNewRoomDetailsViewModelCoordinatorDelegate {
    
    func enterNewRoomDetailsViewModel(_ viewModel: EnterNewRoomDetailsViewModelType, didCreateNewRoom room: MXRoom) {
        self.delegate?.enterNewRoomDetailsCoordinator(self, didCreateNewRoom: room)
    }
    
    func enterNewRoomDetailsViewModel(_ viewModel: EnterNewRoomDetailsViewModelType, didTapChooseAvatar sourceView: UIView) {
        singleImagePickerPresenter.present(from: toPresentable(), sourceView: sourceView, sourceRect: sourceView.bounds, animated: true)
    }
    
    func enterNewRoomDetailsViewModelDidCancel(_ viewModel: EnterNewRoomDetailsViewModelType) {
        self.delegate?.enterNewRoomDetailsCoordinatorDidCancel(self)
    }
}

extension EnterNewRoomDetailsCoordinator: SingleImagePickerPresenterDelegate {
    
    func singleImagePickerPresenter(_ presenter: SingleImagePickerPresenter, didSelectImageData imageData: Data, withUTI uti: MXKUTI?) {
        enterNewRoomDetailsViewModel.roomCreationParameters.userSelectedAvatar = UIImage(data: imageData)
        enterNewRoomDetailsViewModel.process(viewAction: .loadData)
        presenter.dismiss(animated: true, completion: nil)
    }
    
    func singleImagePickerPresenterDidCancel(_ presenter: SingleImagePickerPresenter) {
        presenter.dismiss(animated: true, completion: nil)
    }
    
}
