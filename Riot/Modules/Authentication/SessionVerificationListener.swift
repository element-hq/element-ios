// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// An object that will listen for the cross-signing state of a new session
/// determining whether or not verification needs to be performed.
class SessionVerificationListener {
    enum Result {
        case needsVerification
        case authenticationIsComplete
    }
    
    // MARK: - Properties
    
    /// The completion handler called once the cross-signing state has been determined.
    var completion: ((Result) -> Void)?
    /// The session being used
    private let session: MXSession
    /// The session's password (if used), for boot-strapping the cross-signing.
    private let password: String?
    /// The cross-signing service.
    private let crossSigningService = CrossSigningService()
    
    // MARK: - Setup
    
    /// Creates a new listener object.
    /// - Parameter session: The session to listen to.
    /// - Parameter password: The password used for the session (optional).
    init(session: MXSession, password: String?) {
        self.session = session
        self.password = password
    }
    
    // MARK: - Public
    
    /// Start listening for the cross-signing state of the supplied session.
    func start() {
        registerSessionStateChangeNotification(for: session)
    }
    
    // MARK: - Private
    
    private func registerSessionStateChangeNotification(for session: MXSession) {
        NotificationCenter.default.addObserver(self, selector: #selector(sessionStateDidChange), name: .mxSessionStateDidChange, object: session)
    }

    private func unregisterSessionStateChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .mxSessionStateDidChange, object: nil)
    }
                                      
    @objc private func sessionStateDidChange(_ notification: Notification) {
        guard let session = notification.object as? MXSession else {
            MXLog.error("[SessionVerificationListener] sessionStateDidChange: Missing session in the notification")
            return
        }

        if session.state == .running {
            unregisterSessionStateChangeNotification()
            
            if let crypto = session.crypto {
                let crossSigning = crypto.crossSigning
                crossSigning.refreshState { [weak self] stateUpdated in
                    guard let self = self else { return }
                    
                    MXLog.debug("[SessionVerificationListener] sessionStateDidChange: crossSigning.state: \(crossSigning.state)")
                    
                    switch crossSigning.state {
                    case .notBootstrapped:
                        // TODO: This is still not sure we want to disable the automatic cross-signing bootstrap
                        // if the admin disabled e2e by default.
                        // Do like riot-web for the moment
                        if session.vc_homeserverConfiguration().encryption.isE2EEByDefaultEnabled {
                            // Bootstrap cross-signing on user's account
                            // We do it for both registration and new login as long as cross-signing does not exist yet
                            if let password = self.password, !password.isEmpty {
                                MXLog.debug("[SessionVerificationListener] sessionStateDidChange: Bootstrap with password")
                                
                                crossSigning.setup(withPassword: password) {
                                    MXLog.debug("[SessionVerificationListener] sessionStateDidChange: Bootstrap succeeded")
                                    self.completion?(.authenticationIsComplete)
                                } failure: { error in
                                    MXLog.error("[SessionVerificationListener] sessionStateDidChange: Bootstrap failed", context: error)
                                    self.completion?(.authenticationIsComplete)
                                }
                            } else {
                                // Try to setup cross-signing without authentication parameters in case if a grace period is enabled
                                self.crossSigningService.setupCrossSigningWithoutAuthentication(for: session) {
                                    MXLog.debug("[SessionVerificationListener] sessionStateDidChange: Bootstrap succeeded without credentials")
                                    self.completion?(.authenticationIsComplete)
                                } failure: { error in
                                    MXLog.error("[SessionVerificationListener] sessionStateDidChange: Do not know how to bootstrap cross-signing. Skip it.")
                                    self.completion?(.authenticationIsComplete)
                                }
                            }
                        } else {
                            self.completion?(.authenticationIsComplete)
                        }
                    case .crossSigningExists:
                        MXLog.debug("[SessionVerificationListener] sessionStateDidChange: Needs verification")
                        self.completion?(.needsVerification)
                    default:
                        MXLog.debug("[SessionVerificationListener] sessionStateDidChange: Nothing to do")
                        self.completion?(.authenticationIsComplete)
                    }
                } failure: { [weak self] error in
                    MXLog.error("[SessionVerificationListener] sessionStateDidChange: Fail to refresh crypto state", context: error)
                    self?.completion?(.authenticationIsComplete)
                }
            } else {
                completion?(.authenticationIsComplete)
            }
        }
    }
}
