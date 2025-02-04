//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct MentionsAndKeywordNotificationSettings: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    
    var keywordSection: some View {
        SwiftUI.Section(
            header: FormSectionHeader(text: VectorL10n.settingsYourKeywords)
        ) {
            NotificationSettingsKeywords(viewModel: viewModel)
        }
    }

    var body: some View {
        NotificationSettings(
            viewModel: viewModel,
            bottomSection: keywordSection
        )
        .navigationTitle(VectorL10n.settingsMentionsAndKeywords)
        .track(screen: .settingsMentionsAndKeywords)
    }
}

struct MentionsAndKeywords_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MentionsAndKeywordNotificationSettings(
                viewModel: NotificationSettingsViewModel(
                    notificationSettingsService: MockNotificationSettingsService.example,
                    ruleIds: NotificationSettingsScreen.mentionsAndKeywords.pushRules
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
