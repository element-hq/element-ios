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

final class OptionListViewModel: OptionListViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private

    private let title: String?
    private let options: [OptionListItemViewData]

    // MARK: Public

    weak var viewDelegate: OptionListViewModelViewDelegate?
    weak var coordinatorDelegate: OptionListViewModelCoordinatorDelegate?
    
    private(set) var viewState: OptionListViewState = .idle {
        didSet {
            self.viewDelegate?.optionListViewModel(self, didUpdateViewState: viewState)
        }
    }
    
    // MARK: - Setup
    
    init(title: String?, options: [OptionListItemViewData]) {
        self.title = title
        self.options = options
    }
    
    // MARK: - Public
    
    func process(viewAction: OptionListViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .selected(let index):
            self.coordinatorDelegate?.optionListViewModel(self, didSelectOptionAt: index)
        case .cancel:
            self.coordinatorDelegate?.optionListViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        self.viewState = .loaded(title, options)
    }
}
