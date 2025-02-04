//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

typealias UserSessionDetailsViewModelType = StateStoreViewModel<UserSessionDetailsViewState, UserSessionDetailsViewAction>

class UserSessionDetailsViewModel: UserSessionDetailsViewModelType, UserSessionDetailsViewModelProtocol {
    private static var lastSeenDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE, d MMM · HH:mm"
        return dateFormatter
    }()
    
    var completion: ((UserSessionDetailsViewModelResult) -> Void)?
    
    init(sessionInfo: UserSessionInfo) {
        super.init(initialViewState: UserSessionDetailsViewState(sections: []))
        updateViewState(sessionInfo: sessionInfo)
    }
    
    // MARK: - Public
    
    // MARK: - Private
    
    private func updateViewState(sessionInfo: UserSessionInfo) {
        var sections = [UserSessionDetailsSectionViewData]()

        sections.append(sessionSection(sessionInfo: sessionInfo))

        if let applicationSection = applicationSection(sessionInfo: sessionInfo) {
            sections.append(applicationSection)
        }
        
        if let deviceSection = deviceSection(sessionInfo: sessionInfo) {
            sections.append(deviceSection)
        }
        
        state = UserSessionDetailsViewState(sections: sections)
    }
    
    private func sessionSection(sessionInfo: UserSessionInfo) -> UserSessionDetailsSectionViewData {
        var sessionItems: [UserSessionDetailsSectionItemViewData] = []

        if let sessionName = sessionInfo.name {
            sessionItems.append(.init(title: VectorL10n.userSessionDetailsSessionName,
                                      value: sessionName))
        }
        
        sessionItems.append(.init(title: VectorL10n.keyVerificationManuallyVerifyDeviceIdTitle,
                                  value: sessionInfo.id))
        
        if let lastSeenTimestamp = sessionInfo.lastSeenTimestamp {
            let date = Date(timeIntervalSince1970: lastSeenTimestamp)
            sessionItems.append(.init(title: VectorL10n.userSessionDetailsLastActivity,
                                      value: Self.lastSeenDateFormatter.string(from: date)))
        }
        
        return .init(header: VectorL10n.userSessionDetailsSessionSectionHeader.uppercased(),
                     footer: VectorL10n.userSessionDetailsSessionSectionFooter,
                     items: sessionItems)
    }

    private func applicationSection(sessionInfo: UserSessionInfo) -> UserSessionDetailsSectionViewData? {
        var sessionItems: [UserSessionDetailsSectionItemViewData] = []

        if let name = sessionInfo.applicationName, !name.isEmpty {
            sessionItems.append(.init(title: VectorL10n.userSessionDetailsApplicationName,
                                      value: name))
        }
        if let version = sessionInfo.applicationVersion, !version.isEmpty {
            sessionItems.append(.init(title: VectorL10n.userSessionDetailsApplicationVersion,
                                      value: version))
        }
        if let url = sessionInfo.applicationURL, !url.isEmpty {
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
    
    private func deviceSection(sessionInfo: UserSessionInfo) -> UserSessionDetailsSectionViewData? {
        var deviceSectionItems = [UserSessionDetailsSectionItemViewData]()

        if let model = sessionInfo.deviceModel {
            deviceSectionItems.append(.init(title: VectorL10n.userSessionDetailsDeviceModel,
                                            value: model))
        }
        if sessionInfo.deviceType == .web,
           let clientName = sessionInfo.clientName,
           let clientVersion = sessionInfo.clientVersion {
            deviceSectionItems.append(.init(title: VectorL10n.userSessionDetailsDeviceBrowser,
                                            value: "\(clientName) \(clientVersion)"))
        }
        if let deviceOS = sessionInfo.deviceOS {
            deviceSectionItems.append(.init(title: VectorL10n.userSessionDetailsDeviceOs,
                                            value: deviceOS))
        }
        if let lastSeenIP = sessionInfo.lastSeenIP {
            deviceSectionItems.append(.init(title: VectorL10n.userSessionDetailsDeviceIpAddress,
                                            value: lastSeenIP))
        }
        if let lastSeenIPLocation = sessionInfo.lastSeenIPLocation {
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
