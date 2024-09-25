/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

final class TemplateScreenViewModel: TemplateScreenViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    
    private var currentOperation: MXHTTPOperation?
    private var userDisplayName: String?
    
    // MARK: Public

    weak var viewDelegate: TemplateScreenViewModelViewDelegate?
    weak var coordinatorDelegate: TemplateScreenViewModelCoordinatorDelegate?
    
    private(set) var viewState: TemplateScreenViewState = .idle {
        didSet {
            self.viewDelegate?.templateScreenViewModel(self, didUpdateViewState: viewState)
        }
    }
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: TemplateScreenViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .complete:
            self.coordinatorDelegate?.templateScreenViewModel(self, didCompleteWithUserDisplayName: self.userDisplayName)
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.templateScreenViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {

        viewState = .loading

        // Check first that the user homeserver is federated with the  Riot-bot homeserver
        self.currentOperation = self.session.matrixRestClient.displayName(forUser: self.session.myUser.userId) { [weak self]  (response) in

            guard let self = self else {
                return
            }
            
            switch response {
            case .success(let userDisplayName):
                self.viewState = .loaded(userDisplayName)
                self.userDisplayName = userDisplayName
            case .failure(let error):
                self.viewState = .error(error)
            }
        }
    }
        
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}
