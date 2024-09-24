// File created from ScreenTemplate
// $ createScreen.sh Room/ParticipantsInviteModal/OptionList OptionList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol OptionListViewModelViewDelegate: AnyObject {
    func optionListViewModel(_ viewModel: OptionListViewModelProtocol, didUpdateViewState viewSate: OptionListViewState)
}

protocol OptionListViewModelCoordinatorDelegate: AnyObject {
    func optionListViewModel(_ viewModel: OptionListViewModelProtocol, didSelectOptionAt index: Int)
    func optionListViewModelDidCancel(_ viewModel: OptionListViewModelProtocol)
}

/// Protocol describing the view model used by `OptionListViewController`
protocol OptionListViewModelProtocol {        
        
    var viewDelegate: OptionListViewModelViewDelegate? { get set }
    var coordinatorDelegate: OptionListViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: OptionListViewAction)
    
    var viewState: OptionListViewState { get }
}
