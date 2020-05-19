/*
 Copyright 2020 New Vector Ltd
 
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

final class TemplateScreenViewModel: TemplateScreenViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    
    private var currentOperation: MXHTTPOperation?
    private var userDisplayName: String?
    
    // MARK: Public

    weak var viewDelegate: TemplateScreenViewModelViewDelegate?
    weak var coordinatorDelegate: TemplateScreenViewModelCoordinatorDelegate?
    
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

        self.update(viewState: .loading)

        // Check first that the user homeserver is federated with the  Riot-bot homeserver
        self.currentOperation = self.session.matrixRestClient.displayName(forUser: self.session.myUser.userId) { [weak self]  (response) in

            guard let self = self else {
                return
            }
            
            switch response {
            case .success(let userDisplayName):
                self.update(viewState: .loaded(userDisplayName))
                self.userDisplayName = userDisplayName
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }
    
    private func update(viewState: TemplateScreenViewState) {
        self.viewDelegate?.templateScreenViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}
