// swiftlint:disable all
// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable function_parameter_count identifier_name line_length type_body_length
internal enum VectorL10n {
  /// Accept
  internal static let accept = VectorL10n.tr("Vector", "accept")
  /// Logout all accounts
  internal static let accountLogoutAll = VectorL10n.tr("Vector", "account_logout_all")
  /// Active Call
  internal static let activeCall = VectorL10n.tr("Vector", "active_call")
  /// Active Call (%@)
  internal static func activeCallDetails(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "active_call_details", p1)
  }
  /// Please review and accept the policies of this homeserver:
  internal static let authAcceptPolicies = VectorL10n.tr("Vector", "auth_accept_policies")
  /// Add an email address and a phone number to your account to let users discover you. Email address will also let you reset your password.
  internal static let authAddEmailAndPhoneMessage = VectorL10n.tr("Vector", "auth_add_email_and_phone_message")
  /// Registration with email and phone number at once is not supported yet until the api exists. Only the phone number will be taken into account. You may add your email to your profile in settings.
  internal static let authAddEmailAndPhoneWarning = VectorL10n.tr("Vector", "auth_add_email_and_phone_warning")
  /// Add an email address to your account to let users discover you, and let you reset password.
  internal static let authAddEmailMessage = VectorL10n.tr("Vector", "auth_add_email_message")
  /// Add an email address and/or a phone number to your account to let users discover you. Email address will also let you reset your password.
  internal static let authAddEmailPhoneMessage = VectorL10n.tr("Vector", "auth_add_email_phone_message")
  /// Add a phone number to your account to let users discover you.
  internal static let authAddPhoneMessage = VectorL10n.tr("Vector", "auth_add_phone_message")
  /// This email address is already in use
  internal static let authEmailInUse = VectorL10n.tr("Vector", "auth_email_in_use")
  /// Failed to send email: This email address was not found
  internal static let authEmailNotFound = VectorL10n.tr("Vector", "auth_email_not_found")
  /// Email address
  internal static let authEmailPlaceholder = VectorL10n.tr("Vector", "auth_email_placeholder")
  /// Please check your email to continue registration
  internal static let authEmailValidationMessage = VectorL10n.tr("Vector", "auth_email_validation_message")
  /// Forgot password?
  internal static let authForgotPassword = VectorL10n.tr("Vector", "auth_forgot_password")
  /// URL (e.g. https://matrix.org)
  internal static let authHomeServerPlaceholder = VectorL10n.tr("Vector", "auth_home_server_placeholder")
  /// URL (e.g. https://matrix.org)
  internal static let authIdentityServerPlaceholder = VectorL10n.tr("Vector", "auth_identity_server_placeholder")
  /// This doesn't look like a valid email address
  internal static let authInvalidEmail = VectorL10n.tr("Vector", "auth_invalid_email")
  /// Incorrect username and/or password
  internal static let authInvalidLoginParam = VectorL10n.tr("Vector", "auth_invalid_login_param")
  /// Password too short (min 6)
  internal static let authInvalidPassword = VectorL10n.tr("Vector", "auth_invalid_password")
  /// This doesn't look like a valid phone number
  internal static let authInvalidPhone = VectorL10n.tr("Vector", "auth_invalid_phone")
  /// User names may only contain letters, numbers, dots, hyphens and underscores
  internal static let authInvalidUserName = VectorL10n.tr("Vector", "auth_invalid_user_name")
  /// Log in
  internal static let authLogin = VectorL10n.tr("Vector", "auth_login")
  /// Missing email address
  internal static let authMissingEmail = VectorL10n.tr("Vector", "auth_missing_email")
  /// Missing email address or phone number
  internal static let authMissingEmailOrPhone = VectorL10n.tr("Vector", "auth_missing_email_or_phone")
  /// Missing password
  internal static let authMissingPassword = VectorL10n.tr("Vector", "auth_missing_password")
  /// Missing phone number
  internal static let authMissingPhone = VectorL10n.tr("Vector", "auth_missing_phone")
  /// Unable to verify phone number.
  internal static let authMsisdnValidationError = VectorL10n.tr("Vector", "auth_msisdn_validation_error")
  /// We've sent an SMS with an activation code. Please enter this code below.
  internal static let authMsisdnValidationMessage = VectorL10n.tr("Vector", "auth_msisdn_validation_message")
  /// Verification Pending
  internal static let authMsisdnValidationTitle = VectorL10n.tr("Vector", "auth_msisdn_validation_title")
  /// New password
  internal static let authNewPasswordPlaceholder = VectorL10n.tr("Vector", "auth_new_password_placeholder")
  /// Email address (optional)
  internal static let authOptionalEmailPlaceholder = VectorL10n.tr("Vector", "auth_optional_email_placeholder")
  /// Phone number (optional)
  internal static let authOptionalPhonePlaceholder = VectorL10n.tr("Vector", "auth_optional_phone_placeholder")
  /// Passwords don't match
  internal static let authPasswordDontMatch = VectorL10n.tr("Vector", "auth_password_dont_match")
  /// Password
  internal static let authPasswordPlaceholder = VectorL10n.tr("Vector", "auth_password_placeholder")
  /// This phone number is already in use
  internal static let authPhoneInUse = VectorL10n.tr("Vector", "auth_phone_in_use")
  /// Phone number
  internal static let authPhonePlaceholder = VectorL10n.tr("Vector", "auth_phone_placeholder")
  /// This Home Server would like to make sure you are not a robot
  internal static let authRecaptchaMessage = VectorL10n.tr("Vector", "auth_recaptcha_message")
  /// Register
  internal static let authRegister = VectorL10n.tr("Vector", "auth_register")
  /// Confirm your new password
  internal static let authRepeatNewPasswordPlaceholder = VectorL10n.tr("Vector", "auth_repeat_new_password_placeholder")
  /// Repeat password
  internal static let authRepeatPasswordPlaceholder = VectorL10n.tr("Vector", "auth_repeat_password_placeholder")
  /// An email has been sent to %@. Once you've followed the link it contains, click below.
  internal static func authResetPasswordEmailValidationMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "auth_reset_password_email_validation_message", p1)
  }
  /// Your email address does not appear to be associated with a Matrix ID on this Homeserver.
  internal static let authResetPasswordErrorNotFound = VectorL10n.tr("Vector", "auth_reset_password_error_not_found")
  /// Failed to verify email address: make sure you clicked the link in the email
  internal static let authResetPasswordErrorUnauthorized = VectorL10n.tr("Vector", "auth_reset_password_error_unauthorized")
  /// To reset your password, enter the email address linked to your account:
  internal static let authResetPasswordMessage = VectorL10n.tr("Vector", "auth_reset_password_message")
  /// The email address linked to your account must be entered.
  internal static let authResetPasswordMissingEmail = VectorL10n.tr("Vector", "auth_reset_password_missing_email")
  /// A new password must be entered.
  internal static let authResetPasswordMissingPassword = VectorL10n.tr("Vector", "auth_reset_password_missing_password")
  /// I have verified my email address
  internal static let authResetPasswordNextStepButton = VectorL10n.tr("Vector", "auth_reset_password_next_step_button")
  /// Your password has been reset.\n\nYou have been logged out of all devices and will no longer receive push notifications. To re-enable notifications, re-log in on each device.
  internal static let authResetPasswordSuccessMessage = VectorL10n.tr("Vector", "auth_reset_password_success_message")
  /// Return to login screen
  internal static let authReturnToLogin = VectorL10n.tr("Vector", "auth_return_to_login")
  /// Send Reset Email
  internal static let authSendResetEmail = VectorL10n.tr("Vector", "auth_send_reset_email")
  /// Skip
  internal static let authSkip = VectorL10n.tr("Vector", "auth_skip")
  /// Submit
  internal static let authSubmit = VectorL10n.tr("Vector", "auth_submit")
  /// The identity server is not trusted
  internal static let authUntrustedIdServer = VectorL10n.tr("Vector", "auth_untrusted_id_server")
  /// Use custom server options (advanced)
  internal static let authUseServerOptions = VectorL10n.tr("Vector", "auth_use_server_options")
  /// Email or user name
  internal static let authUserIdPlaceholder = VectorL10n.tr("Vector", "auth_user_id_placeholder")
  /// User name
  internal static let authUserNamePlaceholder = VectorL10n.tr("Vector", "auth_user_name_placeholder")
  /// Username in use
  internal static let authUsernameInUse = VectorL10n.tr("Vector", "auth_username_in_use")
  /// Back
  internal static let back = VectorL10n.tr("Vector", "back")
  /// Please describe what you did before the crash:
  internal static let bugCrashReportDescription = VectorL10n.tr("Vector", "bug_crash_report_description")
  /// Crash Report
  internal static let bugCrashReportTitle = VectorL10n.tr("Vector", "bug_crash_report_title")
  /// Please describe the bug. What did you do? What did you expect to happen? What actually happened?
  internal static let bugReportDescription = VectorL10n.tr("Vector", "bug_report_description")
  /// In order to diagnose problems, logs from this client will be sent with this bug report. If you would prefer to only send the text above, please untick:
  internal static let bugReportLogsDescription = VectorL10n.tr("Vector", "bug_report_logs_description")
  /// Uploading report
  internal static let bugReportProgressUploading = VectorL10n.tr("Vector", "bug_report_progress_uploading")
  /// Collecting logs
  internal static let bugReportProgressZipping = VectorL10n.tr("Vector", "bug_report_progress_zipping")
  /// The application has crashed last time. Would you like to submit a crash report?
  internal static let bugReportPrompt = VectorL10n.tr("Vector", "bug_report_prompt")
  /// Send
  internal static let bugReportSend = VectorL10n.tr("Vector", "bug_report_send")
  /// Send logs
  internal static let bugReportSendLogs = VectorL10n.tr("Vector", "bug_report_send_logs")
  /// Send screenshot
  internal static let bugReportSendScreenshot = VectorL10n.tr("Vector", "bug_report_send_screenshot")
  /// Bug Report
  internal static let bugReportTitle = VectorL10n.tr("Vector", "bug_report_title")
  /// There is already a call in progress.
  internal static let callAlreadyDisplayed = VectorL10n.tr("Vector", "call_already_displayed")
  /// Incoming video call...
  internal static let callIncomingVideo = VectorL10n.tr("Vector", "call_incoming_video")
  /// Incoming video call from %@
  internal static func callIncomingVideoPrompt(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "call_incoming_video_prompt", p1)
  }
  /// Incoming call...
  internal static let callIncomingVoice = VectorL10n.tr("Vector", "call_incoming_voice")
  /// Incoming voice call from %@
  internal static func callIncomingVoicePrompt(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "call_incoming_voice_prompt", p1)
  }
  /// Failed to join the conference call.
  internal static let callJitsiError = VectorL10n.tr("Vector", "call_jitsi_error")
  /// Camera
  internal static let camera = VectorL10n.tr("Vector", "camera")
  /// %@ doesn't have permission to use Camera, please change privacy settings
  internal static func cameraAccessNotGranted(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "camera_access_not_granted", p1)
  }
  /// Cancel
  internal static let cancel = VectorL10n.tr("Vector", "cancel")
  /// collapse
  internal static let collapse = VectorL10n.tr("Vector", "collapse")
  /// Matrix users only
  internal static let contactsAddressBookMatrixUsersToggle = VectorL10n.tr("Vector", "contacts_address_book_matrix_users_toggle")
  /// No local contacts
  internal static let contactsAddressBookNoContact = VectorL10n.tr("Vector", "contacts_address_book_no_contact")
  /// You didn't allow Riot to access your local contacts
  internal static let contactsAddressBookPermissionDenied = VectorL10n.tr("Vector", "contacts_address_book_permission_denied")
  /// Permission required to access local contacts
  internal static let contactsAddressBookPermissionRequired = VectorL10n.tr("Vector", "contacts_address_book_permission_required")
  /// LOCAL CONTACTS
  internal static let contactsAddressBookSection = VectorL10n.tr("Vector", "contacts_address_book_section")
  /// USER DIRECTORY (offline)
  internal static let contactsUserDirectoryOfflineSection = VectorL10n.tr("Vector", "contacts_user_directory_offline_section")
  /// USER DIRECTORY
  internal static let contactsUserDirectorySection = VectorL10n.tr("Vector", "contacts_user_directory_section")
  /// Continue
  internal static let `continue` = VectorL10n.tr("Vector", "continue")
  /// Create
  internal static let create = VectorL10n.tr("Vector", "create")
  /// Please forget all messages I have sent when my account is deactivated (
  internal static let deactivateAccountForgetMessagesInformationPart1 = VectorL10n.tr("Vector", "deactivate_account_forget_messages_information_part1")
  /// Warning
  internal static let deactivateAccountForgetMessagesInformationPart2Emphasize = VectorL10n.tr("Vector", "deactivate_account_forget_messages_information_part2_emphasize")
  /// : this will cause future users to see an incomplete view of conversations)
  internal static let deactivateAccountForgetMessagesInformationPart3 = VectorL10n.tr("Vector", "deactivate_account_forget_messages_information_part3")
  /// This will make your account permanently unusable. You will not be able to log in, and no one will be able to re-register the same user ID.  This will cause your account to leave all rooms it is participating in, and it will remove your account details from your identity server. 
  internal static let deactivateAccountInformationsPart1 = VectorL10n.tr("Vector", "deactivate_account_informations_part1")
  /// This action is irreversible.
  internal static let deactivateAccountInformationsPart2Emphasize = VectorL10n.tr("Vector", "deactivate_account_informations_part2_emphasize")
  /// \n\nDeactivating your account 
  internal static let deactivateAccountInformationsPart3 = VectorL10n.tr("Vector", "deactivate_account_informations_part3")
  /// does not by default cause us to forget messages you have sent. 
  internal static let deactivateAccountInformationsPart4Emphasize = VectorL10n.tr("Vector", "deactivate_account_informations_part4_emphasize")
  /// If you would like us to forget your messages, please tick the box below\n\nMessage visibility in Matrix is similar to email. Our forgetting your messages means that messages you have sent will not be shared with any new or unregistered users, but registered users who already have access to these messages will still have access to their copy.
  internal static let deactivateAccountInformationsPart5 = VectorL10n.tr("Vector", "deactivate_account_informations_part5")
  /// To continue, please enter your password
  internal static let deactivateAccountPasswordAlertMessage = VectorL10n.tr("Vector", "deactivate_account_password_alert_message")
  /// Deactivate Account
  internal static let deactivateAccountPasswordAlertTitle = VectorL10n.tr("Vector", "deactivate_account_password_alert_title")
  /// Deactivate Account
  internal static let deactivateAccountTitle = VectorL10n.tr("Vector", "deactivate_account_title")
  /// Deactivate account
  internal static let deactivateAccountValidateAction = VectorL10n.tr("Vector", "deactivate_account_validate_action")
  /// Decline
  internal static let decline = VectorL10n.tr("Vector", "decline")
  /// %tu rooms
  internal static func directoryCellDescription(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "directory_cell_description", p1)
  }
  /// Browse directory
  internal static let directoryCellTitle = VectorL10n.tr("Vector", "directory_cell_title")
  /// Failed to fetch data
  internal static let directorySearchFail = VectorL10n.tr("Vector", "directory_search_fail")
  /// %tu results found for %@
  internal static func directorySearchResults(_ p1: Int, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "directory_search_results", p1, p2)
  }
  /// >%tu results found for %@
  internal static func directorySearchResultsMoreThan(_ p1: Int, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "directory_search_results_more_than", p1, p2)
  }
  /// Browse directory results
  internal static let directorySearchResultsTitle = VectorL10n.tr("Vector", "directory_search_results_title")
  /// Searching directory…
  internal static let directorySearchingTitle = VectorL10n.tr("Vector", "directory_searching_title")
  /// All native Matrix rooms
  internal static let directoryServerAllNativeRooms = VectorL10n.tr("Vector", "directory_server_all_native_rooms")
  /// All rooms on %@ server
  internal static func directoryServerAllRooms(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "directory_server_all_rooms", p1)
  }
  /// Select a directory
  internal static let directoryServerPickerTitle = VectorL10n.tr("Vector", "directory_server_picker_title")
  /// matrix.org
  internal static let directoryServerPlaceholder = VectorL10n.tr("Vector", "directory_server_placeholder")
  /// Type a homeserver to list public rooms from
  internal static let directoryServerTypeHomeserver = VectorL10n.tr("Vector", "directory_server_type_homeserver")
  /// Directory
  internal static let directoryTitle = VectorL10n.tr("Vector", "directory_title")
  /// Do not ask again
  internal static let doNotAskAgain = VectorL10n.tr("Vector", "do_not_ask_again")
  /// Riot now supports end-to-end encryption but you need to log in again to enable it.\n\nYou can do it now or later from the application settings.
  internal static let e2eEnablingOnAppUpdate = VectorL10n.tr("Vector", "e2e_enabling_on_app_update")
  /// You need to log back in to generate end-to-end encryption keys for this device and submit the public key to your homeserver.\nThis is a once off; sorry for the inconvenience.
  internal static let e2eNeedLogInAgain = VectorL10n.tr("Vector", "e2e_need_log_in_again")
  /// Ignore request
  internal static let e2eRoomKeyRequestIgnoreRequest = VectorL10n.tr("Vector", "e2e_room_key_request_ignore_request")
  /// Your unverified device '%@' is requesting encryption keys.
  internal static func e2eRoomKeyRequestMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "e2e_room_key_request_message", p1)
  }
  /// You added a new device '%@', which is requesting encryption keys.
  internal static func e2eRoomKeyRequestMessageNewDevice(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "e2e_room_key_request_message_new_device", p1)
  }
  /// Share without verifying
  internal static let e2eRoomKeyRequestShareWithoutVerifying = VectorL10n.tr("Vector", "e2e_room_key_request_share_without_verifying")
  /// Start verification...
  internal static let e2eRoomKeyRequestStartVerification = VectorL10n.tr("Vector", "e2e_room_key_request_start_verification")
  /// Encryption key request
  internal static let e2eRoomKeyRequestTitle = VectorL10n.tr("Vector", "e2e_room_key_request_title")
  /// Send an encrypted message…
  internal static let encryptedRoomMessagePlaceholder = VectorL10n.tr("Vector", "encrypted_room_message_placeholder")
  /// Send an encrypted reply…
  internal static let encryptedRoomMessageReplyToPlaceholder = VectorL10n.tr("Vector", "encrypted_room_message_reply_to_placeholder")
  /// VoIP conference added by %@
  internal static func eventFormatterJitsiWidgetAdded(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_jitsi_widget_added", p1)
  }
  /// VoIP conference removed by %@
  internal static func eventFormatterJitsiWidgetRemoved(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_jitsi_widget_removed", p1)
  }
  /// %tu membership changes
  internal static func eventFormatterMemberUpdates(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "event_formatter_member_updates", p1)
  }
  /// Re-request encryption keys
  internal static let eventFormatterRerequestKeysPart1Link = VectorL10n.tr("Vector", "event_formatter_rerequest_keys_part1_link")
  ///  from your other devices.
  internal static let eventFormatterRerequestKeysPart2 = VectorL10n.tr("Vector", "event_formatter_rerequest_keys_part2")
  /// %@ widget added by %@
  internal static func eventFormatterWidgetAdded(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_widget_added", p1, p2)
  }
  /// %@ widget removed by %@
  internal static func eventFormatterWidgetRemoved(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_widget_removed", p1, p2)
  }
  /// To continue using the %@ homeserver you must review and agree to the terms and conditions.
  internal static func gdprConsentNotGivenAlertMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "gdpr_consent_not_given_alert_message", p1)
  }
  /// Review now
  internal static let gdprConsentNotGivenAlertReviewNowAction = VectorL10n.tr("Vector", "gdpr_consent_not_given_alert_review_now_action")
  /// Would you like to help improve %@ by automatically reporting anonymous crash reports and usage data?
  internal static func googleAnalyticsUsePrompt(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "google_analytics_use_prompt", p1)
  }
  /// Home
  internal static let groupDetailsHome = VectorL10n.tr("Vector", "group_details_home")
  /// People
  internal static let groupDetailsPeople = VectorL10n.tr("Vector", "group_details_people")
  /// Rooms
  internal static let groupDetailsRooms = VectorL10n.tr("Vector", "group_details_rooms")
  /// Community Details
  internal static let groupDetailsTitle = VectorL10n.tr("Vector", "group_details_title")
  /// %tu members
  internal static func groupHomeMultiMembersFormat(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "group_home_multi_members_format", p1)
  }
  /// %tu rooms
  internal static func groupHomeMultiRoomsFormat(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "group_home_multi_rooms_format", p1)
  }
  /// 1 member
  internal static let groupHomeOneMemberFormat = VectorL10n.tr("Vector", "group_home_one_member_format")
  /// 1 room
  internal static let groupHomeOneRoomFormat = VectorL10n.tr("Vector", "group_home_one_room_format")
  /// %@ has invited you to join this community
  internal static func groupInvitationFormat(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "group_invitation_format", p1)
  }
  /// INVITES
  internal static let groupInviteSection = VectorL10n.tr("Vector", "group_invite_section")
  /// Add participant
  internal static let groupParticipantsAddParticipant = VectorL10n.tr("Vector", "group_participants_add_participant")
  /// Filter community members
  internal static let groupParticipantsFilterMembers = VectorL10n.tr("Vector", "group_participants_filter_members")
  /// Search / invite by User ID or Name
  internal static let groupParticipantsInviteAnotherUser = VectorL10n.tr("Vector", "group_participants_invite_another_user")
  /// Malformed ID. Should be a Matrix ID like '@localpart:domain'
  internal static let groupParticipantsInviteMalformedId = VectorL10n.tr("Vector", "group_participants_invite_malformed_id")
  /// Invite Error
  internal static let groupParticipantsInviteMalformedIdTitle = VectorL10n.tr("Vector", "group_participants_invite_malformed_id_title")
  /// Are you sure you want to invite %@ to this group?
  internal static func groupParticipantsInvitePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "group_participants_invite_prompt_msg", p1)
  }
  /// Confirmation
  internal static let groupParticipantsInvitePromptTitle = VectorL10n.tr("Vector", "group_participants_invite_prompt_title")
  /// INVITED
  internal static let groupParticipantsInvitedSection = VectorL10n.tr("Vector", "group_participants_invited_section")
  /// Are you sure you want to leave the group?
  internal static let groupParticipantsLeavePromptMsg = VectorL10n.tr("Vector", "group_participants_leave_prompt_msg")
  /// Leave group
  internal static let groupParticipantsLeavePromptTitle = VectorL10n.tr("Vector", "group_participants_leave_prompt_title")
  /// Are you sure you want to remove %@ from this group?
  internal static func groupParticipantsRemovePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "group_participants_remove_prompt_msg", p1)
  }
  /// Confirmation
  internal static let groupParticipantsRemovePromptTitle = VectorL10n.tr("Vector", "group_participants_remove_prompt_title")
  /// Filter community rooms
  internal static let groupRoomsFilterRooms = VectorL10n.tr("Vector", "group_rooms_filter_rooms")
  /// COMMUNITIES
  internal static let groupSection = VectorL10n.tr("Vector", "group_section")
  /// Could not connect to the homeserver.
  internal static let homeserverConnectionLost = VectorL10n.tr("Vector", "homeserver_connection_lost")
  /// Invite
  internal static let invite = VectorL10n.tr("Vector", "invite")
  /// Join
  internal static let join = VectorL10n.tr("Vector", "join")
  /// %.1fK
  internal static func largeBadgeValueKFormat(_ p1: Float) -> String {
    return VectorL10n.tr("Vector", "large_badge_value_k_format", p1)
  }
  /// Later
  internal static let later = VectorL10n.tr("Vector", "later")
  /// Leave
  internal static let leave = VectorL10n.tr("Vector", "leave")
  /// Library
  internal static let mediaPickerLibrary = VectorL10n.tr("Vector", "media_picker_library")
  /// Select
  internal static let mediaPickerSelect = VectorL10n.tr("Vector", "media_picker_select")
  /// The Internet connection appears to be offline.
  internal static let networkOfflinePrompt = VectorL10n.tr("Vector", "network_offline_prompt")
  /// Next
  internal static let next = VectorL10n.tr("Vector", "next")
  /// %@ is calling you but %@ does not support calls yet.\nYou can ignore this notification and answer the call from another device or you can reject it.
  internal static func noVoip(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "no_voip", p1, p2)
  }
  /// Incoming call
  internal static let noVoipTitle = VectorL10n.tr("Vector", "no_voip_title")
  /// Off
  internal static let off = VectorL10n.tr("Vector", "off")
  /// On
  internal static let on = VectorL10n.tr("Vector", "on")
  /// or
  internal static let or = VectorL10n.tr("Vector", "or")
  /// CONVERSATIONS
  internal static let peopleConversationSection = VectorL10n.tr("Vector", "people_conversation_section")
  /// INVITES
  internal static let peopleInvitesSection = VectorL10n.tr("Vector", "people_invites_section")
  /// No conversations
  internal static let peopleNoConversation = VectorL10n.tr("Vector", "people_no_conversation")
  /// Preview
  internal static let preview = VectorL10n.tr("Vector", "preview")
  /// Public Rooms (at %@):
  internal static func publicRoomSectionTitle(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "public_room_section_title", p1)
  }
  /// You seem to be shaking the phone in frustration. Would you like to submit a bug report?
  internal static let rageShakePrompt = VectorL10n.tr("Vector", "rage_shake_prompt")
  /// Read Receipts List
  internal static let readReceiptsList = VectorL10n.tr("Vector", "read_receipts_list")
  /// Read: 
  internal static let receiptStatusRead = VectorL10n.tr("Vector", "receipt_status_read")
  /// Remove
  internal static let remove = VectorL10n.tr("Vector", "remove")
  /// Rename
  internal static let rename = VectorL10n.tr("Vector", "rename")
  /// Please launch Riot on another device that can decrypt the message so it can send the keys to this device.
  internal static let rerequestKeysAlertMessage = VectorL10n.tr("Vector", "rerequest_keys_alert_message")
  /// Request Sent
  internal static let rerequestKeysAlertTitle = VectorL10n.tr("Vector", "rerequest_keys_alert_title")
  /// Retry
  internal static let retry = VectorL10n.tr("Vector", "retry")
  /// Send photo or video
  internal static let roomActionSendPhotoOrVideo = VectorL10n.tr("Vector", "room_action_send_photo_or_video")
  /// Send sticker
  internal static let roomActionSendSticker = VectorL10n.tr("Vector", "room_action_send_sticker")
  /// You need permission to manage conference call in this room
  internal static let roomConferenceCallNoPower = VectorL10n.tr("Vector", "room_conference_call_no_power")
  /// Account
  internal static let roomCreationAccount = VectorL10n.tr("Vector", "room_creation_account")
  /// Appearance
  internal static let roomCreationAppearance = VectorL10n.tr("Vector", "room_creation_appearance")
  /// Name
  internal static let roomCreationAppearanceName = VectorL10n.tr("Vector", "room_creation_appearance_name")
  /// Chat picture (optional)
  internal static let roomCreationAppearancePicture = VectorL10n.tr("Vector", "room_creation_appearance_picture")
  /// Search / invite by User ID, Name or email
  internal static let roomCreationInviteAnotherUser = VectorL10n.tr("Vector", "room_creation_invite_another_user")
  /// Keep private
  internal static let roomCreationKeepPrivate = VectorL10n.tr("Vector", "room_creation_keep_private")
  /// Make private
  internal static let roomCreationMakePrivate = VectorL10n.tr("Vector", "room_creation_make_private")
  /// Make public
  internal static let roomCreationMakePublic = VectorL10n.tr("Vector", "room_creation_make_public")
  /// Are you sure you want to make this chat public? Anyone can read your messages and join the chat.
  internal static let roomCreationMakePublicPromptMsg = VectorL10n.tr("Vector", "room_creation_make_public_prompt_msg")
  /// Make this chat public?
  internal static let roomCreationMakePublicPromptTitle = VectorL10n.tr("Vector", "room_creation_make_public_prompt_title")
  /// Privacy
  internal static let roomCreationPrivacy = VectorL10n.tr("Vector", "room_creation_privacy")
  /// This chat is private
  internal static let roomCreationPrivateRoom = VectorL10n.tr("Vector", "room_creation_private_room")
  /// This chat is public
  internal static let roomCreationPublicRoom = VectorL10n.tr("Vector", "room_creation_public_room")
  /// New Chat
  internal static let roomCreationTitle = VectorL10n.tr("Vector", "room_creation_title")
  /// A room is already being created. Please wait.
  internal static let roomCreationWaitForCreation = VectorL10n.tr("Vector", "room_creation_wait_for_creation")
  /// Delete unsent messages
  internal static let roomDeleteUnsentMessages = VectorL10n.tr("Vector", "room_delete_unsent_messages")
  /// Who can access this room?
  internal static let roomDetailsAccessSection = VectorL10n.tr("Vector", "room_details_access_section")
  /// Anyone who knows the room's link, including guests
  internal static let roomDetailsAccessSectionAnyone = VectorL10n.tr("Vector", "room_details_access_section_anyone")
  /// Anyone who knows the room's link, apart from guests
  internal static let roomDetailsAccessSectionAnyoneApartFromGuest = VectorL10n.tr("Vector", "room_details_access_section_anyone_apart_from_guest")
  /// List this room in room directory
  internal static let roomDetailsAccessSectionDirectoryToggle = VectorL10n.tr("Vector", "room_details_access_section_directory_toggle")
  /// Only people who have been invited
  internal static let roomDetailsAccessSectionInvitedOnly = VectorL10n.tr("Vector", "room_details_access_section_invited_only")
  /// To link to a room it must have an address
  internal static let roomDetailsAccessSectionNoAddressWarning = VectorL10n.tr("Vector", "room_details_access_section_no_address_warning")
  /// You will have no main address specified. The default main address for this room will be picked randomly
  internal static let roomDetailsAddressesDisableMainAddressPromptMsg = VectorL10n.tr("Vector", "room_details_addresses_disable_main_address_prompt_msg")
  /// Main address warning
  internal static let roomDetailsAddressesDisableMainAddressPromptTitle = VectorL10n.tr("Vector", "room_details_addresses_disable_main_address_prompt_title")
  /// %@ is not a valid format for an alias
  internal static func roomDetailsAddressesInvalidAddressPromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_details_addresses_invalid_address_prompt_msg", p1)
  }
  /// Invalid alias format
  internal static let roomDetailsAddressesInvalidAddressPromptTitle = VectorL10n.tr("Vector", "room_details_addresses_invalid_address_prompt_title")
  /// Addresses
  internal static let roomDetailsAddressesSection = VectorL10n.tr("Vector", "room_details_addresses_section")
  /// Encrypt to verified devices only
  internal static let roomDetailsAdvancedE2eEncryptionBlacklistUnverifiedDevices = VectorL10n.tr("Vector", "room_details_advanced_e2e_encryption_blacklist_unverified_devices")
  /// Encryption is not enabled in this room.
  internal static let roomDetailsAdvancedE2eEncryptionDisabled = VectorL10n.tr("Vector", "room_details_advanced_e2e_encryption_disabled")
  /// Encryption is enabled in this room
  internal static let roomDetailsAdvancedE2eEncryptionEnabled = VectorL10n.tr("Vector", "room_details_advanced_e2e_encryption_enabled")
  /// End-to-end encryption is experimental and may not be reliable.\n\nYou should not yet trust it to secure data.\n\nDevices will not yet be able to decrypt history from before they joined the room.\n\nOnce encryption is enabled for a room it cannot be turned off again (for now).\n\nEncrypted messages will not be visible on clients that do not yet implement encryption.
  internal static let roomDetailsAdvancedE2eEncryptionPromptMessage = VectorL10n.tr("Vector", "room_details_advanced_e2e_encryption_prompt_message")
  /// Enable encryption (warning: cannot be disabled again!)
  internal static let roomDetailsAdvancedEnableE2eEncryption = VectorL10n.tr("Vector", "room_details_advanced_enable_e2e_encryption")
  /// Room ID:
  internal static let roomDetailsAdvancedRoomId = VectorL10n.tr("Vector", "room_details_advanced_room_id")
  /// Advanced
  internal static let roomDetailsAdvancedSection = VectorL10n.tr("Vector", "room_details_advanced_section")
  /// Banned users
  internal static let roomDetailsBannedUsersSection = VectorL10n.tr("Vector", "room_details_banned_users_section")
  /// Copy Room Address
  internal static let roomDetailsCopyRoomAddress = VectorL10n.tr("Vector", "room_details_copy_room_address")
  /// Copy Room ID
  internal static let roomDetailsCopyRoomId = VectorL10n.tr("Vector", "room_details_copy_room_id")
  /// Copy Room URL
  internal static let roomDetailsCopyRoomUrl = VectorL10n.tr("Vector", "room_details_copy_room_url")
  /// Direct Chat
  internal static let roomDetailsDirectChat = VectorL10n.tr("Vector", "room_details_direct_chat")
  /// Fail to add the new room addresses
  internal static let roomDetailsFailToAddRoomAliases = VectorL10n.tr("Vector", "room_details_fail_to_add_room_aliases")
  /// Fail to enable encryption in this room
  internal static let roomDetailsFailToEnableEncryption = VectorL10n.tr("Vector", "room_details_fail_to_enable_encryption")
  /// Fail to remove the room addresses
  internal static let roomDetailsFailToRemoveRoomAliases = VectorL10n.tr("Vector", "room_details_fail_to_remove_room_aliases")
  /// Fail to update the room photo
  internal static let roomDetailsFailToUpdateAvatar = VectorL10n.tr("Vector", "room_details_fail_to_update_avatar")
  /// Fail to update the history visibility
  internal static let roomDetailsFailToUpdateHistoryVisibility = VectorL10n.tr("Vector", "room_details_fail_to_update_history_visibility")
  /// Fail to update the main address
  internal static let roomDetailsFailToUpdateRoomCanonicalAlias = VectorL10n.tr("Vector", "room_details_fail_to_update_room_canonical_alias")
  /// Fail to update the related communities
  internal static let roomDetailsFailToUpdateRoomCommunities = VectorL10n.tr("Vector", "room_details_fail_to_update_room_communities")
  /// Fail to update the direct flag of this room
  internal static let roomDetailsFailToUpdateRoomDirect = VectorL10n.tr("Vector", "room_details_fail_to_update_room_direct")
  /// Fail to update the room directory visibility
  internal static let roomDetailsFailToUpdateRoomDirectoryVisibility = VectorL10n.tr("Vector", "room_details_fail_to_update_room_directory_visibility")
  /// Fail to update the room guest access
  internal static let roomDetailsFailToUpdateRoomGuestAccess = VectorL10n.tr("Vector", "room_details_fail_to_update_room_guest_access")
  /// Fail to update the join rule
  internal static let roomDetailsFailToUpdateRoomJoinRule = VectorL10n.tr("Vector", "room_details_fail_to_update_room_join_rule")
  /// Fail to update the room name
  internal static let roomDetailsFailToUpdateRoomName = VectorL10n.tr("Vector", "room_details_fail_to_update_room_name")
  /// Fail to update the topic
  internal static let roomDetailsFailToUpdateTopic = VectorL10n.tr("Vector", "room_details_fail_to_update_topic")
  /// Favourite
  internal static let roomDetailsFavouriteTag = VectorL10n.tr("Vector", "room_details_favourite_tag")
  /// Files
  internal static let roomDetailsFiles = VectorL10n.tr("Vector", "room_details_files")
  /// %@ is not a valid identifier for a community
  internal static func roomDetailsFlairInvalidIdPromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_details_flair_invalid_id_prompt_msg", p1)
  }
  /// Invalid format
  internal static let roomDetailsFlairInvalidIdPromptTitle = VectorL10n.tr("Vector", "room_details_flair_invalid_id_prompt_title")
  /// Show flair for communities
  internal static let roomDetailsFlairSection = VectorL10n.tr("Vector", "room_details_flair_section")
  /// Who can read history?
  internal static let roomDetailsHistorySection = VectorL10n.tr("Vector", "room_details_history_section")
  /// Anyone
  internal static let roomDetailsHistorySectionAnyone = VectorL10n.tr("Vector", "room_details_history_section_anyone")
  /// Members only (since the point in time of selecting this option)
  internal static let roomDetailsHistorySectionMembersOnly = VectorL10n.tr("Vector", "room_details_history_section_members_only")
  /// Members only (since they were invited)
  internal static let roomDetailsHistorySectionMembersOnlySinceInvited = VectorL10n.tr("Vector", "room_details_history_section_members_only_since_invited")
  /// Members only (since they joined)
  internal static let roomDetailsHistorySectionMembersOnlySinceJoined = VectorL10n.tr("Vector", "room_details_history_section_members_only_since_joined")
  /// Changes to who can read history will only apply to future messages in this room. The visibility of existing history will be unchanged.
  internal static let roomDetailsHistorySectionPromptMsg = VectorL10n.tr("Vector", "room_details_history_section_prompt_msg")
  /// Privacy warning
  internal static let roomDetailsHistorySectionPromptTitle = VectorL10n.tr("Vector", "room_details_history_section_prompt_title")
  /// Low priority
  internal static let roomDetailsLowPriorityTag = VectorL10n.tr("Vector", "room_details_low_priority_tag")
  /// Mute notifications
  internal static let roomDetailsMuteNotifs = VectorL10n.tr("Vector", "room_details_mute_notifs")
  /// Add new address
  internal static let roomDetailsNewAddress = VectorL10n.tr("Vector", "room_details_new_address")
  /// Add new address (e.g. #foo%@)
  internal static func roomDetailsNewAddressPlaceholder(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_details_new_address_placeholder", p1)
  }
  /// Add new community ID (e.g. +foo%@)
  internal static func roomDetailsNewFlairPlaceholder(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_details_new_flair_placeholder", p1)
  }
  /// This room has no local addresses
  internal static let roomDetailsNoLocalAddresses = VectorL10n.tr("Vector", "room_details_no_local_addresses")
  /// Members
  internal static let roomDetailsPeople = VectorL10n.tr("Vector", "room_details_people")
  /// Room Photo
  internal static let roomDetailsPhoto = VectorL10n.tr("Vector", "room_details_photo")
  /// Room Name
  internal static let roomDetailsRoomName = VectorL10n.tr("Vector", "room_details_room_name")
  /// Do you want to save changes?
  internal static let roomDetailsSaveChangesPrompt = VectorL10n.tr("Vector", "room_details_save_changes_prompt")
  /// Set as Main Address
  internal static let roomDetailsSetMainAddress = VectorL10n.tr("Vector", "room_details_set_main_address")
  /// Settings
  internal static let roomDetailsSettings = VectorL10n.tr("Vector", "room_details_settings")
  /// Room Details
  internal static let roomDetailsTitle = VectorL10n.tr("Vector", "room_details_title")
  /// Topic
  internal static let roomDetailsTopic = VectorL10n.tr("Vector", "room_details_topic")
  /// Unset as Main Address
  internal static let roomDetailsUnsetMainAddress = VectorL10n.tr("Vector", "room_details_unset_main_address")
  /// No public rooms available
  internal static let roomDirectoryNoPublicRoom = VectorL10n.tr("Vector", "room_directory_no_public_room")
  /// You do not have permission to post to this room
  internal static let roomDoNotHavePermissionToPost = VectorL10n.tr("Vector", "room_do_not_have_permission_to_post")
  /// Reason for banning this user
  internal static let roomEventActionBanPromptReason = VectorL10n.tr("Vector", "room_event_action_ban_prompt_reason")
  /// Cancel Download
  internal static let roomEventActionCancelDownload = VectorL10n.tr("Vector", "room_event_action_cancel_download")
  /// Cancel Send
  internal static let roomEventActionCancelSend = VectorL10n.tr("Vector", "room_event_action_cancel_send")
  /// Copy
  internal static let roomEventActionCopy = VectorL10n.tr("Vector", "room_event_action_copy")
  /// Delete
  internal static let roomEventActionDelete = VectorL10n.tr("Vector", "room_event_action_delete")
  /// Reason for kicking this user
  internal static let roomEventActionKickPromptReason = VectorL10n.tr("Vector", "room_event_action_kick_prompt_reason")
  /// More
  internal static let roomEventActionMore = VectorL10n.tr("Vector", "room_event_action_more")
  /// Permalink
  internal static let roomEventActionPermalink = VectorL10n.tr("Vector", "room_event_action_permalink")
  /// Quote
  internal static let roomEventActionQuote = VectorL10n.tr("Vector", "room_event_action_quote")
  /// Remove
  internal static let roomEventActionRedact = VectorL10n.tr("Vector", "room_event_action_redact")
  /// Report content
  internal static let roomEventActionReport = VectorL10n.tr("Vector", "room_event_action_report")
  /// Do you want to hide all messages from this user?
  internal static let roomEventActionReportPromptIgnoreUser = VectorL10n.tr("Vector", "room_event_action_report_prompt_ignore_user")
  /// Reason for reporting this content
  internal static let roomEventActionReportPromptReason = VectorL10n.tr("Vector", "room_event_action_report_prompt_reason")
  /// Resend
  internal static let roomEventActionResend = VectorL10n.tr("Vector", "room_event_action_resend")
  /// Save
  internal static let roomEventActionSave = VectorL10n.tr("Vector", "room_event_action_save")
  /// Share
  internal static let roomEventActionShare = VectorL10n.tr("Vector", "room_event_action_share")
  /// View Decrypted Source
  internal static let roomEventActionViewDecryptedSource = VectorL10n.tr("Vector", "room_event_action_view_decrypted_source")
  /// Encryption Information
  internal static let roomEventActionViewEncryption = VectorL10n.tr("Vector", "room_event_action_view_encryption")
  /// View Source
  internal static let roomEventActionViewSource = VectorL10n.tr("Vector", "room_event_action_view_source")
  /// Failed to send
  internal static let roomEventFailedToSend = VectorL10n.tr("Vector", "room_event_failed_to_send")
  /// Jump to first unread message
  internal static let roomJumpToFirstUnread = VectorL10n.tr("Vector", "room_jump_to_first_unread")
  /// %@, %@ & others are typing…
  internal static func roomManyUsersAreTyping(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_many_users_are_typing", p1, p2)
  }
  /// Send a message (unencrypted)…
  internal static let roomMessagePlaceholder = VectorL10n.tr("Vector", "room_message_placeholder")
  /// Send a reply (unencrypted)…
  internal static let roomMessageReplyToPlaceholder = VectorL10n.tr("Vector", "room_message_reply_to_placeholder")
  /// Send a reply…
  internal static let roomMessageReplyToShortPlaceholder = VectorL10n.tr("Vector", "room_message_reply_to_short_placeholder")
  /// Send a message…
  internal static let roomMessageShortPlaceholder = VectorL10n.tr("Vector", "room_message_short_placeholder")
  /// %d new message
  internal static func roomNewMessageNotification(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "room_new_message_notification", p1)
  }
  /// %d new messages
  internal static func roomNewMessagesNotification(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "room_new_messages_notification", p1)
  }
  /// Connectivity to the server has been lost.
  internal static let roomOfflineNotification = VectorL10n.tr("Vector", "room_offline_notification")
  /// %@ is typing…
  internal static func roomOneUserIsTyping(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_one_user_is_typing", p1)
  }
  /// Ongoing conference call. Join as %@ or %@.
  internal static func roomOngoingConferenceCall(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_ongoing_conference_call", p1, p2)
  }
  /// Close
  internal static let roomOngoingConferenceCallClose = VectorL10n.tr("Vector", "room_ongoing_conference_call_close")
  /// Ongoing conference call. Join as %@ or %@. %@ it.
  internal static func roomOngoingConferenceCallWithClose(_ p1: String, _ p2: String, _ p3: String) -> String {
    return VectorL10n.tr("Vector", "room_ongoing_conference_call_with_close", p1, p2, p3)
  }
  /// Ban from this room
  internal static let roomParticipantsActionBan = VectorL10n.tr("Vector", "room_participants_action_ban")
  /// Hide all messages from this user
  internal static let roomParticipantsActionIgnore = VectorL10n.tr("Vector", "room_participants_action_ignore")
  /// Invite
  internal static let roomParticipantsActionInvite = VectorL10n.tr("Vector", "room_participants_action_invite")
  /// Leave this room
  internal static let roomParticipantsActionLeave = VectorL10n.tr("Vector", "room_participants_action_leave")
  /// Mention
  internal static let roomParticipantsActionMention = VectorL10n.tr("Vector", "room_participants_action_mention")
  /// Remove from this room
  internal static let roomParticipantsActionRemove = VectorL10n.tr("Vector", "room_participants_action_remove")
  /// Admin tools
  internal static let roomParticipantsActionSectionAdminTools = VectorL10n.tr("Vector", "room_participants_action_section_admin_tools")
  /// Devices
  internal static let roomParticipantsActionSectionDevices = VectorL10n.tr("Vector", "room_participants_action_section_devices")
  /// Direct chats
  internal static let roomParticipantsActionSectionDirectChats = VectorL10n.tr("Vector", "room_participants_action_section_direct_chats")
  /// Other
  internal static let roomParticipantsActionSectionOther = VectorL10n.tr("Vector", "room_participants_action_section_other")
  /// Make admin
  internal static let roomParticipantsActionSetAdmin = VectorL10n.tr("Vector", "room_participants_action_set_admin")
  /// Reset to normal user
  internal static let roomParticipantsActionSetDefaultPowerLevel = VectorL10n.tr("Vector", "room_participants_action_set_default_power_level")
  /// Make moderator
  internal static let roomParticipantsActionSetModerator = VectorL10n.tr("Vector", "room_participants_action_set_moderator")
  /// Start new chat
  internal static let roomParticipantsActionStartNewChat = VectorL10n.tr("Vector", "room_participants_action_start_new_chat")
  /// Start video call
  internal static let roomParticipantsActionStartVideoCall = VectorL10n.tr("Vector", "room_participants_action_start_video_call")
  /// Start voice call
  internal static let roomParticipantsActionStartVoiceCall = VectorL10n.tr("Vector", "room_participants_action_start_voice_call")
  /// Unban
  internal static let roomParticipantsActionUnban = VectorL10n.tr("Vector", "room_participants_action_unban")
  /// Show all messages from this user
  internal static let roomParticipantsActionUnignore = VectorL10n.tr("Vector", "room_participants_action_unignore")
  /// Add participant
  internal static let roomParticipantsAddParticipant = VectorL10n.tr("Vector", "room_participants_add_participant")
  /// ago
  internal static let roomParticipantsAgo = VectorL10n.tr("Vector", "room_participants_ago")
  /// Filter room members
  internal static let roomParticipantsFilterRoomMembers = VectorL10n.tr("Vector", "room_participants_filter_room_members")
  /// Idle
  internal static let roomParticipantsIdle = VectorL10n.tr("Vector", "room_participants_idle")
  /// Search / invite by User ID, Name or email
  internal static let roomParticipantsInviteAnotherUser = VectorL10n.tr("Vector", "room_participants_invite_another_user")
  /// Malformed ID. Should be an email address or a Matrix ID like '@localpart:domain'
  internal static let roomParticipantsInviteMalformedId = VectorL10n.tr("Vector", "room_participants_invite_malformed_id")
  /// Invite Error
  internal static let roomParticipantsInviteMalformedIdTitle = VectorL10n.tr("Vector", "room_participants_invite_malformed_id_title")
  /// Are you sure you want to invite %@ to this chat?
  internal static func roomParticipantsInvitePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_participants_invite_prompt_msg", p1)
  }
  /// Confirmation
  internal static let roomParticipantsInvitePromptTitle = VectorL10n.tr("Vector", "room_participants_invite_prompt_title")
  /// INVITED
  internal static let roomParticipantsInvitedSection = VectorL10n.tr("Vector", "room_participants_invited_section")
  /// Are you sure you want to leave the room?
  internal static let roomParticipantsLeavePromptMsg = VectorL10n.tr("Vector", "room_participants_leave_prompt_msg")
  /// Leave room
  internal static let roomParticipantsLeavePromptTitle = VectorL10n.tr("Vector", "room_participants_leave_prompt_title")
  /// %d participants
  internal static func roomParticipantsMultiParticipants(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "room_participants_multi_participants", p1)
  }
  /// now
  internal static let roomParticipantsNow = VectorL10n.tr("Vector", "room_participants_now")
  /// Offline
  internal static let roomParticipantsOffline = VectorL10n.tr("Vector", "room_participants_offline")
  /// 1 participant
  internal static let roomParticipantsOneParticipant = VectorL10n.tr("Vector", "room_participants_one_participant")
  /// Online
  internal static let roomParticipantsOnline = VectorL10n.tr("Vector", "room_participants_online")
  /// Are you sure you want to remove %@ from this chat?
  internal static func roomParticipantsRemovePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_participants_remove_prompt_msg", p1)
  }
  /// Confirmation
  internal static let roomParticipantsRemovePromptTitle = VectorL10n.tr("Vector", "room_participants_remove_prompt_title")
  /// Remove third-party invite is not supported yet until the api exists
  internal static let roomParticipantsRemoveThirdPartyInviteMsg = VectorL10n.tr("Vector", "room_participants_remove_third_party_invite_msg")
  /// Participants
  internal static let roomParticipantsTitle = VectorL10n.tr("Vector", "room_participants_title")
  /// Unknown
  internal static let roomParticipantsUnknown = VectorL10n.tr("Vector", "room_participants_unknown")
  /// This room is a continuation of another conversation.
  internal static let roomPredecessorInformation = VectorL10n.tr("Vector", "room_predecessor_information")
  /// Click here to see older messages.
  internal static let roomPredecessorLink = VectorL10n.tr("Vector", "room_predecessor_link")
  /// You have been invited to join this room by %@
  internal static func roomPreviewInvitationFormat(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_preview_invitation_format", p1)
  }
  /// This is a preview of this room. Room interactions have been disabled.
  internal static let roomPreviewSubtitle = VectorL10n.tr("Vector", "room_preview_subtitle")
  /// You are trying to access %@. Would you like to join in order to participate in the discussion?
  internal static func roomPreviewTryJoinAnUnknownRoom(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_preview_try_join_an_unknown_room", p1)
  }
  /// a room
  internal static let roomPreviewTryJoinAnUnknownRoomDefault = VectorL10n.tr("Vector", "room_preview_try_join_an_unknown_room_default")
  /// This invitation was sent to %@, which is not associated with this account. You may wish to login with a different account, or add this email to your this account.
  internal static func roomPreviewUnlinkedEmailWarning(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_preview_unlinked_email_warning", p1)
  }
  /// cancel all
  internal static let roomPromptCancel = VectorL10n.tr("Vector", "room_prompt_cancel")
  /// Resend all
  internal static let roomPromptResend = VectorL10n.tr("Vector", "room_prompt_resend")
  /// ROOMS
  internal static let roomRecentsConversationsSection = VectorL10n.tr("Vector", "room_recents_conversations_section")
  /// Create room
  internal static let roomRecentsCreateEmptyRoom = VectorL10n.tr("Vector", "room_recents_create_empty_room")
  /// ROOM DIRECTORY
  internal static let roomRecentsDirectorySection = VectorL10n.tr("Vector", "room_recents_directory_section")
  /// Network
  internal static let roomRecentsDirectorySectionNetwork = VectorL10n.tr("Vector", "room_recents_directory_section_network")
  /// FAVOURITES
  internal static let roomRecentsFavouritesSection = VectorL10n.tr("Vector", "room_recents_favourites_section")
  /// INVITES
  internal static let roomRecentsInvitesSection = VectorL10n.tr("Vector", "room_recents_invites_section")
  /// Join room
  internal static let roomRecentsJoinRoom = VectorL10n.tr("Vector", "room_recents_join_room")
  /// Type a room id or a room alias
  internal static let roomRecentsJoinRoomPrompt = VectorL10n.tr("Vector", "room_recents_join_room_prompt")
  /// Join a room
  internal static let roomRecentsJoinRoomTitle = VectorL10n.tr("Vector", "room_recents_join_room_title")
  /// LOW PRIORITY
  internal static let roomRecentsLowPrioritySection = VectorL10n.tr("Vector", "room_recents_low_priority_section")
  /// No rooms
  internal static let roomRecentsNoConversation = VectorL10n.tr("Vector", "room_recents_no_conversation")
  /// PEOPLE
  internal static let roomRecentsPeopleSection = VectorL10n.tr("Vector", "room_recents_people_section")
  /// SYSTEM ALERTS
  internal static let roomRecentsServerNoticeSection = VectorL10n.tr("Vector", "room_recents_server_notice_section")
  /// Start chat
  internal static let roomRecentsStartChatWith = VectorL10n.tr("Vector", "room_recents_start_chat_with")
  /// This room has been replaced and is no longer active.
  internal static let roomReplacementInformation = VectorL10n.tr("Vector", "room_replacement_information")
  /// The conversation continues here.
  internal static let roomReplacementLink = VectorL10n.tr("Vector", "room_replacement_link")
  /// Resend unsent messages
  internal static let roomResendUnsentMessages = VectorL10n.tr("Vector", "room_resend_unsent_messages")
  ///  Please 
  internal static let roomResourceLimitExceededMessageContact1 = VectorL10n.tr("Vector", "room_resource_limit_exceeded_message_contact_1")
  /// contact your service administrator
  internal static let roomResourceLimitExceededMessageContact2Link = VectorL10n.tr("Vector", "room_resource_limit_exceeded_message_contact_2_link")
  ///  to continue using this service.
  internal static let roomResourceLimitExceededMessageContact3 = VectorL10n.tr("Vector", "room_resource_limit_exceeded_message_contact_3")
  /// This homeserver has exceeded one of its resource limits so 
  internal static let roomResourceUsageLimitReachedMessage1Default = VectorL10n.tr("Vector", "room_resource_usage_limit_reached_message_1_default")
  /// This homeserver has hit its Monthly Active User limit so 
  internal static let roomResourceUsageLimitReachedMessage1MonthlyActiveUser = VectorL10n.tr("Vector", "room_resource_usage_limit_reached_message_1_monthly_active_user")
  /// some users will not be able to log in.
  internal static let roomResourceUsageLimitReachedMessage2 = VectorL10n.tr("Vector", "room_resource_usage_limit_reached_message_2")
  ///  to get this limit increased.
  internal static let roomResourceUsageLimitReachedMessageContact3 = VectorL10n.tr("Vector", "room_resource_usage_limit_reached_message_contact_3")
  /// Invite members
  internal static let roomTitleInviteMembers = VectorL10n.tr("Vector", "room_title_invite_members")
  /// %@ members
  internal static func roomTitleMembers(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_title_members", p1)
  }
  /// %@/%@ active members
  internal static func roomTitleMultipleActiveMembers(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_title_multiple_active_members", p1, p2)
  }
  /// New room
  internal static let roomTitleNewRoom = VectorL10n.tr("Vector", "room_title_new_room")
  /// %@/%@ active member
  internal static func roomTitleOneActiveMember(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_title_one_active_member", p1, p2)
  }
  /// 1 member
  internal static let roomTitleOneMember = VectorL10n.tr("Vector", "room_title_one_member")
  /// %@ & %@ are typing…
  internal static func roomTwoUsersAreTyping(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_two_users_are_typing", p1, p2)
  }
  /// Messages not sent. %@ or %@ now?
  internal static func roomUnsentMessagesNotification(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_unsent_messages_notification", p1, p2)
  }
  /// Message not sent due to unknown devices being present. %@ or %@ now?
  internal static func roomUnsentMessagesUnknownDevicesNotification(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_unsent_messages_unknown_devices_notification", p1, p2)
  }
  /// End-to-end encryption is in beta and may not be reliable.\n\nYou should not yet trust it to secure data.\n\nDevices will not yet be able to decrypt history from before they joined the room.\n\nEncrypted messages will not be visible on clients that do not yet implement encryption.
  internal static let roomWarningAboutEncryption = VectorL10n.tr("Vector", "room_warning_about_encryption")
  /// Save
  internal static let save = VectorL10n.tr("Vector", "save")
  /// Search
  internal static let searchDefaultPlaceholder = VectorL10n.tr("Vector", "search_default_placeholder")
  /// Files
  internal static let searchFiles = VectorL10n.tr("Vector", "search_files")
  /// Searching…
  internal static let searchInProgress = VectorL10n.tr("Vector", "search_in_progress")
  /// Messages
  internal static let searchMessages = VectorL10n.tr("Vector", "search_messages")
  /// No results
  internal static let searchNoResult = VectorL10n.tr("Vector", "search_no_result")
  /// People
  internal static let searchPeople = VectorL10n.tr("Vector", "search_people")
  /// Search by User ID, Name or email
  internal static let searchPeoplePlaceholder = VectorL10n.tr("Vector", "search_people_placeholder")
  /// Rooms
  internal static let searchRooms = VectorL10n.tr("Vector", "search_rooms")
  /// Send to %@
  internal static func sendTo(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "send_to", p1)
  }
  /// Sending
  internal static let sending = VectorL10n.tr("Vector", "sending")
  /// Add email address
  internal static let settingsAddEmailAddress = VectorL10n.tr("Vector", "settings_add_email_address")
  /// Add phone number
  internal static let settingsAddPhoneNumber = VectorL10n.tr("Vector", "settings_add_phone_number")
  /// ADVANCED
  internal static let settingsAdvanced = VectorL10n.tr("Vector", "settings_advanced")
  /// Receive incoming calls on your lock screen. See your Riot calls in the system's call history. If iCloud is enabled, this call history will be shared with Apple.
  internal static let settingsCallkitInfo = VectorL10n.tr("Vector", "settings_callkit_info")
  /// CALLS
  internal static let settingsCallsSettings = VectorL10n.tr("Vector", "settings_calls_settings")
  /// Change password
  internal static let settingsChangePassword = VectorL10n.tr("Vector", "settings_change_password")
  /// Clear cache
  internal static let settingsClearCache = VectorL10n.tr("Vector", "settings_clear_cache")
  /// Home server is %@
  internal static func settingsConfigHomeServer(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_config_home_server", p1)
  }
  /// Identity server is %@
  internal static func settingsConfigIdentityServer(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_config_identity_server", p1)
  }
  /// No build info
  internal static let settingsConfigNoBuildInfo = VectorL10n.tr("Vector", "settings_config_no_build_info")
  /// Logged in as %@
  internal static func settingsConfigUserId(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_config_user_id", p1)
  }
  /// confirm password
  internal static let settingsConfirmPassword = VectorL10n.tr("Vector", "settings_confirm_password")
  /// LOCAL CONTACTS
  internal static let settingsContacts = VectorL10n.tr("Vector", "settings_contacts")
  /// Use emails and phone numbers to discover users
  internal static let settingsContactsDiscoverMatrixUsers = VectorL10n.tr("Vector", "settings_contacts_discover_matrix_users")
  /// Phonebook country
  internal static let settingsContactsPhonebookCountry = VectorL10n.tr("Vector", "settings_contacts_phonebook_country")
  /// Copyright
  internal static let settingsCopyright = VectorL10n.tr("Vector", "settings_copyright")
  /// https://riot.im/copyright
  internal static let settingsCopyrightUrl = VectorL10n.tr("Vector", "settings_copyright_url")
  /// Encrypt to verified devices only
  internal static let settingsCryptoBlacklistUnverifiedDevices = VectorL10n.tr("Vector", "settings_crypto_blacklist_unverified_devices")
  /// \nDevice ID: 
  internal static let settingsCryptoDeviceId = VectorL10n.tr("Vector", "settings_crypto_device_id")
  /// \nDevice key: 
  internal static let settingsCryptoDeviceKey = VectorL10n.tr("Vector", "settings_crypto_device_key")
  /// Device name: 
  internal static let settingsCryptoDeviceName = VectorL10n.tr("Vector", "settings_crypto_device_name")
  /// Export keys
  internal static let settingsCryptoExport = VectorL10n.tr("Vector", "settings_crypto_export")
  /// CRYPTOGRAPHY
  internal static let settingsCryptography = VectorL10n.tr("Vector", "settings_cryptography")
  /// DEACTIVATE ACCOUNT
  internal static let settingsDeactivateAccount = VectorL10n.tr("Vector", "settings_deactivate_account")
  /// Deactivate my account
  internal static let settingsDeactivateMyAccount = VectorL10n.tr("Vector", "settings_deactivate_my_account")
  /// DEVICES
  internal static let settingsDevices = VectorL10n.tr("Vector", "settings_devices")
  /// Display Name
  internal static let settingsDisplayName = VectorL10n.tr("Vector", "settings_display_name")
  /// Email
  internal static let settingsEmailAddress = VectorL10n.tr("Vector", "settings_email_address")
  /// Enter your email address
  internal static let settingsEmailAddressPlaceholder = VectorL10n.tr("Vector", "settings_email_address_placeholder")
  /// Integrated calling
  internal static let settingsEnableCallkit = VectorL10n.tr("Vector", "settings_enable_callkit")
  /// Notifications on this device
  internal static let settingsEnablePushNotif = VectorL10n.tr("Vector", "settings_enable_push_notif")
  /// Rage shake to report bug
  internal static let settingsEnableRageshake = VectorL10n.tr("Vector", "settings_enable_rageshake")
  /// Fail to update password
  internal static let settingsFailToUpdatePassword = VectorL10n.tr("Vector", "settings_fail_to_update_password")
  /// Fail to update profile
  internal static let settingsFailToUpdateProfile = VectorL10n.tr("Vector", "settings_fail_to_update_profile")
  /// First Name
  internal static let settingsFirstName = VectorL10n.tr("Vector", "settings_first_name")
  /// Show flair where allowed
  internal static let settingsFlair = VectorL10n.tr("Vector", "settings_flair")
  /// Global notification settings are available on your %@ web client
  internal static func settingsGlobalSettingsInfo(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_global_settings_info", p1)
  }
  /// IGNORED USERS
  internal static let settingsIgnoredUsers = VectorL10n.tr("Vector", "settings_ignored_users")
  /// LABS
  internal static let settingsLabs = VectorL10n.tr("Vector", "settings_labs")
  /// Create conference calls with jitsi
  internal static let settingsLabsCreateConferenceWithJitsi = VectorL10n.tr("Vector", "settings_labs_create_conference_with_jitsi")
  /// End-to-End Encryption
  internal static let settingsLabsE2eEncryption = VectorL10n.tr("Vector", "settings_labs_e2e_encryption")
  /// To finish setting up encryption you must log in again.
  internal static let settingsLabsE2eEncryptionPromptMessage = VectorL10n.tr("Vector", "settings_labs_e2e_encryption_prompt_message")
  /// Lazy load rooms members
  internal static let settingsLabsRoomMembersLazyLoading = VectorL10n.tr("Vector", "settings_labs_room_members_lazy_loading")
  /// Your homeserver does not support lazy loading of room members yet. Try later.
  internal static let settingsLabsRoomMembersLazyLoadingErrorMessage = VectorL10n.tr("Vector", "settings_labs_room_members_lazy_loading_error_message")
  /// Mark all messages as read
  internal static let settingsMarkAllAsRead = VectorL10n.tr("Vector", "settings_mark_all_as_read")
  /// new password
  internal static let settingsNewPassword = VectorL10n.tr("Vector", "settings_new_password")
  /// Night Mode
  internal static let settingsNightMode = VectorL10n.tr("Vector", "settings_night_mode")
  /// NOTIFICATION SETTINGS
  internal static let settingsNotificationsSettings = VectorL10n.tr("Vector", "settings_notifications_settings")
  /// old password
  internal static let settingsOldPassword = VectorL10n.tr("Vector", "settings_old_password")
  /// Olm Version %@
  internal static func settingsOlmVersion(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_olm_version", p1)
  }
  /// Notifications are denied for %@, please allow them in your device settings
  internal static func settingsOnDeniedNotification(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_on_denied_notification", p1)
  }
  /// OTHER
  internal static let settingsOther = VectorL10n.tr("Vector", "settings_other")
  /// Your password has been updated
  internal static let settingsPasswordUpdated = VectorL10n.tr("Vector", "settings_password_updated")
  /// Phone
  internal static let settingsPhoneNumber = VectorL10n.tr("Vector", "settings_phone_number")
  /// Pin rooms with missed notifications
  internal static let settingsPinRoomsWithMissedNotif = VectorL10n.tr("Vector", "settings_pin_rooms_with_missed_notif")
  /// Pin rooms with unread messages
  internal static let settingsPinRoomsWithUnread = VectorL10n.tr("Vector", "settings_pin_rooms_with_unread")
  /// Privacy Policy
  internal static let settingsPrivacyPolicy = VectorL10n.tr("Vector", "settings_privacy_policy")
  /// https://riot.im/privacy
  internal static let settingsPrivacyPolicyUrl = VectorL10n.tr("Vector", "settings_privacy_policy_url")
  /// Profile Picture
  internal static let settingsProfilePicture = VectorL10n.tr("Vector", "settings_profile_picture")
  /// Are you sure you want to remove the email address %@?
  internal static func settingsRemoveEmailPromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_remove_email_prompt_msg", p1)
  }
  /// Are you sure you want to remove the phone number %@?
  internal static func settingsRemovePhonePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_remove_phone_prompt_msg", p1)
  }
  /// Confirmation
  internal static let settingsRemovePromptTitle = VectorL10n.tr("Vector", "settings_remove_prompt_title")
  /// Report bug
  internal static let settingsReportBug = VectorL10n.tr("Vector", "settings_report_bug")
  /// Send anon crash & usage data
  internal static let settingsSendCrashReport = VectorL10n.tr("Vector", "settings_send_crash_report")
  /// Show decrypted content
  internal static let settingsShowDecryptedContent = VectorL10n.tr("Vector", "settings_show_decrypted_content")
  /// Sign Out
  internal static let settingsSignOut = VectorL10n.tr("Vector", "settings_sign_out")
  /// Are you sure?
  internal static let settingsSignOutConfirmation = VectorL10n.tr("Vector", "settings_sign_out_confirmation")
  /// You will lose your end-to-end encryption keys. That means you will no longer be able to read old messages in encrypted rooms on this device.
  internal static let settingsSignOutE2eWarn = VectorL10n.tr("Vector", "settings_sign_out_e2e_warn")
  /// Surname
  internal static let settingsSurname = VectorL10n.tr("Vector", "settings_surname")
  /// Terms & Conditions
  internal static let settingsTermConditions = VectorL10n.tr("Vector", "settings_term_conditions")
  /// https://riot.im/tac_apple
  internal static let settingsTermConditionsUrl = VectorL10n.tr("Vector", "settings_term_conditions_url")
  /// Third-party Notices
  internal static let settingsThirdPartyNotices = VectorL10n.tr("Vector", "settings_third_party_notices")
  /// Settings
  internal static let settingsTitle = VectorL10n.tr("Vector", "settings_title")
  /// Language
  internal static let settingsUiLanguage = VectorL10n.tr("Vector", "settings_ui_language")
  /// Theme
  internal static let settingsUiTheme = VectorL10n.tr("Vector", "settings_ui_theme")
  /// Auto
  internal static let settingsUiThemeAuto = VectorL10n.tr("Vector", "settings_ui_theme_auto")
  /// Black
  internal static let settingsUiThemeBlack = VectorL10n.tr("Vector", "settings_ui_theme_black")
  /// Dark
  internal static let settingsUiThemeDark = VectorL10n.tr("Vector", "settings_ui_theme_dark")
  /// Light
  internal static let settingsUiThemeLight = VectorL10n.tr("Vector", "settings_ui_theme_light")
  /// "Auto" uses your device "Invert Colours" settings
  internal static let settingsUiThemePickerMessage = VectorL10n.tr("Vector", "settings_ui_theme_picker_message")
  /// Select a theme
  internal static let settingsUiThemePickerTitle = VectorL10n.tr("Vector", "settings_ui_theme_picker_title")
  /// Show all messages from %@?
  internal static func settingsUnignoreUser(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_unignore_user", p1)
  }
  /// USER INTERFACE
  internal static let settingsUserInterface = VectorL10n.tr("Vector", "settings_user_interface")
  /// USER SETTINGS
  internal static let settingsUserSettings = VectorL10n.tr("Vector", "settings_user_settings")
  /// Version %@
  internal static func settingsVersion(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_version", p1)
  }
  /// Login in the main app to share content
  internal static let shareExtensionAuthPrompt = VectorL10n.tr("Vector", "share_extension_auth_prompt")
  /// Failed to send. Check in the main app the encryption settings for this room
  internal static let shareExtensionFailedToEncrypt = VectorL10n.tr("Vector", "share_extension_failed_to_encrypt")
  /// Start
  internal static let start = VectorL10n.tr("Vector", "start")
  /// Favourites
  internal static let titleFavourites = VectorL10n.tr("Vector", "title_favourites")
  /// Communities
  internal static let titleGroups = VectorL10n.tr("Vector", "title_groups")
  /// Home
  internal static let titleHome = VectorL10n.tr("Vector", "title_home")
  /// People
  internal static let titlePeople = VectorL10n.tr("Vector", "title_people")
  /// Rooms
  internal static let titleRooms = VectorL10n.tr("Vector", "title_rooms")
  /// Today
  internal static let today = VectorL10n.tr("Vector", "today")
  /// This room contains unknown devices which have not been verified.\nThis means there is no guarantee that the devices belong to the users they claim to.\nWe recommend you go through the verification process for each device before continuing, but you can resend the message without verifying if you prefer.
  internal static let unknownDevicesAlert = VectorL10n.tr("Vector", "unknown_devices_alert")
  /// Room contains unknown devices
  internal static let unknownDevicesAlertTitle = VectorL10n.tr("Vector", "unknown_devices_alert_title")
  /// Answer Anyway
  internal static let unknownDevicesAnswerAnyway = VectorL10n.tr("Vector", "unknown_devices_answer_anyway")
  /// Call Anyway
  internal static let unknownDevicesCallAnyway = VectorL10n.tr("Vector", "unknown_devices_call_anyway")
  /// Send Anyway
  internal static let unknownDevicesSendAnyway = VectorL10n.tr("Vector", "unknown_devices_send_anyway")
  /// Unknown devices
  internal static let unknownDevicesTitle = VectorL10n.tr("Vector", "unknown_devices_title")
  /// Verify…
  internal static let unknownDevicesVerify = VectorL10n.tr("Vector", "unknown_devices_verify")
  /// Video
  internal static let video = VectorL10n.tr("Vector", "video")
  /// View
  internal static let view = VectorL10n.tr("Vector", "view")
  /// Voice
  internal static let voice = VectorL10n.tr("Vector", "voice")
  /// Warning
  internal static let warning = VectorL10n.tr("Vector", "warning")
  /// Widget creation has failed
  internal static let widgetCreationFailure = VectorL10n.tr("Vector", "widget_creation_failure")
  /// Failed to send request.
  internal static let widgetIntegrationFailedToSendRequest = VectorL10n.tr("Vector", "widget_integration_failed_to_send_request")
  /// Missing room_id in request.
  internal static let widgetIntegrationMissingRoomId = VectorL10n.tr("Vector", "widget_integration_missing_room_id")
  /// Missing user_id in request.
  internal static let widgetIntegrationMissingUserId = VectorL10n.tr("Vector", "widget_integration_missing_user_id")
  /// You are not in this room.
  internal static let widgetIntegrationMustBeInRoom = VectorL10n.tr("Vector", "widget_integration_must_be_in_room")
  /// You need to be able to invite users to do that.
  internal static let widgetIntegrationNeedToBeAbleToInvite = VectorL10n.tr("Vector", "widget_integration_need_to_be_able_to_invite")
  /// You do not have permission to do that in this room.
  internal static let widgetIntegrationNoPermissionInRoom = VectorL10n.tr("Vector", "widget_integration_no_permission_in_room")
  /// Power level must be positive integer.
  internal static let widgetIntegrationPositivePowerLevel = VectorL10n.tr("Vector", "widget_integration_positive_power_level")
  /// This room is not recognised.
  internal static let widgetIntegrationRoomNotRecognised = VectorL10n.tr("Vector", "widget_integration_room_not_recognised")
  /// Room %@ is not visible.
  internal static func widgetIntegrationRoomNotVisible(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "widget_integration_room_not_visible", p1)
  }
  /// Unable to create widget.
  internal static let widgetIntegrationUnableToCreate = VectorL10n.tr("Vector", "widget_integration_unable_to_create")
  /// You need permission to manage widgets in this room
  internal static let widgetNoPowerToManage = VectorL10n.tr("Vector", "widget_no_power_to_manage")
  /// You don't currently have any stickerpacks enabled.
  internal static let widgetStickerPickerNoStickerpacksAlert = VectorL10n.tr("Vector", "widget_sticker_picker_no_stickerpacks_alert")
  /// Add some now?
  internal static let widgetStickerPickerNoStickerpacksAlertAddNow = VectorL10n.tr("Vector", "widget_sticker_picker_no_stickerpacks_alert_add_now")
  /// Yesterday
  internal static let yesterday = VectorL10n.tr("Vector", "yesterday")
  /// You
  internal static let you = VectorL10n.tr("Vector", "you")
}
// swiftlint:enable function_parameter_count identifier_name line_length type_body_length

// MARK: - Implementation Details

extension VectorL10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
