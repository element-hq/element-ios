// File created from ScreenTemplate
// $ createScreen.sh Modal/Save ServiceTermsModalSaveTermsScreen
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

final class ServiceTermsModalSaveTermsScreenViewModel: ServiceTermsModalSaveTermsScreenViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let serviceTerms: MXServiceTerms
    private let termsUrls: [String]
    private var operation: MXHTTPOperation?

    // MARK: Public

    weak var viewDelegate: ServiceTermsModalSaveTermsScreenViewModelViewDelegate?
    weak var coordinatorDelegate: ServiceTermsModalSaveTermsScreenViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(serviceTerms: MXServiceTerms, termsUrls: [String]) {
        self.serviceTerms = serviceTerms
        self.termsUrls = termsUrls
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: ServiceTermsModalSaveTermsScreenViewAction) {
        switch viewAction {
        case .save:
            self.saveTerms()
        case .cancel:
            self.coordinatorDelegate?.serviceTermsModalSaveTermsScreenViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func saveTerms() {

        self.update(viewState: .loading)

        self.operation = self.serviceTerms.agree(toTerms: self.termsUrls, success: { [weak self] in
            guard let self = self else {
                return
            }
            self.update(viewState: .loaded)
            self.coordinatorDelegate?.serviceTermsModalSaveTermsScreenViewModelDidComplete(self)

        }, failure: { [weak self] (error) in
            guard let self = self else {
                return
            }

            self.update(viewState: .error(error))
        })
    }
    
    private func update(viewState: ServiceTermsModalSaveTermsScreenViewState) {
        self.viewDelegate?.serviceTermsModalSaveTermsScreenViewModel(self, didUpdateViewState: viewState)
    }
}
