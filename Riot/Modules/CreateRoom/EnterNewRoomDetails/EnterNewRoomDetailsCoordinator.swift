// File created from ScreenTemplate
// $ createScreen.sh CreateRoom/EnterNewRoomDetails EnterNewRoomDetails
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
