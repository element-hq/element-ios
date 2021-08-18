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

@available(iOS 14.0, *)
struct NotificationSettings<Footer: View>: View {
    
    @ObservedObject var viewModel: NotificationSettingsViewModel
    
    var footer: Footer
    
    @ViewBuilder
    private var rightButton: some View {
        Button(VectorL10n.save) {
            viewModel.process(viewAction: .save)
        }
    }
    
    var body: some View {
        VectorForm {
            SwiftUI.Section(
                header: FormSectionHeader(text: VectorL10n.roomNotifsSettingsNotifyMeFor),
                footer: footer
            ) {
                ForEach(viewModel.viewState.selectionState) { item in
                    FormPickerItem(title: item.title ?? "", selected: item.selected) {
                        viewModel.process(viewAction: .selectNotification(item.ruleId, !item.selected))
                    }
                }
            }
        }
        .activityIndicator(show: viewModel.viewState.saving)
        .navigationBarItems(
            trailing: rightButton
        )
        .onAppear {
            viewModel.process(viewAction: .load)
        }
    }
}

@available(iOS 14.0, *)
struct NotificationSettings_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(NotificationSettingsScreen.allCases) { screen in
                NavigationView {
                    NotificationSettings(
                        viewModel: NotificationSettingsViewModel(rules: screen.pushRules),
                        footer: EmptyView()
                    )
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
}
