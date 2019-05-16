// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(OSX)
  import AppKit.NSImage
  internal typealias AssetColorTypeAlias = NSColor
  internal typealias AssetImageTypeAlias = NSImage
#elseif os(iOS) || os(tvOS) || os(watchOS)
  import UIKit.UIImage
  internal typealias AssetColorTypeAlias = UIColor
  internal typealias AssetImageTypeAlias = UIImage
#endif

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Images {
    internal static let callAudioMuteOffIcon = ImageAsset(name: "call_audio_mute_off_icon")
    internal static let callAudioMuteOnIcon = ImageAsset(name: "call_audio_mute_on_icon")
    internal static let callChatIcon = ImageAsset(name: "call_chat_icon")
    internal static let callHangupIcon = ImageAsset(name: "call_hangup_icon")
    internal static let callSpeakerOffIcon = ImageAsset(name: "call_speaker_off_icon")
    internal static let callSpeakerOnIcon = ImageAsset(name: "call_speaker_on_icon")
    internal static let callVideoMuteOffIcon = ImageAsset(name: "call_video_mute_off_icon")
    internal static let callVideoMuteOnIcon = ImageAsset(name: "call_video_mute_on_icon")
    internal static let cameraSwitch = ImageAsset(name: "camera_switch")
    internal static let riotIconCallkit = ImageAsset(name: "riot_icon_callkit")
    internal static let adminIcon = ImageAsset(name: "admin_icon")
    internal static let backIcon = ImageAsset(name: "back_icon")
    internal static let chevron = ImageAsset(name: "chevron")
    internal static let disclosureIcon = ImageAsset(name: "disclosure_icon")
    internal static let group = ImageAsset(name: "group")
    internal static let logo = ImageAsset(name: "logo")
    internal static let placeholder = ImageAsset(name: "placeholder")
    internal static let plusIcon = ImageAsset(name: "plus_icon")
    internal static let removeIcon = ImageAsset(name: "remove_icon")
    internal static let selectionTick = ImageAsset(name: "selection_tick")
    internal static let selectionUntick = ImageAsset(name: "selection_untick")
    internal static let shrinkIcon = ImageAsset(name: "shrink_icon")
    internal static let startChat = ImageAsset(name: "start_chat")
    internal static let addGroupParticipant = ImageAsset(name: "add_group_participant")
    internal static let createGroup = ImageAsset(name: "create_group")
    internal static let removeIconBlue = ImageAsset(name: "remove_icon_blue")
    internal static let riotIcon = ImageAsset(name: "riot_icon")
    internal static let e2eBlocked = ImageAsset(name: "e2e_blocked")
    internal static let e2eUnencrypted = ImageAsset(name: "e2e_unencrypted")
    internal static let e2eWarning = ImageAsset(name: "e2e_warning")
    internal static let directChatOff = ImageAsset(name: "directChatOff")
    internal static let directChatOn = ImageAsset(name: "directChatOn")
    internal static let favourite = ImageAsset(name: "favourite")
    internal static let favouriteOff = ImageAsset(name: "favouriteOff")
    internal static let leave = ImageAsset(name: "leave")
    internal static let notifications = ImageAsset(name: "notifications")
    internal static let notificationsOff = ImageAsset(name: "notificationsOff")
    internal static let priorityHigh = ImageAsset(name: "priorityHigh")
    internal static let priorityLow = ImageAsset(name: "priorityLow")
    internal static let createRoom = ImageAsset(name: "create_room")
    internal static let closeBanner = ImageAsset(name: "close_banner")
    internal static let importFilesButton = ImageAsset(name: "import_files_button")
    internal static let keyBackupLogo = ImageAsset(name: "key_backup_logo")
    internal static let revealPasswordButton = ImageAsset(name: "reveal_password_button")
    internal static let launchScreenRiot = ImageAsset(name: "LaunchScreenRiot")
    internal static let cameraCapture = ImageAsset(name: "camera_capture")
    internal static let cameraPlay = ImageAsset(name: "camera_play")
    internal static let cameraStop = ImageAsset(name: "camera_stop")
    internal static let cameraVideoCapture = ImageAsset(name: "camera_video_capture")
    internal static let videoIcon = ImageAsset(name: "video_icon")
    internal static let createDirectChat = ImageAsset(name: "create_direct_chat")
    internal static let error = ImageAsset(name: "error")
    internal static let newmessages = ImageAsset(name: "newmessages")
    internal static let scrolldown = ImageAsset(name: "scrolldown")
    internal static let scrollup = ImageAsset(name: "scrollup")
    internal static let typing = ImageAsset(name: "typing")
    internal static let roomContextMenuCopy = ImageAsset(name: "room_context_menu_copy")
    internal static let roomContextMenuEdit = ImageAsset(name: "room_context_menu_edit")
    internal static let roomContextMenuMore = ImageAsset(name: "room_context_menu_more")
    internal static let roomContextMenuReply = ImageAsset(name: "room_context_menu_reply")
    internal static let uploadIcon = ImageAsset(name: "upload_icon")
    internal static let voiceCallIcon = ImageAsset(name: "voice_call_icon")
    internal static let addParticipant = ImageAsset(name: "add_participant")
    internal static let appsIcon = ImageAsset(name: "apps-icon")
    internal static let detailsIcon = ImageAsset(name: "details_icon")
    internal static let editIcon = ImageAsset(name: "edit_icon")
    internal static let jumpToUnread = ImageAsset(name: "jump_to_unread")
    internal static let mainAliasIcon = ImageAsset(name: "main_alias_icon")
    internal static let membersListIcon = ImageAsset(name: "members_list_icon")
    internal static let modIcon = ImageAsset(name: "mod_icon")
    internal static let fileDocIcon = ImageAsset(name: "file_doc_icon")
    internal static let fileMusicIcon = ImageAsset(name: "file_music_icon")
    internal static let filePhotoIcon = ImageAsset(name: "file_photo_icon")
    internal static let fileVideoIcon = ImageAsset(name: "file_video_icon")
    internal static let searchBg = ImageAsset(name: "search_bg")
    internal static let searchIcon = ImageAsset(name: "search_icon")
    internal static let removeIconPink = ImageAsset(name: "remove_icon_pink")
    internal static let settingsIcon = ImageAsset(name: "settings_icon")
    internal static let tabFavourites = ImageAsset(name: "tab_favourites")
    internal static let tabFavouritesSelected = ImageAsset(name: "tab_favourites_selected")
    internal static let tabGroups = ImageAsset(name: "tab_groups")
    internal static let tabGroupsSelected = ImageAsset(name: "tab_groups_selected")
    internal static let tabHome = ImageAsset(name: "tab_home")
    internal static let tabHomeSelected = ImageAsset(name: "tab_home_selected")
    internal static let tabPeople = ImageAsset(name: "tab_people")
    internal static let tabPeopleSelected = ImageAsset(name: "tab_people_selected")
    internal static let tabRooms = ImageAsset(name: "tab_rooms")
    internal static let tabRoomsSelected = ImageAsset(name: "tab_rooms_selected")
  }
  internal enum SharedImages {
    internal static let animatedLogo0 = ImageAsset(name: "animatedLogo-0")
    internal static let animatedLogo1 = ImageAsset(name: "animatedLogo-1")
    internal static let animatedLogo2 = ImageAsset(name: "animatedLogo-2")
    internal static let animatedLogo3 = ImageAsset(name: "animatedLogo-3")
    internal static let animatedLogo4 = ImageAsset(name: "animatedLogo-4")
    internal static let cancel = ImageAsset(name: "cancel")
    internal static let e2eVerified = ImageAsset(name: "e2e_verified")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal struct ColorAsset {
  internal fileprivate(set) var name: String

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, OSX 10.13, *)
  internal var color: AssetColorTypeAlias {
    return AssetColorTypeAlias(asset: self)
  }
}

