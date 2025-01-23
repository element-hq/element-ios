//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
