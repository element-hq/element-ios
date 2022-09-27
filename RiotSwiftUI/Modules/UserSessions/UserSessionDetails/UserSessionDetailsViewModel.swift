//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

typealias UserSessionDetailsViewModelType = StateStoreViewModel<UserSessionDetailsViewState,
                                                                Never,
                                                                UserSessionDetailsViewAction>

class UserSessionDetailsViewModel: UserSessionDetailsViewModelType, UserSessionDetailsViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    // MARK: Public
    
    var completion: ((UserSessionDetailsViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(userSessionInfo: UserSessionInfo) {
        super.init(initialViewState: UserSessionDetailsViewState(sections: []))
        updateViewState(userSessionInfo: userSessionInfo)
    }
    
    // MARK: - Public
    
    // MARK: - Private
    
    private func updateViewState(userSessionInfo: UserSessionInfo) {
        var sections = [UserSessionDetailsSectionViewData]()
        
        sections.append(sessionSection(userSessionInfo: userSessionInfo))

        if let applicationSection = applicationSection(userSessionInfo: userSessionInfo) {
            sections.append(applicationSection)
        }

        if let deviceSection = deviceSection(userSessionInfo: userSessionInfo) {
            sections.append(deviceSection)
        }
        
        state = UserSessionDetailsViewState(sections: sections)
    }
    
    private func sessionSection(userSessionInfo: UserSessionInfo) -> UserSessionDetailsSectionViewData {
        var sessionItems = [UserSessionDetailsSectionItemViewData]()
        
        if let sessionName = userSessionInfo.sessionName {
            sessionItems.append(UserSessionDetailsSectionItemViewData(title: VectorL10n.userSessionDetailsSessionName,
                                                                      value: sessionName))
        }
        
        sessionItems.append(UserSessionDetailsSectionItemViewData(title: VectorL10n.keyVerificationManuallyVerifyDeviceIdTitle,
                                                                  value: userSessionInfo.sessionId))
        
        return UserSessionDetailsSectionViewData(header: VectorL10n.userSessionDetailsSessionSectionHeader,
                                                 footer: VectorL10n.userSessionDetailsSessionSectionFooter,
                                                 items: sessionItems)
    }

    private func applicationSection(userSessionInfo: UserSessionInfo) -> UserSessionDetailsSectionViewData? {
        var sessionItems: [UserSessionDetailsSectionItemViewData] = []

        if let name = userSessionInfo.applicationName {
            sessionItems.append(.init(title: VectorL10n.userSessionDetailsApplicationName,
                                      value: name))
        }
        if let version = userSessionInfo.applicationVersion {
            sessionItems.append(.init(title: VectorL10n.userSessionDetailsApplicationVersion,
                                      value: version))
        }
        if let url = userSessionInfo.applicationURL {
            sessionItems.append(.init(title: VectorL10n.userSessionDetailsApplicationUrl,
                                      value: url))
        }

        guard !sessionItems.isEmpty else {
            return nil
        }
        return .init(header: VectorL10n.userSessionDetailsApplicationSectionHeader,
                     footer: nil,
                     items: sessionItems)
    }
    
    private func deviceSection(userSessionInfo: UserSessionInfo) -> UserSessionDetailsSectionViewData? {
        var deviceSectionItems = [UserSessionDetailsSectionItemViewData]()
        if let lastSeenIP = userSessionInfo.lastSeenIP {
            deviceSectionItems.append(UserSessionDetailsSectionItemViewData(title: VectorL10n.userSessionDetailsDeviceIpAddress,
                                                                            value: lastSeenIP))
        }
        if deviceSectionItems.count > 0 {
            return UserSessionDetailsSectionViewData(header: VectorL10n.userSessionDetailsDeviceSectionHeader,
                                                     footer: nil,
                                                     items: deviceSectionItems)
        }
        return nil
    }
}
