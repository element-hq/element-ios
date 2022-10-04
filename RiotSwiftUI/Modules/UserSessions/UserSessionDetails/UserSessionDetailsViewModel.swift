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

typealias UserSessionDetailsViewModelType = StateStoreViewModel<UserSessionDetailsViewState, UserSessionDetailsViewAction>

class UserSessionDetailsViewModel: UserSessionDetailsViewModelType, UserSessionDetailsViewModelProtocol {
    var completion: ((UserSessionDetailsViewModelResult) -> Void)?
    
    init(session: UserSessionInfo) {
        super.init(initialViewState: UserSessionDetailsViewState(sections: []))
        updateViewState(session: session)
    }
    
    // MARK: - Public
    
    // MARK: - Private
    
    private func updateViewState(session: UserSessionInfo) {
        var sections = [UserSessionDetailsSectionViewData]()

        sections.append(sessionSection(session: session))

        if let applicationSection = applicationSection(session: session) {
            sections.append(applicationSection)
        }
        
        if let deviceSection = deviceSection(session: session) {
            sections.append(deviceSection)
        }
        
        state = UserSessionDetailsViewState(sections: sections)
    }
    
    private func sessionSection(session: UserSessionInfo) -> UserSessionDetailsSectionViewData {
        var sessionItems: [UserSessionDetailsSectionItemViewData] = []

        if let sessionName = session.name {
            sessionItems.append(.init(title: VectorL10n.userSessionDetailsSessionName,
                                      value: sessionName))
        }
        
        sessionItems.append(.init(title: VectorL10n.keyVerificationManuallyVerifyDeviceIdTitle,
                                  value: session.id))
        
        return .init(header: VectorL10n.userSessionDetailsSessionSectionHeader.uppercased(),
                     footer: VectorL10n.userSessionDetailsSessionSectionFooter,
                     items: sessionItems)
    }

    private func applicationSection(session: UserSessionInfo) -> UserSessionDetailsSectionViewData? {
        var sessionItems: [UserSessionDetailsSectionItemViewData] = []

        if let name = session.applicationName {
            sessionItems.append(.init(title: VectorL10n.userSessionDetailsApplicationName,
                                      value: name))
        }
        if let version = session.applicationVersion {
            sessionItems.append(.init(title: VectorL10n.userSessionDetailsApplicationVersion,
                                      value: version))
        }
        if let url = session.applicationURL {
            sessionItems.append(.init(title: VectorL10n.userSessionDetailsApplicationUrl,
                                      value: url))
        }

        guard !sessionItems.isEmpty else {
            return nil
        }
        return .init(header: VectorL10n.userSessionDetailsApplicationSectionHeader.uppercased(),
                     footer: nil,
                     items: sessionItems)
    }
    
    private func deviceSection(session: UserSessionInfo) -> UserSessionDetailsSectionViewData? {
        var deviceSectionItems = [UserSessionDetailsSectionItemViewData]()

        if let model = session.deviceModel {
            deviceSectionItems.append(.init(title: VectorL10n.userSessionDetailsDeviceModel,
                                            value: model))
        }
        if session.deviceType == .web,
           let clientName = session.clientName,
           let clientVersion = session.clientVersion {
            deviceSectionItems.append(.init(title: VectorL10n.userSessionDetailsDeviceBrowser,
                                            value: "\(clientName) \(clientVersion)"))
        }
        if let deviceOS = session.deviceOS {
            deviceSectionItems.append(.init(title: VectorL10n.userSessionDetailsDeviceOs,
                                            value: deviceOS))
        }
        if let lastSeenIP = session.lastSeenIP {
            deviceSectionItems.append(.init(title: VectorL10n.userSessionDetailsDeviceIpAddress,
                                            value: lastSeenIP))
        }
        if let lastSeenIPLocation = session.lastSeenIPLocation {
            deviceSectionItems.append(.init(title: VectorL10n.userSessionDetailsDeviceIpLocation,
                                            value: lastSeenIPLocation))
        }
        if deviceSectionItems.count > 0 {
            return .init(header: VectorL10n.userSessionDetailsDeviceSectionHeader.uppercased(),
                         footer: nil,
                         items: deviceSectionItems)
        }
        return nil
    }
}
