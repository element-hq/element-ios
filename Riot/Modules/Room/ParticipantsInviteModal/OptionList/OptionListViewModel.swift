// File created from ScreenTemplate
// $ createScreen.sh Room/ParticipantsInviteModal/OptionList OptionList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
