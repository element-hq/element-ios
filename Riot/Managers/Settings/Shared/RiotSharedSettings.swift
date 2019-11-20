/*
 Copyright 2019 New Vector Ltd

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

import MatrixSDK

@objc enum WidgetPermission: Int {
    case undefined
    case granted
    case declined
}

/// Shared user settings across all Riot clients.
/// It implements https://github.com/vector-im/riot-meta/blob/master/spec/settings.md
@objcMembers
class RiotSharedSettings: NSObject {

    // MARK: - Constants
    private enum Settings {
        static let breadcrumbs = "im.vector.setting.breadcrumbs"
        static let integrationProvisioning = "im.vector.setting.integration_provisioning"
        static let allowedWidgets = "im.vector.setting.allowed_widgets"
    }


    // MARK: - Properties
    // MARK: Private
    private let session: MXSession
    private lazy var serializationService: SerializationServiceType = SerializationService()


    // MARK: - Setup

    init(session: MXSession) {
        self.session = session
    }


    // MARK: - Public

    // MARK: Allowed widgets
    func permissionFor(widget: Widget) -> WidgetPermission {
        guard let allowedWidgets = getAllowedWidgets() else {
            return .undefined
        }

        return allowedWidgets.widgets[widget.widgetEvent.eventId] == true ? .granted : .declined
    }

    func getAllowedWidgets() -> RiotSettingAllowedWidgets? {
        guard let allowedWidgetsDict = getAccountData(forEventType: Settings.allowedWidgets) else {
            return nil
        }

        do {
            let allowedWidgets: RiotSettingAllowedWidgets = try serializationService.deserialize(allowedWidgetsDict)
            return allowedWidgets
        } catch {
            return nil
        }
    }

    @discardableResult func setPermissionFor(widget: Widget,
                          permission: WidgetPermission,
                          success: @escaping () -> Void,
                          failure: @escaping (Error?) -> Void)
        -> MXHTTPOperation? {

        guard let widgetEventId = widget.widgetEvent.eventId else {
            return nil
        }

        var widgets = getAllowedWidgets()?.widgets ?? [:]

        switch permission {
        case .undefined:
            widgets.removeValue(forKey: widgetEventId)
        case .granted:
            widgets[widgetEventId] = true
        case .declined:
            widgets[widgetEventId] = false
        }

        // Update only the "widgets" field in the account data
        var allowedWidgetsDict = getAccountData(forEventType: Settings.allowedWidgets) ?? [:]
        allowedWidgetsDict[RiotSettingAllowedWidgets.CodingKeys.widgets.rawValue] = widgets

        return session.setAccountData(allowedWidgetsDict, forType: Settings.allowedWidgets, success: success, failure: failure)
    }


    // MARK: - Private
    private func getAccountData(forEventType eventType: String) -> [String: Any]? {
        return session.accountData.accountData(forEventType: eventType) as? [String: Any]
    }
}
