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

    // MARK: Integration provisioning

    var hasIntegrationProvisioningEnabled: Bool {
        return getIntegrationProvisioning()?.enabled ?? true
    }

    func getIntegrationProvisioning() -> RiotSettingIntegrationProvisioning? {
        guard let integrationProvisioningDict = getAccountData(forEventType: Settings.integrationProvisioning) else {
            return nil
        }

        return try? serializationService.deserialize(integrationProvisioningDict)
    }

    @discardableResult
    func setIntegrationProvisioning(enabled: Bool,
                                    success: @escaping () -> Void,
                                    failure: @escaping (Error?) -> Void)
        -> MXHTTPOperation? {

        // Update only the "widgets" field in the account data
        var integrationProvisioningDict = getAccountData(forEventType: Settings.integrationProvisioning) ?? [:]
        integrationProvisioningDict[RiotSettingIntegrationProvisioning.CodingKeys.enabled.rawValue] = enabled

        return session.setAccountData(integrationProvisioningDict, forType: Settings.integrationProvisioning, success: success, failure: failure)
    }


    // MARK: Allowed widgets
    func permission(for widget: Widget) -> WidgetPermission {
        guard let allowedWidgets = getAllowedWidgets() else {
            return .undefined
        }

        if let value = allowedWidgets.widgets[widget.widgetEvent.eventId] {
            return value == true ? .granted : .declined
        } else {
            return .undefined
        }
    }

    func getAllowedWidgets() -> RiotSettingAllowedWidgets? {
        guard let allowedWidgetsDict = getAccountData(forEventType: Settings.allowedWidgets) else {
            return nil
        }

        return try? serializationService.deserialize(allowedWidgetsDict)
    }

    @discardableResult
    func setPermission(_ permission: WidgetPermission,
                                          for widget: Widget,
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


    // MARK: Allowed native widgets

    /// Get the permission for widget that will be displayed natively instead within
    /// a webview.
    ///
    /// - Parameters:
    ///   - widget: the widget
    ///   - url: the url the native implementation will open. Nil will use the url declared in the widget
    /// - Returns: the permission
    func permission(forNative widget: Widget, fromUrl url: URL? = nil) -> WidgetPermission {
        guard let allowedWidgets = getAllowedWidgets() else {
            return .undefined
        }

        guard let type = widget.type, let domain = domainForNativeWidget(widget, fromUrl: url) else {
            return .undefined
        }

        if let value = allowedWidgets.nativeWidgets[type]?[domain] {
            return value == true ? .granted : .declined
        } else {
            return .undefined
        }
    }

    /// Set the permission for widget that is displayed natively.
    ///
    /// - Parameters:
    ///   - permission: the permission to set
    ///   - widget: the widget
    ///   - url: the url the native implementation opens. Nil will use the url declared in the widget
    ///   - success: the success block
    ///   - failure: the failure block
    /// - Returns: a `MXHTTPOperation` instance.
    @discardableResult
    func setPermission(_ permission: WidgetPermission,
                       forNative widget: Widget,
                       fromUrl url: URL?,
                       success: @escaping () -> Void,
                       failure: @escaping (Error?) -> Void)
        -> MXHTTPOperation? {

        guard let type = widget.type, let domain = domainForNativeWidget(widget, fromUrl: url) else {
            return nil
        }

        var nativeWidgets = getAllowedWidgets()?.nativeWidgets ?? [String: [String: Bool]]()
        var nativeWidgetsType = nativeWidgets[type] ?? [String: Bool]()

        switch permission {
        case .undefined:
            nativeWidgetsType.removeValue(forKey: domain)
        case .granted:
            nativeWidgetsType[domain] = true
        case .declined:
            nativeWidgetsType[domain] = false
        }

        nativeWidgets[type] = nativeWidgetsType

        // Update only the "native_widgets" field in the account data
        var allowedWidgetsDict = getAccountData(forEventType: Settings.allowedWidgets) ?? [:]
        allowedWidgetsDict[RiotSettingAllowedWidgets.CodingKeys.nativeWidgets.rawValue] = nativeWidgets

        return session.setAccountData(allowedWidgetsDict, forType: Settings.allowedWidgets, success: success, failure: failure)
    }


    // MARK: - Private
    private func getAccountData(forEventType eventType: String) -> [String: Any]? {
        return session.accountData.accountData(forEventType: eventType) as? [String: Any]
    }

    private func domainForNativeWidget(_ widget: Widget, fromUrl url: URL? = nil) -> String? {
        var widgetUrl: URL?
        if let widgetUrlString = widget.url {
            widgetUrl = URL(string: widgetUrlString)
        }

        guard let url = url ?? widgetUrl, let domain = url.host else {
            return nil
        }

        return domain
    }
}
