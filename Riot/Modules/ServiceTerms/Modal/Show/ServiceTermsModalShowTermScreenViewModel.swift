// File created from ScreenTemplate
// $ createScreen.sh Modal/Show ServiceTermsModalShowTermScreen
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

final class ServiceTermsModalShowTermScreenViewModel: ServiceTermsModalShowTermScreenViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    // MARK: Public
    
    var policy: MXLoginPolicyData
    var progress: Progress

    weak var viewDelegate: ServiceTermsModalShowTermScreenViewModelViewDelegate?
    weak var coordinatorDelegate: ServiceTermsModalShowTermScreenViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(policy: MXLoginPolicyData, progress: Progress) {
        self.policy = policy
        self.progress = progress
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: ServiceTermsModalShowTermScreenViewAction) {
        switch viewAction {
        case .load:
            self.loadData()
        case .accept:
            self.coordinatorDelegate?.serviceTermsModalShowTermScreenViewModel(self, didAcceptPolicy: self.policy)
        case .decline:
            self.coordinatorDelegate?.serviceTermsModalShowTermScreenViewModelDidDecline(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        // The data is quite static on this screen
        self.update(viewState: .loaded(self.policy))
    }
    
    private func update(viewState: ServiceTermsModalShowTermScreenViewState) {
        self.viewDelegate?.serviceTermsModalShowTermScreenViewModel(self, didUpdateViewState: viewState)
    }
}
