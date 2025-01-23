//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct OtherNotificationSettings: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    
    var body: some View {
        NotificationSettings(viewModel: viewModel)
            .navigationTitle(VectorL10n.settingsOther)
            .track(screen: .settingsNotifications)
    }
}

struct OtherNotifications_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DefaultNotificationSettings(
                viewModel: NotificationSettingsViewModel(
                    notificationSettingsService: MockNotificationSettingsService.example,
                    ruleIds: NotificationSettingsScreen.other.pushRules
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
