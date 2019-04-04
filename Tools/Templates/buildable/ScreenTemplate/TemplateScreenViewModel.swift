/*
 Copyright 2019 New Vector Ltd
 
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
    
    // MARK: Public
    
    var message: String?

    weak var viewDelegate: TemplateScreenViewModelViewDelegate?
    weak var coordinatorDelegate: TemplateScreenViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        self.message = nil
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: TemplateScreenViewAction) {
        switch viewAction {
        case .sayHello:
            self.setupHelloMessage()
        case .complete:
            if let message = self.message {
            self.coordinatorDelegate?.templateScreenViewModel(self, didCompleteWithMessage: message)
            }
        case .cancel:
            self.coordinatorDelegate?.templateScreenViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func setupHelloMessage() {

        self.update(viewState: .loading)

        // Check first that the user homeserver is federated with the  Riot-bot homeserver
        self.session.matrixRestClient.displayName(forUser: self.session.myUser.userId) { [weak self]  (response) in

            guard let sself = self else {
                return
            }
            
            switch response {
            case .success:
                sself.message = "Hello \(response.value ?? "you")"
                sself.update(viewState: .loaded)
            case .failure(let error):
                sself.update(viewState: .error(error))
            }
        }
    }
    
    private func update(viewState: TemplateScreenViewState) {
        self.viewDelegate?.templateScreenViewModel(self, didUpdateViewState: viewState)
    }
}
