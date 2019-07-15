// swiftlint:disable all
// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable function_parameter_count identifier_name line_length type_body_length
internal enum VectorL10n {
  /// Accept
  internal static var accept: String { 
    return VectorL10n.tr("Vector", "accept") 
  }
  /// Logout all accounts
  internal static var accountLogoutAll: String { 
    return VectorL10n.tr("Vector", "account_logout_all") 
  }
  /// Active Call
  internal static var activeCall: String { 
    return VectorL10n.tr("Vector", "active_call") 
  }
  /// Active Call (%@)
  internal static func activeCallDetails(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "active_call_details", p1)
  }
  /// Please review and accept the policies of this homeserver:
  internal static var authAcceptPolicies: String { 
    return VectorL10n.tr("Vector", "auth_accept_policies") 
  }
  /// Add an email address and a phone number to your account to let users discover you. Email address will also let you reset your password.
  internal static var authAddEmailAndPhoneMessage: String { 
    return VectorL10n.tr("Vector", "auth_add_email_and_phone_message") 
  }
  /// Registration with email and phone number at once is not supported yet until the api exists. Only the phone number will be taken into account. You may add your email to your profile in settings.
  internal static var authAddEmailAndPhoneWarning: String { 
    return VectorL10n.tr("Vector", "auth_add_email_and_phone_warning") 
  }
  /// Add an email address to your account to let users discover you, and to reset your password.
  internal static var authAddEmailMessage: String { 
    return VectorL10n.tr("Vector", "auth_add_email_message") 
  }
  /// Add an email address and/or a phone number to your account to let users discover you. Email address will also let you reset your password.
  internal static var authAddEmailPhoneMessage: String { 
    return VectorL10n.tr("Vector", "auth_add_email_phone_message") 
  }
  /// Add a phone number to your account to let users discover you.
  internal static var authAddPhoneMessage: String { 
    return VectorL10n.tr("Vector", "auth_add_phone_message") 
  }
  /// Invalid homeserver discovery response
  internal static var authAutodiscoverInvalidResponse: String { 
    return VectorL10n.tr("Vector", "auth_autodiscover_invalid_response") 
  }
  /// This email address is already in use
  internal static var authEmailInUse: String { 
    return VectorL10n.tr("Vector", "auth_email_in_use") 
  }
  /// Failed to send email: This email address was not found
  internal static var authEmailNotFound: String { 
    return VectorL10n.tr("Vector", "auth_email_not_found") 
  }
  /// Email address
  internal static var authEmailPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_email_placeholder") 
  }
  /// Please check your email to continue registration
  internal static var authEmailValidationMessage: String { 
    return VectorL10n.tr("Vector", "auth_email_validation_message") 
  }
  /// Forgot password?
  internal static var authForgotPassword: String { 
    return VectorL10n.tr("Vector", "auth_forgot_password") 
  }
  /// URL (e.g. https://matrix.org)
  internal static var authHomeServerPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_home_server_placeholder") 
  }
  /// URL (e.g. https://matrix.org)
  internal static var authIdentityServerPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_identity_server_placeholder") 
  }
  /// This doesn't look like a valid email address
  internal static var authInvalidEmail: String { 
    return VectorL10n.tr("Vector", "auth_invalid_email") 
  }
  /// Incorrect username and/or password
  internal static var authInvalidLoginParam: String { 
    return VectorL10n.tr("Vector", "auth_invalid_login_param") 
  }
  /// Password too short (min 6)
  internal static var authInvalidPassword: String { 
    return VectorL10n.tr("Vector", "auth_invalid_password") 
  }
  /// This doesn't look like a valid phone number
  internal static var authInvalidPhone: String { 
    return VectorL10n.tr("Vector", "auth_invalid_phone") 
  }
  /// User names may only contain letters, numbers, dots, hyphens and underscores
  internal static var authInvalidUserName: String { 
    return VectorL10n.tr("Vector", "auth_invalid_user_name") 
  }
  /// Log in
  internal static var authLogin: String { 
    return VectorL10n.tr("Vector", "auth_login") 
  }
  /// Sign in with single sign-on
  internal static var authLoginSingleSignOn: String { 
    return VectorL10n.tr("Vector", "auth_login_single_sign_on") 
  }
  /// Missing email address
  internal static var authMissingEmail: String { 
    return VectorL10n.tr("Vector", "auth_missing_email") 
  }
  /// Missing email address or phone number
  internal static var authMissingEmailOrPhone: String { 
    return VectorL10n.tr("Vector", "auth_missing_email_or_phone") 
  }
  /// Missing password
  internal static var authMissingPassword: String { 
    return VectorL10n.tr("Vector", "auth_missing_password") 
  }
  /// Missing phone number
  internal static var authMissingPhone: String { 
    return VectorL10n.tr("Vector", "auth_missing_phone") 
  }
  /// Unable to verify phone number.
  internal static var authMsisdnValidationError: String { 
    return VectorL10n.tr("Vector", "auth_msisdn_validation_error") 
  }
  /// We've sent an SMS with an activation code. Please enter this code below.
  internal static var authMsisdnValidationMessage: String { 
    return VectorL10n.tr("Vector", "auth_msisdn_validation_message") 
  }
  /// Verification Pending
  internal static var authMsisdnValidationTitle: String { 
    return VectorL10n.tr("Vector", "auth_msisdn_validation_title") 
  }
  /// New password
  internal static var authNewPasswordPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_new_password_placeholder") 
  }
  /// Email address (optional)
  internal static var authOptionalEmailPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_optional_email_placeholder") 
  }
  /// Phone number (optional)
  internal static var authOptionalPhonePlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_optional_phone_placeholder") 
  }
  /// Passwords don't match
  internal static var authPasswordDontMatch: String { 
    return VectorL10n.tr("Vector", "auth_password_dont_match") 
  }
  /// Password
  internal static var authPasswordPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_password_placeholder") 
  }
  /// This phone number is already in use
  internal static var authPhoneInUse: String { 
    return VectorL10n.tr("Vector", "auth_phone_in_use") 
  }
  /// Phone number
  internal static var authPhonePlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_phone_placeholder") 
  }
  /// This homeserver would like to make sure you are not a robot
  internal static var authRecaptchaMessage: String { 
    return VectorL10n.tr("Vector", "auth_recaptcha_message") 
  }
  /// Register
  internal static var authRegister: String { 
    return VectorL10n.tr("Vector", "auth_register") 
  }
  /// Confirm your new password
  internal static var authRepeatNewPasswordPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_repeat_new_password_placeholder") 
  }
  /// Repeat password
  internal static var authRepeatPasswordPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_repeat_password_placeholder") 
  }
  /// An email has been sent to %@. Once you've followed the link it contains, click below.
  internal static func authResetPasswordEmailValidationMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "auth_reset_password_email_validation_message", p1)
  }
  /// Your email address does not appear to be associated with a Matrix ID on this homeserver.
  internal static var authResetPasswordErrorNotFound: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_error_not_found") 
  }
  /// Failed to verify email address: make sure you clicked the link in the email
  internal static var authResetPasswordErrorUnauthorized: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_error_unauthorized") 
  }
  /// To reset your password, enter the email address linked to your account:
  internal static var authResetPasswordMessage: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_message") 
  }
  /// The email address linked to your account must be entered.
  internal static var authResetPasswordMissingEmail: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_missing_email") 
  }
  /// A new password must be entered.
  internal static var authResetPasswordMissingPassword: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_missing_password") 
  }
  /// I have verified my email address
  internal static var authResetPasswordNextStepButton: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_next_step_button") 
  }
  /// Your password has been reset.\n\nYou have been logged out of all devices and will no longer receive push notifications. To re-enable notifications, re-log in on each device.
  internal static var authResetPasswordSuccessMessage: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_success_message") 
  }
  /// Return to login screen
  internal static var authReturnToLogin: String { 
    return VectorL10n.tr("Vector", "auth_return_to_login") 
  }
  /// Send Reset Email
  internal static var authSendResetEmail: String { 
    return VectorL10n.tr("Vector", "auth_send_reset_email") 
  }
  /// Skip
  internal static var authSkip: String { 
    return VectorL10n.tr("Vector", "auth_skip") 
  }
  /// Submit
  internal static var authSubmit: String { 
    return VectorL10n.tr("Vector", "auth_submit") 
  }
  /// The identity server is not trusted
  internal static var authUntrustedIdServer: String { 
    return VectorL10n.tr("Vector", "auth_untrusted_id_server") 
  }
  /// Use custom server options (advanced)
  internal static var authUseServerOptions: String { 
    return VectorL10n.tr("Vector", "auth_use_server_options") 
  }
  /// Email or user name
  internal static var authUserIdPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_user_id_placeholder") 
  }
  /// User name
  internal static var authUserNamePlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_user_name_placeholder") 
  }
  /// Username in use
  internal static var authUsernameInUse: String { 
    return VectorL10n.tr("Vector", "auth_username_in_use") 
  }
  /// Back
  internal static var back: String { 
    return VectorL10n.tr("Vector", "back") 
  }
  /// Please describe what you did before the crash:
  internal static var bugCrashReportDescription: String { 
    return VectorL10n.tr("Vector", "bug_crash_report_description") 
  }
  /// Crash Report
  internal static var bugCrashReportTitle: String { 
    return VectorL10n.tr("Vector", "bug_crash_report_title") 
  }
  /// Please describe the bug. What did you do? What did you expect to happen? What actually happened?
  internal static var bugReportDescription: String { 
    return VectorL10n.tr("Vector", "bug_report_description") 
  }
  /// In order to diagnose problems, logs from this client will be sent with this bug report. If you would prefer to only send the text above, please untick:
  internal static var bugReportLogsDescription: String { 
    return VectorL10n.tr("Vector", "bug_report_logs_description") 
  }
  /// Uploading report
  internal static var bugReportProgressUploading: String { 
    return VectorL10n.tr("Vector", "bug_report_progress_uploading") 
  }
  /// Collecting logs
  internal static var bugReportProgressZipping: String { 
    return VectorL10n.tr("Vector", "bug_report_progress_zipping") 
  }
  /// The application has crashed last time. Would you like to submit a crash report?
  internal static var bugReportPrompt: String { 
    return VectorL10n.tr("Vector", "bug_report_prompt") 
  }
  /// Send
  internal static var bugReportSend: String { 
    return VectorL10n.tr("Vector", "bug_report_send") 
  }
  /// Send logs
  internal static var bugReportSendLogs: String { 
    return VectorL10n.tr("Vector", "bug_report_send_logs") 
  }
  /// Send screenshot
  internal static var bugReportSendScreenshot: String { 
    return VectorL10n.tr("Vector", "bug_report_send_screenshot") 
  }
  /// Bug Report
  internal static var bugReportTitle: String { 
    return VectorL10n.tr("Vector", "bug_report_title") 
  }
  /// There is already a call in progress.
  internal static var callAlreadyDisplayed: String { 
    return VectorL10n.tr("Vector", "call_already_displayed") 
  }
  /// Incoming video call...
  internal static var callIncomingVideo: String { 
    return VectorL10n.tr("Vector", "call_incoming_video") 
  }
  /// Incoming video call from %@
  internal static func callIncomingVideoPrompt(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "call_incoming_video_prompt", p1)
  }
  /// Incoming call...
  internal static var callIncomingVoice: String { 
    return VectorL10n.tr("Vector", "call_incoming_voice") 
  }
  /// Incoming voice call from %@
  internal static func callIncomingVoicePrompt(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "call_incoming_voice_prompt", p1)
  }
  /// Failed to join the conference call.
  internal static var callJitsiError: String { 
    return VectorL10n.tr("Vector", "call_jitsi_error") 
  }
  /// Camera
  internal static var camera: String { 
    return VectorL10n.tr("Vector", "camera") 
  }
  /// %@ doesn't have permission to use Camera, please change privacy settings
  internal static func cameraAccessNotGranted(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "camera_access_not_granted", p1)
  }
  /// Cancel
  internal static var cancel: String { 
    return VectorL10n.tr("Vector", "cancel") 
  }
  /// Close
  internal static var close: String { 
    return VectorL10n.tr("Vector", "close") 
  }
  /// collapse
  internal static var collapse: String { 
    return VectorL10n.tr("Vector", "collapse") 
  }
  /// Matrix users only
  internal static var contactsAddressBookMatrixUsersToggle: String { 
    return VectorL10n.tr("Vector", "contacts_address_book_matrix_users_toggle") 
  }
  /// No local contacts
  internal static var contactsAddressBookNoContact: String { 
    return VectorL10n.tr("Vector", "contacts_address_book_no_contact") 
  }
  /// You didn't allow Riot to access your local contacts
  internal static var contactsAddressBookPermissionDenied: String { 
    return VectorL10n.tr("Vector", "contacts_address_book_permission_denied") 
  }
  /// Permission required to access local contacts
  internal static var contactsAddressBookPermissionRequired: String { 
    return VectorL10n.tr("Vector", "contacts_address_book_permission_required") 
  }
  /// LOCAL CONTACTS
  internal static var contactsAddressBookSection: String { 
    return VectorL10n.tr("Vector", "contacts_address_book_section") 
  }
  /// USER DIRECTORY (offline)
  internal static var contactsUserDirectoryOfflineSection: String { 
    return VectorL10n.tr("Vector", "contacts_user_directory_offline_section") 
  }
  /// USER DIRECTORY
  internal static var contactsUserDirectorySection: String { 
    return VectorL10n.tr("Vector", "contacts_user_directory_section") 
  }
  /// Continue
  internal static var `continue`: String { 
    return VectorL10n.tr("Vector", "continue") 
  }
  /// Create
  internal static var create: String { 
    return VectorL10n.tr("Vector", "create") 
  }
  /// Please forget all messages I have sent when my account is deactivated (
  internal static var deactivateAccountForgetMessagesInformationPart1: String { 
    return VectorL10n.tr("Vector", "deactivate_account_forget_messages_information_part1") 
  }
  /// Warning
  internal static var deactivateAccountForgetMessagesInformationPart2Emphasize: String { 
    return VectorL10n.tr("Vector", "deactivate_account_forget_messages_information_part2_emphasize") 
  }
  /// : this will cause future users to see an incomplete view of conversations)
  internal static var deactivateAccountForgetMessagesInformationPart3: String { 
    return VectorL10n.tr("Vector", "deactivate_account_forget_messages_information_part3") 
  }
  /// This will make your account permanently unusable. You will not be able to log in, and no one will be able to re-register the same user ID.  This will cause your account to leave all rooms it is participating in, and it will remove your account details from your identity server. 
  internal static var deactivateAccountInformationsPart1: String { 
    return VectorL10n.tr("Vector", "deactivate_account_informations_part1") 
  }
  /// This action is irreversible.
  internal static var deactivateAccountInformationsPart2Emphasize: String { 
    return VectorL10n.tr("Vector", "deactivate_account_informations_part2_emphasize") 
  }
  /// \n\nDeactivating your account 
  internal static var deactivateAccountInformationsPart3: String { 
    return VectorL10n.tr("Vector", "deactivate_account_informations_part3") 
  }
  /// does not by default cause us to forget messages you have sent. 
  internal static var deactivateAccountInformationsPart4Emphasize: String { 
    return VectorL10n.tr("Vector", "deactivate_account_informations_part4_emphasize") 
  }
  /// If you would like us to forget your messages, please tick the box below\n\nMessage visibility in Matrix is similar to email. Our forgetting your messages means that messages you have sent will not be shared with any new or unregistered users, but registered users who already have access to these messages will still have access to their copy.
  internal static var deactivateAccountInformationsPart5: String { 
    return VectorL10n.tr("Vector", "deactivate_account_informations_part5") 
  }
  /// To continue, please enter your password
  internal static var deactivateAccountPasswordAlertMessage: String { 
    return VectorL10n.tr("Vector", "deactivate_account_password_alert_message") 
  }
  /// Deactivate Account
  internal static var deactivateAccountPasswordAlertTitle: String { 
    return VectorL10n.tr("Vector", "deactivate_account_password_alert_title") 
  }
  /// Deactivate Account
  internal static var deactivateAccountTitle: String { 
    return VectorL10n.tr("Vector", "deactivate_account_title") 
  }
  /// Deactivate account
  internal static var deactivateAccountValidateAction: String { 
    return VectorL10n.tr("Vector", "deactivate_account_validate_action") 
  }
  /// Decline
  internal static var decline: String { 
    return VectorL10n.tr("Vector", "decline") 
  }
  /// The other party cancelled the verification.
  internal static var deviceVerificationCancelled: String { 
    return VectorL10n.tr("Vector", "device_verification_cancelled") 
  }
  /// The verification has been cancelled. Reason: %@
  internal static func deviceVerificationCancelledByMe(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "device_verification_cancelled_by_me", p1)
  }
  /// Aeroplane
  internal static var deviceVerificationEmojiAeroplane: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_aeroplane") 
  }
  /// Anchor
  internal static var deviceVerificationEmojiAnchor: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_anchor") 
  }
  /// Apple
  internal static var deviceVerificationEmojiApple: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_apple") 
  }
  /// Ball
  internal static var deviceVerificationEmojiBall: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_ball") 
  }
  /// Banana
  internal static var deviceVerificationEmojiBanana: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_banana") 
  }
  /// Bell
  internal static var deviceVerificationEmojiBell: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_bell") 
  }
  /// Bicycle
  internal static var deviceVerificationEmojiBicycle: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_bicycle") 
  }
  /// Book
  internal static var deviceVerificationEmojiBook: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_book") 
  }
  /// Butterfly
  internal static var deviceVerificationEmojiButterfly: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_butterfly") 
  }
  /// Cactus
  internal static var deviceVerificationEmojiCactus: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_cactus") 
  }
  /// Cake
  internal static var deviceVerificationEmojiCake: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_cake") 
  }
  /// Cat
  internal static var deviceVerificationEmojiCat: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_cat") 
  }
  /// Clock
  internal static var deviceVerificationEmojiClock: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_clock") 
  }
  /// Cloud
  internal static var deviceVerificationEmojiCloud: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_cloud") 
  }
  /// Corn
  internal static var deviceVerificationEmojiCorn: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_corn") 
  }
  /// Dog
  internal static var deviceVerificationEmojiDog: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_dog") 
  }
  /// Elephant
  internal static var deviceVerificationEmojiElephant: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_elephant") 
  }
  /// Fire
  internal static var deviceVerificationEmojiFire: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_fire") 
  }
  /// Fish
  internal static var deviceVerificationEmojiFish: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_fish") 
  }
  /// Flag
  internal static var deviceVerificationEmojiFlag: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_flag") 
  }
  /// Flower
  internal static var deviceVerificationEmojiFlower: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_flower") 
  }
  /// Folder
  internal static var deviceVerificationEmojiFolder: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_folder") 
  }
  /// Gift
  internal static var deviceVerificationEmojiGift: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_gift") 
  }
  /// Glasses
  internal static var deviceVerificationEmojiGlasses: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_glasses") 
  }
  /// Globe
  internal static var deviceVerificationEmojiGlobe: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_globe") 
  }
  /// Guitar
  internal static var deviceVerificationEmojiGuitar: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_guitar") 
  }
  /// Hammer
  internal static var deviceVerificationEmojiHammer: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_hammer") 
  }
  /// Hat
  internal static var deviceVerificationEmojiHat: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_hat") 
  }
  /// Headphones
  internal static var deviceVerificationEmojiHeadphones: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_headphones") 
  }
  /// Heart
  internal static var deviceVerificationEmojiHeart: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_heart") 
  }
  /// Horse
  internal static var deviceVerificationEmojiHorse: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_horse") 
  }
  /// Hourglass
  internal static var deviceVerificationEmojiHourglass: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_hourglass") 
  }
  /// Key
  internal static var deviceVerificationEmojiKey: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_key") 
  }
  /// Light Bulb
  internal static var deviceVerificationEmojiLightBulb: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_light bulb") 
  }
  /// Lion
  internal static var deviceVerificationEmojiLion: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_lion") 
  }
  /// Lock
  internal static var deviceVerificationEmojiLock: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_lock") 
  }
  /// Moon
  internal static var deviceVerificationEmojiMoon: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_moon") 
  }
  /// Mushroom
  internal static var deviceVerificationEmojiMushroom: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_mushroom") 
  }
  /// Octopus
  internal static var deviceVerificationEmojiOctopus: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_octopus") 
  }
  /// Panda
  internal static var deviceVerificationEmojiPanda: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_panda") 
  }
  /// Paperclip
  internal static var deviceVerificationEmojiPaperclip: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_paperclip") 
  }
  /// Pencil
  internal static var deviceVerificationEmojiPencil: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_pencil") 
  }
  /// Penguin
  internal static var deviceVerificationEmojiPenguin: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_penguin") 
  }
  /// Pig
  internal static var deviceVerificationEmojiPig: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_pig") 
  }
  /// Pin
  internal static var deviceVerificationEmojiPin: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_pin") 
  }
  /// Pizza
  internal static var deviceVerificationEmojiPizza: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_pizza") 
  }
  /// Rabbit
  internal static var deviceVerificationEmojiRabbit: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_rabbit") 
  }
  /// Robot
  internal static var deviceVerificationEmojiRobot: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_robot") 
  }
  /// Rocket
  internal static var deviceVerificationEmojiRocket: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_rocket") 
  }
  /// Rooster
  internal static var deviceVerificationEmojiRooster: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_rooster") 
  }
  /// Santa
  internal static var deviceVerificationEmojiSanta: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_santa") 
  }
  /// Scissors
  internal static var deviceVerificationEmojiScissors: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_scissors") 
  }
  /// Smiley
  internal static var deviceVerificationEmojiSmiley: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_smiley") 
  }
  /// Spanner
  internal static var deviceVerificationEmojiSpanner: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_spanner") 
  }
  /// Strawberry
  internal static var deviceVerificationEmojiStrawberry: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_strawberry") 
  }
  /// Telephone
  internal static var deviceVerificationEmojiTelephone: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_telephone") 
  }
  /// Thumbs up
  internal static var deviceVerificationEmojiThumbsUp: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_thumbs up") 
  }
  /// Train
  internal static var deviceVerificationEmojiTrain: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_train") 
  }
  /// Tree
  internal static var deviceVerificationEmojiTree: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_tree") 
  }
  /// Trophy
  internal static var deviceVerificationEmojiTrophy: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_trophy") 
  }
  /// Trumpet
  internal static var deviceVerificationEmojiTrumpet: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_trumpet") 
  }
  /// Turtle
  internal static var deviceVerificationEmojiTurtle: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_turtle") 
  }
  /// Umbrella
  internal static var deviceVerificationEmojiUmbrella: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_umbrella") 
  }
  /// Unicorn
  internal static var deviceVerificationEmojiUnicorn: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_unicorn") 
  }
  /// Cannot load device information.
  internal static var deviceVerificationErrorCannotLoadDevice: String { 
    return VectorL10n.tr("Vector", "device_verification_error_cannot_load_device") 
  }
  /// Verify this device to mark it as trusted. Trusting devices of partners gives you extra peace of mind when using end-to-end encrypted messages.
  internal static var deviceVerificationIncomingDescription1: String { 
    return VectorL10n.tr("Vector", "device_verification_incoming_description_1") 
  }
  /// Verifying this device will mark it as trusted, and also mark your device as trusted to the partner.
  internal static var deviceVerificationIncomingDescription2: String { 
    return VectorL10n.tr("Vector", "device_verification_incoming_description_2") 
  }
  /// Incoming Verification Request
  internal static var deviceVerificationIncomingTitle: String { 
    return VectorL10n.tr("Vector", "device_verification_incoming_title") 
  }
  /// For maximum security, we recommend you do this in person or use another trusted means of communication
  internal static var deviceVerificationSecurityAdvice: String { 
    return VectorL10n.tr("Vector", "device_verification_security_advice") 
  }
  /// Verify by comparing a short text string
  internal static var deviceVerificationStartTitle: String { 
    return VectorL10n.tr("Vector", "device_verification_start_title") 
  }
  /// Nothing appearing? Not all clients supports interactive verification yet. Use legacy verification.
  internal static var deviceVerificationStartUseLegacy: String { 
    return VectorL10n.tr("Vector", "device_verification_start_use_legacy") 
  }
  /// Use Legacy Verification
  internal static var deviceVerificationStartUseLegacyAction: String { 
    return VectorL10n.tr("Vector", "device_verification_start_use_legacy_action") 
  }
  /// Begin Verifying
  internal static var deviceVerificationStartVerifyButton: String { 
    return VectorL10n.tr("Vector", "device_verification_start_verify_button") 
  }
  /// Waiting for partner to accept...
  internal static var deviceVerificationStartWaitPartner: String { 
    return VectorL10n.tr("Vector", "device_verification_start_wait_partner") 
  }
  /// Verify device
  internal static var deviceVerificationTitle: String { 
    return VectorL10n.tr("Vector", "device_verification_title") 
  }
  /// You've successfully verified this device.
  internal static var deviceVerificationVerifiedDescription1: String { 
    return VectorL10n.tr("Vector", "device_verification_verified_description_1") 
  }
  /// Secure messages with this user are end-to-end encrypted and not able to be read by third parties.
  internal static var deviceVerificationVerifiedDescription2: String { 
    return VectorL10n.tr("Vector", "device_verification_verified_description_2") 
  }
  /// Got it
  internal static var deviceVerificationVerifiedGotItButton: String { 
    return VectorL10n.tr("Vector", "device_verification_verified_got_it_button") 
  }
  /// Verified!
  internal static var deviceVerificationVerifiedTitle: String { 
    return VectorL10n.tr("Vector", "device_verification_verified_title") 
  }
  /// Verify this device by confirming the following emoji appear on the screen of the partner
  internal static var deviceVerificationVerifyTitleEmoji: String { 
    return VectorL10n.tr("Vector", "device_verification_verify_title_emoji") 
  }
  /// Verify this device by confirming the following numbers appear on the screen of the partner
  internal static var deviceVerificationVerifyTitleNumber: String { 
    return VectorL10n.tr("Vector", "device_verification_verify_title_number") 
  }
  /// Waiting for partner to confirm...
  internal static var deviceVerificationVerifyWaitPartner: String { 
    return VectorL10n.tr("Vector", "device_verification_verify_wait_partner") 
  }
  /// %tu rooms
  internal static func directoryCellDescription(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "directory_cell_description", p1)
  }
  /// Browse directory
  internal static var directoryCellTitle: String { 
    return VectorL10n.tr("Vector", "directory_cell_title") 
  }
  /// Failed to fetch data
  internal static var directorySearchFail: String { 
    return VectorL10n.tr("Vector", "directory_search_fail") 
  }
  /// %tu results found for %@
  internal static func directorySearchResults(_ p1: Int, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "directory_search_results", p1, p2)
  }
  /// >%tu results found for %@
  internal static func directorySearchResultsMoreThan(_ p1: Int, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "directory_search_results_more_than", p1, p2)
  }
  /// Browse directory results
  internal static var directorySearchResultsTitle: String { 
    return VectorL10n.tr("Vector", "directory_search_results_title") 
  }
  /// Searching directory…
  internal static var directorySearchingTitle: String { 
    return VectorL10n.tr("Vector", "directory_searching_title") 
  }
  /// All native Matrix rooms
  internal static var directoryServerAllNativeRooms: String { 
    return VectorL10n.tr("Vector", "directory_server_all_native_rooms") 
  }
  /// All rooms on %@ server
  internal static func directoryServerAllRooms(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "directory_server_all_rooms", p1)
  }
  /// Select a directory
  internal static var directoryServerPickerTitle: String { 
    return VectorL10n.tr("Vector", "directory_server_picker_title") 
  }
  /// matrix.org
  internal static var directoryServerPlaceholder: String { 
    return VectorL10n.tr("Vector", "directory_server_placeholder") 
  }
  /// Type a homeserver to list public rooms from
  internal static var directoryServerTypeHomeserver: String { 
    return VectorL10n.tr("Vector", "directory_server_type_homeserver") 
  }
  /// Directory
  internal static var directoryTitle: String { 
    return VectorL10n.tr("Vector", "directory_title") 
  }
  /// Do not ask again
  internal static var doNotAskAgain: String { 
    return VectorL10n.tr("Vector", "do_not_ask_again") 
  }
  /// Riot now supports end-to-end encryption but you need to log in again to enable it.\n\nYou can do it now or later from the application settings.
  internal static var e2eEnablingOnAppUpdate: String { 
    return VectorL10n.tr("Vector", "e2e_enabling_on_app_update") 
  }
  /// A new secure message key backup has been detected.\n\nIf this wasn’t you, set a new passphrase in Settings.
  internal static var e2eKeyBackupWrongVersion: String { 
    return VectorL10n.tr("Vector", "e2e_key_backup_wrong_version") 
  }
  /// Settings
  internal static var e2eKeyBackupWrongVersionButtonSettings: String { 
    return VectorL10n.tr("Vector", "e2e_key_backup_wrong_version_button_settings") 
  }
  /// It was me
  internal static var e2eKeyBackupWrongVersionButtonWasme: String { 
    return VectorL10n.tr("Vector", "e2e_key_backup_wrong_version_button_wasme") 
  }
  /// New Key Backup
  internal static var e2eKeyBackupWrongVersionTitle: String { 
    return VectorL10n.tr("Vector", "e2e_key_backup_wrong_version_title") 
  }
  /// You need to log back in to generate end-to-end encryption keys for this device and submit the public key to your homeserver.\nThis is a once off; sorry for the inconvenience.
  internal static var e2eNeedLogInAgain: String { 
    return VectorL10n.tr("Vector", "e2e_need_log_in_again") 
  }
  /// Ignore request
  internal static var e2eRoomKeyRequestIgnoreRequest: String { 
    return VectorL10n.tr("Vector", "e2e_room_key_request_ignore_request") 
  }
  /// Your unverified device '%@' is requesting encryption keys.
  internal static func e2eRoomKeyRequestMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "e2e_room_key_request_message", p1)
  }
  /// You added a new device '%@', which is requesting encryption keys.
  internal static func e2eRoomKeyRequestMessageNewDevice(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "e2e_room_key_request_message_new_device", p1)
  }
  /// Share without verifying
  internal static var e2eRoomKeyRequestShareWithoutVerifying: String { 
    return VectorL10n.tr("Vector", "e2e_room_key_request_share_without_verifying") 
  }
  /// Start verification...
  internal static var e2eRoomKeyRequestStartVerification: String { 
    return VectorL10n.tr("Vector", "e2e_room_key_request_start_verification") 
  }
  /// Encryption key request
  internal static var e2eRoomKeyRequestTitle: String { 
    return VectorL10n.tr("Vector", "e2e_room_key_request_title") 
  }
  /// Send an encrypted message…
  internal static var encryptedRoomMessagePlaceholder: String { 
    return VectorL10n.tr("Vector", "encrypted_room_message_placeholder") 
  }
  /// Send an encrypted reply…
  internal static var encryptedRoomMessageReplyToPlaceholder: String { 
    return VectorL10n.tr("Vector", "encrypted_room_message_reply_to_placeholder") 
  }
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
  /// (edited)
  internal static var eventFormatterMessageEditedMention: String { 
    return VectorL10n.tr("Vector", "event_formatter_message_edited_mention") 
  }
  /// Re-request encryption keys
  internal static var eventFormatterRerequestKeysPart1Link: String { 
    return VectorL10n.tr("Vector", "event_formatter_rerequest_keys_part1_link") 
  }
  ///  from your other devices.
  internal static var eventFormatterRerequestKeysPart2: String { 
    return VectorL10n.tr("Vector", "event_formatter_rerequest_keys_part2") 
  }
  /// %@ widget added by %@
  internal static func eventFormatterWidgetAdded(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_widget_added", p1, p2)
  }
  /// %@ widget removed by %@
  internal static func eventFormatterWidgetRemoved(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_widget_removed", p1, p2)
  }
  /// File upload
  internal static var fileUploadErrorTitle: String { 
    return VectorL10n.tr("Vector", "file_upload_error_title") 
  }
  /// File type not supported.
  internal static var fileUploadErrorUnsupportedFileTypeMessage: String { 
    return VectorL10n.tr("Vector", "file_upload_error_unsupported_file_type_message") 
  }
  /// To continue using the %@ homeserver you must review and agree to the terms and conditions.
  internal static func gdprConsentNotGivenAlertMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "gdpr_consent_not_given_alert_message", p1)
  }
  /// Review now
  internal static var gdprConsentNotGivenAlertReviewNowAction: String { 
    return VectorL10n.tr("Vector", "gdpr_consent_not_given_alert_review_now_action") 
  }
  /// Would you like to help improve %@ by automatically reporting anonymous crash reports and usage data?
  internal static func googleAnalyticsUsePrompt(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "google_analytics_use_prompt", p1)
  }
  /// Home
  internal static var groupDetailsHome: String { 
    return VectorL10n.tr("Vector", "group_details_home") 
  }
  /// People
  internal static var groupDetailsPeople: String { 
    return VectorL10n.tr("Vector", "group_details_people") 
  }
  /// Rooms
  internal static var groupDetailsRooms: String { 
    return VectorL10n.tr("Vector", "group_details_rooms") 
  }
  /// Community Details
  internal static var groupDetailsTitle: String { 
    return VectorL10n.tr("Vector", "group_details_title") 
  }
  /// %tu members
  internal static func groupHomeMultiMembersFormat(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "group_home_multi_members_format", p1)
  }
  /// %tu rooms
  internal static func groupHomeMultiRoomsFormat(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "group_home_multi_rooms_format", p1)
  }
  /// 1 member
  internal static var groupHomeOneMemberFormat: String { 
    return VectorL10n.tr("Vector", "group_home_one_member_format") 
  }
  /// 1 room
  internal static var groupHomeOneRoomFormat: String { 
    return VectorL10n.tr("Vector", "group_home_one_room_format") 
  }
  /// %@ has invited you to join this community
  internal static func groupInvitationFormat(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "group_invitation_format", p1)
  }
  /// INVITES
  internal static var groupInviteSection: String { 
    return VectorL10n.tr("Vector", "group_invite_section") 
  }
  /// Add participant
  internal static var groupParticipantsAddParticipant: String { 
    return VectorL10n.tr("Vector", "group_participants_add_participant") 
  }
  /// Filter community members
  internal static var groupParticipantsFilterMembers: String { 
    return VectorL10n.tr("Vector", "group_participants_filter_members") 
  }
  /// Search / invite by User ID or Name
  internal static var groupParticipantsInviteAnotherUser: String { 
    return VectorL10n.tr("Vector", "group_participants_invite_another_user") 
  }
  /// Malformed ID. Should be a Matrix ID like '@localpart:domain'
  internal static var groupParticipantsInviteMalformedId: String { 
    return VectorL10n.tr("Vector", "group_participants_invite_malformed_id") 
  }
  /// Invite Error
  internal static var groupParticipantsInviteMalformedIdTitle: String { 
    return VectorL10n.tr("Vector", "group_participants_invite_malformed_id_title") 
  }
  /// Are you sure you want to invite %@ to this group?
  internal static func groupParticipantsInvitePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "group_participants_invite_prompt_msg", p1)
  }
  /// Confirmation
  internal static var groupParticipantsInvitePromptTitle: String { 
    return VectorL10n.tr("Vector", "group_participants_invite_prompt_title") 
  }
  /// INVITED
  internal static var groupParticipantsInvitedSection: String { 
    return VectorL10n.tr("Vector", "group_participants_invited_section") 
  }
  /// Are you sure you want to leave the group?
  internal static var groupParticipantsLeavePromptMsg: String { 
    return VectorL10n.tr("Vector", "group_participants_leave_prompt_msg") 
  }
  /// Leave group
  internal static var groupParticipantsLeavePromptTitle: String { 
    return VectorL10n.tr("Vector", "group_participants_leave_prompt_title") 
  }
  /// Are you sure you want to remove %@ from this group?
  internal static func groupParticipantsRemovePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "group_participants_remove_prompt_msg", p1)
  }
  /// Confirmation
  internal static var groupParticipantsRemovePromptTitle: String { 
    return VectorL10n.tr("Vector", "group_participants_remove_prompt_title") 
  }
  /// Filter community rooms
  internal static var groupRoomsFilterRooms: String { 
    return VectorL10n.tr("Vector", "group_rooms_filter_rooms") 
  }
  /// COMMUNITIES
  internal static var groupSection: String { 
    return VectorL10n.tr("Vector", "group_section") 
  }
  /// Could not connect to the homeserver.
  internal static var homeserverConnectionLost: String { 
    return VectorL10n.tr("Vector", "homeserver_connection_lost") 
  }
  /// Invite
  internal static var invite: String { 
    return VectorL10n.tr("Vector", "invite") 
  }
  /// Join
  internal static var join: String { 
    return VectorL10n.tr("Vector", "join") 
  }
  /// Never lose encrypted messages
  internal static var keyBackupRecoverBannerTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_banner_title") 
  }
  /// Connect this device to Key Backup
  internal static var keyBackupRecoverConnentBannerSubtitle: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_connent_banner_subtitle") 
  }
  /// Done
  internal static var keyBackupRecoverDoneAction: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_done_action") 
  }
  /// Use your recovery passphrase to unlock your secure message history
  internal static var keyBackupRecoverFromPassphraseInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_info") 
  }
  /// Don’t know your recovery passphrase? You can 
  internal static var keyBackupRecoverFromPassphraseLostPassphraseActionPart1: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_lost_passphrase_action_part1") 
  }
  /// use your recovery key
  internal static var keyBackupRecoverFromPassphraseLostPassphraseActionPart2: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_lost_passphrase_action_part2") 
  }
  /// .
  internal static var keyBackupRecoverFromPassphraseLostPassphraseActionPart3: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_lost_passphrase_action_part3") 
  }
  /// Enter Passphrase
  internal static var keyBackupRecoverFromPassphrasePassphrasePlaceholder: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_passphrase_placeholder") 
  }
  /// Enter
  internal static var keyBackupRecoverFromPassphrasePassphraseTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_passphrase_title") 
  }
  /// Unlock History
  internal static var keyBackupRecoverFromPassphraseRecoverAction: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_recover_action") 
  }
  /// Use your recovery key to unlock your secure message history
  internal static var keyBackupRecoverFromRecoveryKeyInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_recovery_key_info") 
  }
  /// Lost your recovery key? You can set up a new one in settings.
  internal static var keyBackupRecoverFromRecoveryKeyLostRecoveryKeyAction: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_recovery_key_lost_recovery_key_action") 
  }
  /// Unlock History
  internal static var keyBackupRecoverFromRecoveryKeyRecoverAction: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_recovery_key_recover_action") 
  }
  /// Enter Recovery Key
  internal static var keyBackupRecoverFromRecoveryKeyRecoveryKeyPlaceholder: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_recovery_key_recovery_key_placeholder") 
  }
  /// Enter
  internal static var keyBackupRecoverFromRecoveryKeyRecoveryKeyTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_recovery_key_recovery_key_title") 
  }
  /// Backup could not be decrypted with this passphrase: please verify that you entered the correct recovery passphrase.
  internal static var keyBackupRecoverInvalidPassphrase: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_invalid_passphrase") 
  }
  /// Incorrect Recovery Passphrase
  internal static var keyBackupRecoverInvalidPassphraseTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_invalid_passphrase_title") 
  }
  /// Backup could not be decrypted with this key: please verify that you entered the correct recovery key.
  internal static var keyBackupRecoverInvalidRecoveryKey: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_invalid_recovery_key") 
  }
  /// Recovery Key Mismatch
  internal static var keyBackupRecoverInvalidRecoveryKeyTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_invalid_recovery_key_title") 
  }
  /// Backup Restored!
  internal static var keyBackupRecoverSuccessInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_success_info") 
  }
  /// Secure Messages
  internal static var keyBackupRecoverTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_title") 
  }
  /// Start using Key Backup
  internal static var keyBackupSetupBannerSubtitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_banner_subtitle") 
  }
  /// Never lose encrypted messages
  internal static var keyBackupSetupBannerTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_banner_title") 
  }
  /// Messages in encrypted rooms are secured with end-to-end encryption. Only you and the recipient(s) have the keys to read these messages.\n\nSecurely back up your keys to avoid losing them.
  internal static var keyBackupSetupIntroInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_intro_info") 
  }
  /// Manually export keys
  internal static var keyBackupSetupIntroManualExportAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_intro_manual_export_action") 
  }
  /// (Advanced)
  internal static var keyBackupSetupIntroManualExportInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_intro_manual_export_info") 
  }
  /// Start using Key Backup
  internal static var keyBackupSetupIntroSetupActionWithoutExistingBackup: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_intro_setup_action_without_existing_backup") 
  }
  /// Connect this device to Key Backup
  internal static var keyBackupSetupIntroSetupConnectActionWithExistingBackup: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_intro_setup_connect_action_with_existing_backup") 
  }
  /// Never lose encrypted messages
  internal static var keyBackupSetupIntroTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_intro_title") 
  }
  /// Passphrase doesn’t match
  internal static var keyBackupSetupPassphraseConfirmPassphraseInvalid: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_confirm_passphrase_invalid") 
  }
  /// Confirm passphrase
  internal static var keyBackupSetupPassphraseConfirmPassphrasePlaceholder: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_confirm_passphrase_placeholder") 
  }
  /// Confirm
  internal static var keyBackupSetupPassphraseConfirmPassphraseTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_confirm_passphrase_title") 
  }
  /// Great!
  internal static var keyBackupSetupPassphraseConfirmPassphraseValid: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_confirm_passphrase_valid") 
  }
  /// We'll store an encrypted copy of your keys on our server. Protect your backup with a passphrase to keep it secure.\n\nFor maximum security, this should be different from your account password.
  internal static var keyBackupSetupPassphraseInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_info") 
  }
  /// Try adding a word
  internal static var keyBackupSetupPassphrasePassphraseInvalid: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_passphrase_invalid") 
  }
  /// Enter passphrase
  internal static var keyBackupSetupPassphrasePassphrasePlaceholder: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_passphrase_placeholder") 
  }
  /// Enter
  internal static var keyBackupSetupPassphrasePassphraseTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_passphrase_title") 
  }
  /// Great!
  internal static var keyBackupSetupPassphrasePassphraseValid: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_passphrase_valid") 
  }
  /// Set Passphrase
  internal static var keyBackupSetupPassphraseSetPassphraseAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_set_passphrase_action") 
  }
  /// (Advanced) Set up with Recovery Key
  internal static var keyBackupSetupPassphraseSetupRecoveryKeyAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_setup_recovery_key_action") 
  }
  /// Or, secure your backup with a Recovery Key, saving it somewhere safe.
  internal static var keyBackupSetupPassphraseSetupRecoveryKeyInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_setup_recovery_key_info") 
  }
  /// Secure your backup with a Passphrase
  internal static var keyBackupSetupPassphraseTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_title") 
  }
  /// You may lose secure messages if you log out or lose your device.
  internal static var keyBackupSetupSkipAlertMessage: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_skip_alert_message") 
  }
  /// Skip
  internal static var keyBackupSetupSkipAlertSkipAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_skip_alert_skip_action") 
  }
  /// Are you sure?
  internal static var keyBackupSetupSkipAlertTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_skip_alert_title") 
  }
  /// Done
  internal static var keyBackupSetupSuccessFromPassphraseDoneAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_passphrase_done_action") 
  }
  /// Your keys are being backed up.\n\nYour recovery key is a safety net - you can use it to restore access to your encrypted messages if you forget your passphrase.\n\nKeep your recovery key somewhere very secure, like a password manager (or a safe).
  internal static var keyBackupSetupSuccessFromPassphraseInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_passphrase_info") 
  }
  /// Save Recovery Key
  internal static var keyBackupSetupSuccessFromPassphraseSaveRecoveryKeyAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_passphrase_save_recovery_key_action") 
  }
  /// Your keys are being backed up.\n\nMake a copy of this recovery key and keep it safe.
  internal static var keyBackupSetupSuccessFromRecoveryKeyInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_recovery_key_info") 
  }
  /// I've made a copy
  internal static var keyBackupSetupSuccessFromRecoveryKeyMadeCopyAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_recovery_key_made_copy_action") 
  }
  /// Make a Copy
  internal static var keyBackupSetupSuccessFromRecoveryKeyMakeCopyAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_recovery_key_make_copy_action") 
  }
  /// Recovery Key
  internal static var keyBackupSetupSuccessFromRecoveryKeyRecoveryKeyTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_recovery_key_recovery_key_title") 
  }
  /// Success!
  internal static var keyBackupSetupSuccessTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_title") 
  }
  /// Key Backup
  internal static var keyBackupSetupTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_title") 
  }
  /// %.1fK
  internal static func largeBadgeValueKFormat(_ p1: Float) -> String {
    return VectorL10n.tr("Vector", "large_badge_value_k_format", p1)
  }
  /// Later
  internal static var later: String { 
    return VectorL10n.tr("Vector", "later") 
  }
  /// Leave
  internal static var leave: String { 
    return VectorL10n.tr("Vector", "leave") 
  }
  /// Library
  internal static var mediaPickerLibrary: String { 
    return VectorL10n.tr("Vector", "media_picker_library") 
  }
  /// Select
  internal static var mediaPickerSelect: String { 
    return VectorL10n.tr("Vector", "media_picker_select") 
  }
  /// The Internet connection appears to be offline.
  internal static var networkOfflinePrompt: String { 
    return VectorL10n.tr("Vector", "network_offline_prompt") 
  }
  /// Next
  internal static var next: String { 
    return VectorL10n.tr("Vector", "next") 
  }
  /// %@ is calling you but %@ does not support calls yet.\nYou can ignore this notification and answer the call from another device or you can reject it.
  internal static func noVoip(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "no_voip", p1, p2)
  }
  /// Incoming call
  internal static var noVoipTitle: String { 
    return VectorL10n.tr("Vector", "no_voip_title") 
  }
  /// Off
  internal static var off: String { 
    return VectorL10n.tr("Vector", "off") 
  }
  /// On
  internal static var on: String { 
    return VectorL10n.tr("Vector", "on") 
  }
  /// or
  internal static var or: String { 
    return VectorL10n.tr("Vector", "or") 
  }
  /// CONVERSATIONS
  internal static var peopleConversationSection: String { 
    return VectorL10n.tr("Vector", "people_conversation_section") 
  }
  /// INVITES
  internal static var peopleInvitesSection: String { 
    return VectorL10n.tr("Vector", "people_invites_section") 
  }
  /// No conversations
  internal static var peopleNoConversation: String { 
    return VectorL10n.tr("Vector", "people_no_conversation") 
  }
  /// Preview
  internal static var preview: String { 
    return VectorL10n.tr("Vector", "preview") 
  }
  /// Public Rooms (at %@):
  internal static func publicRoomSectionTitle(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "public_room_section_title", p1)
  }
  /// You seem to be shaking the phone in frustration. Would you like to submit a bug report?
  internal static var rageShakePrompt: String { 
    return VectorL10n.tr("Vector", "rage_shake_prompt") 
  }
  /// Read Receipts List
  internal static var readReceiptsList: String { 
    return VectorL10n.tr("Vector", "read_receipts_list") 
  }
  /// Read: 
  internal static var receiptStatusRead: String { 
    return VectorL10n.tr("Vector", "receipt_status_read") 
  }
  /// Remove
  internal static var remove: String { 
    return VectorL10n.tr("Vector", "remove") 
  }
  /// Rename
  internal static var rename: String { 
    return VectorL10n.tr("Vector", "rename") 
  }
  /// Please launch Riot on another device that can decrypt the message so it can send the keys to this device.
  internal static var rerequestKeysAlertMessage: String { 
    return VectorL10n.tr("Vector", "rerequest_keys_alert_message") 
  }
  /// Request Sent
  internal static var rerequestKeysAlertTitle: String { 
    return VectorL10n.tr("Vector", "rerequest_keys_alert_title") 
  }
  /// Retry
  internal static var retry: String { 
    return VectorL10n.tr("Vector", "retry") 
  }
  /// Reply
  internal static var roomActionReply: String { 
    return VectorL10n.tr("Vector", "room_action_reply") 
  }
  /// Send file
  internal static var roomActionSendFile: String { 
    return VectorL10n.tr("Vector", "room_action_send_file") 
  }
  /// Send photo or video
  internal static var roomActionSendPhotoOrVideo: String { 
    return VectorL10n.tr("Vector", "room_action_send_photo_or_video") 
  }
  /// Send sticker
  internal static var roomActionSendSticker: String { 
    return VectorL10n.tr("Vector", "room_action_send_sticker") 
  }
  /// You need permission to manage conference call in this room
  internal static var roomConferenceCallNoPower: String { 
    return VectorL10n.tr("Vector", "room_conference_call_no_power") 
  }
  /// Account
  internal static var roomCreationAccount: String { 
    return VectorL10n.tr("Vector", "room_creation_account") 
  }
  /// Appearance
  internal static var roomCreationAppearance: String { 
    return VectorL10n.tr("Vector", "room_creation_appearance") 
  }
  /// Name
  internal static var roomCreationAppearanceName: String { 
    return VectorL10n.tr("Vector", "room_creation_appearance_name") 
  }
  /// Chat picture (optional)
  internal static var roomCreationAppearancePicture: String { 
    return VectorL10n.tr("Vector", "room_creation_appearance_picture") 
  }
  /// Search / invite by User ID, Name or email
  internal static var roomCreationInviteAnotherUser: String { 
    return VectorL10n.tr("Vector", "room_creation_invite_another_user") 
  }
  /// Keep private
  internal static var roomCreationKeepPrivate: String { 
    return VectorL10n.tr("Vector", "room_creation_keep_private") 
  }
  /// Make private
  internal static var roomCreationMakePrivate: String { 
    return VectorL10n.tr("Vector", "room_creation_make_private") 
  }
  /// Make public
  internal static var roomCreationMakePublic: String { 
    return VectorL10n.tr("Vector", "room_creation_make_public") 
  }
  /// Are you sure you want to make this chat public? Anyone can read your messages and join the chat.
  internal static var roomCreationMakePublicPromptMsg: String { 
    return VectorL10n.tr("Vector", "room_creation_make_public_prompt_msg") 
  }
  /// Make this chat public?
  internal static var roomCreationMakePublicPromptTitle: String { 
    return VectorL10n.tr("Vector", "room_creation_make_public_prompt_title") 
  }
  /// Privacy
  internal static var roomCreationPrivacy: String { 
    return VectorL10n.tr("Vector", "room_creation_privacy") 
  }
  /// This chat is private
  internal static var roomCreationPrivateRoom: String { 
    return VectorL10n.tr("Vector", "room_creation_private_room") 
  }
  /// This chat is public
  internal static var roomCreationPublicRoom: String { 
    return VectorL10n.tr("Vector", "room_creation_public_room") 
  }
  /// New Chat
  internal static var roomCreationTitle: String { 
    return VectorL10n.tr("Vector", "room_creation_title") 
  }
  /// A room is already being created. Please wait.
  internal static var roomCreationWaitForCreation: String { 
    return VectorL10n.tr("Vector", "room_creation_wait_for_creation") 
  }
  /// Delete unsent messages
  internal static var roomDeleteUnsentMessages: String { 
    return VectorL10n.tr("Vector", "room_delete_unsent_messages") 
  }
  /// Who can access this room?
  internal static var roomDetailsAccessSection: String { 
    return VectorL10n.tr("Vector", "room_details_access_section") 
  }
  /// Anyone who knows the room's link, including guests
  internal static var roomDetailsAccessSectionAnyone: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_anyone") 
  }
  /// Anyone who knows the room's link, apart from guests
  internal static var roomDetailsAccessSectionAnyoneApartFromGuest: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_anyone_apart_from_guest") 
  }
  /// List this room in room directory
  internal static var roomDetailsAccessSectionDirectoryToggle: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_directory_toggle") 
  }
  /// Only people who have been invited
  internal static var roomDetailsAccessSectionInvitedOnly: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_invited_only") 
  }
  /// To link to a room it must have an address
  internal static var roomDetailsAccessSectionNoAddressWarning: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_no_address_warning") 
  }
  /// You will have no main address specified. The default main address for this room will be picked randomly
  internal static var roomDetailsAddressesDisableMainAddressPromptMsg: String { 
    return VectorL10n.tr("Vector", "room_details_addresses_disable_main_address_prompt_msg") 
  }
  /// Main address warning
  internal static var roomDetailsAddressesDisableMainAddressPromptTitle: String { 
    return VectorL10n.tr("Vector", "room_details_addresses_disable_main_address_prompt_title") 
  }
  /// %@ is not a valid format for an alias
  internal static func roomDetailsAddressesInvalidAddressPromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_details_addresses_invalid_address_prompt_msg", p1)
  }
  /// Invalid alias format
  internal static var roomDetailsAddressesInvalidAddressPromptTitle: String { 
    return VectorL10n.tr("Vector", "room_details_addresses_invalid_address_prompt_title") 
  }
  /// Addresses
  internal static var roomDetailsAddressesSection: String { 
    return VectorL10n.tr("Vector", "room_details_addresses_section") 
  }
  /// Encrypt to verified devices only
  internal static var roomDetailsAdvancedE2eEncryptionBlacklistUnverifiedDevices: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_e2e_encryption_blacklist_unverified_devices") 
  }
  /// Encryption is not enabled in this room.
  internal static var roomDetailsAdvancedE2eEncryptionDisabled: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_e2e_encryption_disabled") 
  }
  /// Encryption is enabled in this room
  internal static var roomDetailsAdvancedE2eEncryptionEnabled: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_e2e_encryption_enabled") 
  }
  /// Enable encryption (warning: cannot be disabled again!)
  internal static var roomDetailsAdvancedEnableE2eEncryption: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_enable_e2e_encryption") 
  }
  /// Room ID:
  internal static var roomDetailsAdvancedRoomId: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_room_id") 
  }
  /// Advanced
  internal static var roomDetailsAdvancedSection: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_section") 
  }
  /// Banned users
  internal static var roomDetailsBannedUsersSection: String { 
    return VectorL10n.tr("Vector", "room_details_banned_users_section") 
  }
  /// Copy Room Address
  internal static var roomDetailsCopyRoomAddress: String { 
    return VectorL10n.tr("Vector", "room_details_copy_room_address") 
  }
  /// Copy Room ID
  internal static var roomDetailsCopyRoomId: String { 
    return VectorL10n.tr("Vector", "room_details_copy_room_id") 
  }
  /// Copy Room URL
  internal static var roomDetailsCopyRoomUrl: String { 
    return VectorL10n.tr("Vector", "room_details_copy_room_url") 
  }
  /// Direct Chat
  internal static var roomDetailsDirectChat: String { 
    return VectorL10n.tr("Vector", "room_details_direct_chat") 
  }
  /// Fail to add the new room addresses
  internal static var roomDetailsFailToAddRoomAliases: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_add_room_aliases") 
  }
  /// Fail to enable encryption in this room
  internal static var roomDetailsFailToEnableEncryption: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_enable_encryption") 
  }
  /// Fail to remove the room addresses
  internal static var roomDetailsFailToRemoveRoomAliases: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_remove_room_aliases") 
  }
  /// Fail to update the room photo
  internal static var roomDetailsFailToUpdateAvatar: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_avatar") 
  }
  /// Fail to update the history visibility
  internal static var roomDetailsFailToUpdateHistoryVisibility: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_history_visibility") 
  }
  /// Fail to update the main address
  internal static var roomDetailsFailToUpdateRoomCanonicalAlias: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_canonical_alias") 
  }
  /// Fail to update the related communities
  internal static var roomDetailsFailToUpdateRoomCommunities: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_communities") 
  }
  /// Fail to update the direct flag of this room
  internal static var roomDetailsFailToUpdateRoomDirect: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_direct") 
  }
  /// Fail to update the room directory visibility
  internal static var roomDetailsFailToUpdateRoomDirectoryVisibility: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_directory_visibility") 
  }
  /// Fail to update the room guest access
  internal static var roomDetailsFailToUpdateRoomGuestAccess: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_guest_access") 
  }
  /// Fail to update the join rule
  internal static var roomDetailsFailToUpdateRoomJoinRule: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_join_rule") 
  }
  /// Fail to update the room name
  internal static var roomDetailsFailToUpdateRoomName: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_name") 
  }
  /// Fail to update the topic
  internal static var roomDetailsFailToUpdateTopic: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_topic") 
  }
  /// Favourite
  internal static var roomDetailsFavouriteTag: String { 
    return VectorL10n.tr("Vector", "room_details_favourite_tag") 
  }
  /// Files
  internal static var roomDetailsFiles: String { 
    return VectorL10n.tr("Vector", "room_details_files") 
  }
  /// %@ is not a valid identifier for a community
  internal static func roomDetailsFlairInvalidIdPromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_details_flair_invalid_id_prompt_msg", p1)
  }
  /// Invalid format
  internal static var roomDetailsFlairInvalidIdPromptTitle: String { 
    return VectorL10n.tr("Vector", "room_details_flair_invalid_id_prompt_title") 
  }
  /// Show flair for communities
  internal static var roomDetailsFlairSection: String { 
    return VectorL10n.tr("Vector", "room_details_flair_section") 
  }
  /// Who can read history?
  internal static var roomDetailsHistorySection: String { 
    return VectorL10n.tr("Vector", "room_details_history_section") 
  }
  /// Anyone
  internal static var roomDetailsHistorySectionAnyone: String { 
    return VectorL10n.tr("Vector", "room_details_history_section_anyone") 
  }
  /// Members only (since the point in time of selecting this option)
  internal static var roomDetailsHistorySectionMembersOnly: String { 
    return VectorL10n.tr("Vector", "room_details_history_section_members_only") 
  }
  /// Members only (since they were invited)
  internal static var roomDetailsHistorySectionMembersOnlySinceInvited: String { 
    return VectorL10n.tr("Vector", "room_details_history_section_members_only_since_invited") 
  }
  /// Members only (since they joined)
  internal static var roomDetailsHistorySectionMembersOnlySinceJoined: String { 
    return VectorL10n.tr("Vector", "room_details_history_section_members_only_since_joined") 
  }
  /// Changes to who can read history will only apply to future messages in this room. The visibility of existing history will be unchanged.
  internal static var roomDetailsHistorySectionPromptMsg: String { 
    return VectorL10n.tr("Vector", "room_details_history_section_prompt_msg") 
  }
  /// Privacy warning
  internal static var roomDetailsHistorySectionPromptTitle: String { 
    return VectorL10n.tr("Vector", "room_details_history_section_prompt_title") 
  }
  /// Low priority
  internal static var roomDetailsLowPriorityTag: String { 
    return VectorL10n.tr("Vector", "room_details_low_priority_tag") 
  }
  /// Mute notifications
  internal static var roomDetailsMuteNotifs: String { 
    return VectorL10n.tr("Vector", "room_details_mute_notifs") 
  }
  /// Add new address
  internal static var roomDetailsNewAddress: String { 
    return VectorL10n.tr("Vector", "room_details_new_address") 
  }
  /// Add new address (e.g. #foo%@)
  internal static func roomDetailsNewAddressPlaceholder(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_details_new_address_placeholder", p1)
  }
  /// Add new community ID (e.g. +foo%@)
  internal static func roomDetailsNewFlairPlaceholder(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_details_new_flair_placeholder", p1)
  }
  /// This room has no local addresses
  internal static var roomDetailsNoLocalAddresses: String { 
    return VectorL10n.tr("Vector", "room_details_no_local_addresses") 
  }
  /// Members
  internal static var roomDetailsPeople: String { 
    return VectorL10n.tr("Vector", "room_details_people") 
  }
  /// Room Photo
  internal static var roomDetailsPhoto: String { 
    return VectorL10n.tr("Vector", "room_details_photo") 
  }
  /// Room Name
  internal static var roomDetailsRoomName: String { 
    return VectorL10n.tr("Vector", "room_details_room_name") 
  }
  /// Do you want to save changes?
  internal static var roomDetailsSaveChangesPrompt: String { 
    return VectorL10n.tr("Vector", "room_details_save_changes_prompt") 
  }
  /// Set as Main Address
  internal static var roomDetailsSetMainAddress: String { 
    return VectorL10n.tr("Vector", "room_details_set_main_address") 
  }
  /// Settings
  internal static var roomDetailsSettings: String { 
    return VectorL10n.tr("Vector", "room_details_settings") 
  }
  /// Room Details
  internal static var roomDetailsTitle: String { 
    return VectorL10n.tr("Vector", "room_details_title") 
  }
  /// Topic
  internal static var roomDetailsTopic: String { 
    return VectorL10n.tr("Vector", "room_details_topic") 
  }
  /// Unset as Main Address
  internal static var roomDetailsUnsetMainAddress: String { 
    return VectorL10n.tr("Vector", "room_details_unset_main_address") 
  }
  /// No public rooms available
  internal static var roomDirectoryNoPublicRoom: String { 
    return VectorL10n.tr("Vector", "room_directory_no_public_room") 
  }
  /// You do not have permission to post to this room
  internal static var roomDoNotHavePermissionToPost: String { 
    return VectorL10n.tr("Vector", "room_do_not_have_permission_to_post") 
  }
  /// %@ does not exist
  internal static func roomDoesNotExist(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_does_not_exist", p1)
  }
  /// Reason for banning this user
  internal static var roomEventActionBanPromptReason: String { 
    return VectorL10n.tr("Vector", "room_event_action_ban_prompt_reason") 
  }
  /// Cancel Download
  internal static var roomEventActionCancelDownload: String { 
    return VectorL10n.tr("Vector", "room_event_action_cancel_download") 
  }
  /// Cancel Send
  internal static var roomEventActionCancelSend: String { 
    return VectorL10n.tr("Vector", "room_event_action_cancel_send") 
  }
  /// Copy
  internal static var roomEventActionCopy: String { 
    return VectorL10n.tr("Vector", "room_event_action_copy") 
  }
  /// Delete
  internal static var roomEventActionDelete: String { 
    return VectorL10n.tr("Vector", "room_event_action_delete") 
  }
  /// Edit
  internal static var roomEventActionEdit: String { 
    return VectorL10n.tr("Vector", "room_event_action_edit") 
  }
  /// Reason for kicking this user
  internal static var roomEventActionKickPromptReason: String { 
    return VectorL10n.tr("Vector", "room_event_action_kick_prompt_reason") 
  }
  /// More
  internal static var roomEventActionMore: String { 
    return VectorL10n.tr("Vector", "room_event_action_more") 
  }
  /// Permalink
  internal static var roomEventActionPermalink: String { 
    return VectorL10n.tr("Vector", "room_event_action_permalink") 
  }
  /// Quote
  internal static var roomEventActionQuote: String { 
    return VectorL10n.tr("Vector", "room_event_action_quote") 
  }
  /// Show all
  internal static var roomEventActionReactionShowAll: String { 
    return VectorL10n.tr("Vector", "room_event_action_reaction_show_all") 
  }
  /// Show less
  internal static var roomEventActionReactionShowLess: String { 
    return VectorL10n.tr("Vector", "room_event_action_reaction_show_less") 
  }
  /// Remove
  internal static var roomEventActionRedact: String { 
    return VectorL10n.tr("Vector", "room_event_action_redact") 
  }
  /// Reply
  internal static var roomEventActionReply: String { 
    return VectorL10n.tr("Vector", "room_event_action_reply") 
  }
  /// Report content
  internal static var roomEventActionReport: String { 
    return VectorL10n.tr("Vector", "room_event_action_report") 
  }
  /// Do you want to hide all messages from this user?
  internal static var roomEventActionReportPromptIgnoreUser: String { 
    return VectorL10n.tr("Vector", "room_event_action_report_prompt_ignore_user") 
  }
  /// Reason for reporting this content
  internal static var roomEventActionReportPromptReason: String { 
    return VectorL10n.tr("Vector", "room_event_action_report_prompt_reason") 
  }
  /// Resend
  internal static var roomEventActionResend: String { 
    return VectorL10n.tr("Vector", "room_event_action_resend") 
  }
  /// Save
  internal static var roomEventActionSave: String { 
    return VectorL10n.tr("Vector", "room_event_action_save") 
  }
  /// Share
  internal static var roomEventActionShare: String { 
    return VectorL10n.tr("Vector", "room_event_action_share") 
  }
  /// View Decrypted Source
  internal static var roomEventActionViewDecryptedSource: String { 
    return VectorL10n.tr("Vector", "room_event_action_view_decrypted_source") 
  }
  /// Encryption Information
  internal static var roomEventActionViewEncryption: String { 
    return VectorL10n.tr("Vector", "room_event_action_view_encryption") 
  }
  /// View Source
  internal static var roomEventActionViewSource: String { 
    return VectorL10n.tr("Vector", "room_event_action_view_source") 
  }
  /// Failed to send
  internal static var roomEventFailedToSend: String { 
    return VectorL10n.tr("Vector", "room_event_failed_to_send") 
  }
  /// Jump to first unread message
  internal static var roomJumpToFirstUnread: String { 
    return VectorL10n.tr("Vector", "room_jump_to_first_unread") 
  }
  /// %@, %@ & others are typing…
  internal static func roomManyUsersAreTyping(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_many_users_are_typing", p1, p2)
  }
  /// Message edits
  internal static var roomMessageEditsHistoryTitle: String { 
    return VectorL10n.tr("Vector", "room_message_edits_history_title") 
  }
  /// Send a message (unencrypted)…
  internal static var roomMessagePlaceholder: String { 
    return VectorL10n.tr("Vector", "room_message_placeholder") 
  }
  /// Send a reply (unencrypted)…
  internal static var roomMessageReplyToPlaceholder: String { 
    return VectorL10n.tr("Vector", "room_message_reply_to_placeholder") 
  }
  /// Send a reply…
  internal static var roomMessageReplyToShortPlaceholder: String { 
    return VectorL10n.tr("Vector", "room_message_reply_to_short_placeholder") 
  }
  /// Send a message…
  internal static var roomMessageShortPlaceholder: String { 
    return VectorL10n.tr("Vector", "room_message_short_placeholder") 
  }
  /// Unable to open the link.
  internal static var roomMessageUnableOpenLinkErrorMessage: String { 
    return VectorL10n.tr("Vector", "room_message_unable_open_link_error_message") 
  }
  /// %d new message
  internal static func roomNewMessageNotification(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "room_new_message_notification", p1)
  }
  /// %d new messages
  internal static func roomNewMessagesNotification(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "room_new_messages_notification", p1)
  }
  /// Connectivity to the server has been lost.
  internal static var roomOfflineNotification: String { 
    return VectorL10n.tr("Vector", "room_offline_notification") 
  }
  /// %@ is typing…
  internal static func roomOneUserIsTyping(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_one_user_is_typing", p1)
  }
  /// Ongoing conference call. Join as %@ or %@.
  internal static func roomOngoingConferenceCall(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_ongoing_conference_call", p1, p2)
  }
  /// Close
  internal static var roomOngoingConferenceCallClose: String { 
    return VectorL10n.tr("Vector", "room_ongoing_conference_call_close") 
  }
  /// Ongoing conference call. Join as %@ or %@. %@ it.
  internal static func roomOngoingConferenceCallWithClose(_ p1: String, _ p2: String, _ p3: String) -> String {
    return VectorL10n.tr("Vector", "room_ongoing_conference_call_with_close", p1, p2, p3)
  }
  /// Ban from this room
  internal static var roomParticipantsActionBan: String { 
    return VectorL10n.tr("Vector", "room_participants_action_ban") 
  }
  /// Hide all messages from this user
  internal static var roomParticipantsActionIgnore: String { 
    return VectorL10n.tr("Vector", "room_participants_action_ignore") 
  }
  /// Invite
  internal static var roomParticipantsActionInvite: String { 
    return VectorL10n.tr("Vector", "room_participants_action_invite") 
  }
  /// Leave this room
  internal static var roomParticipantsActionLeave: String { 
    return VectorL10n.tr("Vector", "room_participants_action_leave") 
  }
  /// Mention
  internal static var roomParticipantsActionMention: String { 
    return VectorL10n.tr("Vector", "room_participants_action_mention") 
  }
  /// Remove from this room
  internal static var roomParticipantsActionRemove: String { 
    return VectorL10n.tr("Vector", "room_participants_action_remove") 
  }
  /// Admin tools
  internal static var roomParticipantsActionSectionAdminTools: String { 
    return VectorL10n.tr("Vector", "room_participants_action_section_admin_tools") 
  }
  /// Devices
  internal static var roomParticipantsActionSectionDevices: String { 
    return VectorL10n.tr("Vector", "room_participants_action_section_devices") 
  }
  /// Direct chats
  internal static var roomParticipantsActionSectionDirectChats: String { 
    return VectorL10n.tr("Vector", "room_participants_action_section_direct_chats") 
  }
  /// Other
  internal static var roomParticipantsActionSectionOther: String { 
    return VectorL10n.tr("Vector", "room_participants_action_section_other") 
  }
  /// Make admin
  internal static var roomParticipantsActionSetAdmin: String { 
    return VectorL10n.tr("Vector", "room_participants_action_set_admin") 
  }
  /// Reset to normal user
  internal static var roomParticipantsActionSetDefaultPowerLevel: String { 
    return VectorL10n.tr("Vector", "room_participants_action_set_default_power_level") 
  }
  /// Make moderator
  internal static var roomParticipantsActionSetModerator: String { 
    return VectorL10n.tr("Vector", "room_participants_action_set_moderator") 
  }
  /// Start new chat
  internal static var roomParticipantsActionStartNewChat: String { 
    return VectorL10n.tr("Vector", "room_participants_action_start_new_chat") 
  }
  /// Start video call
  internal static var roomParticipantsActionStartVideoCall: String { 
    return VectorL10n.tr("Vector", "room_participants_action_start_video_call") 
  }
  /// Start voice call
  internal static var roomParticipantsActionStartVoiceCall: String { 
    return VectorL10n.tr("Vector", "room_participants_action_start_voice_call") 
  }
  /// Unban
  internal static var roomParticipantsActionUnban: String { 
    return VectorL10n.tr("Vector", "room_participants_action_unban") 
  }
  /// Show all messages from this user
  internal static var roomParticipantsActionUnignore: String { 
    return VectorL10n.tr("Vector", "room_participants_action_unignore") 
  }
  /// Add participant
  internal static var roomParticipantsAddParticipant: String { 
    return VectorL10n.tr("Vector", "room_participants_add_participant") 
  }
  /// ago
  internal static var roomParticipantsAgo: String { 
    return VectorL10n.tr("Vector", "room_participants_ago") 
  }
  /// Filter room members
  internal static var roomParticipantsFilterRoomMembers: String { 
    return VectorL10n.tr("Vector", "room_participants_filter_room_members") 
  }
  /// Idle
  internal static var roomParticipantsIdle: String { 
    return VectorL10n.tr("Vector", "room_participants_idle") 
  }
  /// Search / invite by User ID, Name or email
  internal static var roomParticipantsInviteAnotherUser: String { 
    return VectorL10n.tr("Vector", "room_participants_invite_another_user") 
  }
  /// Malformed ID. Should be an email address or a Matrix ID like '@localpart:domain'
  internal static var roomParticipantsInviteMalformedId: String { 
    return VectorL10n.tr("Vector", "room_participants_invite_malformed_id") 
  }
  /// Invite Error
  internal static var roomParticipantsInviteMalformedIdTitle: String { 
    return VectorL10n.tr("Vector", "room_participants_invite_malformed_id_title") 
  }
  /// Are you sure you want to invite %@ to this chat?
  internal static func roomParticipantsInvitePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_participants_invite_prompt_msg", p1)
  }
  /// Confirmation
  internal static var roomParticipantsInvitePromptTitle: String { 
    return VectorL10n.tr("Vector", "room_participants_invite_prompt_title") 
  }
  /// INVITED
  internal static var roomParticipantsInvitedSection: String { 
    return VectorL10n.tr("Vector", "room_participants_invited_section") 
  }
  /// Are you sure you want to leave the room?
  internal static var roomParticipantsLeavePromptMsg: String { 
    return VectorL10n.tr("Vector", "room_participants_leave_prompt_msg") 
  }
  /// Leave room
  internal static var roomParticipantsLeavePromptTitle: String { 
    return VectorL10n.tr("Vector", "room_participants_leave_prompt_title") 
  }
  /// %d participants
  internal static func roomParticipantsMultiParticipants(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "room_participants_multi_participants", p1)
  }
  /// now
  internal static var roomParticipantsNow: String { 
    return VectorL10n.tr("Vector", "room_participants_now") 
  }
  /// Offline
  internal static var roomParticipantsOffline: String { 
    return VectorL10n.tr("Vector", "room_participants_offline") 
  }
  /// 1 participant
  internal static var roomParticipantsOneParticipant: String { 
    return VectorL10n.tr("Vector", "room_participants_one_participant") 
  }
  /// Online
  internal static var roomParticipantsOnline: String { 
    return VectorL10n.tr("Vector", "room_participants_online") 
  }
  /// Are you sure you want to remove %@ from this chat?
  internal static func roomParticipantsRemovePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_participants_remove_prompt_msg", p1)
  }
  /// Confirmation
  internal static var roomParticipantsRemovePromptTitle: String { 
    return VectorL10n.tr("Vector", "room_participants_remove_prompt_title") 
  }
  /// Remove third-party invite is not supported yet until the api exists
  internal static var roomParticipantsRemoveThirdPartyInviteMsg: String { 
    return VectorL10n.tr("Vector", "room_participants_remove_third_party_invite_msg") 
  }
  /// Participants
  internal static var roomParticipantsTitle: String { 
    return VectorL10n.tr("Vector", "room_participants_title") 
  }
  /// Unknown
  internal static var roomParticipantsUnknown: String { 
    return VectorL10n.tr("Vector", "room_participants_unknown") 
  }
  /// This room is a continuation of another conversation.
  internal static var roomPredecessorInformation: String { 
    return VectorL10n.tr("Vector", "room_predecessor_information") 
  }
  /// Tap here to see older messages.
  internal static var roomPredecessorLink: String { 
    return VectorL10n.tr("Vector", "room_predecessor_link") 
  }
  /// You have been invited to join this room by %@
  internal static func roomPreviewInvitationFormat(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_preview_invitation_format", p1)
  }
  /// This is a preview of this room. Room interactions have been disabled.
  internal static var roomPreviewSubtitle: String { 
    return VectorL10n.tr("Vector", "room_preview_subtitle") 
  }
  /// You are trying to access %@. Would you like to join in order to participate in the discussion?
  internal static func roomPreviewTryJoinAnUnknownRoom(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_preview_try_join_an_unknown_room", p1)
  }
  /// a room
  internal static var roomPreviewTryJoinAnUnknownRoomDefault: String { 
    return VectorL10n.tr("Vector", "room_preview_try_join_an_unknown_room_default") 
  }
  /// This invitation was sent to %@, which is not associated with this account. You may wish to login with a different account, or add this email to your account.
  internal static func roomPreviewUnlinkedEmailWarning(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_preview_unlinked_email_warning", p1)
  }
  /// cancel all
  internal static var roomPromptCancel: String { 
    return VectorL10n.tr("Vector", "room_prompt_cancel") 
  }
  /// Resend all
  internal static var roomPromptResend: String { 
    return VectorL10n.tr("Vector", "room_prompt_resend") 
  }
  /// ROOMS
  internal static var roomRecentsConversationsSection: String { 
    return VectorL10n.tr("Vector", "room_recents_conversations_section") 
  }
  /// Create room
  internal static var roomRecentsCreateEmptyRoom: String { 
    return VectorL10n.tr("Vector", "room_recents_create_empty_room") 
  }
  /// ROOM DIRECTORY
  internal static var roomRecentsDirectorySection: String { 
    return VectorL10n.tr("Vector", "room_recents_directory_section") 
  }
  /// Network
  internal static var roomRecentsDirectorySectionNetwork: String { 
    return VectorL10n.tr("Vector", "room_recents_directory_section_network") 
  }
  /// FAVOURITES
  internal static var roomRecentsFavouritesSection: String { 
    return VectorL10n.tr("Vector", "room_recents_favourites_section") 
  }
  /// INVITES
  internal static var roomRecentsInvitesSection: String { 
    return VectorL10n.tr("Vector", "room_recents_invites_section") 
  }
  /// Join room
  internal static var roomRecentsJoinRoom: String { 
    return VectorL10n.tr("Vector", "room_recents_join_room") 
  }
  /// Type a room id or a room alias
  internal static var roomRecentsJoinRoomPrompt: String { 
    return VectorL10n.tr("Vector", "room_recents_join_room_prompt") 
  }
  /// Join a room
  internal static var roomRecentsJoinRoomTitle: String { 
    return VectorL10n.tr("Vector", "room_recents_join_room_title") 
  }
  /// LOW PRIORITY
  internal static var roomRecentsLowPrioritySection: String { 
    return VectorL10n.tr("Vector", "room_recents_low_priority_section") 
  }
  /// No rooms
  internal static var roomRecentsNoConversation: String { 
    return VectorL10n.tr("Vector", "room_recents_no_conversation") 
  }
  /// PEOPLE
  internal static var roomRecentsPeopleSection: String { 
    return VectorL10n.tr("Vector", "room_recents_people_section") 
  }
  /// SYSTEM ALERTS
  internal static var roomRecentsServerNoticeSection: String { 
    return VectorL10n.tr("Vector", "room_recents_server_notice_section") 
  }
  /// Start chat
  internal static var roomRecentsStartChatWith: String { 
    return VectorL10n.tr("Vector", "room_recents_start_chat_with") 
  }
  /// This room has been replaced and is no longer active.
  internal static var roomReplacementInformation: String { 
    return VectorL10n.tr("Vector", "room_replacement_information") 
  }
  /// The conversation continues here.
  internal static var roomReplacementLink: String { 
    return VectorL10n.tr("Vector", "room_replacement_link") 
  }
  /// Resend unsent messages
  internal static var roomResendUnsentMessages: String { 
    return VectorL10n.tr("Vector", "room_resend_unsent_messages") 
  }
  ///  Please 
  internal static var roomResourceLimitExceededMessageContact1: String { 
    return VectorL10n.tr("Vector", "room_resource_limit_exceeded_message_contact_1") 
  }
  /// contact your service administrator
  internal static var roomResourceLimitExceededMessageContact2Link: String { 
    return VectorL10n.tr("Vector", "room_resource_limit_exceeded_message_contact_2_link") 
  }
  ///  to continue using this service.
  internal static var roomResourceLimitExceededMessageContact3: String { 
    return VectorL10n.tr("Vector", "room_resource_limit_exceeded_message_contact_3") 
  }
  /// This homeserver has exceeded one of its resource limits so 
  internal static var roomResourceUsageLimitReachedMessage1Default: String { 
    return VectorL10n.tr("Vector", "room_resource_usage_limit_reached_message_1_default") 
  }
  /// This homeserver has hit its Monthly Active User limit so 
  internal static var roomResourceUsageLimitReachedMessage1MonthlyActiveUser: String { 
    return VectorL10n.tr("Vector", "room_resource_usage_limit_reached_message_1_monthly_active_user") 
  }
  /// some users will not be able to log in.
  internal static var roomResourceUsageLimitReachedMessage2: String { 
    return VectorL10n.tr("Vector", "room_resource_usage_limit_reached_message_2") 
  }
  ///  to get this limit increased.
  internal static var roomResourceUsageLimitReachedMessageContact3: String { 
    return VectorL10n.tr("Vector", "room_resource_usage_limit_reached_message_contact_3") 
  }
  /// Invite members
  internal static var roomTitleInviteMembers: String { 
    return VectorL10n.tr("Vector", "room_title_invite_members") 
  }
  /// %@ members
  internal static func roomTitleMembers(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_title_members", p1)
  }
  /// %@/%@ active members
  internal static func roomTitleMultipleActiveMembers(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_title_multiple_active_members", p1, p2)
  }
  /// New room
  internal static var roomTitleNewRoom: String { 
    return VectorL10n.tr("Vector", "room_title_new_room") 
  }
  /// %@/%@ active member
  internal static func roomTitleOneActiveMember(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_title_one_active_member", p1, p2)
  }
  /// 1 member
  internal static var roomTitleOneMember: String { 
    return VectorL10n.tr("Vector", "room_title_one_member") 
  }
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
  internal static var roomWarningAboutEncryption: String { 
    return VectorL10n.tr("Vector", "room_warning_about_encryption") 
  }
  /// Save
  internal static var save: String { 
    return VectorL10n.tr("Vector", "save") 
  }
  /// Search
  internal static var searchDefaultPlaceholder: String { 
    return VectorL10n.tr("Vector", "search_default_placeholder") 
  }
  /// Files
  internal static var searchFiles: String { 
    return VectorL10n.tr("Vector", "search_files") 
  }
  /// Searching…
  internal static var searchInProgress: String { 
    return VectorL10n.tr("Vector", "search_in_progress") 
  }
  /// Messages
  internal static var searchMessages: String { 
    return VectorL10n.tr("Vector", "search_messages") 
  }
  /// No results
  internal static var searchNoResult: String { 
    return VectorL10n.tr("Vector", "search_no_result") 
  }
  /// People
  internal static var searchPeople: String { 
    return VectorL10n.tr("Vector", "search_people") 
  }
  /// Search by User ID, Name or email
  internal static var searchPeoplePlaceholder: String { 
    return VectorL10n.tr("Vector", "search_people_placeholder") 
  }
  /// Rooms
  internal static var searchRooms: String { 
    return VectorL10n.tr("Vector", "search_rooms") 
  }
  /// Send to %@
  internal static func sendTo(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "send_to", p1)
  }
  /// Sending
  internal static var sending: String { 
    return VectorL10n.tr("Vector", "sending") 
  }
  /// Add email address
  internal static var settingsAddEmailAddress: String { 
    return VectorL10n.tr("Vector", "settings_add_email_address") 
  }
  /// Add phone number
  internal static var settingsAddPhoneNumber: String { 
    return VectorL10n.tr("Vector", "settings_add_phone_number") 
  }
  /// ADVANCED
  internal static var settingsAdvanced: String { 
    return VectorL10n.tr("Vector", "settings_advanced") 
  }
  /// Receive incoming calls on your lock screen. See your Riot calls in the system's call history. If iCloud is enabled, this call history will be shared with Apple.
  internal static var settingsCallkitInfo: String { 
    return VectorL10n.tr("Vector", "settings_callkit_info") 
  }
  /// CALLS
  internal static var settingsCallsSettings: String { 
    return VectorL10n.tr("Vector", "settings_calls_settings") 
  }
  /// Change password
  internal static var settingsChangePassword: String { 
    return VectorL10n.tr("Vector", "settings_change_password") 
  }
  /// Clear cache
  internal static var settingsClearCache: String { 
    return VectorL10n.tr("Vector", "settings_clear_cache") 
  }
  /// Homeserver is %@
  internal static func settingsConfigHomeServer(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_config_home_server", p1)
  }
  /// Identity server is %@
  internal static func settingsConfigIdentityServer(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_config_identity_server", p1)
  }
  /// No build info
  internal static var settingsConfigNoBuildInfo: String { 
    return VectorL10n.tr("Vector", "settings_config_no_build_info") 
  }
  /// Logged in as %@
  internal static func settingsConfigUserId(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_config_user_id", p1)
  }
  /// confirm password
  internal static var settingsConfirmPassword: String { 
    return VectorL10n.tr("Vector", "settings_confirm_password") 
  }
  /// LOCAL CONTACTS
  internal static var settingsContacts: String { 
    return VectorL10n.tr("Vector", "settings_contacts") 
  }
  /// Use emails and phone numbers to discover users
  internal static var settingsContactsDiscoverMatrixUsers: String { 
    return VectorL10n.tr("Vector", "settings_contacts_discover_matrix_users") 
  }
  /// Phonebook country
  internal static var settingsContactsPhonebookCountry: String { 
    return VectorL10n.tr("Vector", "settings_contacts_phonebook_country") 
  }
  /// Copyright
  internal static var settingsCopyright: String { 
    return VectorL10n.tr("Vector", "settings_copyright") 
  }
  /// https://riot.im/copyright
  internal static var settingsCopyrightUrl: String { 
    return VectorL10n.tr("Vector", "settings_copyright_url") 
  }
  /// Encrypt to verified devices only
  internal static var settingsCryptoBlacklistUnverifiedDevices: String { 
    return VectorL10n.tr("Vector", "settings_crypto_blacklist_unverified_devices") 
  }
  /// \nDevice ID: 
  internal static var settingsCryptoDeviceId: String { 
    return VectorL10n.tr("Vector", "settings_crypto_device_id") 
  }
  /// \nDevice key: 
  internal static var settingsCryptoDeviceKey: String { 
    return VectorL10n.tr("Vector", "settings_crypto_device_key") 
  }
  /// Device name: 
  internal static var settingsCryptoDeviceName: String { 
    return VectorL10n.tr("Vector", "settings_crypto_device_name") 
  }
  /// Export keys
  internal static var settingsCryptoExport: String { 
    return VectorL10n.tr("Vector", "settings_crypto_export") 
  }
  /// CRYPTOGRAPHY
  internal static var settingsCryptography: String { 
    return VectorL10n.tr("Vector", "settings_cryptography") 
  }
  /// DEACTIVATE ACCOUNT
  internal static var settingsDeactivateAccount: String { 
    return VectorL10n.tr("Vector", "settings_deactivate_account") 
  }
  /// Deactivate my account
  internal static var settingsDeactivateMyAccount: String { 
    return VectorL10n.tr("Vector", "settings_deactivate_my_account") 
  }
  /// DEVICES
  internal static var settingsDevices: String { 
    return VectorL10n.tr("Vector", "settings_devices") 
  }
  /// Display Name
  internal static var settingsDisplayName: String { 
    return VectorL10n.tr("Vector", "settings_display_name") 
  }
  /// Email
  internal static var settingsEmailAddress: String { 
    return VectorL10n.tr("Vector", "settings_email_address") 
  }
  /// Enter your email address
  internal static var settingsEmailAddressPlaceholder: String { 
    return VectorL10n.tr("Vector", "settings_email_address_placeholder") 
  }
  /// Integrated calling
  internal static var settingsEnableCallkit: String { 
    return VectorL10n.tr("Vector", "settings_enable_callkit") 
  }
  /// Notifications on this device
  internal static var settingsEnablePushNotif: String { 
    return VectorL10n.tr("Vector", "settings_enable_push_notif") 
  }
  /// Rage shake to report bug
  internal static var settingsEnableRageshake: String { 
    return VectorL10n.tr("Vector", "settings_enable_rageshake") 
  }
  /// Fail to update password
  internal static var settingsFailToUpdatePassword: String { 
    return VectorL10n.tr("Vector", "settings_fail_to_update_password") 
  }
  /// Fail to update profile
  internal static var settingsFailToUpdateProfile: String { 
    return VectorL10n.tr("Vector", "settings_fail_to_update_profile") 
  }
  /// First Name
  internal static var settingsFirstName: String { 
    return VectorL10n.tr("Vector", "settings_first_name") 
  }
  /// Show flair where allowed
  internal static var settingsFlair: String { 
    return VectorL10n.tr("Vector", "settings_flair") 
  }
  /// Global notification settings are available on your %@ web client
  internal static func settingsGlobalSettingsInfo(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_global_settings_info", p1)
  }
  /// IGNORED USERS
  internal static var settingsIgnoredUsers: String { 
    return VectorL10n.tr("Vector", "settings_ignored_users") 
  }
  /// KEY BACKUP
  internal static var settingsKeyBackup: String { 
    return VectorL10n.tr("Vector", "settings_key_backup") 
  }
  /// Connect this device to Key Backup
  internal static var settingsKeyBackupButtonConnect: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_button_connect") 
  }
  /// Start using Key Backup
  internal static var settingsKeyBackupButtonCreate: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_button_create") 
  }
  /// Delete Backup
  internal static var settingsKeyBackupButtonDelete: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_button_delete") 
  }
  /// Restore from Backup
  internal static var settingsKeyBackupButtonRestore: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_button_restore") 
  }
  /// Are you sure? You will lose your encrypted messages if your keys are not backed up properly.
  internal static var settingsKeyBackupDeleteConfirmationPromptMsg: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_delete_confirmation_prompt_msg") 
  }
  /// Delete Backup
  internal static var settingsKeyBackupDeleteConfirmationPromptTitle: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_delete_confirmation_prompt_title") 
  }
  /// Encrypted messages are secured with end-to-end encryption. Only you and the recipient(s) have the keys to read these messages.
  internal static var settingsKeyBackupInfo: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info") 
  }
  /// Algorithm: %@
  internal static func settingsKeyBackupInfoAlgorithm(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_algorithm", p1)
  }
  /// Checking...
  internal static var settingsKeyBackupInfoChecking: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_checking") 
  }
  /// Your keys are not being backed up from this device.
  internal static var settingsKeyBackupInfoNone: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_none") 
  }
  /// This device is not backing up your keys, but you do have an existing backup you can restore from and add to going forward.
  internal static var settingsKeyBackupInfoNotValid: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_not_valid") 
  }
  /// Backing up %@ keys...
  internal static func settingsKeyBackupInfoProgress(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_progress", p1)
  }
  /// All keys backed up
  internal static var settingsKeyBackupInfoProgressDone: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_progress_done") 
  }
  /// Connect this device to key backup before signing out to avoid losing any keys that may only be on this device.
  internal static var settingsKeyBackupInfoSignoutWarning: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_signout_warning") 
  }
  /// Backup has an invalid signature from %@
  internal static func settingsKeyBackupInfoTrustSignatureInvalidDeviceUnverified(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_trust_signature_invalid_device_unverified", p1)
  }
  /// Backup has an invalid signature from %@
  internal static func settingsKeyBackupInfoTrustSignatureInvalidDeviceVerified(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_trust_signature_invalid_device_verified", p1)
  }
  /// Backup has a signature from device with ID: %@
  internal static func settingsKeyBackupInfoTrustSignatureUnknown(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_trust_signature_unknown", p1)
  }
  /// Backup has a valid signature from this device
  internal static var settingsKeyBackupInfoTrustSignatureValid: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_trust_signature_valid") 
  }
  /// Backup has a signature from %@
  internal static func settingsKeyBackupInfoTrustSignatureValidDeviceUnverified(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_trust_signature_valid_device_unverified", p1)
  }
  /// Backup has a valid signature from %@
  internal static func settingsKeyBackupInfoTrustSignatureValidDeviceVerified(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_trust_signature_valid_device_verified", p1)
  }
  /// This device is backing up your keys.
  internal static var settingsKeyBackupInfoValid: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_valid") 
  }
  /// Key Backup Version: %@
  internal static func settingsKeyBackupInfoVersion(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_version", p1)
  }
  /// LABS
  internal static var settingsLabs: String { 
    return VectorL10n.tr("Vector", "settings_labs") 
  }
  /// Create conference calls with jitsi
  internal static var settingsLabsCreateConferenceWithJitsi: String { 
    return VectorL10n.tr("Vector", "settings_labs_create_conference_with_jitsi") 
  }
  /// End-to-End Encryption
  internal static var settingsLabsE2eEncryption: String { 
    return VectorL10n.tr("Vector", "settings_labs_e2e_encryption") 
  }
  /// To finish setting up encryption you must log in again.
  internal static var settingsLabsE2eEncryptionPromptMessage: String { 
    return VectorL10n.tr("Vector", "settings_labs_e2e_encryption_prompt_message") 
  }
  /// React to messages with emoji
  internal static var settingsLabsMessageReaction: String { 
    return VectorL10n.tr("Vector", "settings_labs_message_reaction") 
  }
  /// Lazy load rooms members
  internal static var settingsLabsRoomMembersLazyLoading: String { 
    return VectorL10n.tr("Vector", "settings_labs_room_members_lazy_loading") 
  }
  /// Your homeserver does not support lazy loading of room members yet. Try later.
  internal static var settingsLabsRoomMembersLazyLoadingErrorMessage: String { 
    return VectorL10n.tr("Vector", "settings_labs_room_members_lazy_loading_error_message") 
  }
  /// Mark all messages as read
  internal static var settingsMarkAllAsRead: String { 
    return VectorL10n.tr("Vector", "settings_mark_all_as_read") 
  }
  /// new password
  internal static var settingsNewPassword: String { 
    return VectorL10n.tr("Vector", "settings_new_password") 
  }
  /// Night Mode
  internal static var settingsNightMode: String { 
    return VectorL10n.tr("Vector", "settings_night_mode") 
  }
  /// NOTIFICATION SETTINGS
  internal static var settingsNotificationsSettings: String { 
    return VectorL10n.tr("Vector", "settings_notifications_settings") 
  }
  /// old password
  internal static var settingsOldPassword: String { 
    return VectorL10n.tr("Vector", "settings_old_password") 
  }
  /// Olm Version %@
  internal static func settingsOlmVersion(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_olm_version", p1)
  }
  /// Notifications are denied for %@, please allow them in your device settings
  internal static func settingsOnDeniedNotification(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_on_denied_notification", p1)
  }
  /// OTHER
  internal static var settingsOther: String { 
    return VectorL10n.tr("Vector", "settings_other") 
  }
  /// Your password has been updated
  internal static var settingsPasswordUpdated: String { 
    return VectorL10n.tr("Vector", "settings_password_updated") 
  }
  /// Phone
  internal static var settingsPhoneNumber: String { 
    return VectorL10n.tr("Vector", "settings_phone_number") 
  }
  /// Pin rooms with missed notifications
  internal static var settingsPinRoomsWithMissedNotif: String { 
    return VectorL10n.tr("Vector", "settings_pin_rooms_with_missed_notif") 
  }
  /// Pin rooms with unread messages
  internal static var settingsPinRoomsWithUnread: String { 
    return VectorL10n.tr("Vector", "settings_pin_rooms_with_unread") 
  }
  /// Privacy Policy
  internal static var settingsPrivacyPolicy: String { 
    return VectorL10n.tr("Vector", "settings_privacy_policy") 
  }
  /// https://riot.im/privacy
  internal static var settingsPrivacyPolicyUrl: String { 
    return VectorL10n.tr("Vector", "settings_privacy_policy_url") 
  }
  /// Profile Picture
  internal static var settingsProfilePicture: String { 
    return VectorL10n.tr("Vector", "settings_profile_picture") 
  }
  /// Are you sure you want to remove the email address %@?
  internal static func settingsRemoveEmailPromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_remove_email_prompt_msg", p1)
  }
  /// Are you sure you want to remove the phone number %@?
  internal static func settingsRemovePhonePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_remove_phone_prompt_msg", p1)
  }
  /// Confirmation
  internal static var settingsRemovePromptTitle: String { 
    return VectorL10n.tr("Vector", "settings_remove_prompt_title") 
  }
  /// Report bug
  internal static var settingsReportBug: String { 
    return VectorL10n.tr("Vector", "settings_report_bug") 
  }
  /// Send anon crash & usage data
  internal static var settingsSendCrashReport: String { 
    return VectorL10n.tr("Vector", "settings_send_crash_report") 
  }
  /// Show decrypted content
  internal static var settingsShowDecryptedContent: String { 
    return VectorL10n.tr("Vector", "settings_show_decrypted_content") 
  }
  /// Sign Out
  internal static var settingsSignOut: String { 
    return VectorL10n.tr("Vector", "settings_sign_out") 
  }
  /// Are you sure?
  internal static var settingsSignOutConfirmation: String { 
    return VectorL10n.tr("Vector", "settings_sign_out_confirmation") 
  }
  /// You will lose your end-to-end encryption keys. That means you will no longer be able to read old messages in encrypted rooms on this device.
  internal static var settingsSignOutE2eWarn: String { 
    return VectorL10n.tr("Vector", "settings_sign_out_e2e_warn") 
  }
  /// Surname
  internal static var settingsSurname: String { 
    return VectorL10n.tr("Vector", "settings_surname") 
  }
  /// Terms & Conditions
  internal static var settingsTermConditions: String { 
    return VectorL10n.tr("Vector", "settings_term_conditions") 
  }
  /// https://riot.im/tac_apple
  internal static var settingsTermConditionsUrl: String { 
    return VectorL10n.tr("Vector", "settings_term_conditions_url") 
  }
  /// Third-party Notices
  internal static var settingsThirdPartyNotices: String { 
    return VectorL10n.tr("Vector", "settings_third_party_notices") 
  }
  /// Settings
  internal static var settingsTitle: String { 
    return VectorL10n.tr("Vector", "settings_title") 
  }
  /// Language
  internal static var settingsUiLanguage: String { 
    return VectorL10n.tr("Vector", "settings_ui_language") 
  }
  /// Theme
  internal static var settingsUiTheme: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme") 
  }
  /// Auto
  internal static var settingsUiThemeAuto: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_auto") 
  }
  /// Black
  internal static var settingsUiThemeBlack: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_black") 
  }
  /// Dark
  internal static var settingsUiThemeDark: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_dark") 
  }
  /// Light
  internal static var settingsUiThemeLight: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_light") 
  }
  /// "Auto" uses your device "Invert Colours" settings
  internal static var settingsUiThemePickerMessage: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_picker_message") 
  }
  /// Select a theme
  internal static var settingsUiThemePickerTitle: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_picker_title") 
  }
  /// Show all messages from %@?
  internal static func settingsUnignoreUser(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_unignore_user", p1)
  }
  /// USER INTERFACE
  internal static var settingsUserInterface: String { 
    return VectorL10n.tr("Vector", "settings_user_interface") 
  }
  /// USER SETTINGS
  internal static var settingsUserSettings: String { 
    return VectorL10n.tr("Vector", "settings_user_settings") 
  }
  /// Version %@
  internal static func settingsVersion(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_version", p1)
  }
  /// Login in the main app to share content
  internal static var shareExtensionAuthPrompt: String { 
    return VectorL10n.tr("Vector", "share_extension_auth_prompt") 
  }
  /// Failed to send. Check in the main app the encryption settings for this room
  internal static var shareExtensionFailedToEncrypt: String { 
    return VectorL10n.tr("Vector", "share_extension_failed_to_encrypt") 
  }
  /// Sign out
  internal static var signOutExistingKeyBackupAlertSignOutAction: String { 
    return VectorL10n.tr("Vector", "sign_out_existing_key_backup_alert_sign_out_action") 
  }
  /// Are you sure you want to sign out?
  internal static var signOutExistingKeyBackupAlertTitle: String { 
    return VectorL10n.tr("Vector", "sign_out_existing_key_backup_alert_title") 
  }
  /// I'll wait
  internal static var signOutKeyBackupInProgressAlertCancelAction: String { 
    return VectorL10n.tr("Vector", "sign_out_key_backup_in_progress_alert_cancel_action") 
  }
  /// I don't want my encrypted messages
  internal static var signOutKeyBackupInProgressAlertDiscardKeyBackupAction: String { 
    return VectorL10n.tr("Vector", "sign_out_key_backup_in_progress_alert_discard_key_backup_action") 
  }
  /// Key backup in progress. If you sign out now you’ll lose access to your encrypted messages.
  internal static var signOutKeyBackupInProgressAlertTitle: String { 
    return VectorL10n.tr("Vector", "sign_out_key_backup_in_progress_alert_title") 
  }
  /// I don't want my encrypted messages
  internal static var signOutNonExistingKeyBackupAlertDiscardKeyBackupAction: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_alert_discard_key_backup_action") 
  }
  /// Start using Key Backup
  internal static var signOutNonExistingKeyBackupAlertSetupKeyBackupAction: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_alert_setup_key_backup_action") 
  }
  /// You’ll lose access to your encrypted messages if you sign out now
  internal static var signOutNonExistingKeyBackupAlertTitle: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_alert_title") 
  }
  /// Backup
  internal static var signOutNonExistingKeyBackupSignOutConfirmationAlertBackupAction: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_sign_out_confirmation_alert_backup_action") 
  }
  /// You'll lose access to your encrypted messages unless you back up your keys before signing out.
  internal static var signOutNonExistingKeyBackupSignOutConfirmationAlertMessage: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_sign_out_confirmation_alert_message") 
  }
  /// Sign out
  internal static var signOutNonExistingKeyBackupSignOutConfirmationAlertSignOutAction: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_sign_out_confirmation_alert_sign_out_action") 
  }
  /// You'll lose your encrypted messages
  internal static var signOutNonExistingKeyBackupSignOutConfirmationAlertTitle: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_sign_out_confirmation_alert_title") 
  }
  /// Start
  internal static var start: String { 
    return VectorL10n.tr("Vector", "start") 
  }
  /// Communicate, your way.\n\nA chat app, under your control and entirely flexible. Riot lets you communicate the way you want. Made for [matrix] - the standard for open, decentralised communication.\n\nGet a free matrix.org account, get your own server at https://modular.im, or use another Matrix server.\n\nWhy choose Riot.im?\n\nCOMPLETE COMMUNICATION: Build rooms around your teams, your friends, your community - however you like! Chat, share files, add widgets and make voice and video calls - all free of charge.\n\nPOWERFUL INTEGRATIONS: Use Riot.im with the tools you know and love. With Riot.im you can even chat with users and groups on other chat apps.\n\nPRIVATE AND SECURE: Keep your conversations secret. State of the art end-to-end encryption ensures that private communication stays private.\n\nOPEN, NOT CLOSED: Open source, and built on Matrix. Own your own data by hosting your own server, or selecting one you trust.\n\nEVERYWHERE YOU ARE: Stay in touch wherever you are with fully synchronised message history across all your devices and online at https://riot.im.
  internal static var storeFullDescription: String { 
    return VectorL10n.tr("Vector", "store_full_description") 
  }
  /// Secure decentralised chat/VoIP
  internal static var storeShortDescription: String { 
    return VectorL10n.tr("Vector", "store_short_description") 
  }
  /// Favourites
  internal static var titleFavourites: String { 
    return VectorL10n.tr("Vector", "title_favourites") 
  }
  /// Communities
  internal static var titleGroups: String { 
    return VectorL10n.tr("Vector", "title_groups") 
  }
  /// Home
  internal static var titleHome: String { 
    return VectorL10n.tr("Vector", "title_home") 
  }
  /// People
  internal static var titlePeople: String { 
    return VectorL10n.tr("Vector", "title_people") 
  }
  /// Rooms
  internal static var titleRooms: String { 
    return VectorL10n.tr("Vector", "title_rooms") 
  }
  /// Today
  internal static var today: String { 
    return VectorL10n.tr("Vector", "today") 
  }
  /// This room contains unknown devices which have not been verified.\nThis means there is no guarantee that the devices belong to the users they claim to.\nWe recommend you go through the verification process for each device before continuing, but you can resend the message without verifying if you prefer.
  internal static var unknownDevicesAlert: String { 
    return VectorL10n.tr("Vector", "unknown_devices_alert") 
  }
  /// Room contains unknown devices
  internal static var unknownDevicesAlertTitle: String { 
    return VectorL10n.tr("Vector", "unknown_devices_alert_title") 
  }
  /// Answer Anyway
  internal static var unknownDevicesAnswerAnyway: String { 
    return VectorL10n.tr("Vector", "unknown_devices_answer_anyway") 
  }
  /// Call Anyway
  internal static var unknownDevicesCallAnyway: String { 
    return VectorL10n.tr("Vector", "unknown_devices_call_anyway") 
  }
  /// Send Anyway
  internal static var unknownDevicesSendAnyway: String { 
    return VectorL10n.tr("Vector", "unknown_devices_send_anyway") 
  }
  /// Unknown devices
  internal static var unknownDevicesTitle: String { 
    return VectorL10n.tr("Vector", "unknown_devices_title") 
  }
  /// Verify…
  internal static var unknownDevicesVerify: String { 
    return VectorL10n.tr("Vector", "unknown_devices_verify") 
  }
  /// Video
  internal static var video: String { 
    return VectorL10n.tr("Vector", "video") 
  }
  /// View
  internal static var view: String { 
    return VectorL10n.tr("Vector", "view") 
  }
  /// Voice
  internal static var voice: String { 
    return VectorL10n.tr("Vector", "voice") 
  }
  /// Warning
  internal static var warning: String { 
    return VectorL10n.tr("Vector", "warning") 
  }
  /// Widget creation has failed
  internal static var widgetCreationFailure: String { 
    return VectorL10n.tr("Vector", "widget_creation_failure") 
  }
  /// Failed to send request.
  internal static var widgetIntegrationFailedToSendRequest: String { 
    return VectorL10n.tr("Vector", "widget_integration_failed_to_send_request") 
  }
  /// Missing room_id in request.
  internal static var widgetIntegrationMissingRoomId: String { 
    return VectorL10n.tr("Vector", "widget_integration_missing_room_id") 
  }
  /// Missing user_id in request.
  internal static var widgetIntegrationMissingUserId: String { 
    return VectorL10n.tr("Vector", "widget_integration_missing_user_id") 
  }
  /// You are not in this room.
  internal static var widgetIntegrationMustBeInRoom: String { 
    return VectorL10n.tr("Vector", "widget_integration_must_be_in_room") 
  }
  /// You need to be able to invite users to do that.
  internal static var widgetIntegrationNeedToBeAbleToInvite: String { 
    return VectorL10n.tr("Vector", "widget_integration_need_to_be_able_to_invite") 
  }
  /// You do not have permission to do that in this room.
  internal static var widgetIntegrationNoPermissionInRoom: String { 
    return VectorL10n.tr("Vector", "widget_integration_no_permission_in_room") 
  }
  /// Power level must be positive integer.
  internal static var widgetIntegrationPositivePowerLevel: String { 
    return VectorL10n.tr("Vector", "widget_integration_positive_power_level") 
  }
  /// This room is not recognised.
  internal static var widgetIntegrationRoomNotRecognised: String { 
    return VectorL10n.tr("Vector", "widget_integration_room_not_recognised") 
  }
  /// Room %@ is not visible.
  internal static func widgetIntegrationRoomNotVisible(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "widget_integration_room_not_visible", p1)
  }
  /// Unable to create widget.
  internal static var widgetIntegrationUnableToCreate: String { 
    return VectorL10n.tr("Vector", "widget_integration_unable_to_create") 
  }
  /// Failed to connect to integrations server
  internal static var widgetIntegrationsServerFailedToConnect: String { 
    return VectorL10n.tr("Vector", "widget_integrations_server_failed_to_connect") 
  }
  /// No integrations server configured
  internal static var widgetNoIntegrationsServerConfigured: String { 
    return VectorL10n.tr("Vector", "widget_no_integrations_server_configured") 
  }
  /// You need permission to manage widgets in this room
  internal static var widgetNoPowerToManage: String { 
    return VectorL10n.tr("Vector", "widget_no_power_to_manage") 
  }
  /// You don't currently have any stickerpacks enabled.
  internal static var widgetStickerPickerNoStickerpacksAlert: String { 
    return VectorL10n.tr("Vector", "widget_sticker_picker_no_stickerpacks_alert") 
  }
  /// Add some now?
  internal static var widgetStickerPickerNoStickerpacksAlertAddNow: String { 
    return VectorL10n.tr("Vector", "widget_sticker_picker_no_stickerpacks_alert_add_now") 
  }
  /// Yesterday
  internal static var yesterday: String { 
    return VectorL10n.tr("Vector", "yesterday") 
  }
  /// You
  internal static var you: String { 
    return VectorL10n.tr("Vector", "you") 
  }
}
// swiftlint:enable function_parameter_count identifier_name line_length type_body_length

// MARK: - Implementation Details

extension VectorL10n {
  static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    let locale: Locale
    if let localeIdentifier = Bundle.mxk_language() {
       locale = Locale(identifier: localeIdentifier)
    } else if let fallbackLocaleIdentifier = Bundle.mxk_fallbackLanguage() {
       locale = Locale(identifier: fallbackLocaleIdentifier)
    } else {
       locale = Locale.current
    }        

      return String(format: format, locale: locale, arguments: args)
    }
}

private final class BundleToken {}
