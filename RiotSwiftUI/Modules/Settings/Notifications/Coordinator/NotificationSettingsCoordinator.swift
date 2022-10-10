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

import Foundation
import SwiftUI

final class NotificationSettingsCoordinator: NotificationSettingsCoordinatorType {
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var notificationSettingsViewModel: NotificationSettingsViewModelType
    private let notificationSettingsViewController: UIViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: NotificationSettingsCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, screen: NotificationSettingsScreen) {
        self.session = session
        let notificationSettingsService = MXNotificationSettingsService(session: session)
        let viewModel = NotificationSettingsViewModel(notificationSettingsService: notificationSettingsService, ruleIds: screen.pushRules)
        let viewController: UIViewController
        switch screen {
        case .defaultNotifications:
            viewController = VectorHostingController(rootView: DefaultNotificationSettings(viewModel: viewModel))
        case .mentionsAndKeywords:
            viewController = VectorHostingController(rootView: MentionsAndKeywordNotificationSettings(viewModel: viewModel))
        case .other:
            viewController = VectorHostingController(rootView: OtherNotificationSettings(viewModel: viewModel))
        }
        notificationSettingsViewModel = viewModel
        notificationSettingsViewController = viewController
        notificationSettingsViewController.vc_setLargeTitleDisplayMode(.never)
    }
    
    // MARK: - Public methods
    
    func start() {
        notificationSettingsViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        notificationSettingsViewController
    }
}

// MARK: - NotificationSettingsViewModelCoordinatorDelegate

extension NotificationSettingsCoordinator: NotificationSettingsViewModelCoordinatorDelegate {
    func notificationSettingsViewModelDidComplete(_ viewModel: NotificationSettingsViewModelType) {
        delegate?.notificationSettingsCoordinatorDidComplete(self)
    }
}
