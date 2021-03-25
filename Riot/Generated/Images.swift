// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Images {
    internal static let socialLoginButtonApple = ImageAsset(name: "social_login_button_apple")
    internal static let socialLoginButtonFacebook = ImageAsset(name: "social_login_button_facebook")
    internal static let socialLoginButtonGithub = ImageAsset(name: "social_login_button_github")
    internal static let socialLoginButtonGitlab = ImageAsset(name: "social_login_button_gitlab")
    internal static let socialLoginButtonGoogle = ImageAsset(name: "social_login_button_google")
    internal static let socialLoginButtonTwitter = ImageAsset(name: "social_login_button_twitter")
    internal static let callAudioMuteOffIcon = ImageAsset(name: "call_audio_mute_off_icon")
    internal static let callAudioMuteOnIcon = ImageAsset(name: "call_audio_mute_on_icon")
    internal static let callChatIcon = ImageAsset(name: "call_chat_icon")
    internal static let callDialpadBackspaceIcon = ImageAsset(name: "call_dialpad_backspace_icon")
    internal static let callDialpadCallIcon = ImageAsset(name: "call_dialpad_call_icon")
    internal static let callHangupLarge = ImageAsset(name: "call_hangup_large")
    internal static let callMoreIcon = ImageAsset(name: "call_more_icon")
    internal static let callPausedIcon = ImageAsset(name: "call_paused_icon")
    internal static let callPausedWhiteIcon = ImageAsset(name: "call_paused_white_icon")
    internal static let callPipIcon = ImageAsset(name: "call_pip_icon")
    internal static let callSpeakerOffIcon = ImageAsset(name: "call_speaker_off_icon")
    internal static let callSpeakerOnIcon = ImageAsset(name: "call_speaker_on_icon")
    internal static let callVideoIcon = ImageAsset(name: "call_video_icon")
    internal static let callVideoMuteOffIcon = ImageAsset(name: "call_video_mute_off_icon")
    internal static let callVideoMuteOnIcon = ImageAsset(name: "call_video_mute_on_icon")
    internal static let callkitIcon = ImageAsset(name: "callkit_icon")
    internal static let cameraSwitch = ImageAsset(name: "camera_switch")
    internal static let appSymbol = ImageAsset(name: "app_symbol")
    internal static let backIcon = ImageAsset(name: "back_icon")
    internal static let camera = ImageAsset(name: "camera")
    internal static let checkmark = ImageAsset(name: "checkmark")
    internal static let chevron = ImageAsset(name: "chevron")
    internal static let closeButton = ImageAsset(name: "close_button")
    internal static let disclosureIcon = ImageAsset(name: "disclosure_icon")
    internal static let errorIcon = ImageAsset(name: "error_icon")
    internal static let faceidIcon = ImageAsset(name: "faceid_icon")
    internal static let group = ImageAsset(name: "group")
    internal static let monitor = ImageAsset(name: "monitor")
    internal static let placeholder = ImageAsset(name: "placeholder")
    internal static let plusIcon = ImageAsset(name: "plus_icon")
    internal static let removeIcon = ImageAsset(name: "remove_icon")
    internal static let revealPasswordButton = ImageAsset(name: "reveal_password_button")
    internal static let selectionTick = ImageAsset(name: "selection_tick")
    internal static let selectionUntick = ImageAsset(name: "selection_untick")
    internal static let shareActionButton = ImageAsset(name: "share_action_button")
    internal static let shrinkIcon = ImageAsset(name: "shrink_icon")
    internal static let smartphone = ImageAsset(name: "smartphone")
    internal static let startChat = ImageAsset(name: "start_chat")
    internal static let touchidIcon = ImageAsset(name: "touchid_icon")
    internal static let addGroupParticipant = ImageAsset(name: "add_group_participant")
    internal static let removeIconBlue = ImageAsset(name: "remove_icon_blue")
    internal static let captureAvatar = ImageAsset(name: "capture_avatar")
    internal static let e2eBlocked = ImageAsset(name: "e2e_blocked")
    internal static let e2eUnencrypted = ImageAsset(name: "e2e_unencrypted")
    internal static let e2eWarning = ImageAsset(name: "e2e_warning")
    internal static let encryptionNormal = ImageAsset(name: "encryption_normal")
    internal static let encryptionTrusted = ImageAsset(name: "encryption_trusted")
    internal static let encryptionWarning = ImageAsset(name: "encryption_warning")
    internal static let favouritesEmptyScreenArtwork = ImageAsset(name: "favourites_empty_screen_artwork")
    internal static let favouritesEmptyScreenArtworkDark = ImageAsset(name: "favourites_empty_screen_artwork_dark")
    internal static let roomActionDirectChat = ImageAsset(name: "room_action_direct_chat")
    internal static let roomActionFavourite = ImageAsset(name: "room_action_favourite")
    internal static let roomActionLeave = ImageAsset(name: "room_action_leave")
    internal static let roomActionNotification = ImageAsset(name: "room_action_notification")
    internal static let roomActionPriorityHigh = ImageAsset(name: "room_action_priority_high")
    internal static let roomActionPriorityLow = ImageAsset(name: "room_action_priority_low")
    internal static let homeEmptyScreenArtwork = ImageAsset(name: "home_empty_screen_artwork")
    internal static let homeEmptyScreenArtworkDark = ImageAsset(name: "home_empty_screen_artwork_dark")
    internal static let plusFloatingAction = ImageAsset(name: "plus_floating_action")
    internal static let closeBanner = ImageAsset(name: "close_banner")
    internal static let importFilesButton = ImageAsset(name: "import_files_button")
    internal static let keyBackupLogo = ImageAsset(name: "key_backup_logo")
    internal static let keyVerificationSuccessShield = ImageAsset(name: "key_verification_success_shield")
    internal static let oldLogo = ImageAsset(name: "old_logo")
    internal static let cameraCapture = ImageAsset(name: "camera_capture")
    internal static let cameraPlay = ImageAsset(name: "camera_play")
    internal static let cameraStop = ImageAsset(name: "camera_stop")
    internal static let cameraVideoCapture = ImageAsset(name: "camera_video_capture")
    internal static let videoIcon = ImageAsset(name: "video_icon")
    internal static let peopleEmptyScreenArtwork = ImageAsset(name: "people_empty_screen_artwork")
    internal static let peopleEmptyScreenArtworkDark = ImageAsset(name: "people_empty_screen_artwork_dark")
    internal static let peopleFloatingAction = ImageAsset(name: "people_floating_action")
    internal static let actionCamera = ImageAsset(name: "action_camera")
    internal static let actionFile = ImageAsset(name: "action_file")
    internal static let actionMediaLibrary = ImageAsset(name: "action_media_library")
    internal static let actionSticker = ImageAsset(name: "action_sticker")
    internal static let error = ImageAsset(name: "error")
    internal static let errorMessageTick = ImageAsset(name: "error_message_tick")
    internal static let roomActivitiesRetry = ImageAsset(name: "room_activities_retry")
    internal static let scrolldown = ImageAsset(name: "scrolldown")
    internal static let scrolldownDark = ImageAsset(name: "scrolldown_dark")
    internal static let sendingMessageTick = ImageAsset(name: "sending_message_tick")
    internal static let sentMessageTick = ImageAsset(name: "sent_message_tick")
    internal static let typing = ImageAsset(name: "typing")
    internal static let roomContextMenuCopy = ImageAsset(name: "room_context_menu_copy")
    internal static let roomContextMenuDelete = ImageAsset(name: "room_context_menu_delete")
    internal static let roomContextMenuEdit = ImageAsset(name: "room_context_menu_edit")
    internal static let roomContextMenuMore = ImageAsset(name: "room_context_menu_more")
    internal static let roomContextMenuReply = ImageAsset(name: "room_context_menu_reply")
    internal static let roomContextMenuRetry = ImageAsset(name: "room_context_menu_retry")
    internal static let inputCloseIcon = ImageAsset(name: "input_close_icon")
    internal static let inputEditIcon = ImageAsset(name: "input_edit_icon")
    internal static let inputReplyIcon = ImageAsset(name: "input_reply_icon")
    internal static let inputTextBackground = ImageAsset(name: "input_text_background")
    internal static let saveIcon = ImageAsset(name: "save_icon")
    internal static let sendIcon = ImageAsset(name: "send_icon")
    internal static let uploadIcon = ImageAsset(name: "upload_icon")
    internal static let uploadIconDark = ImageAsset(name: "upload_icon_dark")
    internal static let videoCall = ImageAsset(name: "video_call")
    internal static let voiceCallHangonIcon = ImageAsset(name: "voice_call_hangon_icon")
    internal static let voiceCallHangupIcon = ImageAsset(name: "voice_call_hangup_icon")
    internal static let addMemberFloatingAction = ImageAsset(name: "add_member_floating_action")
    internal static let addParticipant = ImageAsset(name: "add_participant")
    internal static let addParticipants = ImageAsset(name: "add_participants")
    internal static let detailsIcon = ImageAsset(name: "details_icon")
    internal static let editIcon = ImageAsset(name: "edit_icon")
    internal static let integrationsIcon = ImageAsset(name: "integrations_icon")
    internal static let mainAliasIcon = ImageAsset(name: "main_alias_icon")
    internal static let membersListIcon = ImageAsset(name: "members_list_icon")
    internal static let modIcon = ImageAsset(name: "mod_icon")
    internal static let moreReactions = ImageAsset(name: "more_reactions")
    internal static let scrollup = ImageAsset(name: "scrollup")
    internal static let roomsEmptyScreenArtwork = ImageAsset(name: "rooms_empty_screen_artwork")
    internal static let roomsEmptyScreenArtworkDark = ImageAsset(name: "rooms_empty_screen_artwork_dark")
    internal static let roomsFloatingAction = ImageAsset(name: "rooms_floating_action")
    internal static let userIcon = ImageAsset(name: "user_icon")
    internal static let fileDocIcon = ImageAsset(name: "file_doc_icon")
    internal static let fileMusicIcon = ImageAsset(name: "file_music_icon")
    internal static let filePhotoIcon = ImageAsset(name: "file_photo_icon")
    internal static let fileVideoIcon = ImageAsset(name: "file_video_icon")
    internal static let searchBg = ImageAsset(name: "search_bg")
    internal static let searchIcon = ImageAsset(name: "search_icon")
    internal static let secretsRecoveryKey = ImageAsset(name: "secrets_recovery_key")
    internal static let secretsRecoveryPassphrase = ImageAsset(name: "secrets_recovery_passphrase")
    internal static let secretsSetupKey = ImageAsset(name: "secrets_setup_key")
    internal static let secretsSetupPassphrase = ImageAsset(name: "secrets_setup_passphrase")
    internal static let secretsResetWarning = ImageAsset(name: "secrets_reset_warning")
    internal static let removeIconPink = ImageAsset(name: "remove_icon_pink")
    internal static let settingsIcon = ImageAsset(name: "settings_icon")
    internal static let tabFavourites = ImageAsset(name: "tab_favourites")
    internal static let tabGroups = ImageAsset(name: "tab_groups")
    internal static let tabHome = ImageAsset(name: "tab_home")
    internal static let tabPeople = ImageAsset(name: "tab_people")
    internal static let tabRooms = ImageAsset(name: "tab_rooms")
    internal static let launchScreenLogo = ImageAsset(name: "launch_screen_logo")
  }
  internal enum SharedImages {
    internal static let cancel = ImageAsset(name: "cancel")
    internal static let e2eVerified = ImageAsset(name: "e2e_verified")
    internal static let horizontalLogo = ImageAsset(name: "horizontal_logo")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image named \(name).")
    }
    return result
  }
}

internal extension ImageAsset.Image {
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init!(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
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
