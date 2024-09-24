// File created from ScreenTemplate
// $ createScreen.sh Room/ParticipantsInviteModal/OptionList OptionList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class OptionListCoordinator: OptionListCoordinatorProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: OptionListCoordinatorParameters
    private var optionListViewModel: OptionListViewModelProtocol
    private let optionListViewController: OptionListViewController
    private lazy var slidingModalPresenter: SlidingModalPresenter = SlidingModalPresenter()

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: OptionListCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: OptionListCoordinatorParameters) {
        self.parameters = parameters
        let optionListViewModel = OptionListViewModel(title: self.parameters.title, options: self.parameters.options)
        let optionListViewController = OptionListViewController.instantiate(with: optionListViewModel)
        self.optionListViewModel = optionListViewModel
        self.optionListViewController = optionListViewController
    }
    
    // MARK: - Public
    
    func start() {
        self.optionListViewModel.coordinatorDelegate = self
        
        if let rootViewController = self.parameters.navigationRouter?.toPresentable() {
            slidingModalPresenter.present(optionListViewController, from: rootViewController, animated: true, completion: nil)
        }
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        slidingModalPresenter.dismiss(animated: animated, completion: completion)
    }
    
    func toPresentable() -> UIViewController {
        return self.optionListViewController
    }
}

// MARK: - OptionListViewModelCoordinatorDelegate
extension OptionListCoordinator: OptionListViewModelCoordinatorDelegate {
    func optionListViewModel(_ viewModel: OptionListViewModelProtocol, didSelectOptionAt index: Int) {
        dismiss(animated: false) {
            self.delegate?.optionListCoordinator(self, didSelectOptionAt: index)
        }
    }
    
    func optionListViewModelDidCancel(_ viewModel: OptionListViewModelProtocol) {
        dismiss(animated: true) {
            self.delegate?.optionListCoordinatorDidCancel(self)
        }
    }
}
