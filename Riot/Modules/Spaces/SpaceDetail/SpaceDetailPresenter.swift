//
// Copyright 2021 New Vector Ltd
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

/// Presenter for space detail screen
class SpaceDetailPresenter: NSObject {
    // MARK: - Constants
    
    enum Actions {
        case exploreRooms
        case exploreMembers
    }
    
    // MARK: - Properties
    
    @objc public weak var delegate: SpaceDetailPresenterDelegate?

    // MARK: Private
    
    private weak var presentingViewController: UIViewController?
    private var viewModel: SpaceDetailViewModel!
    private weak var sourceView: UIView?
    private lazy var slidingModalPresenter = SlidingModalPresenter()

    private var session: MXSession!
    private var spaceId: String!
    private var senderId: String?

    // MARK: - Public
    
    @objc func present(forSpaceWithId spaceId: String,
                       from viewController: UIViewController,
                       sourceView: UIView?,
                       session: MXSession,
                       animated: Bool) {
        self.session = session
        self.spaceId = spaceId
        
        viewModel = SpaceDetailViewModel(session: session, spaceId: spaceId)
        viewModel.coordinatorDelegate = self
        presentingViewController = viewController
        self.sourceView = sourceView
        
        show(with: session)
    }
    
    @objc func present(forSpaceWithPublicRoom publicRoom: MXPublicRoom, senderId: String?,
                       from viewController: UIViewController,
                       sourceView: UIView?,
                       session: MXSession,
                       animated: Bool) {
        self.session = session
        spaceId = publicRoom.roomId
        self.senderId = senderId

        viewModel = SpaceDetailViewModel(session: session, publicRoom: publicRoom, senderId: senderId)
        viewModel.coordinatorDelegate = self
        presentingViewController = viewController
        self.sourceView = sourceView
        
        show(with: session)
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        presentingViewController?.dismiss(animated: animated, completion: completion)
    }
    
    // MARK: - Private
    
    private func show(with session: MXSession) {
        let viewController = SpaceDetailViewController.instantiate(mediaManager: session.mediaManager, viewModel: viewModel, showCancel: true)
        present(viewController, animated: true)
    }
    
    private func present(_ viewController: SpaceDetailViewController, animated: Bool) {
        guard let presentingViewController = presentingViewController?.presentedViewController ?? presentingViewController else {
            MXLog.error("[SpaceDetailPresenter] present no presentingViewController found")
            return
        }
        
        if UIDevice.current.isPhone {
            slidingModalPresenter.present(viewController, from: presentingViewController, animated: true, completion: nil)
        } else {
            // Configure source view when view controller is presented with a popover
            viewController.modalPresentationStyle = .popover
            if let popoverPresentationController = viewController.popoverPresentationController, let sourceView = sourceView ?? presentingViewController.view {
                popoverPresentationController.sourceView = sourceView
                popoverPresentationController.sourceRect = sourceView.bounds
            }

            self.presentingViewController?.present(viewController, animated: animated, completion: nil)
        }
    }
}

// MARK: - SpaceDetailModelViewModelCoordinatorDelegate

extension SpaceDetailPresenter: SpaceDetailModelViewModelCoordinatorDelegate {
    func spaceDetailViewModelDidJoin(_ viewModel: SpaceDetailViewModelType) {
        dismiss(animated: true) {
            self.delegate?.spaceDetailPresenter(self, didJoinSpaceWithId: self.spaceId)
        }
    }
    
    func spaceDetailViewModelDidOpen(_ viewModel: SpaceDetailViewModelType) {
        dismiss(animated: false) {
            self.delegate?.spaceDetailPresenter(self, didOpenSpaceWithId: self.spaceId)
        }
    }
    
    func spaceDetailViewModelDidCancel(_ viewModel: SpaceDetailViewModelType) {
        dismiss(animated: true, completion: nil)
    }
    
    func spaceDetailViewModelDidDismiss(_ viewModel: SpaceDetailViewModelType) {
        delegate?.spaceDetailPresenterDidComplete(self)
    }
}

@objc protocol SpaceDetailPresenterDelegate: AnyObject {
    func spaceDetailPresenterDidComplete(_ presenter: SpaceDetailPresenter)
    func spaceDetailPresenter(_ presenter: SpaceDetailPresenter, didJoinSpaceWithId spaceId: String)
    func spaceDetailPresenter(_ presenter: SpaceDetailPresenter, didOpenSpaceWithId spaceId: String)
}
