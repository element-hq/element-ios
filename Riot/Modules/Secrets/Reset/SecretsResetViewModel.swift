// File created from ScreenTemplate
// $ createScreen.sh Secrets/Reset SecretsReset
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

final class SecretsResetViewModel: SecretsResetViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let recoveryService: MXRecoveryService
    private let crossSigningService: CrossSigningService
    
    // MARK: Public

    weak var viewDelegate: SecretsResetViewModelViewDelegate?
    weak var coordinatorDelegate: SecretsResetViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        self.recoveryService = session.crypto.recoveryService
        self.crossSigningService = CrossSigningService()
    }
    
    // MARK: - Public
    
    func process(viewAction: SecretsResetViewAction) {
        switch viewAction {
        case .loadData:
            break
        case .reset:
            self.resetSecrets()
        case .authenticationCancelled:
            self.authenticationCancelled()
        case .authenticationInfoEntered(let authParameters):
            self.resetSecrets(with: authParameters, hasAuthenticated: true)
        case .cancel:
            self.coordinatorDelegate?.secretsResetViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    func update(viewState: SecretsResetViewState) {
        self.viewDelegate?.secretsResetViewModel(self, didUpdateViewState: viewState)
    }
    
    private func resetSecrets(with authParameters: [String: Any] = [:], hasAuthenticated: Bool = false) {
        guard let crossSigning = self.session.crypto?.crossSigning else { return }
        
        MXLog.debug("[SecretsResetViewModel] resetSecrets")
        self.update(viewState: .resetting)

        crossSigning.setup(withAuthParams: authParameters) { [weak self] in
            guard let self else { return }
            
            self.recoveryService.deleteRecovery(withDeleteServicesBackups: true) { [weak self] in
                guard let self else { return }
                
                self.update(viewState: .resetDone)
                self.coordinatorDelegate?.secretsResetViewModelDidResetSecrets(self)

            } failure: { [weak self] error in
                guard let self else { return }
                self.update(viewState: .error(error))
            }

        } failure: { [weak self] error in
            guard let self else { return }
            
            if let responseData = (error as NSError).userInfo[MXHTTPClientErrorResponseDataKey] as? [AnyHashable: Any],
               let authenticationSession = MXAuthenticationSession(fromJSON: responseData),
               !hasAuthenticated { // Don't re-presenting authentication if the user closes the web view without finishing.
                askAuthentication(session: authenticationSession)
            } else {
                self.update(viewState: .error(error))
            }
        }
    }
    
    private func askAuthentication(session: MXAuthenticationSession) {
        let setupCrossSigningRequest = self.crossSigningService.setupCrossSigningRequest()
        self.coordinatorDelegate?.secretsResetViewModel(self, needsToAuthenticateFor: session)
    }
    
    private func authenticationCancelled() {
        self.update(viewState: .resetCancelled)
    }
}
