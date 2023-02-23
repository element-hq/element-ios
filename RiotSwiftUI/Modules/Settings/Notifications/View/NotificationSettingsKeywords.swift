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

/// Renders the keywords input, driven by 'NotificationSettingsViewModel'.
struct NotificationSettingsKeywords: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    var body: some View {
        ChipsInput(
            titles: viewModel.viewState.keywords,
            didAddChip: viewModel.add(keyword:),
            didDeleteChip: viewModel.remove(keyword:),
            placeholder: VectorL10n.settingsNewKeyword
        )
        .disabled(!(viewModel.viewState.selectionState[.keywords] ?? false))
    }
}

struct Keywords_Previews: PreviewProvider {
    static let viewModel = NotificationSettingsViewModel(
        notificationSettingsService: MockNotificationSettingsService.example,
        ruleIds: NotificationSettingsScreen.mentionsAndKeywords.pushRules
    )
    static var previews: some View {
        NotificationSettingsKeywords(viewModel: viewModel)
    }
}
