// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Plist Files

// swiftlint:disable identifier_name line_length type_body_length
internal enum RiotDefaults {
  private static let _document = PlistDocument(path: "Riot-Defaults.plist")

  internal static let bugReportApp: String = _document["bugReportApp"]
  internal static let bugReportEndpointUrl: String = _document["bugReportEndpointUrl"]
  internal static let createConferenceCallsWithJitsi: Bool = _document["createConferenceCallsWithJitsi"]
  internal static let enableBotCreation: Bool = _document["enableBotCreation"]
  internal static let enableRageShake: Bool = _document["enableRageShake"]
  internal static let homeserver: String = _document["homeserver"]
  internal static let homeserverurl: String = _document["homeserverurl"]
  internal static let identityserverurl: String = _document["identityserverurl"]
  internal static let integrationsRestUrl: String = _document["integrationsRestUrl"]
  internal static let integrationsUiUrl: String = _document["integrationsUiUrl"]
  internal static let integrationsWidgetsUrls: [String] = _document["integrationsWidgetsUrls"]
  internal static let jitsiServerURL: String = _document["jitsiServerURL"]
  internal static let matrixApps: Bool = _document["matrixApps"]
  internal static let maxAllowedMediaCacheSize: Int = _document["maxAllowedMediaCacheSize"]
  internal static let pinRoomsWithMissedNotif: Bool = _document["pinRoomsWithMissedNotif"]
  internal static let pinRoomsWithUnread: Bool = _document["pinRoomsWithUnread"]
  internal static let piwik: [String: Any] = _document["piwik"]
  internal static let presenceColorForOfflineUser: Int = _document["presenceColorForOfflineUser"]
  internal static let presenceColorForOnlineUser: Int = _document["presenceColorForOnlineUser"]
  internal static let presenceColorForUnavailableUser: Int = _document["presenceColorForUnavailableUser"]
  internal static let pushGatewayURL: String = _document["pushGatewayURL"]
  internal static let pushKitAppIdDev: String = _document["pushKitAppIdDev"]
  internal static let pushKitAppIdProd: String = _document["pushKitAppIdProd"]
  internal static let pusherAppIdDev: String = _document["pusherAppIdDev"]
  internal static let pusherAppIdProd: String = _document["pusherAppIdProd"]
  internal static let roomDirectoryServers: [String: Any] = _document["roomDirectoryServers"]
  internal static let settingsCopyrightUrl: String = _document["settingsCopyrightUrl"]
  internal static let settingsPrivacyPolicyUrl: String = _document["settingsPrivacyPolicyUrl"]
  internal static let settingsTermsConditionsUrl: String = _document["settingsTermsConditionsUrl"]
  internal static let showAllEventsInRoomHistory: Bool = _document["showAllEventsInRoomHistory"]
  internal static let showLeftMembersInRoomMemberList: Bool = _document["showLeftMembersInRoomMemberList"]
  internal static let showRedactionsInRoomHistory: Bool = _document["showRedactionsInRoomHistory"]
  internal static let showUnsupportedEventsInRoomHistory: Bool = _document["showUnsupportedEventsInRoomHistory"]
  internal static let sortRoomMembersUsingLastSeenTime: Bool = _document["sortRoomMembersUsingLastSeenTime"]
  internal static let stunServerFallback: String = _document["stunServerFallback"]
  internal static let syncLocalContacts: Bool = _document["syncLocalContacts"]
  internal static let webAppUrl: String = _document["webAppUrl"]
  internal static let webAppUrlDev: String = _document["webAppUrlDev"]
  internal static let webAppUrlStaging: String = _document["webAppUrlStaging"]
}
// swiftlint:enable identifier_name line_length type_body_length

// MARK: - Implementation Details

private func arrayFromPlist<T>(at path: String) -> [T] {
  let bundle = Bundle(for: BundleToken.self)
  guard let url = bundle.url(forResource: path, withExtension: nil),
    let data = NSArray(contentsOf: url) as? [T] else {
    fatalError("Unable to load PLIST at path: \(path)")
  }
  return data
}

private struct PlistDocument {
  let data: [String: Any]

  init(path: String) {
    let bundle = Bundle(for: BundleToken.self)
    guard let url = bundle.url(forResource: path, withExtension: nil),
      let data = NSDictionary(contentsOf: url) as? [String: Any] else {
        fatalError("Unable to load PLIST at path: \(path)")
    }
    self.data = data
  }

  subscript<T>(key: String) -> T {
    guard let result = data[key] as? T else {
      fatalError("Property '\(key)' is not of type \(T.self)")
    }
    return result
  }
}

private final class BundleToken {}
