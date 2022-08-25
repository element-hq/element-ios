// File created from ScreenTemplate
// $ createScreen.sh Details SettingsDiscoveryThreePidDetails
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

enum SettingsDiscoveryThreePidDetailsViewModelError: Error {
    case unknown
}

private struct ThreePidRequestTokenInfo {
    let clientSecret: String
    let sid: String
    let bind: Bool
}

final class SettingsDiscoveryThreePidDetailsViewModel: SettingsDiscoveryThreePidDetailsViewModelType {
    // MARK: - Properties
    
    // MARK: Private

    private var viewState: SettingsDiscoveryThreePidDetailsViewState?

    private let threePidAddManager: MX3PidAddManager
    private let identityService: MXIdentityService?
    private var currentThreePidAddSession: MX3PidAddSession?
    
    // MARK: Public

    let threePid: MX3PID
    
    weak var viewDelegate: SettingsDiscoveryThreePidDetailsViewModelViewDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, threePid: MX3PID) {
        threePidAddManager = session.threePidAddManager
        identityService = session.identityService
        self.threePid = threePid
    }
    
    // MARK: - Public
    
    func process(viewAction: SettingsDiscoveryThreePidDetailsViewAction) {
        switch viewAction {
        case .load:
            load()
        case .share:
            share()
        case .revoke:
            revoke()
        case .cancelThreePidValidation:
            cancelThreePidValidation()
        case .confirmEmailValidation:
            confirmEmailValidation()
        case .confirmMSISDNValidation(code: let code):
            validatePhoneNumber(with: code)
        }
    }
    
    // MARK: - Private
    
    private func load() {
        update(viewState: .loading)

        checkThreePidDiscoverability()
    }
    
    private func checkThreePidDiscoverability() {
        isThreePidDiscoverable(threePid) { response in
            switch response {
            case .success(let isDiscoverable):
                if isDiscoverable {
                    self.update(viewState: .loaded(displayMode: .revoke))
                } else {
                    self.update(viewState: .loaded(displayMode: .share))
                }
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }
    
    private func share() {
        bind(bind: true)
    }

    private func revoke() {
        bind(bind: false)
    }

    private func bind(bind: Bool) {
        update(viewState: .loading)

        let completion: ((MXResponse<Bool>) -> Void) = { response in
            switch response {
            case .success(let needValidation):
                if needValidation {
                    self.update(viewState: .loaded(displayMode: .pendingThreePidVerification))

                    if case .email = self.threePid.medium {
                        self.registerEmailValidationNotification()
                    }
                } else {
                    self.checkThreePidDiscoverability()
                }

            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }

        switch threePid.medium {
        case .email:
            currentThreePidAddSession = threePidAddManager.startIdentityServerSession(withEmail: threePid.address, bind: bind, completion: completion)
        case .msisdn:
            let formattedPhoneNumber = formattedPhoneNumber(from: threePid.address)
            currentThreePidAddSession = threePidAddManager.startIdentityServerSession(withPhoneNumber: formattedPhoneNumber, countryCode: nil, bind: bind, completion: completion)
        default:
            break
        }
    }

    @discardableResult
    private func isThreePidDiscoverable(_ threePid: MX3PID, completion: @escaping (_ response: MXResponse<Bool>) -> Void) -> MXHTTPOperation? {
        guard let identityService = identityService else {
            completion(.failure(SettingsDiscoveryThreePidDetailsViewModelError.unknown))
            return nil
        }
        
        return identityService.lookup3PIDs([threePid]) { lookupResponse in
            switch lookupResponse {
            case .success(let threePids):
                completion(.success(threePids.isEmpty == false))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func update(viewState: SettingsDiscoveryThreePidDetailsViewState) {
        viewDelegate?.settingsDiscoveryThreePidDetailsViewModel(self, didUpdateViewState: viewState)
    }
    
    // MARK: Email
    
    private func cancelThreePidValidation() {
        if case .email = threePid.medium {
            self.unregisterEmailValidationNotification()
        }

        if let currentThreePidAddSession = currentThreePidAddSession {
            threePidAddManager.cancel(session: currentThreePidAddSession)
            self.currentThreePidAddSession = nil
        }

        checkThreePidDiscoverability()
    }
    
    private func confirmEmailValidation() {
        guard let threePidAddSession = currentThreePidAddSession else {
            return
        }
        update(viewState: .loading)

        threePidAddManager.tryFinaliseIdentityServerEmailSession(threePidAddSession) { response in
            switch response {
            case .success:

                if threePidAddSession.medium == kMX3PIDMediumEmail {
                    self.unregisterEmailValidationNotification()
                }

                self.checkThreePidDiscoverability()
            case .failure(let error):
                if let mxError = MXError(nsError: error),
                   mxError.errcode == kMXErrCodeStringThreePIDAuthFailed
                   || mxError.errcode == kMXErrCodeStringUnknown {
                    self.update(viewState: .loaded(displayMode: .pendingThreePidVerification))
                } else {
                    if threePidAddSession.medium == kMX3PIDMediumEmail {
                        self.unregisterEmailValidationNotification()
                    }

                    self.update(viewState: .error(error))
                }
            }
        }
    }
    
    private func registerEmailValidationNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleEmailValidationNotification(notification:)), name: .AppDelegateDidValidateEmail, object: nil)
    }
    
    private func unregisterEmailValidationNotification() {
        NotificationCenter.default.removeObserver(self, name: .AppDelegateDidValidateEmail, object: nil)
    }
    
    @objc private func handleEmailValidationNotification(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let clientSecret = userInfo[AppDelegateDidValidateEmailNotificationClientSecretKey] as? String,
              let sid = userInfo[AppDelegateDidValidateEmailNotificationSIDKey] as? String,
              let threePidAddSession = currentThreePidAddSession,
              threePidAddSession.clientSecret == clientSecret,
              threePidAddSession.sid == sid else {
            return
        }

        confirmEmailValidation()
    }
    
    // MARK: Phone number
    
    private func formattedPhoneNumber(from phoneNumber: String) -> String {
        guard phoneNumber.starts(with: "+") == false else {
            return phoneNumber
        }
        return "+\(phoneNumber)"
    }
    
    private func validatePhoneNumber(with activationCode: String) {
        guard let threePidAddSession = currentThreePidAddSession else {
            return
        }
        update(viewState: .loading)

        threePidAddManager.finaliseIdentityServerPhoneNumberSession(threePidAddSession, token: activationCode) { response in
            switch response {
            case .success:
                self.checkThreePidDiscoverability()
            case .failure(let error):
                if let mxError = MXError(nsError: error), mxError.errcode == kMXErrCodeStringUnknownToken {
                    self.update(viewState: .loaded(displayMode: .pendingThreePidVerification))
                } else {
                    self.update(viewState: .error(error))
                }
            }
        }
    }
}
