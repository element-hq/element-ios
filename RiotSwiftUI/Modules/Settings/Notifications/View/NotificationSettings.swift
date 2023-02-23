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

/// Renders the push rule settings that can be enabled/disable.
///
/// Also renders an optional bottom section.
/// Used in the case of keywords, for the keyword chips and input.
struct NotificationSettings<BottomSection: View>: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    
    var bottomSection: BottomSection?
    
    var body: some View {
        VectorForm {
            SwiftUI.Section(
                header: FormSectionHeader(text: VectorL10n.settingsNotifyMeFor)
            ) {
                ForEach(viewModel.viewState.ruleIds) { ruleId in
                    let checked = viewModel.viewState.selectionState[ruleId] ?? false
                    FormPickerItem(title: ruleId.title, selected: checked) {
                        viewModel.update(ruleID: ruleId, isChecked: !checked)
                    }
                }
            }
            bottomSection
        }
        .activityIndicator(show: viewModel.viewState.saving)
    }
}

extension NotificationSettings where BottomSection == EmptyView {
    init(viewModel: NotificationSettingsViewModel) {
        self.init(viewModel: viewModel, bottomSection: nil)
    }
}

struct NotificationSettings_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(NotificationSettingsScreen.allCases) { screen in
                NavigationView {
                    NotificationSettings(
                        viewModel: NotificationSettingsViewModel(
                            notificationSettingsService: MockNotificationSettingsService.example,
                            ruleIds: screen.pushRules
                        )
                    )
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
}
