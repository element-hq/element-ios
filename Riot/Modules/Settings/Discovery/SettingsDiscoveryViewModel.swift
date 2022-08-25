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
            serviceTerms = MXServiceTerms(baseUrl: identityService.identityServer, serviceType: MXServiceTypeIdentityService, matrixSession: session, accessToken: nil)
        }
        
        self.identityService = identityService
        threePIDs = SettingsDiscoveryViewModel.threePids(from: thirdPartyIdentifiers)
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
        threePIDs = SettingsDiscoveryViewModel.threePids(from: thirdPartyIdentifiers)
        
        // Update view state only if three3pids was previously
        guard let viewState = viewState,
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
            updateViewStateFromCurrentThreePids()
        }
    }
    
    // MARK: - Private
    
    private func checkTerms() {
        guard let identityService = identityService, let serviceTerms = serviceTerms else {
            update(viewState: .loaded(displayMode: .noIdentityServer))
            return
        }
        
        guard canCheckTerms() else {
            return
        }
        
        update(viewState: .loading)
        
        serviceTerms.areAllTermsAgreed({ agreedTermsProgress in
            if agreedTermsProgress.isFinished || agreedTermsProgress.totalUnitCount == 0 {
                // Display three pids if presents
                self.updateViewStateFromCurrentThreePids()
            } else {
                let identityServer = identityService.identityServer
                let identityServerHost = URL(string: identityServer)?.host ?? identityServer
                
                self.update(viewState: .loaded(displayMode: .termsNotSigned(host: identityServerHost)))
            }
        }, failure: { error in
            self.update(viewState: .error(error))
        })
    }
    
    private func canCheckTerms() -> Bool {
        guard let viewState = viewState else {
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
        updateViewState(with: threePIDs)
    }
    
    private func updateViewState(with threePids: [MX3PID]) {
        let viewState: SettingsDiscoveryViewState
        
        if threePids.isEmpty {
            viewState = .loaded(displayMode: .noThreePidsAdded)
        } else {
            let emails = threePids.compactMap { threePid -> MX3PID? in
                if case .email = threePid.medium {
                    return threePid
                } else {
                    return nil
                }
            }
            
            let phoneNumbers = threePids.compactMap { threePid -> MX3PID? in
                if case .msisdn = threePid.medium {
                    return threePid
                } else {
                    return nil
                }
            }
            
            viewState = .loaded(displayMode: .threePidsAdded(emails: emails, phoneNumbers: phoneNumbers))
        }
        
        update(viewState: viewState)
    }
    
    private func update(viewState: SettingsDiscoveryViewState) {
        self.viewState = viewState
        viewDelegate?.settingsDiscoveryViewModel(self, didUpdateViewState: viewState)
    }
    
    private class func threePids(from thirdPartyIdentifiers: [MXThirdPartyIdentifier]) -> [MX3PID] {
        thirdPartyIdentifiers.map { thirdPartyIdentifier -> MX3PID in
            MX3PID(medium: MX3PID.Medium(identifier: thirdPartyIdentifier.medium), address: thirdPartyIdentifier.address)
        }
    }
}
