// 
// Copyright 2022 New Vector Ltd
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

class UserSessionDetailsViewModel: UserSessionDetailsViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    // MARK: Public

    // MARK: - Setup
    
    init(userSessionInfo: UserSessionInfo) {
        var sections = [UserSessionDetailsSectionViewData]()
        
        var sessionItems = [UserSessionDetailsSectionItemViewData]()
        if let sessionName = userSessionInfo.sessionName {
            sessionItems.append(UserSessionDetailsSectionItemViewData(title: VectorL10n.userSessionDetailsSessionName,
                                                                      value: sessionName))
        }
        sessionItems.append(UserSessionDetailsSectionItemViewData(title: VectorL10n.keyVerificationManuallyVerifyDeviceIdTitle,
                                                                  value: userSessionInfo.sessionId))
        sections.append(UserSessionDetailsSectionViewData(header: VectorL10n.userSessionDetailsSessionSectionHeader,
                                                          footer: VectorL10n.userSessionDetailsSessionSectionFooter,
                                                          items: sessionItems))
        
        var deviceSectionItems = [UserSessionDetailsSectionItemViewData]()
        if let lastSeenIP = userSessionInfo.lastSeenIP {
            deviceSectionItems.append(UserSessionDetailsSectionItemViewData(title: VectorL10n.userSessionDetailsDeviceIpAddress,
                                                                            value: lastSeenIP))
        }
        if deviceSectionItems.count > 0 {
            sections.append(UserSessionDetailsSectionViewData(header: VectorL10n.userSessionDetailsDeviceSectionHeader,
                                                              footer: nil,
                                                              items: deviceSectionItems))
        }
        
        let initialViewState = UserSessionDetailsViewState(sections: sections)
        super.init(initialViewState: initialViewState)
    }
    
    // MARK: - Public

    // MARK: - Private
}

