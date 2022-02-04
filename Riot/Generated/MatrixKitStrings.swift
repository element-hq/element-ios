// swiftlint:disable all
// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable function_parameter_count identifier_name line_length type_body_length
@objcMembers
public class MatrixKitL10n: NSObject {
  /// Abort
  public static var abort: String { 
    return MatrixKitL10n.tr("abort") 
  }
  /// Unable to verify email address. Please check your email and click on the link it contains. Once this is done, click continue
  public static var accountEmailValidationError: String { 
    return MatrixKitL10n.tr("account_email_validation_error") 
  }
  /// Please check your email and click on the link it contains. Once this is done, click continue.
  public static var accountEmailValidationMessage: String { 
    return MatrixKitL10n.tr("account_email_validation_message") 
  }
  /// Verification Pending
  public static var accountEmailValidationTitle: String { 
    return MatrixKitL10n.tr("account_email_validation_title") 
  }
  /// Display name change failed
  public static var accountErrorDisplayNameChangeFailed: String { 
    return MatrixKitL10n.tr("account_error_display_name_change_failed") 
  }
  /// This doesn't appear to be a valid email address
  public static var accountErrorEmailWrongDescription: String { 
    return MatrixKitL10n.tr("account_error_email_wrong_description") 
  }
  /// Invalid Email Address
  public static var accountErrorEmailWrongTitle: String { 
    return MatrixKitL10n.tr("account_error_email_wrong_title") 
  }
  /// Matrix session is not opened
  public static var accountErrorMatrixSessionIsNotOpened: String { 
    return MatrixKitL10n.tr("account_error_matrix_session_is_not_opened") 
  }
  /// This doesn't appear to be a valid phone number
  public static var accountErrorMsisdnWrongDescription: String { 
    return MatrixKitL10n.tr("account_error_msisdn_wrong_description") 
  }
  /// Invalid Phone Number
  public static var accountErrorMsisdnWrongTitle: String { 
    return MatrixKitL10n.tr("account_error_msisdn_wrong_title") 
  }
  /// Picture change failed
  public static var accountErrorPictureChangeFailed: String { 
    return MatrixKitL10n.tr("account_error_picture_change_failed") 
  }
  /// Notifications not allowed
  public static var accountErrorPushNotAllowed: String { 
    return MatrixKitL10n.tr("account_error_push_not_allowed") 
  }
  /// Link Email
  public static var accountLinkEmail: String { 
    return MatrixKitL10n.tr("account_link_email") 
  }
  /// Linked emails
  public static var accountLinkedEmails: String { 
    return MatrixKitL10n.tr("account_linked_emails") 
  }
  /// Unable to verify phone number.
  public static var accountMsisdnValidationError: String { 
    return MatrixKitL10n.tr("account_msisdn_validation_error") 
  }
  /// We've sent an SMS with an activation code. Please enter this code below.
  public static var accountMsisdnValidationMessage: String { 
    return MatrixKitL10n.tr("account_msisdn_validation_message") 
  }
  /// Verification Pending
  public static var accountMsisdnValidationTitle: String { 
    return MatrixKitL10n.tr("account_msisdn_validation_title") 
  }
  /// Save changes
  public static var accountSaveChanges: String { 
    return MatrixKitL10n.tr("account_save_changes") 
  }
  /// Logout
  public static var actionLogout: String { 
    return MatrixKitL10n.tr("action_logout") 
  }
  /// Answer Call
  public static var answerCall: String { 
    return MatrixKitL10n.tr("answer_call") 
  }
  /// Attach Media from Library
  public static var attachMedia: String { 
    return MatrixKitL10n.tr("attach_media") 
  }
  /// Cancel the download?
  public static var attachmentCancelDownload: String { 
    return MatrixKitL10n.tr("attachment_cancel_download") 
  }
  /// Cancel the upload?
  public static var attachmentCancelUpload: String { 
    return MatrixKitL10n.tr("attachment_cancel_upload") 
  }
  /// This file contains encryption keys exported from a Matrix client.\nDo you want to view the file content or import the keys it contains?
  public static var attachmentE2eKeysFilePrompt: String { 
    return MatrixKitL10n.tr("attachment_e2e_keys_file_prompt") 
  }
  /// Import...
  public static var attachmentE2eKeysImport: String { 
    return MatrixKitL10n.tr("attachment_e2e_keys_import") 
  }
  /// Large (~%@)
  public static func attachmentLarge(_ p1: String) -> String {
    return MatrixKitL10n.tr("attachment_large", p1)
  }
  /// Large %@ (~%@)
  public static func attachmentLargeWithResolution(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("attachment_large_with_resolution", p1, p2)
  }
  /// Medium (~%@)
  public static func attachmentMedium(_ p1: String) -> String {
    return MatrixKitL10n.tr("attachment_medium", p1)
  }
  /// Medium %@ (~%@)
  public static func attachmentMediumWithResolution(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("attachment_medium_with_resolution", p1, p2)
  }
  /// Actual Size
  public static var attachmentMultiselectionOriginal: String { 
    return MatrixKitL10n.tr("attachment_multiselection_original") 
  }
  /// Do you want to send images as:
  public static var attachmentMultiselectionSizePrompt: String { 
    return MatrixKitL10n.tr("attachment_multiselection_size_prompt") 
  }
  /// Actual Size (%@)
  public static func attachmentOriginal(_ p1: String) -> String {
    return MatrixKitL10n.tr("attachment_original", p1)
  }
  /// Do you want to send as:
  public static var attachmentSizePrompt: String { 
    return MatrixKitL10n.tr("attachment_size_prompt") 
  }
  /// You can turn this off in settings.
  public static var attachmentSizePromptMessage: String { 
    return MatrixKitL10n.tr("attachment_size_prompt_message") 
  }
  /// Confirm size to send
  public static var attachmentSizePromptTitle: String { 
    return MatrixKitL10n.tr("attachment_size_prompt_title") 
  }
  /// Small (~%@)
  public static func attachmentSmall(_ p1: String) -> String {
    return MatrixKitL10n.tr("attachment_small", p1)
  }
  /// Small %@ (~%@)
  public static func attachmentSmallWithResolution(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("attachment_small_with_resolution", p1, p2)
  }
  /// This file type is not supported.
  public static var attachmentUnsupportedPreviewMessage: String { 
    return MatrixKitL10n.tr("attachment_unsupported_preview_message") 
  }
  /// Unable to preview
  public static var attachmentUnsupportedPreviewTitle: String { 
    return MatrixKitL10n.tr("attachment_unsupported_preview_title") 
  }
  /// Invalid username
  public static var authInvalidUserName: String { 
    return MatrixKitL10n.tr("auth_invalid_user_name") 
  }
  /// Not found
  public static var authResetPasswordErrorNotFound: String { 
    return MatrixKitL10n.tr("auth_reset_password_error_not_found") 
  }
  /// Unauthorized
  public static var authResetPasswordErrorUnauthorized: String { 
    return MatrixKitL10n.tr("auth_reset_password_error_unauthorized") 
  }
  /// Username in use
  public static var authUsernameInUse: String { 
    return MatrixKitL10n.tr("auth_username_in_use") 
  }
  /// Back
  public static var back: String { 
    return MatrixKitL10n.tr("back") 
  }
  /// Ban
  public static var ban: String { 
    return MatrixKitL10n.tr("ban") 
  }
  /// Connecting…
  public static var callConnecting: String { 
    return MatrixKitL10n.tr("call_connecting") 
  }
  /// Consulting with %@
  public static func callConsultingWithUser(_ p1: String) -> String {
    return MatrixKitL10n.tr("call_consulting_with_user", p1)
  }
  /// Call ended
  public static var callEnded: String { 
    return MatrixKitL10n.tr("call_ended") 
  }
  /// You held the call
  public static var callHolded: String { 
    return MatrixKitL10n.tr("call_holded") 
  }
  /// Call Invite Expired
  public static var callInviteExpired: String { 
    return MatrixKitL10n.tr("call_invite_expired") 
  }
  /// Device Speaker
  public static var callMoreActionsAudioUseDevice: String { 
    return MatrixKitL10n.tr("call_more_actions_audio_use_device") 
  }
  /// Change Audio Device
  public static var callMoreActionsChangeAudioDevice: String { 
    return MatrixKitL10n.tr("call_more_actions_change_audio_device") 
  }
  /// Dial pad
  public static var callMoreActionsDialpad: String { 
    return MatrixKitL10n.tr("call_more_actions_dialpad") 
  }
  /// Hold
  public static var callMoreActionsHold: String { 
    return MatrixKitL10n.tr("call_more_actions_hold") 
  }
  /// Transfer
  public static var callMoreActionsTransfer: String { 
    return MatrixKitL10n.tr("call_more_actions_transfer") 
  }
  /// Resume
  public static var callMoreActionsUnhold: String { 
    return MatrixKitL10n.tr("call_more_actions_unhold") 
  }
  /// %@ held the call
  public static func callRemoteHolded(_ p1: String) -> String {
    return MatrixKitL10n.tr("call_remote_holded", p1)
  }
  /// Ringing…
  public static var callRinging: String { 
    return MatrixKitL10n.tr("call_ringing") 
  }
  /// Transfer to %@
  public static func callTransferToUser(_ p1: String) -> String {
    return MatrixKitL10n.tr("call_transfer_to_user", p1)
  }
  /// Video call with %@
  public static func callVideoWithUser(_ p1: String) -> String {
    return MatrixKitL10n.tr("call_video_with_user", p1)
  }
  /// Voice call with %@
  public static func callVoiceWithUser(_ p1: String) -> String {
    return MatrixKitL10n.tr("call_voice_with_user", p1)
  }
  /// Video calls require access to the Camera but %@ doesn't have permission to use it
  public static func cameraAccessNotGrantedForCall(_ p1: String) -> String {
    return MatrixKitL10n.tr("camera_access_not_granted_for_call", p1)
  }
  /// Cancel
  public static var cancel: String { 
    return MatrixKitL10n.tr("cancel") 
  }
  /// Cancel Download
  public static var cancelDownload: String { 
    return MatrixKitL10n.tr("cancel_download") 
  }
  /// Cancel Upload
  public static var cancelUpload: String { 
    return MatrixKitL10n.tr("cancel_upload") 
  }
  /// Take Photo/Video
  public static var captureMedia: String { 
    return MatrixKitL10n.tr("capture_media") 
  }
  /// Close
  public static var close: String { 
    return MatrixKitL10n.tr("close") 
  }
  /// Local Contacts
  public static var contactLocalContacts: String { 
    return MatrixKitL10n.tr("contact_local_contacts") 
  }
  /// Matrix Users
  public static var contactMxUsers: String { 
    return MatrixKitL10n.tr("contact_mx_users") 
  }
  /// Continue
  public static var `continue`: String { 
    return MatrixKitL10n.tr("continue") 
  }
  /// Copy
  public static var copyButtonName: String { 
    return MatrixKitL10n.tr("copy_button_name") 
  }
  /// Choose a country
  public static var countryPickerTitle: String { 
    return MatrixKitL10n.tr("country_picker_title") 
  }
  /// Create Account
  public static var createAccount: String { 
    return MatrixKitL10n.tr("create_account") 
  }
  /// Create Room
  public static var createRoom: String { 
    return MatrixKitL10n.tr("create_room") 
  }
  /// default
  public static var `default`: String { 
    return MatrixKitL10n.tr("default") 
  }
  /// Delete
  public static var delete: String { 
    return MatrixKitL10n.tr("delete") 
  }
  /// This operation requires additional authentication.\nTo continue, please enter your password.
  public static var deviceDetailsDeletePromptMessage: String { 
    return MatrixKitL10n.tr("device_details_delete_prompt_message") 
  }
  /// Authentication
  public static var deviceDetailsDeletePromptTitle: String { 
    return MatrixKitL10n.tr("device_details_delete_prompt_title") 
  }
  /// ID\n
  public static var deviceDetailsIdentifier: String { 
    return MatrixKitL10n.tr("device_details_identifier") 
  }
  /// Last seen\n
  public static var deviceDetailsLastSeen: String { 
    return MatrixKitL10n.tr("device_details_last_seen") 
  }
  /// %@ @ %@\n
  public static func deviceDetailsLastSeenFormat(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("device_details_last_seen_format", p1, p2)
  }
  /// Public Name\n
  public static var deviceDetailsName: String { 
    return MatrixKitL10n.tr("device_details_name") 
  }
  /// A session's public name is visible to people you communicate with
  public static var deviceDetailsRenamePromptMessage: String { 
    return MatrixKitL10n.tr("device_details_rename_prompt_message") 
  }
  /// Session Name
  public static var deviceDetailsRenamePromptTitle: String { 
    return MatrixKitL10n.tr("device_details_rename_prompt_title") 
  }
  /// Session information\n
  public static var deviceDetailsTitle: String { 
    return MatrixKitL10n.tr("device_details_title") 
  }
  /// Discard
  public static var discard: String { 
    return MatrixKitL10n.tr("discard") 
  }
  /// Dismiss
  public static var dismiss: String { 
    return MatrixKitL10n.tr("dismiss") 
  }
  /// Export
  public static var e2eExport: String { 
    return MatrixKitL10n.tr("e2e_export") 
  }
  /// This process allows you to export the keys for messages you have received in encrypted rooms to a local file. You will then be able to import the file into another Matrix client in the future, so that client will also be able to decrypt these messages.\nThe exported file will allow anyone who can read it to decrypt any encrypted messages that you can see, so you should be careful to keep it secure.
  public static var e2eExportPrompt: String { 
    return MatrixKitL10n.tr("e2e_export_prompt") 
  }
  /// Export room keys
  public static var e2eExportRoomKeys: String { 
    return MatrixKitL10n.tr("e2e_export_room_keys") 
  }
  /// Import
  public static var e2eImport: String { 
    return MatrixKitL10n.tr("e2e_import") 
  }
  /// This process allows you to import encryption keys that you had previously exported from another Matrix client. You will then be able to decrypt any messages that the other client could decrypt.\nThe export file is protected with a passphrase. You should enter the passphrase here, to decrypt the file.
  public static var e2eImportPrompt: String { 
    return MatrixKitL10n.tr("e2e_import_prompt") 
  }
  /// Import room keys
  public static var e2eImportRoomKeys: String { 
    return MatrixKitL10n.tr("e2e_import_room_keys") 
  }
  /// Confirm passphrase
  public static var e2ePassphraseConfirm: String { 
    return MatrixKitL10n.tr("e2e_passphrase_confirm") 
  }
  /// Create passphrase
  public static var e2ePassphraseCreate: String { 
    return MatrixKitL10n.tr("e2e_passphrase_create") 
  }
  /// Passphrase must not be empty
  public static var e2ePassphraseEmpty: String { 
    return MatrixKitL10n.tr("e2e_passphrase_empty") 
  }
  /// Enter passphrase
  public static var e2ePassphraseEnter: String { 
    return MatrixKitL10n.tr("e2e_passphrase_enter") 
  }
  /// Passphrases must match
  public static var e2ePassphraseNotMatch: String { 
    return MatrixKitL10n.tr("e2e_passphrase_not_match") 
  }
  /// Passphrase too short (It must be at a minimum %d characters in length)
  public static func e2ePassphraseTooShort(_ p1: Int) -> String {
    return MatrixKitL10n.tr("e2e_passphrase_too_short", p1)
  }
  /// End Call
  public static var endCall: String { 
    return MatrixKitL10n.tr("end_call") 
  }
  /// Error
  public static var error: String { 
    return MatrixKitL10n.tr("error") 
  }
  /// An error occured. Please try again later.
  public static var errorCommonMessage: String { 
    return MatrixKitL10n.tr("error_common_message") 
  }
  /// d
  public static var formatTimeD: String { 
    return MatrixKitL10n.tr("format_time_d") 
  }
  /// h
  public static var formatTimeH: String { 
    return MatrixKitL10n.tr("format_time_h") 
  }
  /// m
  public static var formatTimeM: String { 
    return MatrixKitL10n.tr("format_time_m") 
  }
  /// s
  public static var formatTimeS: String { 
    return MatrixKitL10n.tr("format_time_s") 
  }
  /// Invites
  public static var groupInviteSection: String { 
    return MatrixKitL10n.tr("group_invite_section") 
  }
  /// Groups
  public static var groupSection: String { 
    return MatrixKitL10n.tr("group_section") 
  }
  /// Ignore
  public static var ignore: String { 
    return MatrixKitL10n.tr("ignore") 
  }
  /// Incoming Video Call
  public static var incomingVideoCall: String { 
    return MatrixKitL10n.tr("incoming_video_call") 
  }
  /// Incoming Voice Call
  public static var incomingVoiceCall: String { 
    return MatrixKitL10n.tr("incoming_voice_call") 
  }
  /// I'd like to chat with you with matrix. Please, visit the website http://matrix.org to have more information.
  public static var invitationMessage: String { 
    return MatrixKitL10n.tr("invitation_message") 
  }
  /// Invite
  public static var invite: String { 
    return MatrixKitL10n.tr("invite") 
  }
  /// Invite matrix User
  public static var inviteUser: String { 
    return MatrixKitL10n.tr("invite_user") 
  }
  /// Kick
  public static var kick: String { 
    return MatrixKitL10n.tr("kick") 
  }
  /// Default (%@)
  public static func languagePickerDefaultLanguage(_ p1: String) -> String {
    return MatrixKitL10n.tr("language_picker_default_language", p1)
  }
  /// Choose a language
  public static var languagePickerTitle: String { 
    return MatrixKitL10n.tr("language_picker_title") 
  }
  /// Leave
  public static var leave: String { 
    return MatrixKitL10n.tr("leave") 
  }
  /// To discover contacts already using Matrix, %@ can send email addresses and phone numbers in your address book to your chosen Matrix identity server. Where supported, personal data is hashed before sending - please check your identity server's privacy policy for more details.
  public static func localContactsAccessDiscoveryWarning(_ p1: String) -> String {
    return MatrixKitL10n.tr("local_contacts_access_discovery_warning", p1)
  }
  /// Users discovery
  public static var localContactsAccessDiscoveryWarningTitle: String { 
    return MatrixKitL10n.tr("local_contacts_access_discovery_warning_title") 
  }
  /// Users discovery from local contacts requires access to you contacts but %@ doesn't have permission to use it
  public static func localContactsAccessNotGranted(_ p1: String) -> String {
    return MatrixKitL10n.tr("local_contacts_access_not_granted", p1)
  }
  /// Login
  public static var login: String { 
    return MatrixKitL10n.tr("login") 
  }
  /// Create account:
  public static var loginCreateAccount: String { 
    return MatrixKitL10n.tr("login_create_account") 
  }
  /// Desktop
  public static var loginDesktopDevice: String { 
    return MatrixKitL10n.tr("login_desktop_device") 
  }
  /// Display name (e.g. Bob Obson)
  public static var loginDisplayNamePlaceholder: String { 
    return MatrixKitL10n.tr("login_display_name_placeholder") 
  }
  /// Specify an email address lets other users find you on Matrix more easily, and will give you a way to reset your password in the future.
  public static var loginEmailInfo: String { 
    return MatrixKitL10n.tr("login_email_info") 
  }
  /// Email address
  public static var loginEmailPlaceholder: String { 
    return MatrixKitL10n.tr("login_email_placeholder") 
  }
  /// Already logged in
  public static var loginErrorAlreadyLoggedIn: String { 
    return MatrixKitL10n.tr("login_error_already_logged_in") 
  }
  /// Malformed JSON
  public static var loginErrorBadJson: String { 
    return MatrixKitL10n.tr("login_error_bad_json") 
  }
  /// Currently we do not support any or all login flows defined by this homeserver
  public static var loginErrorDoNotSupportLoginFlows: String { 
    return MatrixKitL10n.tr("login_error_do_not_support_login_flows") 
  }
  /// Invalid username/password
  public static var loginErrorForbidden: String { 
    return MatrixKitL10n.tr("login_error_forbidden") 
  }
  /// Forgot password is not currently supported
  public static var loginErrorForgotPasswordIsNotSupported: String { 
    return MatrixKitL10n.tr("login_error_forgot_password_is_not_supported") 
  }
  /// Too many requests have been sent
  public static var loginErrorLimitExceeded: String { 
    return MatrixKitL10n.tr("login_error_limit_exceeded") 
  }
  /// The email link which has not been clicked yet
  public static var loginErrorLoginEmailNotYet: String { 
    return MatrixKitL10n.tr("login_error_login_email_not_yet") 
  }
  /// URL must start with http[s]://
  public static var loginErrorMustStartHttp: String { 
    return MatrixKitL10n.tr("login_error_must_start_http") 
  }
  /// We failed to retrieve authentication information from this homeserver
  public static var loginErrorNoLoginFlow: String { 
    return MatrixKitL10n.tr("login_error_no_login_flow") 
  }
  /// Did not contain valid JSON
  public static var loginErrorNotJson: String { 
    return MatrixKitL10n.tr("login_error_not_json") 
  }
  /// Registration is not currently supported
  public static var loginErrorRegistrationIsNotSupported: String { 
    return MatrixKitL10n.tr("login_error_registration_is_not_supported") 
  }
  /// Contact Administrator
  public static var loginErrorResourceLimitExceededContactButton: String { 
    return MatrixKitL10n.tr("login_error_resource_limit_exceeded_contact_button") 
  }
  /// \n\nPlease contact your service administrator to continue using this service.
  public static var loginErrorResourceLimitExceededMessageContact: String { 
    return MatrixKitL10n.tr("login_error_resource_limit_exceeded_message_contact") 
  }
  /// This homeserver has exceeded one of its resource limits.
  public static var loginErrorResourceLimitExceededMessageDefault: String { 
    return MatrixKitL10n.tr("login_error_resource_limit_exceeded_message_default") 
  }
  /// This homeserver has hit its Monthly Active User limit.
  public static var loginErrorResourceLimitExceededMessageMonthlyActiveUser: String { 
    return MatrixKitL10n.tr("login_error_resource_limit_exceeded_message_monthly_active_user") 
  }
  /// Resource Limit Exceeded
  public static var loginErrorResourceLimitExceededTitle: String { 
    return MatrixKitL10n.tr("login_error_resource_limit_exceeded_title") 
  }
  /// Login Failed
  public static var loginErrorTitle: String { 
    return MatrixKitL10n.tr("login_error_title") 
  }
  /// The access token specified was not recognised
  public static var loginErrorUnknownToken: String { 
    return MatrixKitL10n.tr("login_error_unknown_token") 
  }
  /// This user name is already used
  public static var loginErrorUserInUse: String { 
    return MatrixKitL10n.tr("login_error_user_in_use") 
  }
  /// Your homeserver stores all your conversations and account data
  public static var loginHomeServerInfo: String { 
    return MatrixKitL10n.tr("login_home_server_info") 
  }
  /// Homeserver URL:
  public static var loginHomeServerTitle: String { 
    return MatrixKitL10n.tr("login_home_server_title") 
  }
  /// Matrix provides identity servers to track which emails etc. belong to which Matrix IDs. Only https://matrix.org currently exists.
  public static var loginIdentityServerInfo: String { 
    return MatrixKitL10n.tr("login_identity_server_info") 
  }
  /// Identity server URL:
  public static var loginIdentityServerTitle: String { 
    return MatrixKitL10n.tr("login_identity_server_title") 
  }
  /// Invalid parameter
  public static var loginInvalidParam: String { 
    return MatrixKitL10n.tr("login_invalid_param") 
  }
  /// Cancel
  public static var loginLeaveFallback: String { 
    return MatrixKitL10n.tr("login_leave_fallback") 
  }
  /// Mobile
  public static var loginMobileDevice: String { 
    return MatrixKitL10n.tr("login_mobile_device") 
  }
  /// optional
  public static var loginOptionalField: String { 
    return MatrixKitL10n.tr("login_optional_field") 
  }
  /// Password
  public static var loginPasswordPlaceholder: String { 
    return MatrixKitL10n.tr("login_password_placeholder") 
  }
  /// Please enter your email validation token:
  public static var loginPromptEmailToken: String { 
    return MatrixKitL10n.tr("login_prompt_email_token") 
  }
  /// URL (e.g. https://matrix.org)
  public static var loginServerUrlPlaceholder: String { 
    return MatrixKitL10n.tr("login_server_url_placeholder") 
  }
  /// Tablet
  public static var loginTabletDevice: String { 
    return MatrixKitL10n.tr("login_tablet_device") 
  }
  /// Use fallback page
  public static var loginUseFallback: String { 
    return MatrixKitL10n.tr("login_use_fallback") 
  }
  /// Matrix ID (e.g. @bob:matrix.org or bob)
  public static var loginUserIdPlaceholder: String { 
    return MatrixKitL10n.tr("login_user_id_placeholder") 
  }
  /// Matrix
  public static var matrix: String { 
    return MatrixKitL10n.tr("matrix") 
  }
  /// Banned
  public static var membershipBan: String { 
    return MatrixKitL10n.tr("membership_ban") 
  }
  /// Invited
  public static var membershipInvite: String { 
    return MatrixKitL10n.tr("membership_invite") 
  }
  /// Left
  public static var membershipLeave: String { 
    return MatrixKitL10n.tr("membership_leave") 
  }
  /// Mention
  public static var mention: String { 
    return MatrixKitL10n.tr("mention") 
  }
  /// In reply to
  public static var messageReplyToMessageToReplyToPrefix: String { 
    return MatrixKitL10n.tr("message_reply_to_message_to_reply_to_prefix") 
  }
  /// sent a file.
  public static var messageReplyToSenderSentAFile: String { 
    return MatrixKitL10n.tr("message_reply_to_sender_sent_a_file") 
  }
  /// sent a video.
  public static var messageReplyToSenderSentAVideo: String { 
    return MatrixKitL10n.tr("message_reply_to_sender_sent_a_video") 
  }
  /// sent a voice message.
  public static var messageReplyToSenderSentAVoiceMessage: String { 
    return MatrixKitL10n.tr("message_reply_to_sender_sent_a_voice_message") 
  }
  /// sent an audio file.
  public static var messageReplyToSenderSentAnAudioFile: String { 
    return MatrixKitL10n.tr("message_reply_to_sender_sent_an_audio_file") 
  }
  /// sent an image.
  public static var messageReplyToSenderSentAnImage: String { 
    return MatrixKitL10n.tr("message_reply_to_sender_sent_an_image") 
  }
  /// has shared their location.
  public static var messageReplyToSenderSentTheirLocation: String { 
    return MatrixKitL10n.tr("message_reply_to_sender_sent_their_location") 
  }
  /// There are unsaved changes. Leaving will discard them.
  public static var messageUnsavedChanges: String { 
    return MatrixKitL10n.tr("message_unsaved_changes") 
  }
  /// Calls require access to the Microphone but %@ doesn't have permission to use it
  public static func microphoneAccessNotGrantedForCall(_ p1: String) -> String {
    return MatrixKitL10n.tr("microphone_access_not_granted_for_call", p1)
  }
  /// Voice messages require access to the Microphone but %@ doesn't have permission to use it
  public static func microphoneAccessNotGrantedForVoiceMessage(_ p1: String) -> String {
    return MatrixKitL10n.tr("microphone_access_not_granted_for_voice_message", p1)
  }
  /// Please check your network connectivity
  public static var networkErrorNotReachable: String { 
    return MatrixKitL10n.tr("network_error_not_reachable") 
  }
  /// No
  public static var no: String { 
    return MatrixKitL10n.tr("no") 
  }
  /// Not supported yet
  public static var notSupportedYet: String { 
    return MatrixKitL10n.tr("not_supported_yet") 
  }
  /// %@ answered the call
  public static func noticeAnsweredVideoCall(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_answered_video_call", p1)
  }
  /// You answered the call
  public static var noticeAnsweredVideoCallByYou: String { 
    return MatrixKitL10n.tr("notice_answered_video_call_by_you") 
  }
  /// audio attachment
  public static var noticeAudioAttachment: String { 
    return MatrixKitL10n.tr("notice_audio_attachment") 
  }
  /// (avatar was changed too)
  public static var noticeAvatarChangedToo: String { 
    return MatrixKitL10n.tr("notice_avatar_changed_too") 
  }
  /// %@ changed their avatar
  public static func noticeAvatarUrlChanged(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_avatar_url_changed", p1)
  }
  /// You changed your avatar
  public static var noticeAvatarUrlChangedByYou: String { 
    return MatrixKitL10n.tr("notice_avatar_url_changed_by_you") 
  }
  /// VoIP conference finished
  public static var noticeConferenceCallFinished: String { 
    return MatrixKitL10n.tr("notice_conference_call_finished") 
  }
  /// %@ requested a VoIP conference
  public static func noticeConferenceCallRequest(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_conference_call_request", p1)
  }
  /// You requested a VoIP conference
  public static var noticeConferenceCallRequestByYou: String { 
    return MatrixKitL10n.tr("notice_conference_call_request_by_you") 
  }
  /// VoIP conference started
  public static var noticeConferenceCallStarted: String { 
    return MatrixKitL10n.tr("notice_conference_call_started") 
  }
  /// The sender's session has not sent us the keys for this message.
  public static var noticeCryptoErrorUnknownInboundSessionId: String { 
    return MatrixKitL10n.tr("notice_crypto_error_unknown_inbound_session_id") 
  }
  /// ** Unable to decrypt: %@ **
  public static func noticeCryptoUnableToDecrypt(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_crypto_unable_to_decrypt", p1)
  }
  /// %@ declined the call
  public static func noticeDeclinedVideoCall(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_declined_video_call", p1)
  }
  /// You declined the call
  public static var noticeDeclinedVideoCallByYou: String { 
    return MatrixKitL10n.tr("notice_declined_video_call_by_you") 
  }
  /// %@ changed their display name from %@ to %@
  public static func noticeDisplayNameChangedFrom(_ p1: String, _ p2: String, _ p3: String) -> String {
    return MatrixKitL10n.tr("notice_display_name_changed_from", p1, p2, p3)
  }
  /// You changed your display name from %@ to %@
  public static func noticeDisplayNameChangedFromByYou(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_display_name_changed_from_by_you", p1, p2)
  }
  /// %@ removed their display name
  public static func noticeDisplayNameRemoved(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_display_name_removed", p1)
  }
  /// You removed your display name
  public static var noticeDisplayNameRemovedByYou: String { 
    return MatrixKitL10n.tr("notice_display_name_removed_by_you") 
  }
  /// %@ set their display name to %@
  public static func noticeDisplayNameSet(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_display_name_set", p1, p2)
  }
  /// You set your display name to %@
  public static func noticeDisplayNameSetByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_display_name_set_by_you", p1)
  }
  /// Encrypted message
  public static var noticeEncryptedMessage: String { 
    return MatrixKitL10n.tr("notice_encrypted_message") 
  }
  /// %@ turned on end-to-end encryption.
  public static func noticeEncryptionEnabledOk(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_encryption_enabled_ok", p1)
  }
  /// You turned on end-to-end encryption.
  public static var noticeEncryptionEnabledOkByYou: String { 
    return MatrixKitL10n.tr("notice_encryption_enabled_ok_by_you") 
  }
  /// %1$@ turned on end-to-end encryption (unrecognised algorithm %2$@).
  public static func noticeEncryptionEnabledUnknownAlgorithm(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_encryption_enabled_unknown_algorithm", p1, p2)
  }
  /// You turned on end-to-end encryption (unrecognised algorithm %@).
  public static func noticeEncryptionEnabledUnknownAlgorithmByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_encryption_enabled_unknown_algorithm_by_you", p1)
  }
  /// %@ ended the call
  public static func noticeEndedVideoCall(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_ended_video_call", p1)
  }
  /// You ended the call
  public static var noticeEndedVideoCallByYou: String { 
    return MatrixKitL10n.tr("notice_ended_video_call_by_you") 
  }
  /// Unexpected event
  public static var noticeErrorUnexpectedEvent: String { 
    return MatrixKitL10n.tr("notice_error_unexpected_event") 
  }
  /// Unknown event type
  public static var noticeErrorUnknownEventType: String { 
    return MatrixKitL10n.tr("notice_error_unknown_event_type") 
  }
  /// Unsupported event
  public static var noticeErrorUnsupportedEvent: String { 
    return MatrixKitL10n.tr("notice_error_unsupported_event") 
  }
  /// <redacted%@>
  public static func noticeEventRedacted(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_event_redacted", p1)
  }
  ///  by %@
  public static func noticeEventRedactedBy(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_event_redacted_by", p1)
  }
  ///  by you
  public static var noticeEventRedactedByYou: String { 
    return MatrixKitL10n.tr("notice_event_redacted_by_you") 
  }
  ///  [reason: %@]
  public static func noticeEventRedactedReason(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_event_redacted_reason", p1)
  }
  /// Feedback event (id: %@): %@
  public static func noticeFeedback(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_feedback", p1, p2)
  }
  /// file attachment
  public static var noticeFileAttachment: String { 
    return MatrixKitL10n.tr("notice_file_attachment") 
  }
  /// image attachment
  public static var noticeImageAttachment: String { 
    return MatrixKitL10n.tr("notice_image_attachment") 
  }
  /// In reply to
  public static var noticeInReplyTo: String { 
    return MatrixKitL10n.tr("notice_in_reply_to") 
  }
  /// invalid attachment
  public static var noticeInvalidAttachment: String { 
    return MatrixKitL10n.tr("notice_invalid_attachment") 
  }
  /// location attachment
  public static var noticeLocationAttachment: String { 
    return MatrixKitL10n.tr("notice_location_attachment") 
  }
  /// %@ placed a video call
  public static func noticePlacedVideoCall(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_placed_video_call", p1)
  }
  /// You placed a video call
  public static var noticePlacedVideoCallByYou: String { 
    return MatrixKitL10n.tr("notice_placed_video_call_by_you") 
  }
  /// %@ placed a voice call
  public static func noticePlacedVoiceCall(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_placed_voice_call", p1)
  }
  /// You placed a voice call
  public static var noticePlacedVoiceCallByYou: String { 
    return MatrixKitL10n.tr("notice_placed_voice_call_by_you") 
  }
  /// %@ updated their profile %@
  public static func noticeProfileChangeRedacted(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_profile_change_redacted", p1, p2)
  }
  /// You updated your profile %@
  public static func noticeProfileChangeRedactedByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_profile_change_redacted_by_you", p1)
  }
  /// %@ redacted an event (id: %@)
  public static func noticeRedaction(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_redaction", p1, p2)
  }
  /// You redacted an event (id: %@)
  public static func noticeRedactionByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_redaction_by_you", p1)
  }
  /// The room aliases are: %@
  public static func noticeRoomAliases(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_aliases", p1)
  }
  /// The aliases are: %@
  public static func noticeRoomAliasesForDm(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_aliases_for_dm", p1)
  }
  /// %@ banned %@
  public static func noticeRoomBan(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_room_ban", p1, p2)
  }
  /// You banned %@
  public static func noticeRoomBanByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_ban_by_you", p1)
  }
  /// %@ created and configured the room.
  public static func noticeRoomCreated(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_created", p1)
  }
  /// You created and configured the room.
  public static var noticeRoomCreatedByYou: String { 
    return MatrixKitL10n.tr("notice_room_created_by_you") 
  }
  /// You joined.
  public static var noticeRoomCreatedByYouForDm: String { 
    return MatrixKitL10n.tr("notice_room_created_by_you_for_dm") 
  }
  /// %@ joined.
  public static func noticeRoomCreatedForDm(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_created_for_dm", p1)
  }
  /// %@ made future room history visible to anyone.
  public static func noticeRoomHistoryVisibleToAnyone(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_history_visible_to_anyone", p1)
  }
  /// You made future room history visible to anyone.
  public static var noticeRoomHistoryVisibleToAnyoneByYou: String { 
    return MatrixKitL10n.tr("notice_room_history_visible_to_anyone_by_you") 
  }
  /// %@ made future room history visible to all room members.
  public static func noticeRoomHistoryVisibleToMembers(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_history_visible_to_members", p1)
  }
  /// You made future room history visible to all room members.
  public static var noticeRoomHistoryVisibleToMembersByYou: String { 
    return MatrixKitL10n.tr("notice_room_history_visible_to_members_by_you") 
  }
  /// You made future messages visible to all room members.
  public static var noticeRoomHistoryVisibleToMembersByYouForDm: String { 
    return MatrixKitL10n.tr("notice_room_history_visible_to_members_by_you_for_dm") 
  }
  /// %@ made future messages visible to all room members.
  public static func noticeRoomHistoryVisibleToMembersForDm(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_history_visible_to_members_for_dm", p1)
  }
  /// %@ made future room history visible to all room members, from the point they are invited.
  public static func noticeRoomHistoryVisibleToMembersFromInvitedPoint(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_history_visible_to_members_from_invited_point", p1)
  }
  /// You made future room history visible to all room members, from the point they are invited.
  public static var noticeRoomHistoryVisibleToMembersFromInvitedPointByYou: String { 
    return MatrixKitL10n.tr("notice_room_history_visible_to_members_from_invited_point_by_you") 
  }
  /// You made future messages visible to everyone, from when they get invited.
  public static var noticeRoomHistoryVisibleToMembersFromInvitedPointByYouForDm: String { 
    return MatrixKitL10n.tr("notice_room_history_visible_to_members_from_invited_point_by_you_for_dm") 
  }
  /// %@ made future messages visible to everyone, from when they get invited.
  public static func noticeRoomHistoryVisibleToMembersFromInvitedPointForDm(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_history_visible_to_members_from_invited_point_for_dm", p1)
  }
  /// %@ made future room history visible to all room members, from the point they joined.
  public static func noticeRoomHistoryVisibleToMembersFromJoinedPoint(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_history_visible_to_members_from_joined_point", p1)
  }
  /// You made future room history visible to all room members, from the point they joined.
  public static var noticeRoomHistoryVisibleToMembersFromJoinedPointByYou: String { 
    return MatrixKitL10n.tr("notice_room_history_visible_to_members_from_joined_point_by_you") 
  }
  /// You made future messages visible to everyone, from when they joined.
  public static var noticeRoomHistoryVisibleToMembersFromJoinedPointByYouForDm: String { 
    return MatrixKitL10n.tr("notice_room_history_visible_to_members_from_joined_point_by_you_for_dm") 
  }
  /// %@ made future messages visible to everyone, from when they joined.
  public static func noticeRoomHistoryVisibleToMembersFromJoinedPointForDm(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_history_visible_to_members_from_joined_point_for_dm", p1)
  }
  /// %@ invited %@
  public static func noticeRoomInvite(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_room_invite", p1, p2)
  }
  /// You invited %@
  public static func noticeRoomInviteByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_invite_by_you", p1)
  }
  /// %@ invited you
  public static func noticeRoomInviteYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_invite_you", p1)
  }
  /// %@ joined
  public static func noticeRoomJoin(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_join", p1)
  }
  /// You joined
  public static var noticeRoomJoinByYou: String { 
    return MatrixKitL10n.tr("notice_room_join_by_you") 
  }
  /// The join rule is: %@
  public static func noticeRoomJoinRule(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_join_rule", p1)
  }
  /// %@ made the room invite only.
  public static func noticeRoomJoinRuleInvite(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_join_rule_invite", p1)
  }
  /// You made the room invite only.
  public static var noticeRoomJoinRuleInviteByYou: String { 
    return MatrixKitL10n.tr("notice_room_join_rule_invite_by_you") 
  }
  /// You made this invite only.
  public static var noticeRoomJoinRuleInviteByYouForDm: String { 
    return MatrixKitL10n.tr("notice_room_join_rule_invite_by_you_for_dm") 
  }
  /// %@ made this invite only.
  public static func noticeRoomJoinRuleInviteForDm(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_join_rule_invite_for_dm", p1)
  }
  /// %@ made the room public.
  public static func noticeRoomJoinRulePublic(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_join_rule_public", p1)
  }
  /// You made the room public.
  public static var noticeRoomJoinRulePublicByYou: String { 
    return MatrixKitL10n.tr("notice_room_join_rule_public_by_you") 
  }
  /// You made this public.
  public static var noticeRoomJoinRulePublicByYouForDm: String { 
    return MatrixKitL10n.tr("notice_room_join_rule_public_by_you_for_dm") 
  }
  /// %@ made this public.
  public static func noticeRoomJoinRulePublicForDm(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_join_rule_public_for_dm", p1)
  }
  /// %@ kicked %@
  public static func noticeRoomKick(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_room_kick", p1, p2)
  }
  /// You kicked %@
  public static func noticeRoomKickByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_kick_by_you", p1)
  }
  /// %@ left
  public static func noticeRoomLeave(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_leave", p1)
  }
  /// You left
  public static var noticeRoomLeaveByYou: String { 
    return MatrixKitL10n.tr("notice_room_leave_by_you") 
  }
  /// %@ changed the room name to %@.
  public static func noticeRoomNameChanged(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_room_name_changed", p1, p2)
  }
  /// You changed the room name to %@.
  public static func noticeRoomNameChangedByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_name_changed_by_you", p1)
  }
  /// You changed the name to %@.
  public static func noticeRoomNameChangedByYouForDm(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_name_changed_by_you_for_dm", p1)
  }
  /// %@ changed the name to %@.
  public static func noticeRoomNameChangedForDm(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_room_name_changed_for_dm", p1, p2)
  }
  /// %@ removed the room name
  public static func noticeRoomNameRemoved(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_name_removed", p1)
  }
  /// You removed the room name
  public static var noticeRoomNameRemovedByYou: String { 
    return MatrixKitL10n.tr("notice_room_name_removed_by_you") 
  }
  /// You removed the name
  public static var noticeRoomNameRemovedByYouForDm: String { 
    return MatrixKitL10n.tr("notice_room_name_removed_by_you_for_dm") 
  }
  /// %@ removed the name
  public static func noticeRoomNameRemovedForDm(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_name_removed_for_dm", p1)
  }
  /// The minimum power levels that a user must have before acting are:
  public static var noticeRoomPowerLevelActingRequirement: String { 
    return MatrixKitL10n.tr("notice_room_power_level_acting_requirement") 
  }
  /// The minimum power levels related to events are:
  public static var noticeRoomPowerLevelEventRequirement: String { 
    return MatrixKitL10n.tr("notice_room_power_level_event_requirement") 
  }
  /// The power level of room members are:
  public static var noticeRoomPowerLevelIntro: String { 
    return MatrixKitL10n.tr("notice_room_power_level_intro") 
  }
  /// The power level of members are:
  public static var noticeRoomPowerLevelIntroForDm: String { 
    return MatrixKitL10n.tr("notice_room_power_level_intro_for_dm") 
  }
  /// . Reason: %@
  public static func noticeRoomReason(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_reason", p1)
  }
  /// %@ rejected the invitation
  public static func noticeRoomReject(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_reject", p1)
  }
  /// You rejected the invitation
  public static var noticeRoomRejectByYou: String { 
    return MatrixKitL10n.tr("notice_room_reject_by_you") 
  }
  /// The groups associated with this room are: %@
  public static func noticeRoomRelatedGroups(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_related_groups", p1)
  }
  /// %@ sent an invitation to %@ to join the room
  public static func noticeRoomThirdPartyInvite(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_room_third_party_invite", p1, p2)
  }
  /// You sent an invitation to %@ to join the room
  public static func noticeRoomThirdPartyInviteByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_third_party_invite_by_you", p1)
  }
  /// You invited %@
  public static func noticeRoomThirdPartyInviteByYouForDm(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_third_party_invite_by_you_for_dm", p1)
  }
  /// %@ invited %@
  public static func noticeRoomThirdPartyInviteForDm(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_room_third_party_invite_for_dm", p1, p2)
  }
  /// %@ accepted the invitation for %@
  public static func noticeRoomThirdPartyRegisteredInvite(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_room_third_party_registered_invite", p1, p2)
  }
  /// You accepted the invitation for %@
  public static func noticeRoomThirdPartyRegisteredInviteByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_third_party_registered_invite_by_you", p1)
  }
  /// %@ revoked the invitation for %@ to join the room
  public static func noticeRoomThirdPartyRevokedInvite(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_room_third_party_revoked_invite", p1, p2)
  }
  /// You revoked the invitation for %@ to join the room
  public static func noticeRoomThirdPartyRevokedInviteByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_third_party_revoked_invite_by_you", p1)
  }
  /// You revoked %@'s invitation
  public static func noticeRoomThirdPartyRevokedInviteByYouForDm(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_third_party_revoked_invite_by_you_for_dm", p1)
  }
  /// %@ revoked %@'s invitation
  public static func noticeRoomThirdPartyRevokedInviteForDm(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_room_third_party_revoked_invite_for_dm", p1, p2)
  }
  /// %@ removed the topic
  public static func noticeRoomTopicRemoved(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_topic_removed", p1)
  }
  /// You removed the topic
  public static var noticeRoomTopicRemovedByYou: String { 
    return MatrixKitL10n.tr("notice_room_topic_removed_by_you") 
  }
  /// %@ unbanned %@
  public static func noticeRoomUnban(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_room_unban", p1, p2)
  }
  /// You unbanned %@
  public static func noticeRoomUnbanByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_unban_by_you", p1)
  }
  /// %@ withdrew %@'s invitation
  public static func noticeRoomWithdraw(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_room_withdraw", p1, p2)
  }
  /// You withdrew %@'s invitation
  public static func noticeRoomWithdrawByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_room_withdraw_by_you", p1)
  }
  /// sticker
  public static var noticeSticker: String { 
    return MatrixKitL10n.tr("notice_sticker") 
  }
  /// %@ changed the topic to "%@".
  public static func noticeTopicChanged(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("notice_topic_changed", p1, p2)
  }
  /// You changed the topic to "%@".
  public static func noticeTopicChangedByYou(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_topic_changed_by_you", p1)
  }
  /// Unsupported attachment: %@
  public static func noticeUnsupportedAttachment(_ p1: String) -> String {
    return MatrixKitL10n.tr("notice_unsupported_attachment", p1)
  }
  /// video attachment
  public static var noticeVideoAttachment: String { 
    return MatrixKitL10n.tr("notice_video_attachment") 
  }
  /// Always notify
  public static var notificationSettingsAlwaysNotify: String { 
    return MatrixKitL10n.tr("notification_settings_always_notify") 
  }
  /// By default...
  public static var notificationSettingsByDefault: String { 
    return MatrixKitL10n.tr("notification_settings_by_default") 
  }
  /// Notify me with sound about messages that contain my display name
  public static var notificationSettingsContainMyDisplayName: String { 
    return MatrixKitL10n.tr("notification_settings_contain_my_display_name") 
  }
  /// Notify me with sound about messages that contain my user name
  public static var notificationSettingsContainMyUserName: String { 
    return MatrixKitL10n.tr("notification_settings_contain_my_user_name") 
  }
  /// Custom sound
  public static var notificationSettingsCustomSound: String { 
    return MatrixKitL10n.tr("notification_settings_custom_sound") 
  }
  /// Disable all notifications
  public static var notificationSettingsDisableAll: String { 
    return MatrixKitL10n.tr("notification_settings_disable_all") 
  }
  /// Enable notifications
  public static var notificationSettingsEnableNotifications: String { 
    return MatrixKitL10n.tr("notification_settings_enable_notifications") 
  }
  /// All notifications are currently disabled for all devices.
  public static var notificationSettingsEnableNotificationsWarning: String { 
    return MatrixKitL10n.tr("notification_settings_enable_notifications_warning") 
  }
  /// Notification settings are saved to your user account and are shared between all clients which support them (including desktop notifications).\n\nRules are applied in order; the first rule which matches defines the outcome for the message.\nSo: Per-word notifications are more important than per-room notifications which are more important than per-sender notifications.\nFor multiple rules of the same kind, the first one in the list that matches takes priority.
  public static var notificationSettingsGlobalInfo: String { 
    return MatrixKitL10n.tr("notification_settings_global_info") 
  }
  /// Highlight
  public static var notificationSettingsHighlight: String { 
    return MatrixKitL10n.tr("notification_settings_highlight") 
  }
  /// Notify me when I am invited to a new room
  public static var notificationSettingsInviteToANewRoom: String { 
    return MatrixKitL10n.tr("notification_settings_invite_to_a_new_room") 
  }
  /// Notify me with sound about messages sent just to me
  public static var notificationSettingsJustSentToMe: String { 
    return MatrixKitL10n.tr("notification_settings_just_sent_to_me") 
  }
  /// Never notify
  public static var notificationSettingsNeverNotify: String { 
    return MatrixKitL10n.tr("notification_settings_never_notify") 
  }
  /// Notify for all other messages/rooms
  public static var notificationSettingsNotifyAllOther: String { 
    return MatrixKitL10n.tr("notification_settings_notify_all_other") 
  }
  /// Other Alerts
  public static var notificationSettingsOtherAlerts: String { 
    return MatrixKitL10n.tr("notification_settings_other_alerts") 
  }
  /// Notify me when people join or leave rooms
  public static var notificationSettingsPeopleJoinLeaveRooms: String { 
    return MatrixKitL10n.tr("notification_settings_people_join_leave_rooms") 
  }
  /// Per-room notifications
  public static var notificationSettingsPerRoomNotifications: String { 
    return MatrixKitL10n.tr("notification_settings_per_room_notifications") 
  }
  /// Per-sender notifications
  public static var notificationSettingsPerSenderNotifications: String { 
    return MatrixKitL10n.tr("notification_settings_per_sender_notifications") 
  }
  /// Words match case insensitively, and may include a * wildcard. So:\nfoo matches the string foo surrounded by word delimiters (e.g. punctuation and whitespace or start/end of line).\nfoo* matches any such word that begins foo.\n*foo* matches any such word which includes the 3 letters foo.
  public static var notificationSettingsPerWordInfo: String { 
    return MatrixKitL10n.tr("notification_settings_per_word_info") 
  }
  /// Per-word notifications
  public static var notificationSettingsPerWordNotifications: String { 
    return MatrixKitL10n.tr("notification_settings_per_word_notifications") 
  }
  /// Notify me when I receive a call
  public static var notificationSettingsReceiveACall: String { 
    return MatrixKitL10n.tr("notification_settings_receive_a_call") 
  }
  /// Room: '%@'
  public static func notificationSettingsRoomRuleTitle(_ p1: String) -> String {
    return MatrixKitL10n.tr("notification_settings_room_rule_title", p1)
  }
  /// Select a room
  public static var notificationSettingsSelectRoom: String { 
    return MatrixKitL10n.tr("notification_settings_select_room") 
  }
  /// @user:domain.com
  public static var notificationSettingsSenderHint: String { 
    return MatrixKitL10n.tr("notification_settings_sender_hint") 
  }
  /// Suppress notifications from bots
  public static var notificationSettingsSuppressFromBots: String { 
    return MatrixKitL10n.tr("notification_settings_suppress_from_bots") 
  }
  /// word to match
  public static var notificationSettingsWordToMatch: String { 
    return MatrixKitL10n.tr("notification_settings_word_to_match") 
  }
  /// %@ user
  public static func numMembersOne(_ p1: String) -> String {
    return MatrixKitL10n.tr("num_members_one", p1)
  }
  /// %@ users
  public static func numMembersOther(_ p1: String) -> String {
    return MatrixKitL10n.tr("num_members_other", p1)
  }
  /// offline
  public static var offline: String { 
    return MatrixKitL10n.tr("offline") 
  }
  /// OK
  public static var ok: String { 
    return MatrixKitL10n.tr("ok") 
  }
  /// Power Level
  public static var powerLevel: String { 
    return MatrixKitL10n.tr("power_level") 
  }
  /// Private
  public static var `private`: String { 
    return MatrixKitL10n.tr("private") 
  }
  /// Public
  public static var `public`: String { 
    return MatrixKitL10n.tr("public") 
  }
  /// Remove
  public static var redact: String { 
    return MatrixKitL10n.tr("redact") 
  }
  /// Registration Failed
  public static var registerErrorTitle: String { 
    return MatrixKitL10n.tr("register_error_title") 
  }
  /// Reject Call
  public static var rejectCall: String { 
    return MatrixKitL10n.tr("reject_call") 
  }
  /// Rename
  public static var rename: String { 
    return MatrixKitL10n.tr("rename") 
  }
  /// Resend
  public static var resend: String { 
    return MatrixKitL10n.tr("resend") 
  }
  /// Resend the message
  public static var resendMessage: String { 
    return MatrixKitL10n.tr("resend_message") 
  }
  /// Reset to default
  public static var resetToDefault: String { 
    return MatrixKitL10n.tr("reset_to_default") 
  }
  /// Resume
  public static var resumeCall: String { 
    return MatrixKitL10n.tr("resume_call") 
  }
  /// Retry
  public static var retry: String { 
    return MatrixKitL10n.tr("retry") 
  }
  /// (e.g. #foo:example.org)
  public static var roomCreationAliasPlaceholder: String { 
    return MatrixKitL10n.tr("room_creation_alias_placeholder") 
  }
  /// (e.g. #foo%@)
  public static func roomCreationAliasPlaceholderWithHomeserver(_ p1: String) -> String {
    return MatrixKitL10n.tr("room_creation_alias_placeholder_with_homeserver", p1)
  }
  /// Room alias:
  public static var roomCreationAliasTitle: String { 
    return MatrixKitL10n.tr("room_creation_alias_title") 
  }
  /// (e.g. lunchGroup)
  public static var roomCreationNamePlaceholder: String { 
    return MatrixKitL10n.tr("room_creation_name_placeholder") 
  }
  /// Room name:
  public static var roomCreationNameTitle: String { 
    return MatrixKitL10n.tr("room_creation_name_title") 
  }
  /// (e.g. @bob:homeserver1; @john:homeserver2...)
  public static var roomCreationParticipantsPlaceholder: String { 
    return MatrixKitL10n.tr("room_creation_participants_placeholder") 
  }
  /// Participants:
  public static var roomCreationParticipantsTitle: String { 
    return MatrixKitL10n.tr("room_creation_participants_title") 
  }
  /// Room Details
  public static var roomDetailsTitle: String { 
    return MatrixKitL10n.tr("room_details_title") 
  }
  /// %@ (Left)
  public static func roomDisplaynameAllOtherMembersLeft(_ p1: String) -> String {
    return MatrixKitL10n.tr("room_displayname_all_other_members_left", p1)
  }
  /// Empty room
  public static var roomDisplaynameEmptyRoom: String { 
    return MatrixKitL10n.tr("room_displayname_empty_room") 
  }
  /// %@ and %@ others
  public static func roomDisplaynameMoreThanTwoMembers(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("room_displayname_more_than_two_members", p1, p2)
  }
  /// %@ and %@
  public static func roomDisplaynameTwoMembers(_ p1: String, _ p2: String) -> String {
    return MatrixKitL10n.tr("room_displayname_two_members", p1, p2)
  }
  /// Failed to load timeline
  public static var roomErrorCannotLoadTimeline: String { 
    return MatrixKitL10n.tr("room_error_cannot_load_timeline") 
  }
  /// It is not currently possible to join an empty room.
  public static var roomErrorJoinFailedEmptyRoom: String { 
    return MatrixKitL10n.tr("room_error_join_failed_empty_room") 
  }
  /// Failed to join room
  public static var roomErrorJoinFailedTitle: String { 
    return MatrixKitL10n.tr("room_error_join_failed_title") 
  }
  /// You are not authorized to edit this room name
  public static var roomErrorNameEditionNotAuthorized: String { 
    return MatrixKitL10n.tr("room_error_name_edition_not_authorized") 
  }
  /// The application was trying to load a specific point in this room's timeline but was unable to find it
  public static var roomErrorTimelineEventNotFound: String { 
    return MatrixKitL10n.tr("room_error_timeline_event_not_found") 
  }
  /// Failed to load timeline position
  public static var roomErrorTimelineEventNotFoundTitle: String { 
    return MatrixKitL10n.tr("room_error_timeline_event_not_found_title") 
  }
  /// You are not authorized to edit this room topic
  public static var roomErrorTopicEditionNotAuthorized: String { 
    return MatrixKitL10n.tr("room_error_topic_edition_not_authorized") 
  }
  /// Blacklist
  public static var roomEventEncryptionInfoBlock: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_block") 
  }
  /// \nSender session information\n
  public static var roomEventEncryptionInfoDevice: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_device") 
  }
  /// Blacklisted
  public static var roomEventEncryptionInfoDeviceBlocked: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_device_blocked") 
  }
  /// Ed25519 fingerprint\n
  public static var roomEventEncryptionInfoDeviceFingerprint: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_device_fingerprint") 
  }
  /// ID\n
  public static var roomEventEncryptionInfoDeviceId: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_device_id") 
  }
  /// Public Name\n
  public static var roomEventEncryptionInfoDeviceName: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_device_name") 
  }
  /// NOT verified
  public static var roomEventEncryptionInfoDeviceNotVerified: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_device_not_verified") 
  }
  /// unknown session\n
  public static var roomEventEncryptionInfoDeviceUnknown: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_device_unknown") 
  }
  /// Verification\n
  public static var roomEventEncryptionInfoDeviceVerification: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_device_verification") 
  }
  /// Verified
  public static var roomEventEncryptionInfoDeviceVerified: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_device_verified") 
  }
  /// Event information\n
  public static var roomEventEncryptionInfoEvent: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_event") 
  }
  /// Algorithm\n
  public static var roomEventEncryptionInfoEventAlgorithm: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_event_algorithm") 
  }
  /// Decryption error\n
  public static var roomEventEncryptionInfoEventDecryptionError: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_event_decryption_error") 
  }
  /// Claimed Ed25519 fingerprint key\n
  public static var roomEventEncryptionInfoEventFingerprintKey: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_event_fingerprint_key") 
  }
  /// Curve25519 identity key\n
  public static var roomEventEncryptionInfoEventIdentityKey: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_event_identity_key") 
  }
  /// none
  public static var roomEventEncryptionInfoEventNone: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_event_none") 
  }
  /// Session ID\n
  public static var roomEventEncryptionInfoEventSessionId: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_event_session_id") 
  }
  /// unencrypted
  public static var roomEventEncryptionInfoEventUnencrypted: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_event_unencrypted") 
  }
  /// User ID\n
  public static var roomEventEncryptionInfoEventUserId: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_event_user_id") 
  }
  /// End-to-end encryption information\n\n
  public static var roomEventEncryptionInfoTitle: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_title") 
  }
  /// Unblacklist
  public static var roomEventEncryptionInfoUnblock: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_unblock") 
  }
  /// Unverify
  public static var roomEventEncryptionInfoUnverify: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_unverify") 
  }
  /// Verify...
  public static var roomEventEncryptionInfoVerify: String { 
    return MatrixKitL10n.tr("room_event_encryption_info_verify") 
  }
  /// To verify that this session can be trusted, please contact its owner using some other means (e.g. in person or a phone call) and ask them whether the key they see in their User Settings for this session matches the key below:\n\n	Session name: %@\n	Session ID: %@\n	Session key: %@\n\nIf it matches, press the verify button below. If it doesnt, then someone else is intercepting this session and you probably want to press the blacklist button instead.\n\nIn future this verification process will be more sophisticated.
  public static func roomEventEncryptionVerifyMessage(_ p1: String, _ p2: String, _ p3: String) -> String {
    return MatrixKitL10n.tr("room_event_encryption_verify_message", p1, p2, p3)
  }
  /// Verify
  public static var roomEventEncryptionVerifyOk: String { 
    return MatrixKitL10n.tr("room_event_encryption_verify_ok") 
  }
  /// Verify session\n\n
  public static var roomEventEncryptionVerifyTitle: String { 
    return MatrixKitL10n.tr("room_event_encryption_verify_title") 
  }
  /// You left the room
  public static var roomLeft: String { 
    return MatrixKitL10n.tr("room_left") 
  }
  /// You left
  public static var roomLeftForDm: String { 
    return MatrixKitL10n.tr("room_left_for_dm") 
  }
  /// Are you sure you want to hide all messages from this user?
  public static var roomMemberIgnorePrompt: String { 
    return MatrixKitL10n.tr("room_member_ignore_prompt") 
  }
  /// You will not be able to undo this change as you are promoting the user to have the same power level as yourself.\nAre you sure?
  public static var roomMemberPowerLevelPrompt: String { 
    return MatrixKitL10n.tr("room_member_power_level_prompt") 
  }
  /// Conference calls are not supported in encrypted rooms
  public static var roomNoConferenceCallInEncryptedRooms: String { 
    return MatrixKitL10n.tr("room_no_conference_call_in_encrypted_rooms") 
  }
  /// You need permission to invite to start a conference in this room
  public static var roomNoPowerToCreateConferenceCall: String { 
    return MatrixKitL10n.tr("room_no_power_to_create_conference_call") 
  }
  /// Please select a room
  public static var roomPleaseSelect: String { 
    return MatrixKitL10n.tr("room_please_select") 
  }
  /// Save
  public static var save: String { 
    return MatrixKitL10n.tr("save") 
  }
  /// No Results
  public static var searchNoResults: String { 
    return MatrixKitL10n.tr("search_no_results") 
  }
  /// Search in progress...
  public static var searchSearching: String { 
    return MatrixKitL10n.tr("search_searching") 
  }
  /// Select an account
  public static var selectAccount: String { 
    return MatrixKitL10n.tr("select_account") 
  }
  /// Select All
  public static var selectAll: String { 
    return MatrixKitL10n.tr("select_all") 
  }
  /// Send
  public static var send: String { 
    return MatrixKitL10n.tr("send") 
  }
  /// Set Admin
  public static var setAdmin: String { 
    return MatrixKitL10n.tr("set_admin") 
  }
  /// Reset Power Level
  public static var setDefaultPowerLevel: String { 
    return MatrixKitL10n.tr("set_default_power_level") 
  }
  /// Set Moderator
  public static var setModerator: String { 
    return MatrixKitL10n.tr("set_moderator") 
  }
  /// Set Power Level
  public static var setPowerLevel: String { 
    return MatrixKitL10n.tr("set_power_level") 
  }
  /// Settings
  public static var settings: String { 
    return MatrixKitL10n.tr("settings") 
  }
  /// Homeserver: %@
  public static func settingsConfigHomeServer(_ p1: String) -> String {
    return MatrixKitL10n.tr("settings_config_home_server", p1)
  }
  /// Identity server: %@
  public static func settingsConfigIdentityServer(_ p1: String) -> String {
    return MatrixKitL10n.tr("settings_config_identity_server", p1)
  }
  /// User ID: %@
  public static func settingsConfigUserId(_ p1: String) -> String {
    return MatrixKitL10n.tr("settings_config_user_id", p1)
  }
  /// Enable In-App notifications
  public static var settingsEnableInappNotifications: String { 
    return MatrixKitL10n.tr("settings_enable_inapp_notifications") 
  }
  /// Enable push notifications
  public static var settingsEnablePushNotifications: String { 
    return MatrixKitL10n.tr("settings_enable_push_notifications") 
  }
  /// Enter validation token for %@:
  public static func settingsEnterValidationTokenFor(_ p1: String) -> String {
    return MatrixKitL10n.tr("settings_enter_validation_token_for", p1)
  }
  /// Configuration
  public static var settingsTitleConfig: String { 
    return MatrixKitL10n.tr("settings_title_config") 
  }
  /// Notifications
  public static var settingsTitleNotifications: String { 
    return MatrixKitL10n.tr("settings_title_notifications") 
  }
  /// Share
  public static var share: String { 
    return MatrixKitL10n.tr("share") 
  }
  /// Show Details
  public static var showDetails: String { 
    return MatrixKitL10n.tr("show_details") 
  }
  /// Sign up
  public static var signUp: String { 
    return MatrixKitL10n.tr("sign_up") 
  }
  /// If the server administrator has said that this is expected, ensure that the fingerprint below matches the fingerprint provided by them.
  public static var sslCertNewAccountExpl: String { 
    return MatrixKitL10n.tr("ssl_cert_new_account_expl") 
  }
  /// This could mean that someone is maliciously intercepting your traffic, or that your phone does not trust the certificate provided by the remote server.
  public static var sslCertNotTrust: String { 
    return MatrixKitL10n.tr("ssl_cert_not_trust") 
  }
  /// Could not verify identity of remote server.
  public static var sslCouldNotVerify: String { 
    return MatrixKitL10n.tr("ssl_could_not_verify") 
  }
  /// The certificate has changed from a previously trusted one to one that is not trusted. The server may have renewed its certificate. Contact the server administrator for the expected fingerprint.
  public static var sslExpectedExistingExpl: String { 
    return MatrixKitL10n.tr("ssl_expected_existing_expl") 
  }
  /// Fingerprint (%@):
  public static func sslFingerprintHash(_ p1: String) -> String {
    return MatrixKitL10n.tr("ssl_fingerprint_hash", p1)
  }
  /// Homeserver URL: %@
  public static func sslHomeserverUrl(_ p1: String) -> String {
    return MatrixKitL10n.tr("ssl_homeserver_url", p1)
  }
  /// Logout
  public static var sslLogoutAccount: String { 
    return MatrixKitL10n.tr("ssl_logout_account") 
  }
  /// ONLY accept the certificate if the server administrator has published a fingerprint that matches the one above.
  public static var sslOnlyAccept: String { 
    return MatrixKitL10n.tr("ssl_only_accept") 
  }
  /// Ignore
  public static var sslRemainOffline: String { 
    return MatrixKitL10n.tr("ssl_remain_offline") 
  }
  /// Trust
  public static var sslTrust: String { 
    return MatrixKitL10n.tr("ssl_trust") 
  }
  /// The certificate has changed from one that was trusted by your phone. This is HIGHLY UNUSUAL. It is recommended that you DO NOT ACCEPT this new certificate.
  public static var sslUnexpectedExistingExpl: String { 
    return MatrixKitL10n.tr("ssl_unexpected_existing_expl") 
  }
  /// Start Chat
  public static var startChat: String { 
    return MatrixKitL10n.tr("start_chat") 
  }
  /// Start Video Call
  public static var startVideoCall: String { 
    return MatrixKitL10n.tr("start_video_call") 
  }
  /// Start Voice Call
  public static var startVoiceCall: String { 
    return MatrixKitL10n.tr("start_voice_call") 
  }
  /// Submit
  public static var submit: String { 
    return MatrixKitL10n.tr("submit") 
  }
  /// Submit code
  public static var submitCode: String { 
    return MatrixKitL10n.tr("submit_code") 
  }
  /// Un-ban
  public static var unban: String { 
    return MatrixKitL10n.tr("unban") 
  }
  /// Unignore
  public static var unignore: String { 
    return MatrixKitL10n.tr("unignore") 
  }
  /// Unsent
  public static var unsent: String { 
    return MatrixKitL10n.tr("unsent") 
  }
  /// ex: @bob:homeserver
  public static var userIdPlaceholder: String { 
    return MatrixKitL10n.tr("user_id_placeholder") 
  }
  /// User ID:
  public static var userIdTitle: String { 
    return MatrixKitL10n.tr("user_id_title") 
  }
  /// View
  public static var view: String { 
    return MatrixKitL10n.tr("view") 
  }
  /// Yes
  public static var yes: String { 
    return MatrixKitL10n.tr("yes") 
  }
}
// swiftlint:enable function_parameter_count identifier_name line_length type_body_length

// MARK: - Implementation Details

extension MatrixKitL10n {
  static func tr(_ key: String, _ args: CVarArg...) -> String {
      let format = Bundle.mxk_localizedString(forKey: key)!
      return String(format: format, arguments: args)
    }
}

private final class BundleToken {}
