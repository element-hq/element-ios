// File created from ScreenTemplate
// $ createScreen.sh Settings/Notifications NotificationSettings
/*
 Copyright 2021 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import Combine
import SwiftUI

@available(iOS 14.0, *)
final class NotificationSettingsViewModel: NotificationSettingsViewModelType, ObservableObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    // MARK: Public

    weak var viewDelegate: NotificationSettingsViewModelViewDelegate?
    weak var coordinatorDelegate: NotificationSettingsViewModelCoordinatorDelegate?
    
    @Published var viewState: NotificationSettingsViewState
    
    // MARK: - Setup
    
    init(initialState: NotificationSettingsViewState) {
        self.viewState = initialState
    }
    
    convenience init(rules: [PushRuleId]) {
        let ruleSate = rules.map({ PushRuleSelectedState(ruleId: $0, selected: false) })
        self.init(initialState: NotificationSettingsViewState(saving: false, selectionState: ruleSate))
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: NotificationSettingsViewAction) {
        switch viewAction {
        case .load:
            self.loadData()
        case .save:
            break
        case .cancel:
            self.cancelOperations()
//            self.coordinatorDelegate?.notificationSettingsViewModelDidCancel(self)
        case .selectNotification(_, _):
            break
        }
    }
    
    // MARK: - Private
    
    private func loadData() {

    }
    
    private func update(viewState: NotificationSettingsViewState) {
//        self.viewDelegate?.notificationSettingsViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
    
    }
}
