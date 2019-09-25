// File created from ScreenTemplate
// $ createScreen.sh Test SettingsIdentityServer
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

enum SettingsIdentityServerViewModelError: Error {
    case missingIdentityServer
    case unknown
}

enum IdentityServerTermsStatus {
    case noTerms
    case terms(agreed: Bool)
}

enum IdentityServerValidity {
    case invalid
    case valid(status: IdentityServerTermsStatus)
}

final class SettingsIdentityServerViewModel: SettingsIdentityServerViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    
    private var validationIdentityService: MXIdentityService?
    private var validationServiceTerms: MXServiceTerms?
    
    // MARK: Public

    weak var viewDelegate: SettingsIdentityServerViewModelViewDelegate?
    var identityServer: String?

    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
    }
    
    // MARK: - Public
    
    func process(viewAction: SettingsIdentityServerViewAction) {
        switch viewAction {
        case .load:
            self.load()
        case .add(identityServer: let identityServer):
            self.addIdentityServer(identityServer)
        case .change(identityServer: let identityServer):
            self.changeIdentityServer(identityServer)
        case .disconnect:
            self.disconnect()
        }
    }
    
    // MARK: - Private
    
    private func load() {
        self.refreshIdentityServerViewState()
    }
    
    private func addIdentityServer(_ newIdentityServer: String) {
        
        self.update(viewState: .loading)
        
        self.checkIdentityServerValidity(identityServer: newIdentityServer) { (identityServerValidityResponse) in
            switch identityServerValidityResponse {
            case .success(let identityServerValidity):
                switch identityServerValidity {
                case .invalid:
                    // Present invalid IS alert
                    break
                case .valid(status: let termsStatus):
                    switch termsStatus {
                    case .noTerms:
                        // Present no terms alert
                        break
                    case .terms(agreed: let termsAgreed):
                        if termsAgreed {
                            self.updateAccountDataAndRefreshViewState(with: newIdentityServer)
                        } else {
                            // Present terms
                            break
                        }
                    }
                }
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }
    
    private func changeIdentityServer(_ newIdentityServer: String) {
        
    }
    
    private func disconnect() {
        
    }
    
    private func updateAccountDataAndRefreshViewState(with identityServer: String) {
        self.session.setAccountDataIdentityServer(identityServer, success: {
            self.refreshIdentityServerViewState()
        }, failure: { error in
            self.update(viewState: .error(error ?? SettingsIdentityServerViewModelError.unknown))
        })
    }
    
    private func refreshIdentityServerViewState() {
        if let identityService = self.session.identityService {
            let host = identityService.identityServer
            self.identityServer = host
            self.update(viewState: .loaded(displayMode: .identityServer(host: host)))
        } else {
            self.update(viewState: .loaded(displayMode: .noIdentityServer))
        }
    }
    
    private func checkExistingDataOnIdentityServer(completion: @escaping (_ response: MXResponse<Bool>) -> Void) {
        self.session.matrixRestClient.thirdPartyIdentifiers { (thirdPartyIDresponse) in
            switch thirdPartyIDresponse {
            case .success(let thirdPartyIdentifiers):
                if thirdPartyIdentifiers.isEmpty {
                    completion(.success(false))
                } else {
                    let mx3Pids = SettingsIdentityServerViewModel.threePids(from: thirdPartyIdentifiers)
                    self.isThreThreePidsDiscoverable(mx3Pids, completion: { discoverable3pidsResponse in
                        switch discoverable3pidsResponse {
                        case .success(let isThereDiscoverable3pids):
                            completion(.success(isThereDiscoverable3pids))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    })
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    @discardableResult
    private func isThreThreePidsDiscoverable(_ threePids: [MX3PID], completion: @escaping (_ response: MXResponse<Bool>) -> Void) -> MXHTTPOperation? {
        guard let identityService = self.session.identityService else {
            completion(.failure(SettingsIdentityServerViewModelError.missingIdentityServer))
            return nil
        }
        
        return identityService.lookup3PIDs(threePids) { lookupResponse in
            switch lookupResponse {
            case .success(let threePids):
                completion(.success(threePids.isEmpty == false))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func checkIdentityServerValidity(identityServer: String, completion: @escaping (_ response: MXResponse<IdentityServerValidity>) -> Void) {
        guard let identityServerURL = URL(string: identityServer) else {
            completion(.success(.invalid))
            return
        }        
        
        let restClient: MXRestClient = self.session.matrixRestClient
        
        let identityService = MXIdentityService(identityServer: identityServerURL, accessToken: nil, homeserverRestClient: restClient)
        
        identityService.accessToken { response in
            switch response {
            case .success(let accessToken):
                let serviceTerms = MXServiceTerms(baseUrl: identityService.identityServer, serviceType: MXServiceTypeIdentityService, matrixSession: self.session, accessToken: accessToken)
                
                serviceTerms.areAllTermsAgreed({ (areAllTermsAgreed) in
                    
                    completion(.success(IdentityServerValidity.valid(status: .terms(agreed: areAllTermsAgreed))))
                    
                    self.validationServiceTerms = nil
                }, failure: { error in
                    completion(.failure(error))
                    self.validationServiceTerms = nil
                })
                
                self.validationServiceTerms = serviceTerms
                
            case .failure(let error):
                completion(.failure(error))
            }
            
            self.validationIdentityService = nil
        }
        
        self.validationIdentityService = identityService
    }
    
    private func update(viewState: SettingsIdentityServerViewState) {
        self.viewDelegate?.settingsIdentityServerViewModel(self, didUpdateViewState: viewState)
    }
    
    private class func threePids(from thirdPartyIdentifiers: [MXThirdPartyIdentifier]) -> [MX3PID] {
        return thirdPartyIdentifiers.map({ (thirdPartyIdentifier) -> MX3PID in
            return MX3PID(medium: MX3PID.Medium(identifier: thirdPartyIdentifier.medium), address: thirdPartyIdentifier.address)
        })
    }
}
