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

/// Presenter for spaces contextual menu
class SpaceMenuPresenter: NSObject {
    
    // MARK: - Constants
    
    enum Actions {
        case exploreRooms
        case exploreMembers
    }
    
    // MARK: - Properties
    
    public weak var delegate: SpaceMenuPresenterDelegate?

    // MARK: Private
    
    private weak var presentingViewController: UIViewController?
    private var viewModel: SpaceMenuViewModel!
    private weak var sourceView: UIView?
    private lazy var slidingModalPresenter: SlidingModalPresenter = {
        return SlidingModalPresenter()
    }()
    private weak var selectedSpace: MXSpace?
    private var session: MXSession!
    private var spaceId: String!

    // MARK: - Public
    
    func present(forSpaceWithId spaceId: String,
                 from viewController: UIViewController,
                 sourceView: UIView?,
                 session: MXSession,
                 animated: Bool) {
        self.session = session
        self.spaceId = spaceId
        
        self.viewModel = SpaceMenuViewModel(session: session, spaceId: spaceId)
        self.viewModel.coordinatorDelegate = self
        self.presentingViewController = viewController
        self.sourceView = sourceView
        self.selectedSpace = session.spaceService.getSpace(withId: spaceId)
        
        self.showMenu(for: spaceId, session: session)
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        self.presentingViewController?.dismiss(animated: animated, completion: completion)
    }
    
    // MARK: - Private
    
    private func showMenu(for spaceId: String, session: MXSession) {
        let menuViewController = SpaceMenuViewController.instantiate(forSpaceWithId: spaceId, matrixSession: session, viewModel: self.viewModel)
        self.present(menuViewController, animated: true)
    }
    
    private func present(_ viewController: SpaceMenuViewController, animated: Bool) {
        
        if UIDevice.current.isPhone {
            guard let rootViewController = self.presentingViewController else {
                MXLog.error("[SpaceMenuPresenter] present no rootViewController found")
                return
            }

            slidingModalPresenter.present(viewController, from: rootViewController.presentedViewController ?? rootViewController, animated: true, completion: nil)
        } else {
            // Configure source view when view controller is presented with a popover
            viewController.modalPresentationStyle = .popover
            if let sourceView = self.sourceView, let popoverPresentationController = viewController.popoverPresentationController {
                popoverPresentationController.sourceView = sourceView
                popoverPresentationController.sourceRect = sourceView.bounds
            }

            self.presentingViewController?.present(viewController, animated: animated, completion: nil)
        }
    }
}

// MARK: - SpaceMenuModelViewModelCoordinatorDelegate

extension SpaceMenuPresenter: SpaceMenuModelViewModelCoordinatorDelegate {
    func spaceMenuViewModelDidDismiss(_ viewModel: SpaceMenuViewModelType) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func spaceMenuViewModel(_ viewModel: SpaceMenuViewModelType, didSelectItemWith action: SpaceMenuListItemAction) {
        switch action {
        case .leaveSpace: break
        case .exploreSpaceMembers:
            self.delegate?.spaceMenuPresenter(self, didCompleteWith: .exploreMembers, forSpaceWithId: self.spaceId, with: self.session)
        case .exploreSpaceRooms:
            self.delegate?.spaceMenuPresenter(self, didCompleteWith: .exploreRooms, forSpaceWithId: self.spaceId, with: self.session)
        default:
            MXLog.error("[SpaceMenuPresenter] spaceListViewModel didSelectItem: invalid action \(action)")
        }
    }
}

protocol SpaceMenuPresenterDelegate: AnyObject {
    func spaceMenuPresenter(_ presenter: SpaceMenuPresenter, didCompleteWith action: SpaceMenuPresenter.Actions, forSpaceWithId spaceId: String, with session: MXSession)
}
