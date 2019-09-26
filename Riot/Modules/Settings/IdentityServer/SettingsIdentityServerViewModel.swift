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
    
    private var identityService: MXIdentityService?
    private var serviceTerms: MXServiceTerms?
    
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
            print("[SettingsIdentityServerViewModel] addIdentityServer: \(newIdentityServer). Validity: \(identityServerValidityResponse)")

            switch identityServerValidityResponse {
            case .success(let identityServerValidity):
                switch identityServerValidity {
                case .invalid:
                    // Present invalid IS alert
                    self.update(viewState: .alert(alert: SettingsIdentityServerAlert.addActionAlert(.invalidIdentityServer(newHost: newIdentityServer)), onContinue: {}))
                case .valid(status: let termsStatus):
                    switch termsStatus {
                    case .noTerms:
                        self.update(viewState: .alert(alert: SettingsIdentityServerAlert.addActionAlert(.noTerms(newHost: newIdentityServer)), onContinue: {
                            self.update(viewState: .loading)
                            self.updateIdentityServerAndRefreshViewState(with: newIdentityServer)
                        }))
                    case .terms(agreed: let termsAgreed):
                        if termsAgreed {
                            self.updateIdentityServerAndRefreshViewState(with: newIdentityServer)
                        } else {
                            guard let accessToken = self.session.matrixRestClient.credentials.accessToken else {
                                print("[SettingsIdentityServerViewModel] addIdentityServer: Error: No access token")
                                self.update(viewState: .error(SettingsIdentityServerViewModelError.unknown))
                                return
                            }

                            // Present terms
                            self.update(viewState: .presentTerms(session: self.session, accessToken: accessToken, baseUrl: newIdentityServer, onComplete: { (areTermsAccepted) in
                                if areTermsAccepted {
                                    self.updateIdentityServerAndRefreshViewState(with: newIdentityServer)
                                } else {
                                    self.update(viewState: .alert(alert: SettingsIdentityServerAlert.addActionAlert(.termsNotAccepted(newHost: newIdentityServer)), onContinue: {}))
                                }
                            }))
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
        guard let identityServer = self.identityServer else {
            return
        }

        self.update(viewState: .loading)

        self.checkExistingDataOnIdentityServer { (response) in
            switch response {
            case .success(let existingData):
                if existingData {
                    self.update(viewState: .alert(alert: SettingsIdentityServerAlert.disconnectActionAlert(.stillSharing3Pids(oldHost: identityServer)), onContinue: {
                        self.disconnect2()
                    }))
                } else {
                    self.update(viewState: .alert(alert: SettingsIdentityServerAlert.disconnectActionAlert(.doubleConfirmation(oldHost: identityServer)), onContinue: {
                        self.disconnect2()
                    }))
                }
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }

    private func disconnect2() {
        self.update(viewState: .loading)

        // TODO: Make a /account/logout request

        self.updateIdentityServerAndRefreshViewState(with: nil)
    }
    
    private func updateIdentityServerAndRefreshViewState(with identityServer: String?) {
        self.accessToken(identityServer: identityServer) { (response) in
            switch response {
            case .success(let accessToken):
                self.session.setIdentityServer(identityServer, andAccessToken: accessToken)

                self.session.setAccountDataIdentityServer(identityServer, success: {
                    self.refreshIdentityServerViewState()
                }, failure: { error in
                    self.update(viewState: .error(error ?? SettingsIdentityServerViewModelError.unknown))
                })
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
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
                    self.areThereThreePidsDiscoverable(mx3Pids, completion: { discoverable3pidsResponse in
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

    private func accessToken(identityServer: String?, completion: @escaping (_ response: MXResponse<String?>) -> Void) {
        guard let identityServer = identityServer, let identityServerURL = URL(string: identityServer) else {
            completion(.success(nil))
            return
        }

        let restClient: MXRestClient = self.session.matrixRestClient
        let identityService = MXIdentityService(identityServer: identityServerURL, accessToken: nil, homeserverRestClient: restClient)

        identityService.accessToken { (response) in
            self.identityService = nil
            completion(response)
        }

        self.identityService = identityService
    }
    
    @discardableResult
    private func areThereThreePidsDiscoverable(_ threePids: [MX3PID], completion: @escaping (_ response: MXResponse<Bool>) -> Void) -> MXHTTPOperation? {
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

        // First, check the server
        identityService.pingIdentityServer { response in
            self.identityService = nil

            switch response {
            case .success:
                // Them, check if there are terms to accept
                let serviceTerms = MXServiceTerms(baseUrl: identityService.identityServer, serviceType: MXServiceTypeIdentityService, matrixSession: self.session, accessToken: nil)

                serviceTerms.areAllTermsAgreed({ (agreedTermsProgress) in
                    self.serviceTerms = nil

                    if agreedTermsProgress.totalUnitCount == 0 {
                        completion(.success(IdentityServerValidity.valid(status: .noTerms)))
                    } else {
                        completion(.success(IdentityServerValidity.valid(status: .terms(agreed: agreedTermsProgress.isFinished))))
                    }

                }, failure: { (error) in
                    self.serviceTerms = nil
                    completion(.failure(error))
                })

                self.serviceTerms = serviceTerms

            case .failure(let error):
                guard let nsError = error as NSError? else {
                    completion(.failure(error))
                    return
                }

                if nsError.domain == MXIdentityServerRestClientErrorDomain
                    || (nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCannotFindHost) {
                    completion(.success(.invalid))
                } else {
                    completion(.failure(error))
                }
            }
        }

        self.identityService = identityService
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
