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
@objcMembers
internal class Asset: NSObject {
  @objcMembers
  @objc(AssetImages) internal class Images: NSObject {
    internal static let analyticsCheckmark = ImageAsset(name: "AnalyticsCheckmark")
    internal static let analyticsLogo = ImageAsset(name: "AnalyticsLogo")
    internal static let socialLoginButtonApple = ImageAsset(name: "social_login_button_apple")
    internal static let socialLoginButtonFacebook = ImageAsset(name: "social_login_button_facebook")
    internal static let socialLoginButtonGithub = ImageAsset(name: "social_login_button_github")
    internal static let socialLoginButtonGitlab = ImageAsset(name: "social_login_button_gitlab")
    internal static let socialLoginButtonGoogle = ImageAsset(name: "social_login_button_google")
    internal static let socialLoginButtonTwitter = ImageAsset(name: "social_login_button_twitter")
    internal static let authenticationServerSelectionEmsLogo = ImageAsset(name: "authentication_server_selection_ems_logo")
    internal static let authenticationServerSelectionIcon = ImageAsset(name: "authentication_server_selection_icon")
    internal static let authenticationSsoIconApple = ImageAsset(name: "authentication_sso_icon_apple")
    internal static let authenticationSsoIconFacebook = ImageAsset(name: "authentication_sso_icon_facebook")
    internal static let authenticationSsoIconGithub = ImageAsset(name: "authentication_sso_icon_github")
    internal static let authenticationSsoIconGitlab = ImageAsset(name: "authentication_sso_icon_gitlab")
    internal static let authenticationSsoIconGoogle = ImageAsset(name: "authentication_sso_icon_google")
    internal static let authenticationSsoIconTwitter = ImageAsset(name: "authentication_sso_icon_twitter")
    internal static let callAudioMuteOffIcon = ImageAsset(name: "call_audio_mute_off_icon")
    internal static let callAudioMuteOnIcon = ImageAsset(name: "call_audio_mute_on_icon")
    internal static let callAudioRouteBuiltin = ImageAsset(name: "call_audio_route_builtin")
    internal static let callAudioRouteHeadphones = ImageAsset(name: "call_audio_route_headphones")
    internal static let callAudioRouteSpeakers = ImageAsset(name: "call_audio_route_speakers")
    internal static let callChatIcon = ImageAsset(name: "call_chat_icon")
    internal static let callDialpadBackspaceIcon = ImageAsset(name: "call_dialpad_backspace_icon")
    internal static let callDialpadCallIcon = ImageAsset(name: "call_dialpad_call_icon")
    internal static let callGoToChatIcon = ImageAsset(name: "call_go_to_chat_icon")
    internal static let callHangupLarge = ImageAsset(name: "call_hangup_large")
    internal static let callMissedVideo = ImageAsset(name: "call_missed_video")
    internal static let callMissedVoice = ImageAsset(name: "call_missed_voice")
    internal static let callMoreIcon = ImageAsset(name: "call_more_icon")
    internal static let callPausedIcon = ImageAsset(name: "call_paused_icon")
    internal static let callPausedWhiteIcon = ImageAsset(name: "call_paused_white_icon")
    internal static let callPipIcon = ImageAsset(name: "call_pip_icon")
    internal static let callSpeakerExternalIcon = ImageAsset(name: "call_speaker_external_icon")
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
    internal static let coachMark = ImageAsset(name: "coach_mark")
    internal static let disclosureIcon = ImageAsset(name: "disclosure_icon")
    internal static let errorIcon = ImageAsset(name: "error_icon")
    internal static let faceidIcon = ImageAsset(name: "faceid_icon")
    internal static let filterOff = ImageAsset(name: "filter_off")
    internal static let filterOn = ImageAsset(name: "filter_on")
    internal static let group = ImageAsset(name: "group")
    internal static let informationButton = ImageAsset(name: "information_button")
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
    internal static let findYourContactsFacepile = ImageAsset(name: "find_your_contacts_facepile")
    internal static let captureAvatar = ImageAsset(name: "capture_avatar")
    internal static let deleteAvatar = ImageAsset(name: "delete_avatar")
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
    internal static let roomActionNotificationMuted = ImageAsset(name: "room_action_notification_muted")
    internal static let roomActionPriorityHigh = ImageAsset(name: "room_action_priority_high")
    internal static let roomActionPriorityLow = ImageAsset(name: "room_action_priority_low")
    internal static let homeEmptyScreenArtwork = ImageAsset(name: "home_empty_screen_artwork")
    internal static let homeEmptyScreenArtworkDark = ImageAsset(name: "home_empty_screen_artwork_dark")
    internal static let plusFloatingAction = ImageAsset(name: "plus_floating_action")
    internal static let versionCheckCloseIcon = ImageAsset(name: "version_check_close_icon")
    internal static let versionCheckInfoIcon = ImageAsset(name: "version_check_info_icon")
    internal static let integrationManagerIconpile = ImageAsset(name: "integration_manager_iconpile")
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
    internal static let onboardingAvatarCamera = ImageAsset(name: "onboarding_avatar_camera")
    internal static let onboardingAvatarEdit = ImageAsset(name: "onboarding_avatar_edit")
    internal static let onboardingCelebrationIcon = ImageAsset(name: "onboarding_celebration_icon")
    internal static let onboardingCongratulationsIcon = ImageAsset(name: "onboarding_congratulations_icon")
    internal static let onboardingSplashScreenPage1 = ImageAsset(name: "onboarding_splash_screen_page_1")
    internal static let onboardingSplashScreenPage1Dark = ImageAsset(name: "onboarding_splash_screen_page_1_dark")
    internal static let onboardingSplashScreenPage2 = ImageAsset(name: "onboarding_splash_screen_page_2")
    internal static let onboardingSplashScreenPage2Dark = ImageAsset(name: "onboarding_splash_screen_page_2_dark")
    internal static let onboardingSplashScreenPage3 = ImageAsset(name: "onboarding_splash_screen_page_3")
    internal static let onboardingSplashScreenPage3Dark = ImageAsset(name: "onboarding_splash_screen_page_3_dark")
    internal static let onboardingSplashScreenPage4 = ImageAsset(name: "onboarding_splash_screen_page_4")
    internal static let onboardingSplashScreenPage4Dark = ImageAsset(name: "onboarding_splash_screen_page_4_dark")
    internal static let onboardingUseCaseCommunity = ImageAsset(name: "onboarding_use_case_community")
    internal static let onboardingUseCaseCommunityDark = ImageAsset(name: "onboarding_use_case_community_dark")
    internal static let onboardingUseCaseIcon = ImageAsset(name: "onboarding_use_case_icon")
    internal static let onboardingUseCasePersonal = ImageAsset(name: "onboarding_use_case_personal")
    internal static let onboardingUseCasePersonalDark = ImageAsset(name: "onboarding_use_case_personal_dark")
    internal static let onboardingUseCaseWork = ImageAsset(name: "onboarding_use_case_work")
    internal static let onboardingUseCaseWorkDark = ImageAsset(name: "onboarding_use_case_work_dark")
    internal static let peopleEmptyScreenArtwork = ImageAsset(name: "people_empty_screen_artwork")
    internal static let peopleEmptyScreenArtworkDark = ImageAsset(name: "people_empty_screen_artwork_dark")
    internal static let peopleFloatingAction = ImageAsset(name: "people_floating_action")
    internal static let actionCamera = ImageAsset(name: "action_camera")
    internal static let actionFile = ImageAsset(name: "action_file")
    internal static let actionLocation = ImageAsset(name: "action_location")
    internal static let actionMediaLibrary = ImageAsset(name: "action_media_library")
    internal static let actionPoll = ImageAsset(name: "action_poll")
    internal static let actionSticker = ImageAsset(name: "action_sticker")
    internal static let error = ImageAsset(name: "error")
    internal static let errorMessageTick = ImageAsset(name: "error_message_tick")
    internal static let newClose = ImageAsset(name: "new_close")
    internal static let roomActivitiesRetry = ImageAsset(name: "room_activities_retry")
    internal static let roomScrollUp = ImageAsset(name: "room_scroll_up")
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
    internal static let roomContextMenuThread = ImageAsset(name: "room_context_menu_thread")
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
    internal static let liveLocationIcon = ImageAsset(name: "live_location_icon")
    internal static let locationCenterMapIcon = ImageAsset(name: "location_center_map_icon")
    internal static let locationLiveCellEndedIcon = ImageAsset(name: "location_live_cell_ended_icon")
    internal static let locationLiveCellIcon = ImageAsset(name: "location_live_cell_icon")
    internal static let locationLiveCellLoadingIcon = ImageAsset(name: "location_live_cell_loading_icon")
    internal static let locationLiveIcon = ImageAsset(name: "location_live_icon")
    internal static let locationMarkerIcon = ImageAsset(name: "location_marker_icon")
    internal static let locationPinIcon = ImageAsset(name: "location_pin_icon")
    internal static let locationPlaceholderBackgroundImage = ImageAsset(name: "location_placeholder_background_image")
    internal static let locationShareIcon = ImageAsset(name: "location_share_icon")
    internal static let locationUserMarker = ImageAsset(name: "location_user_marker")
    internal static let pollCheckboxDefault = ImageAsset(name: "poll_checkbox_default")
    internal static let pollCheckboxSelected = ImageAsset(name: "poll_checkbox_selected")
    internal static let pollDeleteIcon = ImageAsset(name: "poll_delete_icon")
    internal static let pollDeleteOptionIcon = ImageAsset(name: "poll_delete_option_icon")
    internal static let pollEditIcon = ImageAsset(name: "poll_edit_icon")
    internal static let pollEndIcon = ImageAsset(name: "poll_end_icon")
    internal static let pollTypeCheckboxDefault = ImageAsset(name: "poll_type_checkbox_default")
    internal static let pollTypeCheckboxSelected = ImageAsset(name: "poll_type_checkbox_selected")
    internal static let pollWinnerIcon = ImageAsset(name: "poll_winner_icon")
    internal static let threadsFilter = ImageAsset(name: "threads_filter")
    internal static let threadsFilterApplied = ImageAsset(name: "threads_filter_applied")
    internal static let threadsIcon = ImageAsset(name: "threads_icon")
    internal static let threadsIconGrayDotDark = ImageAsset(name: "threads_icon_gray_dot_dark")
    internal static let threadsIconGrayDotLight = ImageAsset(name: "threads_icon_gray_dot_light")
    internal static let threadsIconRedDot = ImageAsset(name: "threads_icon_red_dot")
    internal static let urlPreviewClose = ImageAsset(name: "url_preview_close")
    internal static let urlPreviewCloseDark = ImageAsset(name: "url_preview_close_dark")
    internal static let voiceMessageCancelGradient = ImageAsset(name: "voice_message_cancel_gradient")
    internal static let voiceMessageLockChevron = ImageAsset(name: "voice_message_lock_chevron")
    internal static let voiceMessageLockIconLocked = ImageAsset(name: "voice_message_lock_icon_locked")
    internal static let voiceMessageLockIconUnlocked = ImageAsset(name: "voice_message_lock_icon_unlocked")
    internal static let voiceMessagePauseButton = ImageAsset(name: "voice_message_pause_button")
    internal static let voiceMessagePlayButton = ImageAsset(name: "voice_message_play_button")
    internal static let voiceMessageRecordButtonDefault = ImageAsset(name: "voice_message_record_button_default")
    internal static let voiceMessageRecordButtonRecording = ImageAsset(name: "voice_message_record_button_recording")
    internal static let voiceMessageRecordIcon = ImageAsset(name: "voice_message_record_icon")
    internal static let addMemberFloatingAction = ImageAsset(name: "add_member_floating_action")
    internal static let addParticipant = ImageAsset(name: "add_participant")
    internal static let addParticipants = ImageAsset(name: "add_participants")
    internal static let detailsIcon = ImageAsset(name: "details_icon")
    internal static let editIcon = ImageAsset(name: "edit_icon")
    internal static let fileAttachment = ImageAsset(name: "file_attachment")
    internal static let integrationsIcon = ImageAsset(name: "integrations_icon")
    internal static let linkIcon = ImageAsset(name: "link_icon")
    internal static let mainAliasIcon = ImageAsset(name: "main_alias_icon")
    internal static let membersListIcon = ImageAsset(name: "members_list_icon")
    internal static let modIcon = ImageAsset(name: "mod_icon")
    internal static let moreReactions = ImageAsset(name: "more_reactions")
    internal static let notifications = ImageAsset(name: "notifications")
    internal static let roomAccessInfoHeaderIcon = ImageAsset(name: "room_access_info_header_icon")
    internal static let scrollup = ImageAsset(name: "scrollup")
    internal static let roomsEmptyScreenArtwork = ImageAsset(name: "rooms_empty_screen_artwork")
    internal static let roomsEmptyScreenArtworkDark = ImageAsset(name: "rooms_empty_screen_artwork_dark")
    internal static let roomsFloatingAction = ImageAsset(name: "rooms_floating_action")
    internal static let userIcon = ImageAsset(name: "user_icon")
    internal static let fileDocIcon = ImageAsset(name: "file_doc_icon")
    internal static let fileMusicIcon = ImageAsset(name: "file_music_icon")
    internal static let filePhotoIcon = ImageAsset(name: "file_photo_icon")
    internal static let fileVideoIcon = ImageAsset(name: "file_video_icon")
    internal static let searchIcon = ImageAsset(name: "search_icon")
    internal static let secretsRecoveryKey = ImageAsset(name: "secrets_recovery_key")
    internal static let secretsRecoveryPassphrase = ImageAsset(name: "secrets_recovery_passphrase")
    internal static let secretsSetupKey = ImageAsset(name: "secrets_setup_key")
    internal static let secretsSetupPassphrase = ImageAsset(name: "secrets_setup_passphrase")
    internal static let secretsResetWarning = ImageAsset(name: "secrets_reset_warning")
    internal static let removeIconPink = ImageAsset(name: "remove_icon_pink")
    internal static let settingsIcon = ImageAsset(name: "settings_icon")
    internal static let sideMenuActionIconFeedback = ImageAsset(name: "side_menu_action_icon_feedback")
    internal static let sideMenuActionIconHelp = ImageAsset(name: "side_menu_action_icon_help")
    internal static let sideMenuActionIconSettings = ImageAsset(name: "side_menu_action_icon_settings")
    internal static let sideMenuActionIconShare = ImageAsset(name: "side_menu_action_icon_share")
    internal static let sideMenuIcon = ImageAsset(name: "side_menu_icon")
    internal static let sideMenuNotifIcon = ImageAsset(name: "side_menu_notif_icon")
    internal static let featureUnavaibleArtwork = ImageAsset(name: "feature_unavaible_artwork")
    internal static let featureUnavaibleArtworkDark = ImageAsset(name: "feature_unavaible_artwork_dark")
    internal static let spaceAddRoom = ImageAsset(name: "space_add_room")
    internal static let spaceCreationCamera = ImageAsset(name: "space_creation_camera")
    internal static let spaceCreationPrivate = ImageAsset(name: "space_creation_private")
    internal static let spaceCreationPublic = ImageAsset(name: "space_creation_public")
    internal static let spaceHomeIconDark = ImageAsset(name: "space_home_icon_dark")
    internal static let spaceHomeIconLight = ImageAsset(name: "space_home_icon_light")
    internal static let spaceInviteUser = ImageAsset(name: "space_invite_user")
    internal static let spaceMenuClose = ImageAsset(name: "space_menu_close")
    internal static let spaceMenuLeave = ImageAsset(name: "space_menu_leave")
    internal static let spaceMenuMembers = ImageAsset(name: "space_menu_members")
    internal static let spaceMenuPlusIcon = ImageAsset(name: "space_menu_plus_icon")
    internal static let spaceMenuRooms = ImageAsset(name: "space_menu_rooms")
    internal static let spacePrivateIcon = ImageAsset(name: "space_private_icon")
    internal static let spaceRoomIcon = ImageAsset(name: "space_room_icon")
    internal static let spaceTypeIcon = ImageAsset(name: "space_type_icon")
    internal static let spaceUserIcon = ImageAsset(name: "space_user_icon")
    internal static let spacesAddSpaceDark = ImageAsset(name: "spaces_add_space_dark")
    internal static let spacesAddSpaceLight = ImageAsset(name: "spaces_add_space_light")
    internal static let spacesInviteUsers = ImageAsset(name: "spaces_invite_users")
    internal static let spacesModalBack = ImageAsset(name: "spaces_modal_back")
    internal static let spacesModalClose = ImageAsset(name: "spaces_modal_close")
    internal static let spacesMore = ImageAsset(name: "spaces_more")
    internal static let tabFavourites = ImageAsset(name: "tab_favourites")
    internal static let tabGroups = ImageAsset(name: "tab_groups")
    internal static let tabHome = ImageAsset(name: "tab_home")
    internal static let tabPeople = ImageAsset(name: "tab_people")
    internal static let tabRooms = ImageAsset(name: "tab_rooms")
    internal static let launchScreenLogo = ImageAsset(name: "launch_screen_logo")
  }
  @objcMembers
  @objc(AssetSharedImages) internal class SharedImages: NSObject {
    internal static let cancel = ImageAsset(name: "cancel")
    internal static let e2eVerified = ImageAsset(name: "e2e_verified")
    internal static let horizontalLogo = ImageAsset(name: "horizontal_logo")
    internal static let radioButtonDefault = ImageAsset(name: "radio-button-default")
    internal static let radioButtonSelected = ImageAsset(name: "radio-button-selected")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

@objcMembers
internal class ImageAsset: NSObject {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
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
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  internal init(name: String) {
    self.name = name
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif
}

internal extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
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

