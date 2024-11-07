/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc final class SettingsDiscoveryViewModel: NSObject, SettingsDiscoveryViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var identityService: MXIdentityService?
    private var serviceTerms: MXServiceTerms?
    private var viewState: SettingsDiscoveryViewState?
    private var threePIDs: [MX3PID] = []
    
    // MARK: Public
    
    weak var viewDelegate: SettingsDiscoveryViewModelViewDelegate?
    @objc weak var coordinatorDelegate: SettingsDiscoveryViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    @objc init(session: MXSession, thirdPartyIdentifiers: [MXThirdPartyIdentifier]) {
        self.session = session
        
        let identityService = session.identityService
        
        if let identityService = identityService {
            self.serviceTerms = MXServiceTerms(baseUrl: identityService.identityServer, serviceType: MXServiceTypeIdentityService, matrixSession: session, accessToken: nil)
        }
        
        self.identityService = identityService
        self.threePIDs = SettingsDiscoveryViewModel.threePids(from: thirdPartyIdentifiers)
        super.init()
    }
    
    // MARK: - Public
    
    func process(viewAction: SettingsDiscoveryViewAction) {
        switch viewAction {
        case .load:
            checkTerms()
        case .acceptTerms:
            coordinatorDelegate?.settingsDiscoveryViewModelDidTapAcceptIdentityServerTerms(self)
        case .select(threePid: let threePid):
            coordinatorDelegate?.settingsDiscoveryViewModel(self, didSelectThreePidWith: threePid.medium.identifier, and: threePid.address)
        }
    }
    
    @objc func update(thirdPartyIdentifiers: [MXThirdPartyIdentifier]) {
        self.threePIDs = SettingsDiscoveryViewModel.threePids(from: thirdPartyIdentifiers)
        
        // Update view state only if three3pids was previously
        guard let viewState = self.viewState,
            case let .loaded(displayMode: displayMode) = viewState else {
            return
        }
        
        let canDisplayThreePids: Bool
        
        switch displayMode {
        case .threePidsAdded, .noThreePidsAdded:
            canDisplayThreePids = true
        default:
            canDisplayThreePids = false
        }
        
        if canDisplayThreePids {
            self.updateViewStateFromCurrentThreePids()
        }
    }
    
    // MARK: - Private
    
    private func checkTerms() {
        guard let identityService = self.identityService, let serviceTerms = self.serviceTerms else {
            self.update(viewState: .loaded(displayMode: .noIdentityServer))
            return
        }
        
        guard self.canCheckTerms() else {
            return
        }
        
        self.update(viewState: .loading)
        
        serviceTerms.areAllTermsAgreed({ (agreedTermsProgress) in
            if agreedTermsProgress.isFinished || agreedTermsProgress.totalUnitCount == 0 {
                // Display three pids if presents
                self.updateViewStateFromCurrentThreePids()
            } else {
                let identityServer = identityService.identityServer
                let identityServerHost = URL(string: identityServer)?.host ?? identityServer
                
                self.update(viewState: .loaded(displayMode: .termsNotSigned(host: identityServerHost)))
            }
        }, failure: { (error) in
            self.update(viewState: .error(error))
        })
    }
    
    private func canCheckTerms() -> Bool {
        guard let viewState = self.viewState else {
            return true
        }
        
        let canCheckTerms: Bool
        
        if case .loading = viewState {
            canCheckTerms = false
        } else {
            canCheckTerms = true
        }
        
        return canCheckTerms
    }
    
    private func updateViewStateFromCurrentThreePids() {
        self.updateViewState(with: self.threePIDs)
    }
    
    private func updateViewState(with threePids: [MX3PID]) {
        
        let viewState: SettingsDiscoveryViewState
        
        if threePids.isEmpty {
            viewState = .loaded(displayMode: .noThreePidsAdded)
        } else {
            let emails = threePids.compactMap { (threePid) -> MX3PID? in
                if case .email = threePid.medium {
                    return threePid
                } else {
                    return nil
                }
            }
            
            let phoneNumbers = threePids.compactMap { (threePid) -> MX3PID? in
                if case .msisdn = threePid.medium {
                    return threePid
                } else {
                    return nil
                }
            }
            
            viewState = .loaded(displayMode: .threePidsAdded(emails: emails, phoneNumbers: phoneNumbers))
        }
        
        self.update(viewState: viewState)
    }
    
    private func update(viewState: SettingsDiscoveryViewState) {
        self.viewState = viewState
        self.viewDelegate?.settingsDiscoveryViewModel(self, didUpdateViewState: viewState)
    }
    
    private class func threePids(from thirdPartyIdentifiers: [MXThirdPartyIdentifier]) -> [MX3PID] {
        return thirdPartyIdentifiers.map({ (thirdPartyIdentifier) -> MX3PID in
            return MX3PID(medium: MX3PID.Medium(identifier: thirdPartyIdentifier.medium), address: thirdPartyIdentifier.address)
        })
    }    
}
