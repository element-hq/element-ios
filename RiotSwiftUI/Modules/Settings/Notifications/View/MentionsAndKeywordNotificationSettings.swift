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

import SwiftUI

struct MentionsAndKeywordNotificationSettings: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    
    var keywordSection: some View {
        SwiftUI.Section(
            header: FormSectionHeader(text: VectorL10n.settingsYourKeywords),
            footer: FormSectionFooter(text: VectorL10n.settingsMentionsAndKeywordsEncryptionNotice)
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
