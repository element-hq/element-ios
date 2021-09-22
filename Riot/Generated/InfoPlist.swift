// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Plist Files

// swiftlint:disable identifier_name line_length type_body_length
@objcMembers
public class InfoPlist: NSObject {
  private static let _document = PlistDocument(path: "Info.plist")

  public static let cfBundleDevelopmentRegion: String = _document["CFBundleDevelopmentRegion"]
  public static let cfBundleDisplayName: String = _document["CFBundleDisplayName"]
  public static let cfBundleExecutable: String = _document["CFBundleExecutable"]
  public static let cfBundleIdentifier: String = _document["CFBundleIdentifier"]
  public static let cfBundleInfoDictionaryVersion: String = _document["CFBundleInfoDictionaryVersion"]
  public static let cfBundleName: String = _document["CFBundleName"]
  public static let cfBundlePackageType: String = _document["CFBundlePackageType"]
  public static let cfBundleShortVersionString: String = _document["CFBundleShortVersionString"]
  public static let cfBundleSignature: String = _document["CFBundleSignature"]
  public static let cfBundleURLTypes: [[String: Any]] = _document["CFBundleURLTypes"]
  public static let cfBundleVersion: String = _document["CFBundleVersion"]
  public static let itsAppUsesNonExemptEncryption: Bool = _document["ITSAppUsesNonExemptEncryption"]
  public static let itsEncryptionExportComplianceCode: String = _document["ITSEncryptionExportComplianceCode"]
  public static let lsApplicationQueriesSchemes: [String] = _document["LSApplicationQueriesSchemes"]
  public static let lsRequiresIPhoneOS: Bool = _document["LSRequiresIPhoneOS"]
  public static let nsAppTransportSecurity: [String: Any] = _document["NSAppTransportSecurity"]
  public static let nsCalendarsUsageDescription: String = _document["NSCalendarsUsageDescription"]
  public static let nsCameraUsageDescription: String = _document["NSCameraUsageDescription"]
  public static let nsContactsUsageDescription: String = _document["NSContactsUsageDescription"]
  public static let nsFaceIDUsageDescription: String = _document["NSFaceIDUsageDescription"]
  public static let nsMicrophoneUsageDescription: String = _document["NSMicrophoneUsageDescription"]
  public static let nsPhotoLibraryUsageDescription: String = _document["NSPhotoLibraryUsageDescription"]
  public static let nsSiriUsageDescription: String = _document["NSSiriUsageDescription"]
  public static let uiBackgroundModes: [String] = _document["UIBackgroundModes"]
  public static let uiLaunchStoryboardName: String = _document["UILaunchStoryboardName"]
  public static let uiRequiredDeviceCapabilities: [String] = _document["UIRequiredDeviceCapabilities"]
  public static let uiStatusBarHidden: Bool = _document["UIStatusBarHidden"]
  public static let uiStatusBarTintParameters: [String: Any] = _document["UIStatusBarTintParameters"]
  public static let uiSupportedInterfaceOrientations: [String] = _document["UISupportedInterfaceOrientations"]
  public static let uiSupportedInterfaceOrientationsIpad: [String] = _document["UISupportedInterfaceOrientations~ipad"]
  public static let uiViewControllerBasedStatusBarAppearance: Bool = _document["UIViewControllerBasedStatusBarAppearance"]
  public static let userDefaults: String = _document["UserDefaults"]
  public static let applicationGroupIdentifier: String = _document["applicationGroupIdentifier"]
  public static let baseBundleIdentifier: String = _document["baseBundleIdentifier"]
  public static let keychainAccessGroup: String = _document["keychainAccessGroup"]
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
