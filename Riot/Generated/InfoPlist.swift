// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Plist Files

// swiftlint:disable identifier_name line_length type_body_length
internal enum InfoPlist {
  private static let _document = PlistDocument(path: "Info.plist")

  internal static let cfBundleDevelopmentRegion: String = _document["CFBundleDevelopmentRegion"]
  internal static let cfBundleDisplayName: String = _document["CFBundleDisplayName"]
  internal static let cfBundleExecutable: String = _document["CFBundleExecutable"]
  internal static let cfBundleIdentifier: String = _document["CFBundleIdentifier"]
  internal static let cfBundleInfoDictionaryVersion: String = _document["CFBundleInfoDictionaryVersion"]
  internal static let cfBundleName: String = _document["CFBundleName"]
  internal static let cfBundlePackageType: String = _document["CFBundlePackageType"]
  internal static let cfBundleShortVersionString: String = _document["CFBundleShortVersionString"]
  internal static let cfBundleSignature: String = _document["CFBundleSignature"]
  internal static let cfBundleVersion: String = _document["CFBundleVersion"]
  internal static let itsAppUsesNonExemptEncryption: Bool = _document["ITSAppUsesNonExemptEncryption"]
  internal static let itsEncryptionExportComplianceCode: String = _document["ITSEncryptionExportComplianceCode"]
  internal static let lsRequiresIPhoneOS: Bool = _document["LSRequiresIPhoneOS"]
  internal static let nsAppTransportSecurity: [String: Any] = _document["NSAppTransportSecurity"]
  internal static let nsCalendarsUsageDescription: String = _document["NSCalendarsUsageDescription"]
  internal static let nsCameraUsageDescription: String = _document["NSCameraUsageDescription"]
  internal static let nsContactsUsageDescription: String = _document["NSContactsUsageDescription"]
  internal static let nsFaceIDUsageDescription: String = _document["NSFaceIDUsageDescription"]
  internal static let nsMicrophoneUsageDescription: String = _document["NSMicrophoneUsageDescription"]
  internal static let nsPhotoLibraryUsageDescription: String = _document["NSPhotoLibraryUsageDescription"]
  internal static let nsSiriUsageDescription: String = _document["NSSiriUsageDescription"]
  internal static let uiBackgroundModes: [String] = _document["UIBackgroundModes"]
  internal static let uiLaunchStoryboardName: String = _document["UILaunchStoryboardName"]
  internal static let uiMainStoryboardFile: String = _document["UIMainStoryboardFile"]
  internal static let uiRequiredDeviceCapabilities: [String] = _document["UIRequiredDeviceCapabilities"]
  internal static let uiStatusBarHidden: Bool = _document["UIStatusBarHidden"]
  internal static let uiStatusBarTintParameters: [String: Any] = _document["UIStatusBarTintParameters"]
  internal static let uiSupportedInterfaceOrientations: [String] = _document["UISupportedInterfaceOrientations"]
  internal static let uiSupportedInterfaceOrientationsIpad: [String] = _document["UISupportedInterfaceOrientations~ipad"]
  internal static let uiViewControllerBasedStatusBarAppearance: Bool = _document["UIViewControllerBasedStatusBarAppearance"]
  internal static let userDefaults: String = _document["UserDefaults"]
  internal static let applicationGroupIdentifier: String = _document["applicationGroupIdentifier"]
  internal static let baseBundleIdentifier: String = _document["baseBundleIdentifier"]
  internal static let keychainAccessGroup: String = _document["keychainAccessGroup"]
}
// swiftlint:enable identifier_name line_length type_body_length

// MARK: - Implementation Details

private func arrayFromPlist<T>(at path: String) -> [T] {
  let bundle = BundleToken.bundle
  guard let url = bundle.url(forResource: path, withExtension: nil),
    let data = NSArray(contentsOf: url) as? [T] else {
    fatalError("Unable to load PLIST at path: \(path)")
  }
  return data
}

private struct PlistDocument {
  let data: [String: Any]

  init(path: String) {
    let bundle = BundleToken.bundle
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

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    Bundle(for: BundleToken.self)
  }()
}
// swiftlint:enable convenience_type
