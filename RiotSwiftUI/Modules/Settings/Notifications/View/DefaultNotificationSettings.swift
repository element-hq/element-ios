//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct DefaultNotificationSettings: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    
    var body: some View {
        NotificationSettings(viewModel: viewModel)
            .navigationBarTitle(VectorL10n.settingsDefault)
            .track(screen: .settingsDefaultNotifications)
    }
}

struct DefaultNotifications_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DefaultNotificationSettings(
                viewModel: NotificationSettingsViewModel(
                    notificationSettingsService: MockNotificationSettingsService.example,
                    ruleIds: NotificationSettingsScreen.defaultNotifications.pushRules
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
