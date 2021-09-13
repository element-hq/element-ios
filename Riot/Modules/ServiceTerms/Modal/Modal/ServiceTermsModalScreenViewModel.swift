// File created from ScreenTemplate
// $ createScreen.sh Modal/Show ServiceTermsModalScreen
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

final class ServiceTermsModalScreenViewModel: ServiceTermsModalScreenViewModelType {

    // MARK: - Properties

    // MARK: Private

    private let serviceTerms: MXServiceTerms
    
    // MARK: Public

    var serviceUrl: String {
        return serviceTerms.baseUrl
    }
    var serviceType: MXServiceType {
        return serviceTerms.serviceType
    }
    var policies: [MXLoginPolicyData]?
    var alreadyAcceptedPoliciesUrls: [String] = []

    weak var viewDelegate: ServiceTermsModalScreenViewModelViewDelegate?
    weak var coordinatorDelegate: ServiceTermsModalScreenViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(serviceTerms: MXServiceTerms) {
        self.serviceTerms = serviceTerms
    }
    
    // MARK: - Public
    
    func process(viewAction: ServiceTermsModalScreenViewAction) {
        switch viewAction {
        case .load:
            self.loadTerms()
        case .display(let policy):
            self.coordinatorDelegate?.serviceTermsModalScreenViewModel(self, displayPolicy: policy)
        case .accept:
            self.acceptTerms()
        case .decline:
            self.coordinatorDelegate?.serviceTermsModalScreenViewModelDidDecline(self)
        }
    }
    
    // MARK: - Private

    private func loadTerms() {

        self.update(viewState: .loading)

        self.serviceTerms.terms({ [weak self] (terms, alreadyAcceptedTermsUrls) in
            guard let self = self else {
                return
            }

            let policies = self.processTerms(terms: terms)
            self.policies = policies
            self.alreadyAcceptedPoliciesUrls = alreadyAcceptedTermsUrls ?? []
            self.update(viewState: .loaded(policies: policies, alreadyAcceptedPoliciesUrls: self.alreadyAcceptedPoliciesUrls))

            }, failure: { [weak self] error in
                guard let self = self else {
                    return
                }

                self.update(viewState: .error(error))
        })
    }

    private func acceptTerms() {

        self.update(viewState: .loading)

        self.serviceTerms.agree(toTerms: self.termsUrls, success: { [weak self] in
            guard let self = self else {
                return
            }
            self.update(viewState: .accepted)
            
            // Send a notification to update the identity service immediately.
            if self.serviceTerms.serviceType == MXServiceTypeIdentityService {
                let userInfo = [MXIdentityServiceNotificationIdentityServerKey: self.serviceTerms.baseUrl]
                NotificationCenter.default.post(name: .MXIdentityServiceTermsAccepted, object: nil, userInfo: userInfo)
            }
            
            // Notify the delegate.
            self.coordinatorDelegate?.serviceTermsModalScreenViewModelDidAccept(self)

            }, failure: { [weak self] (error) in
                guard let self = self else {
                    return
                }

                self.update(viewState: .error(error))
        })
    }

    private func processTerms(terms: MXLoginTerms?) -> [MXLoginPolicyData] {
        if let policies = terms?.policiesData(forLanguage: Bundle.mxk_language(), defaultLanguage: Bundle.mxk_fallbackLanguage()) {
            return policies
        } else {
            MXLog.debug("[ServiceTermsModalScreenViewModel] processTerms: Error: No terms for \(String(describing: terms))")
            return []
        }
    }

    private var termsUrls: [String] {
        guard let policies = self.policies else {
            return []
        }
        return policies.map({ return $0.url })
    }

    private func update(viewState: ServiceTermsModalScreenViewState) {
        self.viewDelegate?.serviceTermsModalScreenViewModel(self, didUpdateViewState: viewState)
    }
}
