// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Plist Files

// swiftlint:disable identifier_name line_length type_body_length
internal enum RiotDefaults {
  private static let _document = PlistDocument(path: "Riot-Defaults.plist")

  internal static let enableBotCreation: Bool = _document["enableBotCreation"]
  internal static let enableRageShake: Bool = _document["enableRageShake"]
  internal static let enableRingingForGroupCalls: Bool = _document["enableRingingForGroupCalls"]
  internal static let matrixApps: Bool = _document["matrixApps"]
  internal static let maxAllowedMediaCacheSize: Int = _document["maxAllowedMediaCacheSize"]
  internal static let pinRoomsWithMissedNotif: Bool = _document["pinRoomsWithMissedNotif"]
  internal static let pinRoomsWithUnread: Bool = _document["pinRoomsWithUnread"]
  internal static let presenceColorForOfflineUser: Int = _document["presenceColorForOfflineUser"]
  internal static let presenceColorForOnlineUser: Int = _document["presenceColorForOnlineUser"]
  internal static let presenceColorForUnavailableUser: Int = _document["presenceColorForUnavailableUser"]
  internal static let showAllEventsInRoomHistory: Bool = _document["showAllEventsInRoomHistory"]
  internal static let showLeftMembersInRoomMemberList: Bool = _document["showLeftMembersInRoomMemberList"]
  internal static let showRedactionsInRoomHistory: Bool = _document["showRedactionsInRoomHistory"]
  internal static let showUnsupportedEventsInRoomHistory: Bool = _document["showUnsupportedEventsInRoomHistory"]
  internal static let sortRoomMembersUsingLastSeenTime: Bool = _document["sortRoomMembersUsingLastSeenTime"]
  internal static let syncLocalContacts: Bool = _document["syncLocalContacts"]
}
// swiftlint:enable identifier_name line_length type_body_length

// MARK: - Implementation Details

private func arrayFromPlist<T>(at path: String) -> [T] {
  guard let url = BundleToken.bundle.url(forResource: path, withExtension: nil),
    let data = NSArray(contentsOf: url) as? [T] else {
    fatalError("Unable to load PLIST at path: \(path)")
  }
  return data
}

private struct PlistDocument {
  let data: [String: Any]

  init(path: String) {
    guard let url = BundleToken.bundle.url(forResource: path, withExtension: nil),
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

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
