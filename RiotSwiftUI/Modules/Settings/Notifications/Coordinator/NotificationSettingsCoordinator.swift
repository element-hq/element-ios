//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
