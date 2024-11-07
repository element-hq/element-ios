/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol TemplateScreenViewModelViewDelegate: AnyObject {
    func templateScreenViewModel(_ viewModel: TemplateScreenViewModelProtocol, didUpdateViewState viewSate: TemplateScreenViewState)
}

protocol TemplateScreenViewModelCoordinatorDelegate: AnyObject {
    func templateScreenViewModel(_ viewModel: TemplateScreenViewModelProtocol, didCompleteWithUserDisplayName userDisplayName: String?)
    func templateScreenViewModelDidCancel(_ viewModel: TemplateScreenViewModelProtocol)
}

/// Protocol describing the view model used by `TemplateScreenViewController`
protocol TemplateScreenViewModelProtocol {        
        
    var viewDelegate: TemplateScreenViewModelViewDelegate? { get set }
    var coordinatorDelegate: TemplateScreenViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: TemplateScreenViewAction)
    
    var viewState: TemplateScreenViewState { get }
}
