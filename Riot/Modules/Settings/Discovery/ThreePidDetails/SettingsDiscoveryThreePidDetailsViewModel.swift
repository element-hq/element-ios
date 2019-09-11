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

    private let session: MXSession
    private var viewState: SettingsDiscoveryThreePidDetailsViewState?
    private var currentThreePidRequestTokenInfo: ThreePidRequestTokenInfo?
    
    // MARK: Public

    let threePid: MX3PID
    
    weak var viewDelegate: SettingsDiscoveryThreePidDetailsViewModelViewDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, threePid: MX3PID) {
        self.session = session
        self.threePid = threePid
    }
    
    // MARK: - Public
    
    func process(viewAction: SettingsDiscoveryThreePidDetailsViewAction) {
        switch viewAction {
        case .load:
            self.load()
        case .share:
            self.share()
        case .revoke:
            self.revoke()
        case .cancelEmailValidation:
            self.cancelEmailValidation()
        case .confirmEmailValidation:
            self.confirmEmailValidation()
        case .enterSMSCode(let code):
            self.validatePhoneNumber(with: code)
        }
    }
    
    // MARK: - Private
    
    private func load() {
        self.update(viewState: .loading)

        self.checkThreePidDiscoverability()
    }
    
    private func checkThreePidDiscoverability() {
        self.isThreePidDiscoverable(self.threePid) { (response) in
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
        self.requestToken(for: self.threePid, bind: true)
    }
    
    private func revoke() {
        self.requestToken(for: self.threePid, bind: false)
    }
    
    private func requestToken(for threePid: MX3PID, bind: Bool, useOlderHomeserver: Bool = false) {
        guard let restClient = self.session.matrixRestClient,
            let clientSecret = MXTools.generateSecret() else {
            return
        }
        
        let requestThreePidToken: (() -> Void) = {
            switch self.threePid.medium {
            case .email:
                restClient.requestToken(forEmail: threePid.address, isDuringRegistration: false, clientSecret: clientSecret, sendAttempt: 1, nextLink: nil, success: { (sid) in
                    
                    if let sid = sid {
                        self.currentThreePidRequestTokenInfo = ThreePidRequestTokenInfo(clientSecret: clientSecret, sid: sid, bind: bind)
                        self.update(viewState: .loaded(displayMode: .pendingEmailVerification))
                        self.registerEmailValidationNotification()
                    } else {
                        self.update(viewState: .error(SettingsDiscoveryThreePidDetailsViewModelError.unknown))
                    }
                    
                }, failure: { error in
                    if let mxError = MXError(nsError: error), mxError.errcode == kMXErrCodeStringThreePIDInUse, useOlderHomeserver == false {
                        self.requestToken(for: threePid, bind: bind, useOlderHomeserver: true)
                    } else {
                        self.update(viewState: .error(error ?? SettingsDiscoveryThreePidDetailsViewModelError.unknown))
                    }
                })
            case .msisdn:
                let formattedPhoneNumber = self.formattedPhoneNumber(from: threePid.address)
                restClient.requestToken(forPhoneNumber: formattedPhoneNumber, isDuringRegistration: false, countryCode: nil, clientSecret: clientSecret, sendAttempt: 1, nextLink: nil, success: { (sid, msisdn) in
                    
                    if let sid = sid {
                        self.currentThreePidRequestTokenInfo = ThreePidRequestTokenInfo(clientSecret: clientSecret, sid: sid, bind: bind)
                        self.update(viewState: .loaded(displayMode: .enterSMSCode))
                    } else {
                        self.update(viewState: .error(SettingsDiscoveryThreePidDetailsViewModelError.unknown))
                    }
                    
                }, failure: { error in
                    if let mxError = MXError(nsError: error), mxError.errcode == kMXErrCodeStringThreePIDInUse, useOlderHomeserver == false {
                        self.requestToken(for: threePid, bind: bind, useOlderHomeserver: true)
                    } else {
                        self.update(viewState: .error(error ?? SettingsDiscoveryThreePidDetailsViewModelError.unknown))
                    }
                })
            default:
                break
            }
        }
        
        self.update(viewState: .loading)
        
        if useOlderHomeserver {
            restClient.remove3PID(address: threePid.address, medium: threePid.medium.identifier) { (response) in
                switch response {
                case .success:
                    requestThreePidToken()
                case .failure(let error):
                    self.update(viewState: .error(error))
                }
            }
        } else {
            requestThreePidToken()
        }
    }
    
    @discardableResult
    private func isThreePidDiscoverable(_ threePid: MX3PID, completion: @escaping (_ response: MXResponse<Bool>) -> Void) -> MXHTTPOperation? {
        guard let identityService = self.session.identityService else {
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
        self.viewDelegate?.settingsDiscoveryThreePidDetailsViewModel(self, didUpdateViewState: viewState)
    }
    
    private func bindThreePid(_ threePid: MX3PID, threePidRequestTokenInfo: ThreePidRequestTokenInfo) {
        guard let restClient = self.session.matrixRestClient else {
            return
        }
        
        self.update(viewState: .loading)
        
        restClient.addThirdPartyIdentifier(threePidRequestTokenInfo.sid, clientSecret: threePidRequestTokenInfo.clientSecret, bind: threePidRequestTokenInfo.bind) { response in
            switch response {
            case .success:
                
                if case .email = threePid.medium {
                    self.unregisterEmailValidationNotification()
                }
                
                self.checkThreePidDiscoverability()
            case .failure(let error):
                if let mxError = MXError(nsError: error), mxError.errcode == kMXErrCodeStringThreePIDAuthFailed {
                    self.update(viewState: .loaded(displayMode: .pendingEmailVerification))
                } else {
                    if case .email = threePid.medium {
                        self.unregisterEmailValidationNotification()
                    }
                    
                    self.update(viewState: .error(error))
                }
            }
        }
    }
    
    // MARK: Email
    
    private func cancelEmailValidation() {
        self.unregisterEmailValidationNotification()
        self.currentThreePidRequestTokenInfo = nil
        self.checkThreePidDiscoverability()
    }
    
    private func confirmEmailValidation() {
        guard let threePidRequestTokenInfo = self.currentThreePidRequestTokenInfo else {
            return
        }
        self.bindThreePid(self.threePid, threePidRequestTokenInfo: threePidRequestTokenInfo)
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
            let threePidRequestTokenInfo = self.currentThreePidRequestTokenInfo,
            threePidRequestTokenInfo.clientSecret == clientSecret,
            threePidRequestTokenInfo.sid == sid else {
                return
        }
        
        self.bindThreePid(self.threePid, threePidRequestTokenInfo: threePidRequestTokenInfo)
    }
    
    // MARK: Phone number
    
    private func formattedPhoneNumber(from phoneNumber: String) -> String {
        guard phoneNumber.starts(with: "+") == false else {
            return phoneNumber
        }
        return "+\(threePid.address)"
    }
    
    private func validatePhoneNumber(with activationCode: String) {
        guard let identityService = self.session.identityService, let threePidRequestTokenInfo = self.currentThreePidRequestTokenInfo else {
            return
        }
        
        identityService.submit3PIDValidationToken(activationCode, medium: MX3PID.Medium.msisdn.identifier, clientSecret: threePidRequestTokenInfo.clientSecret, sid: threePidRequestTokenInfo.sid) { (response) in
            switch response {
            case .success:
                self.bindThreePid(self.threePid, threePidRequestTokenInfo: threePidRequestTokenInfo)
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }    
}
