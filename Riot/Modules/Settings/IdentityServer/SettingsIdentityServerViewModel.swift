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
    
    // MARK: - Private -
    // MARK: - Actions
    
    private func load() {
        self.refreshIdentityServerViewState()
    }


    // MARK: Add IS

    private func addIdentityServer(_ newIdentityServer: String) {
        self.checkCanAddIdentityServer(newIdentityServer: newIdentityServer,
                                       viewStateUpdate: { (viewState) in
                                        self.update(viewState: viewState)
        },
                                       canAddcompletion: {
                                        self.updateIdentityServerAndRefreshViewState(with: newIdentityServer)
        })
    }

    private func checkCanAddIdentityServer(newIdentityServer: String,
                                           viewStateUpdate: @escaping (SettingsIdentityServerViewState) -> Void,
                                           canAddcompletion: @escaping(() -> Void)) {
        viewStateUpdate(.loading)

        self.checkIdentityServerValidity(identityServer: newIdentityServer) { (identityServerValidityResponse) in
            MXLog.debug("[SettingsIdentityServerViewModel] checkCanAddIdentityServer: \(newIdentityServer). Validity: \(identityServerValidityResponse)")

            switch identityServerValidityResponse {
            case .success(let identityServerValidity):
                switch identityServerValidity {
                case .invalid:
                    // Present invalid IS alert
                    viewStateUpdate(.alert(alert: SettingsIdentityServerAlert.addActionAlert(.invalidIdentityServer(newHost: newIdentityServer)), onContinue: {}))
                case .valid(status: let termsStatus):
                    switch termsStatus {
                    case .noTerms:
                        viewStateUpdate(.alert(alert: SettingsIdentityServerAlert.addActionAlert(.noTerms(newHost: newIdentityServer)), onContinue: {
                            viewStateUpdate(.loading)
                            canAddcompletion()
                        }))
                    case .terms(agreed: let termsAgreed):
                        if termsAgreed {
                            canAddcompletion()
                        } else {
                            self.accessToken(identityServer: newIdentityServer) { (response) in
                                switch response {
                                case .success(let accessToken):
                                    guard let accessToken = accessToken else {
                                        MXLog.debug("[SettingsIdentityServerViewModel] accessToken: Error: No access token")
                                        viewStateUpdate(.error(SettingsIdentityServerViewModelError.unknown))
                                        return
                                    }

                                    // Present terms
                                    viewStateUpdate(.presentTerms(session: self.session, accessToken: accessToken, baseUrl: newIdentityServer, onComplete: { (areTermsAccepted) in
                                        if areTermsAccepted {
                                            canAddcompletion()
                                        } else {
                                            viewStateUpdate(.alert(alert: SettingsIdentityServerAlert.addActionAlert(.termsNotAccepted(newHost: newIdentityServer)), onContinue: {}))
                                        }
                                    }))
                                case .failure(let error):
                                    self.update(viewState: .error(error))
                                }
                            }
                        }
                    }
                }
            case .failure(let error):
                viewStateUpdate(.error(error))
            }
        }
    }


    // MARK: Change IS
    
    private func changeIdentityServer(_ newIdentityServer: String) {
        guard let identityServer = self.identityServer else {
            return
        }

        let viewStateUpdate: (SettingsIdentityServerViewState) -> Void = { (viewState) in

            // Convert states for .addActionAlert and .disconnectActionAlert to .changeActionAlert
            var changeViewState = viewState
            switch viewState {
            case .alert(let alert, let onContinue):
                switch alert {
                case .addActionAlert(.invalidIdentityServer(let newHost)):
                    changeViewState = .alert(
                        alert: SettingsIdentityServerAlert.changeActionAlert(.invalidIdentityServer(newHost: newHost)),
                        onContinue: onContinue)
                case .addActionAlert(.noTerms(let newHost)):
                    changeViewState = .alert(
                        alert: SettingsIdentityServerAlert.changeActionAlert(.noTerms(newHost: newHost)),
                        onContinue: onContinue)
                case .addActionAlert(.termsNotAccepted(let newHost)):
                    changeViewState = .alert(
                        alert: SettingsIdentityServerAlert.changeActionAlert(.termsNotAccepted(newHost: newHost)),
                        onContinue: onContinue)

                case .disconnectActionAlert(.stillSharing3Pids(let oldHost)):
                    changeViewState = .alert(
                        alert: SettingsIdentityServerAlert.changeActionAlert(.stillSharing3Pids(oldHost: oldHost, newHost: newIdentityServer)),
                        onContinue: onContinue)
                case .disconnectActionAlert(.doubleConfirmation(let oldHost)):
                    changeViewState = .alert(
                        alert: SettingsIdentityServerAlert.changeActionAlert(.doubleConfirmation(oldHost: oldHost, newHost: newIdentityServer)),
                        onContinue: onContinue)
                default:
                    break
                }
            default:
                break
            }

            self.update(viewState: changeViewState)
        }

        self.checkCanAddIdentityServer(newIdentityServer: newIdentityServer, viewStateUpdate: viewStateUpdate) {
            self.checkCanDisconnectIdentityServer(identityServer: identityServer, viewStateUpdate: viewStateUpdate, canDisconnectCompletion: {
                self.update(viewState: .loading)
                self.disconnectIdentityServer(refreshViewState: false)
                self.updateIdentityServerAndRefreshViewState(with: newIdentityServer)
            })
        }
    }


    // MARK: Disconnect IS
    
    private func disconnect() {
        guard let identityServer = self.identityServer else {
            return
        }

        self.checkCanDisconnectIdentityServer(identityServer: identityServer,
                                              viewStateUpdate: { (viewState) in
                                                self.update(viewState: viewState)
        },
                                              canDisconnectCompletion: {
                                                self.update(viewState: .loading)
                                                self.disconnectIdentityServer()
        })
    }

    private func disconnectIdentityServer(refreshViewState: Bool = true) {
        // TODO: Make a /account/logout request

        if refreshViewState {
            self.updateIdentityServerAndRefreshViewState(with: nil)
        }
    }

    private func checkCanDisconnectIdentityServer(identityServer: String,
                                                  viewStateUpdate: @escaping (SettingsIdentityServerViewState) -> Void,
                                                  canDisconnectCompletion: @escaping(() -> Void)) {
        self.update(viewState: .loading)

        self.checkExistingDataOnIdentityServer { (response) in
            switch response {
            case .success(let existingData):
                if existingData {
                    viewStateUpdate(.alert(alert: SettingsIdentityServerAlert.disconnectActionAlert(.stillSharing3Pids(oldHost: identityServer)),
                                           onContinue: canDisconnectCompletion))
                } else {
                    viewStateUpdate(.alert(alert: SettingsIdentityServerAlert.disconnectActionAlert(.doubleConfirmation(oldHost: identityServer)),
                                           onContinue: canDisconnectCompletion))
                }
            case .failure(let error):
                viewStateUpdate( .error(error))
            }
        }
    }


    // MARK: - Model update

    private func update(viewState: SettingsIdentityServerViewState) {
        self.viewDelegate?.settingsIdentityServerViewModel(self, didUpdateViewState: viewState)
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


    // MARK: - Helpers
    
    private func checkExistingDataOnIdentityServer(completion: @escaping (_ response: MXResponse<Bool>) -> Void) {
        self.session.matrixRestClient.thirdPartyIdentifiers { (thirdPartyIDresponse) in
            switch thirdPartyIDresponse {
            case .success(let thirdPartyIdentifiers):
                guard let thirdPartyIdentifiers = thirdPartyIdentifiers else {
                    completion(.success(false))
                    return
                }
                
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
                    || (nsError.domain == NSURLErrorDomain
                        && (nsError.code == NSURLErrorCannotFindHost
                            || nsError.code == NSURLErrorCancelled)) {
                    completion(.success(.invalid))
                } else {
                    completion(.failure(error))
                }
            }
        }

        self.identityService = identityService
    }
    
    private class func threePids(from thirdPartyIdentifiers: [MXThirdPartyIdentifier]) -> [MX3PID] {
        return thirdPartyIdentifiers.map({ (thirdPartyIdentifier) -> MX3PID in
            return MX3PID(medium: MX3PID.Medium(identifier: thirdPartyIdentifier.medium), address: thirdPartyIdentifier.address)
        })
    }
}
