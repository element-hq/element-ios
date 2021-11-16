// File created from ScreenTemplate
// $ createScreen.sh Threads/ThreadList ThreadList
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

final class ThreadListViewModel: ThreadListViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    
    private var currentOperation: MXHTTPOperation?
    private var userDisplayName: String?
    
    // MARK: Public

    weak var viewDelegate: ThreadListViewModelViewDelegate?
    weak var coordinatorDelegate: ThreadListViewModelCoordinatorDelegate?
    
    private(set) var viewState: ThreadListViewState = .idle {
        didSet {
            self.viewDelegate?.threadListViewModel(self, didUpdateViewState: viewState)
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
    
    func process(viewAction: ThreadListViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .complete:
            self.coordinatorDelegate?.threadListViewModel(self, didCompleteWithUserDisplayName: self.userDisplayName)
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.threadListViewModelDidCancel(self)
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