internal extension AssetColorTypeAlias {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, OSX 10.13, *)
  convenience init!(asset: ColorAsset) {
    let bundle = Bundle(for: BundleToken.self)
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(OSX)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

internal struct DataAsset {
  internal fileprivate(set) var name: String

  #if os(iOS) || os(tvOS) || os(OSX)
  @available(iOS 9.0, tvOS 9.0, OSX 10.11, *)
  internal var data: NSDataAsset {
    return NSDataAsset(asset: self)
  }
  #endif
}

#if os(iOS) || os(tvOS) || os(OSX)
@available(iOS 9.0, tvOS 9.0, OSX 10.11, *)
internal extension NSDataAsset {
  convenience init!(asset: DataAsset) {
    let bundle = Bundle(for: BundleToken.self)
    #if os(iOS) || os(tvOS)
    self.init(name: asset.name, bundle: bundle)
    #elseif os(OSX)
    self.init(name: NSDataAsset.Name(asset.name), bundle: bundle)
    #endif
  }
}
#endif

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  internal var image: AssetImageTypeAlias {
    let bundle = Bundle(for: BundleToken.self)
    #if os(iOS) || os(tvOS)
    let image = AssetImageTypeAlias(named: name, in: bundle, compatibleWith: nil)
    #elseif os(OSX)
    let image = bundle.image(forResource: NSImage.Name(name))
    #elseif os(watchOS)
    let image = AssetImageTypeAlias(named: name)
    #endif
    guard let result = image else { fatalError("Unable to load image named \(name).") }
    return result
  }
}

internal extension AssetImageTypeAlias {
  @available(iOS 1.0, tvOS 1.0, watchOS 1.0, *)
  @available(OSX, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init!(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = Bundle(for: BundleToken.self)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(OSX)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

private final class BundleToken {}
