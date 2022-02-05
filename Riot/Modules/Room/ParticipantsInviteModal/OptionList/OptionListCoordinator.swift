// File created from ScreenTemplate
// $ createScreen.sh Room/ParticipantsInviteModal/OptionList OptionList
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
