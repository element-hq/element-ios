// File created from ScreenTemplate
// $ createScreen.sh Modal/Load ServiceTermsModalLoadTermsScreen
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

final class ServiceTermsModalLoadTermsScreenViewModel: ServiceTermsModalLoadTermsScreenViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private var operation: MXHTTPOperation?

    //private let session: MXSession
    private let serviceTerms: MXServiceTerms
    
    // MARK: Public
    
    var message: String?

    weak var viewDelegate: ServiceTermsModalLoadTermsScreenViewModelViewDelegate?
    weak var coordinatorDelegate: ServiceTermsModalLoadTermsScreenViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(serviceTerms: MXServiceTerms) {
        self.serviceTerms = serviceTerms
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: ServiceTermsModalLoadTermsScreenViewAction) {
        switch viewAction {
        case .load:
            self.loadTerms()
        case .cancel:
            self.coordinatorDelegate?.serviceTermsModalLoadTermsScreenViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadTerms() {

        self.update(viewState: .loading)

        self.operation = self.serviceTerms.terms({ [weak self] terms in
            guard let self = self else {
                return
            }

            self.operation = nil
            self.update(viewState: .loaded)

            self.coordinatorDelegate?.serviceTermsModalLoadTermsScreenViewModel(self, didCompleteWithTerms: terms)

        }, failure: { [weak self] error in
            guard let self = self else {
                return
            }

            self.operation = nil
            self.update(viewState: .error(error))
        })
    }
    
    private func update(viewState: ServiceTermsModalLoadTermsScreenViewState) {
        self.viewDelegate?.serviceTermsModalLoadTermsScreenViewModel(self, didUpdateViewState: viewState)
    }
}
