// swiftlint:disable all
// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable function_parameter_count identifier_name line_length type_body_length
@objcMembers
public class VectorL10n: NSObject {
  /// Accept
  public static var accept: String { 
    return VectorL10n.tr("Vector", "accept") 
  }
  /// button
  public static var accessibilityButtonLabel: String { 
    return VectorL10n.tr("Vector", "accessibility_button_label") 
  }
  /// checkbox
  public static var accessibilityCheckboxLabel: String { 
    return VectorL10n.tr("Vector", "accessibility_checkbox_label") 
  }
  /// Logout all accounts
  public static var accountLogoutAll: String { 
    return VectorL10n.tr("Vector", "account_logout_all") 
  }
  /// Active Call
  public static var activeCall: String { 
    return VectorL10n.tr("Vector", "active_call") 
  }
  /// Active Call (%@)
  public static func activeCallDetails(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "active_call_details", p1)
  }
  /// Help us identify issues and improve %@ by sharing anonymous usage data. To understand how people use multiple devices, we’ll generate a random identifier, shared by your devices.
  public static func analyticsPromptMessageNewUser(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "analytics_prompt_message_new_user", p1)
  }
  /// You previously consented to share anonymous usage data with us. Now, to help understand how people use multiple devices, we’ll generate a random identifier, shared by your devices.
  public static var analyticsPromptMessageUpgrade: String { 
    return VectorL10n.tr("Vector", "analytics_prompt_message_upgrade") 
  }
  /// Not now
  public static var analyticsPromptNotNow: String { 
    return VectorL10n.tr("Vector", "analytics_prompt_not_now") 
  }
  /// We <b>don't</b> record or profile any account data
  public static var analyticsPromptPoint1: String { 
    return VectorL10n.tr("Vector", "analytics_prompt_point_1") 
  }
  /// We <b>don't</b> share information with third parties
  public static var analyticsPromptPoint2: String { 
    return VectorL10n.tr("Vector", "analytics_prompt_point_2") 
  }
  /// You can turn this off anytime in settings
  public static var analyticsPromptPoint3: String { 
    return VectorL10n.tr("Vector", "analytics_prompt_point_3") 
  }
  /// Stop sharing
  public static var analyticsPromptStop: String { 
    return VectorL10n.tr("Vector", "analytics_prompt_stop") 
  }
  /// here
  public static var analyticsPromptTermsLinkNewUser: String { 
    return VectorL10n.tr("Vector", "analytics_prompt_terms_link_new_user") 
  }
  /// here
  public static var analyticsPromptTermsLinkUpgrade: String { 
    return VectorL10n.tr("Vector", "analytics_prompt_terms_link_upgrade") 
  }
  /// You can read all our terms %@.
  public static func analyticsPromptTermsNewUser(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "analytics_prompt_terms_new_user", p1)
  }
  /// Read all our terms %@. Is that OK?
  public static func analyticsPromptTermsUpgrade(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "analytics_prompt_terms_upgrade", p1)
  }
  /// Help improve %@
  public static func analyticsPromptTitle(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "analytics_prompt_title", p1)
  }
  /// Yes, that's fine
  public static var analyticsPromptYes: String { 
    return VectorL10n.tr("Vector", "analytics_prompt_yes") 
  }
  /// Please review and accept the policies of this homeserver:
  public static var authAcceptPolicies: String { 
    return VectorL10n.tr("Vector", "auth_accept_policies") 
  }
  /// Registration with email and phone number at once is not supported yet until the api exists. Only the phone number will be taken into account. You may add your email to your profile in settings.
  public static var authAddEmailAndPhoneWarning: String { 
    return VectorL10n.tr("Vector", "auth_add_email_and_phone_warning") 
  }
  /// Set an email for account recovery, and later to be optionally discoverable by people who know you.
  public static var authAddEmailMessage2: String { 
    return VectorL10n.tr("Vector", "auth_add_email_message_2") 
  }
  /// Set an email for account recovery. Use later email or phone to be optionally discoverable by people who know you.
  public static var authAddEmailPhoneMessage2: String { 
    return VectorL10n.tr("Vector", "auth_add_email_phone_message_2") 
  }
  /// Set a phone, and later to be optionally discoverable by people who know you.
  public static var authAddPhoneMessage2: String { 
    return VectorL10n.tr("Vector", "auth_add_phone_message_2") 
  }
  /// Invalid homeserver discovery response
  public static var authAutodiscoverInvalidResponse: String { 
    return VectorL10n.tr("Vector", "auth_autodiscover_invalid_response") 
  }
  /// This email address is already in use
  public static var authEmailInUse: String { 
    return VectorL10n.tr("Vector", "auth_email_in_use") 
  }
  /// No identity server is configured so you cannot add an email address in order to reset your password in the future.
  public static var authEmailIsRequired: String { 
    return VectorL10n.tr("Vector", "auth_email_is_required") 
  }
  /// Failed to send email: This email address was not found
  public static var authEmailNotFound: String { 
    return VectorL10n.tr("Vector", "auth_email_not_found") 
  }
  /// Email address
  public static var authEmailPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_email_placeholder") 
  }
  /// Please check your email to continue registration
  public static var authEmailValidationMessage: String { 
    return VectorL10n.tr("Vector", "auth_email_validation_message") 
  }
  /// Forgot password?
  public static var authForgotPassword: String { 
    return VectorL10n.tr("Vector", "auth_forgot_password") 
  }
  /// No identity server is configured: add one to reset your password.
  public static var authForgotPasswordErrorNoConfiguredIdentityServer: String { 
    return VectorL10n.tr("Vector", "auth_forgot_password_error_no_configured_identity_server") 
  }
  /// URL (e.g. https://matrix.org)
  public static var authHomeServerPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_home_server_placeholder") 
  }
  /// URL (e.g. https://vector.im)
  public static var authIdentityServerPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_identity_server_placeholder") 
  }
  /// This doesn't look like a valid email address
  public static var authInvalidEmail: String { 
    return VectorL10n.tr("Vector", "auth_invalid_email") 
  }
  /// Incorrect username and/or password
  public static var authInvalidLoginParam: String { 
    return VectorL10n.tr("Vector", "auth_invalid_login_param") 
  }
  /// Password too short (min 6)
  public static var authInvalidPassword: String { 
    return VectorL10n.tr("Vector", "auth_invalid_password") 
  }
  /// This doesn't look like a valid phone number
  public static var authInvalidPhone: String { 
    return VectorL10n.tr("Vector", "auth_invalid_phone") 
  }
  /// User names may only contain letters, numbers, dots, hyphens and underscores
  public static var authInvalidUserName: String { 
    return VectorL10n.tr("Vector", "auth_invalid_user_name") 
  }
  /// Log in
  public static var authLogin: String { 
    return VectorL10n.tr("Vector", "auth_login") 
  }
  /// Sign In
  public static var authLoginSingleSignOn: String { 
    return VectorL10n.tr("Vector", "auth_login_single_sign_on") 
  }
  /// Missing email address
  public static var authMissingEmail: String { 
    return VectorL10n.tr("Vector", "auth_missing_email") 
  }
  /// Missing email address or phone number
  public static var authMissingEmailOrPhone: String { 
    return VectorL10n.tr("Vector", "auth_missing_email_or_phone") 
  }
  /// Missing password
  public static var authMissingPassword: String { 
    return VectorL10n.tr("Vector", "auth_missing_password") 
  }
  /// Missing phone number
  public static var authMissingPhone: String { 
    return VectorL10n.tr("Vector", "auth_missing_phone") 
  }
  /// Unable to verify phone number.
  public static var authMsisdnValidationError: String { 
    return VectorL10n.tr("Vector", "auth_msisdn_validation_error") 
  }
  /// We've sent an SMS with an activation code. Please enter this code below.
  public static var authMsisdnValidationMessage: String { 
    return VectorL10n.tr("Vector", "auth_msisdn_validation_message") 
  }
  /// Verification Pending
  public static var authMsisdnValidationTitle: String { 
    return VectorL10n.tr("Vector", "auth_msisdn_validation_title") 
  }
  /// New password
  public static var authNewPasswordPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_new_password_placeholder") 
  }
  /// Email address (optional)
  public static var authOptionalEmailPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_optional_email_placeholder") 
  }
  /// Phone number (optional)
  public static var authOptionalPhonePlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_optional_phone_placeholder") 
  }
  /// Passwords don't match
  public static var authPasswordDontMatch: String { 
    return VectorL10n.tr("Vector", "auth_password_dont_match") 
  }
  /// Password
  public static var authPasswordPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_password_placeholder") 
  }
  /// This phone number is already in use
  public static var authPhoneInUse: String { 
    return VectorL10n.tr("Vector", "auth_phone_in_use") 
  }
  /// No identity server is configured so you cannot add a phone number in order to reset your password in the future.
  public static var authPhoneIsRequired: String { 
    return VectorL10n.tr("Vector", "auth_phone_is_required") 
  }
  /// Phone number
  public static var authPhonePlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_phone_placeholder") 
  }
  /// This homeserver would like to make sure you are not a robot
  public static var authRecaptchaMessage: String { 
    return VectorL10n.tr("Vector", "auth_recaptcha_message") 
  }
  /// Register
  public static var authRegister: String { 
    return VectorL10n.tr("Vector", "auth_register") 
  }
  /// Confirm your new password
  public static var authRepeatNewPasswordPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_repeat_new_password_placeholder") 
  }
  /// Repeat password
  public static var authRepeatPasswordPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_repeat_password_placeholder") 
  }
  /// An email has been sent to %@. Once you've followed the link it contains, click below.
  public static func authResetPasswordEmailValidationMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "auth_reset_password_email_validation_message", p1)
  }
  /// No identity server is configured: add one in server options to reset your password.
  public static var authResetPasswordErrorIsRequired: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_error_is_required") 
  }
  /// Your email address does not appear to be associated with a Matrix ID on this homeserver.
  public static var authResetPasswordErrorNotFound: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_error_not_found") 
  }
  /// Failed to verify email address: make sure you clicked the link in the email
  public static var authResetPasswordErrorUnauthorized: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_error_unauthorized") 
  }
  /// To reset your password, enter the email address linked to your account:
  public static var authResetPasswordMessage: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_message") 
  }
  /// The email address linked to your account must be entered.
  public static var authResetPasswordMissingEmail: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_missing_email") 
  }
  /// A new password must be entered.
  public static var authResetPasswordMissingPassword: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_missing_password") 
  }
  /// I have verified my email address
  public static var authResetPasswordNextStepButton: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_next_step_button") 
  }
  /// Your password has been reset.\n\nYou have been logged out of all sessions and will no longer receive push notifications. To re-enable notifications, re-log in on each device.
  public static var authResetPasswordSuccessMessage: String { 
    return VectorL10n.tr("Vector", "auth_reset_password_success_message") 
  }
  /// Return to login screen
  public static var authReturnToLogin: String { 
    return VectorL10n.tr("Vector", "auth_return_to_login") 
  }
  /// Send Reset Email
  public static var authSendResetEmail: String { 
    return VectorL10n.tr("Vector", "auth_send_reset_email") 
  }
  /// Skip
  public static var authSkip: String { 
    return VectorL10n.tr("Vector", "auth_skip") 
  }
  /// Clear personal data
  public static var authSoftlogoutClearData: String { 
    return VectorL10n.tr("Vector", "auth_softlogout_clear_data") 
  }
  /// Clear all data
  public static var authSoftlogoutClearDataButton: String { 
    return VectorL10n.tr("Vector", "auth_softlogout_clear_data_button") 
  }
  /// Warning: Your personal data (including encryption keys) is still stored on this device.
  public static var authSoftlogoutClearDataMessage1: String { 
    return VectorL10n.tr("Vector", "auth_softlogout_clear_data_message_1") 
  }
  /// Clear it if you're finished using this device, or want to sign in to another account.
  public static var authSoftlogoutClearDataMessage2: String { 
    return VectorL10n.tr("Vector", "auth_softlogout_clear_data_message_2") 
  }
  /// Sign out
  public static var authSoftlogoutClearDataSignOut: String { 
    return VectorL10n.tr("Vector", "auth_softlogout_clear_data_sign_out") 
  }
  /// Are you sure you want to clear all data currently stored on this device? Sign in again to access your account data and messages.
  public static var authSoftlogoutClearDataSignOutMsg: String { 
    return VectorL10n.tr("Vector", "auth_softlogout_clear_data_sign_out_msg") 
  }
  /// Are you sure?
  public static var authSoftlogoutClearDataSignOutTitle: String { 
    return VectorL10n.tr("Vector", "auth_softlogout_clear_data_sign_out_title") 
  }
  /// Your homeserver (%1$@) admin has signed you out of your account %2$@ (%3$@).
  public static func authSoftlogoutReason(_ p1: String, _ p2: String, _ p3: String) -> String {
    return VectorL10n.tr("Vector", "auth_softlogout_reason", p1, p2, p3)
  }
  /// Sign in to recover encryption keys stored exclusively on this device. You need them to read all of your secure messages on any device.
  public static var authSoftlogoutRecoverEncryptionKeys: String { 
    return VectorL10n.tr("Vector", "auth_softlogout_recover_encryption_keys") 
  }
  /// Sign In
  public static var authSoftlogoutSignIn: String { 
    return VectorL10n.tr("Vector", "auth_softlogout_sign_in") 
  }
  /// You’re signed out
  public static var authSoftlogoutSignedOut: String { 
    return VectorL10n.tr("Vector", "auth_softlogout_signed_out") 
  }
  /// Submit
  public static var authSubmit: String { 
    return VectorL10n.tr("Vector", "auth_submit") 
  }
  /// The identity server is not trusted
  public static var authUntrustedIdServer: String { 
    return VectorL10n.tr("Vector", "auth_untrusted_id_server") 
  }
  /// Use custom server options (advanced)
  public static var authUseServerOptions: String { 
    return VectorL10n.tr("Vector", "auth_use_server_options") 
  }
  /// Email or user name
  public static var authUserIdPlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_user_id_placeholder") 
  }
  /// User name
  public static var authUserNamePlaceholder: String { 
    return VectorL10n.tr("Vector", "auth_user_name_placeholder") 
  }
  /// Username in use
  public static var authUsernameInUse: String { 
    return VectorL10n.tr("Vector", "auth_username_in_use") 
  }
  /// This app does not support the authentication mechanism on your homeserver.
  public static var authenticatedSessionFlowNotSupported: String { 
    return VectorL10n.tr("Vector", "authenticated_session_flow_not_supported") 
  }
  /// Back
  public static var back: String { 
    return VectorL10n.tr("Vector", "back") 
  }
  /// Log back in
  public static var biometricsCantUnlockedAlertMessageLogin: String { 
    return VectorL10n.tr("Vector", "biometrics_cant_unlocked_alert_message_login") 
  }
  /// Retry
  public static var biometricsCantUnlockedAlertMessageRetry: String { 
    return VectorL10n.tr("Vector", "biometrics_cant_unlocked_alert_message_retry") 
  }
  /// To unlock, use %@ or log back in and enable %@ again
  public static func biometricsCantUnlockedAlertMessageX(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "biometrics_cant_unlocked_alert_message_x", p1, p2)
  }
  /// Can't unlock app
  public static var biometricsCantUnlockedAlertTitle: String { 
    return VectorL10n.tr("Vector", "biometrics_cant_unlocked_alert_title") 
  }
  /// Disable %@
  public static func biometricsDesetupDisableButtonTitleX(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "biometrics_desetup_disable_button_title_x", p1)
  }
  /// Disable %@
  public static func biometricsDesetupTitleX(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "biometrics_desetup_title_x", p1)
  }
  /// Face ID
  public static var biometricsModeFaceId: String { 
    return VectorL10n.tr("Vector", "biometrics_mode_face_id") 
  }
  /// Touch ID
  public static var biometricsModeTouchId: String { 
    return VectorL10n.tr("Vector", "biometrics_mode_touch_id") 
  }
  /// Enable %@
  public static func biometricsSettingsEnableX(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "biometrics_settings_enable_x", p1)
  }
  /// Enable %@
  public static func biometricsSetupEnableButtonTitleX(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "biometrics_setup_enable_button_title_x", p1)
  }
  /// Save yourself time
  public static var biometricsSetupSubtitle: String { 
    return VectorL10n.tr("Vector", "biometrics_setup_subtitle") 
  }
  /// Enable %@
  public static func biometricsSetupTitleX(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "biometrics_setup_title_x", p1)
  }
  /// Authentication is needed to access your app
  public static var biometricsUsageReason: String { 
    return VectorL10n.tr("Vector", "biometrics_usage_reason") 
  }
  /// Please describe what you did before the crash:
  public static var bugCrashReportDescription: String { 
    return VectorL10n.tr("Vector", "bug_crash_report_description") 
  }
  /// Crash Report
  public static var bugCrashReportTitle: String { 
    return VectorL10n.tr("Vector", "bug_crash_report_title") 
  }
  /// Continue in background
  public static var bugReportBackgroundMode: String { 
    return VectorL10n.tr("Vector", "bug_report_background_mode") 
  }
  /// Please describe the bug. What did you do? What did you expect to happen? What actually happened?
  public static var bugReportDescription: String { 
    return VectorL10n.tr("Vector", "bug_report_description") 
  }
  /// In order to diagnose problems, logs from this client will be sent with this bug report. If you would prefer to only send the text above, please untick:
  public static var bugReportLogsDescription: String { 
    return VectorL10n.tr("Vector", "bug_report_logs_description") 
  }
  /// Uploading report
  public static var bugReportProgressUploading: String { 
    return VectorL10n.tr("Vector", "bug_report_progress_uploading") 
  }
  /// Collecting logs
  public static var bugReportProgressZipping: String { 
    return VectorL10n.tr("Vector", "bug_report_progress_zipping") 
  }
  /// The application has crashed last time. Would you like to submit a crash report?
  public static var bugReportPrompt: String { 
    return VectorL10n.tr("Vector", "bug_report_prompt") 
  }
  /// Send
  public static var bugReportSend: String { 
    return VectorL10n.tr("Vector", "bug_report_send") 
  }
  /// Send logs
  public static var bugReportSendLogs: String { 
    return VectorL10n.tr("Vector", "bug_report_send_logs") 
  }
  /// Send screenshot
  public static var bugReportSendScreenshot: String { 
    return VectorL10n.tr("Vector", "bug_report_send_screenshot") 
  }
  /// Bug Report
  public static var bugReportTitle: String { 
    return VectorL10n.tr("Vector", "bug_report_title") 
  }
  /// Resume
  public static var callActionsUnhold: String { 
    return VectorL10n.tr("Vector", "call_actions_unhold") 
  }
  /// There is already a call in progress.
  public static var callAlreadyDisplayed: String { 
    return VectorL10n.tr("Vector", "call_already_displayed") 
  }
  /// Incoming video call…
  public static var callIncomingVideo: String { 
    return VectorL10n.tr("Vector", "call_incoming_video") 
  }
  /// Incoming video call from %@
  public static func callIncomingVideoPrompt(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "call_incoming_video_prompt", p1)
  }
  /// Incoming call…
  public static var callIncomingVoice: String { 
    return VectorL10n.tr("Vector", "call_incoming_voice") 
  }
  /// Incoming voice call from %@
  public static func callIncomingVoicePrompt(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "call_incoming_voice_prompt", p1)
  }
  /// Failed to join the conference call.
  public static var callJitsiError: String { 
    return VectorL10n.tr("Vector", "call_jitsi_error") 
  }
  /// Please ask the administrator of your homeserver %@ to configure a TURN server in order for calls to work reliably.
  public static func callNoStunServerErrorMessage1(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "call_no_stun_server_error_message_1", p1)
  }
  /// Alternatively, you can try to use the public server at %@, but this will not be as reliable, and it will share your IP address with that server. You can also manage this in Settings
  public static func callNoStunServerErrorMessage2(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "call_no_stun_server_error_message_2", p1)
  }
  /// Call failed due to misconfigured server
  public static var callNoStunServerErrorTitle: String { 
    return VectorL10n.tr("Vector", "call_no_stun_server_error_title") 
  }
  /// Try using %@
  public static func callNoStunServerErrorUseFallbackButton(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "call_no_stun_server_error_use_fallback_button", p1)
  }
  /// All
  public static var callTransferContactsAll: String { 
    return VectorL10n.tr("Vector", "call_transfer_contacts_all") 
  }
  /// Recent
  public static var callTransferContactsRecent: String { 
    return VectorL10n.tr("Vector", "call_transfer_contacts_recent") 
  }
  /// Dial pad
  public static var callTransferDialpad: String { 
    return VectorL10n.tr("Vector", "call_transfer_dialpad") 
  }
  /// Call transfer failed
  public static var callTransferErrorMessage: String { 
    return VectorL10n.tr("Vector", "call_transfer_error_message") 
  }
  /// Error
  public static var callTransferErrorTitle: String { 
    return VectorL10n.tr("Vector", "call_transfer_error_title") 
  }
  /// Transfer
  public static var callTransferTitle: String { 
    return VectorL10n.tr("Vector", "call_transfer_title") 
  }
  /// Users
  public static var callTransferUsers: String { 
    return VectorL10n.tr("Vector", "call_transfer_users") 
  }
  /// 1 active call (%@) · %@ paused calls
  public static func callbarActiveAndMultiplePaused(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "callbar_active_and_multiple_paused", p1, p2)
  }
  /// 1 active call (%@) · 1 paused call
  public static func callbarActiveAndSinglePaused(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "callbar_active_and_single_paused", p1)
  }
  /// %@ paused calls
  public static func callbarOnlyMultiplePaused(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "callbar_only_multiple_paused", p1)
  }
  /// Tap to return to the call (%@)
  public static func callbarOnlySingleActive(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "callbar_only_single_active", p1)
  }
  /// Tap to Join the group call (%@)
  public static func callbarOnlySingleActiveGroup(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "callbar_only_single_active_group", p1)
  }
  /// Paused call
  public static var callbarOnlySinglePaused: String { 
    return VectorL10n.tr("Vector", "callbar_only_single_paused") 
  }
  /// Return
  public static var callbarReturn: String { 
    return VectorL10n.tr("Vector", "callbar_return") 
  }
  /// Camera
  public static var camera: String { 
    return VectorL10n.tr("Vector", "camera") 
  }
  /// %@ doesn't have permission to use Camera, please change privacy settings
  public static func cameraAccessNotGranted(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "camera_access_not_granted", p1)
  }
  /// The camera is unavailable on your device
  public static var cameraUnavailable: String { 
    return VectorL10n.tr("Vector", "camera_unavailable") 
  }
  /// Cancel
  public static var cancel: String { 
    return VectorL10n.tr("Vector", "cancel") 
  }
  /// Close
  public static var close: String { 
    return VectorL10n.tr("Vector", "close") 
  }
  /// collapse
  public static var collapse: String { 
    return VectorL10n.tr("Vector", "collapse") 
  }
  /// Matrix users only
  public static var contactsAddressBookMatrixUsersToggle: String { 
    return VectorL10n.tr("Vector", "contacts_address_book_matrix_users_toggle") 
  }
  /// No local contacts
  public static var contactsAddressBookNoContact: String { 
    return VectorL10n.tr("Vector", "contacts_address_book_no_contact") 
  }
  /// No identity server configured
  public static var contactsAddressBookNoIdentityServer: String { 
    return VectorL10n.tr("Vector", "contacts_address_book_no_identity_server") 
  }
  /// You didn't allow %@ to access your local contacts
  public static func contactsAddressBookPermissionDenied(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "contacts_address_book_permission_denied", p1)
  }
  /// To enable contacts, go to your device settings.
  public static var contactsAddressBookPermissionDeniedAlertMessage: String { 
    return VectorL10n.tr("Vector", "contacts_address_book_permission_denied_alert_message") 
  }
  /// Contacts disabled
  public static var contactsAddressBookPermissionDeniedAlertTitle: String { 
    return VectorL10n.tr("Vector", "contacts_address_book_permission_denied_alert_title") 
  }
  /// Permission required to access local contacts
  public static var contactsAddressBookPermissionRequired: String { 
    return VectorL10n.tr("Vector", "contacts_address_book_permission_required") 
  }
  /// LOCAL CONTACTS
  public static var contactsAddressBookSection: String { 
    return VectorL10n.tr("Vector", "contacts_address_book_section") 
  }
  /// USER DIRECTORY (offline)
  public static var contactsUserDirectoryOfflineSection: String { 
    return VectorL10n.tr("Vector", "contacts_user_directory_offline_section") 
  }
  /// USER DIRECTORY
  public static var contactsUserDirectorySection: String { 
    return VectorL10n.tr("Vector", "contacts_user_directory_section") 
  }
  /// Continue
  public static var `continue`: String { 
    return VectorL10n.tr("Vector", "continue") 
  }
  /// Create
  public static var create: String { 
    return VectorL10n.tr("Vector", "create") 
  }
  /// Enable Encryption
  public static var createRoomEnableEncryption: String { 
    return VectorL10n.tr("Vector", "create_room_enable_encryption") 
  }
  /// #testroom:matrix.org
  public static var createRoomPlaceholderAddress: String { 
    return VectorL10n.tr("Vector", "create_room_placeholder_address") 
  }
  /// Name
  public static var createRoomPlaceholderName: String { 
    return VectorL10n.tr("Vector", "create_room_placeholder_name") 
  }
  /// Topic
  public static var createRoomPlaceholderTopic: String { 
    return VectorL10n.tr("Vector", "create_room_placeholder_topic") 
  }
  /// Encryption can’t be disabled afterwards.
  public static var createRoomSectionFooterEncryption: String { 
    return VectorL10n.tr("Vector", "create_room_section_footer_encryption") 
  }
  /// People join a private room only with the room invitation.
  public static var createRoomSectionFooterType: String { 
    return VectorL10n.tr("Vector", "create_room_section_footer_type") 
  }
  /// Room address
  public static var createRoomSectionHeaderAddress: String { 
    return VectorL10n.tr("Vector", "create_room_section_header_address") 
  }
  /// Room encryption
  public static var createRoomSectionHeaderEncryption: String { 
    return VectorL10n.tr("Vector", "create_room_section_header_encryption") 
  }
  /// Room name
  public static var createRoomSectionHeaderName: String { 
    return VectorL10n.tr("Vector", "create_room_section_header_name") 
  }
  /// Room topic (optional)
  public static var createRoomSectionHeaderTopic: String { 
    return VectorL10n.tr("Vector", "create_room_section_header_topic") 
  }
  /// Room type
  public static var createRoomSectionHeaderType: String { 
    return VectorL10n.tr("Vector", "create_room_section_header_type") 
  }
  /// Show the room in the directory
  public static var createRoomShowInDirectory: String { 
    return VectorL10n.tr("Vector", "create_room_show_in_directory") 
  }
  /// New Room
  public static var createRoomTitle: String { 
    return VectorL10n.tr("Vector", "create_room_title") 
  }
  /// Private Room
  public static var createRoomTypePrivate: String { 
    return VectorL10n.tr("Vector", "create_room_type_private") 
  }
  /// Public Room
  public static var createRoomTypePublic: String { 
    return VectorL10n.tr("Vector", "create_room_type_public") 
  }
  /// Verify your other devices easier
  public static var crossSigningSetupBannerSubtitle: String { 
    return VectorL10n.tr("Vector", "cross_signing_setup_banner_subtitle") 
  }
  /// Set up encryption
  public static var crossSigningSetupBannerTitle: String { 
    return VectorL10n.tr("Vector", "cross_signing_setup_banner_title") 
  }
  /// Please forget all messages I have sent when my account is deactivated (
  public static var deactivateAccountForgetMessagesInformationPart1: String { 
    return VectorL10n.tr("Vector", "deactivate_account_forget_messages_information_part1") 
  }
  /// Warning
  public static var deactivateAccountForgetMessagesInformationPart2Emphasize: String { 
    return VectorL10n.tr("Vector", "deactivate_account_forget_messages_information_part2_emphasize") 
  }
  /// : this will cause future users to see an incomplete view of conversations)
  public static var deactivateAccountForgetMessagesInformationPart3: String { 
    return VectorL10n.tr("Vector", "deactivate_account_forget_messages_information_part3") 
  }
  /// This will make your account permanently unusable. You will not be able to log in, and no one will be able to re-register the same user ID.  This will cause your account to leave all rooms it is participating in, and it will remove your account details from your identity server. 
  public static var deactivateAccountInformationsPart1: String { 
    return VectorL10n.tr("Vector", "deactivate_account_informations_part1") 
  }
  /// This action is irreversible.
  public static var deactivateAccountInformationsPart2Emphasize: String { 
    return VectorL10n.tr("Vector", "deactivate_account_informations_part2_emphasize") 
  }
  /// \n\nDeactivating your account 
  public static var deactivateAccountInformationsPart3: String { 
    return VectorL10n.tr("Vector", "deactivate_account_informations_part3") 
  }
  /// does not by default cause us to forget messages you have sent. 
  public static var deactivateAccountInformationsPart4Emphasize: String { 
    return VectorL10n.tr("Vector", "deactivate_account_informations_part4_emphasize") 
  }
  /// If you would like us to forget your messages, please tick the box below\n\nMessage visibility in Matrix is similar to email. Our forgetting your messages means that messages you have sent will not be shared with any new or unregistered users, but registered users who already have access to these messages will still have access to their copy.
  public static var deactivateAccountInformationsPart5: String { 
    return VectorL10n.tr("Vector", "deactivate_account_informations_part5") 
  }
  /// To continue, please enter your password
  public static var deactivateAccountPasswordAlertMessage: String { 
    return VectorL10n.tr("Vector", "deactivate_account_password_alert_message") 
  }
  /// Deactivate Account
  public static var deactivateAccountPasswordAlertTitle: String { 
    return VectorL10n.tr("Vector", "deactivate_account_password_alert_title") 
  }
  /// Deactivate Account
  public static var deactivateAccountTitle: String { 
    return VectorL10n.tr("Vector", "deactivate_account_title") 
  }
  /// Deactivate account
  public static var deactivateAccountValidateAction: String { 
    return VectorL10n.tr("Vector", "deactivate_account_validate_action") 
  }
  /// Decline
  public static var decline: String { 
    return VectorL10n.tr("Vector", "decline") 
  }
  /// The other party cancelled the verification.
  public static var deviceVerificationCancelled: String { 
    return VectorL10n.tr("Vector", "device_verification_cancelled") 
  }
  /// The verification has been cancelled. Reason: %@
  public static func deviceVerificationCancelledByMe(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "device_verification_cancelled_by_me", p1)
  }
  /// Aeroplane
  public static var deviceVerificationEmojiAeroplane: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_aeroplane") 
  }
  /// Anchor
  public static var deviceVerificationEmojiAnchor: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_anchor") 
  }
  /// Apple
  public static var deviceVerificationEmojiApple: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_apple") 
  }
  /// Ball
  public static var deviceVerificationEmojiBall: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_ball") 
  }
  /// Banana
  public static var deviceVerificationEmojiBanana: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_banana") 
  }
  /// Bell
  public static var deviceVerificationEmojiBell: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_bell") 
  }
  /// Bicycle
  public static var deviceVerificationEmojiBicycle: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_bicycle") 
  }
  /// Book
  public static var deviceVerificationEmojiBook: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_book") 
  }
  /// Butterfly
  public static var deviceVerificationEmojiButterfly: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_butterfly") 
  }
  /// Cactus
  public static var deviceVerificationEmojiCactus: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_cactus") 
  }
  /// Cake
  public static var deviceVerificationEmojiCake: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_cake") 
  }
  /// Cat
  public static var deviceVerificationEmojiCat: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_cat") 
  }
  /// Clock
  public static var deviceVerificationEmojiClock: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_clock") 
  }
  /// Cloud
  public static var deviceVerificationEmojiCloud: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_cloud") 
  }
  /// Corn
  public static var deviceVerificationEmojiCorn: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_corn") 
  }
  /// Dog
  public static var deviceVerificationEmojiDog: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_dog") 
  }
  /// Elephant
  public static var deviceVerificationEmojiElephant: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_elephant") 
  }
  /// Fire
  public static var deviceVerificationEmojiFire: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_fire") 
  }
  /// Fish
  public static var deviceVerificationEmojiFish: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_fish") 
  }
  /// Flag
  public static var deviceVerificationEmojiFlag: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_flag") 
  }
  /// Flower
  public static var deviceVerificationEmojiFlower: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_flower") 
  }
  /// Folder
  public static var deviceVerificationEmojiFolder: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_folder") 
  }
  /// Gift
  public static var deviceVerificationEmojiGift: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_gift") 
  }
  /// Glasses
  public static var deviceVerificationEmojiGlasses: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_glasses") 
  }
  /// Globe
  public static var deviceVerificationEmojiGlobe: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_globe") 
  }
  /// Guitar
  public static var deviceVerificationEmojiGuitar: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_guitar") 
  }
  /// Hammer
  public static var deviceVerificationEmojiHammer: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_hammer") 
  }
  /// Hat
  public static var deviceVerificationEmojiHat: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_hat") 
  }
  /// Headphones
  public static var deviceVerificationEmojiHeadphones: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_headphones") 
  }
  /// Heart
  public static var deviceVerificationEmojiHeart: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_heart") 
  }
  /// Horse
  public static var deviceVerificationEmojiHorse: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_horse") 
  }
  /// Hourglass
  public static var deviceVerificationEmojiHourglass: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_hourglass") 
  }
  /// Key
  public static var deviceVerificationEmojiKey: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_key") 
  }
  /// Light Bulb
  public static var deviceVerificationEmojiLightBulb: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_light bulb") 
  }
  /// Lion
  public static var deviceVerificationEmojiLion: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_lion") 
  }
  /// Lock
  public static var deviceVerificationEmojiLock: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_lock") 
  }
  /// Moon
  public static var deviceVerificationEmojiMoon: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_moon") 
  }
  /// Mushroom
  public static var deviceVerificationEmojiMushroom: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_mushroom") 
  }
  /// Octopus
  public static var deviceVerificationEmojiOctopus: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_octopus") 
  }
  /// Panda
  public static var deviceVerificationEmojiPanda: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_panda") 
  }
  /// Paperclip
  public static var deviceVerificationEmojiPaperclip: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_paperclip") 
  }
  /// Pencil
  public static var deviceVerificationEmojiPencil: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_pencil") 
  }
  /// Penguin
  public static var deviceVerificationEmojiPenguin: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_penguin") 
  }
  /// Pig
  public static var deviceVerificationEmojiPig: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_pig") 
  }
  /// Pin
  public static var deviceVerificationEmojiPin: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_pin") 
  }
  /// Pizza
  public static var deviceVerificationEmojiPizza: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_pizza") 
  }
  /// Rabbit
  public static var deviceVerificationEmojiRabbit: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_rabbit") 
  }
  /// Robot
  public static var deviceVerificationEmojiRobot: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_robot") 
  }
  /// Rocket
  public static var deviceVerificationEmojiRocket: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_rocket") 
  }
  /// Rooster
  public static var deviceVerificationEmojiRooster: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_rooster") 
  }
  /// Santa
  public static var deviceVerificationEmojiSanta: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_santa") 
  }
  /// Scissors
  public static var deviceVerificationEmojiScissors: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_scissors") 
  }
  /// Smiley
  public static var deviceVerificationEmojiSmiley: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_smiley") 
  }
  /// Spanner
  public static var deviceVerificationEmojiSpanner: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_spanner") 
  }
  /// Strawberry
  public static var deviceVerificationEmojiStrawberry: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_strawberry") 
  }
  /// Telephone
  public static var deviceVerificationEmojiTelephone: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_telephone") 
  }
  /// Thumbs up
  public static var deviceVerificationEmojiThumbsUp: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_thumbs up") 
  }
  /// Train
  public static var deviceVerificationEmojiTrain: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_train") 
  }
  /// Tree
  public static var deviceVerificationEmojiTree: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_tree") 
  }
  /// Trophy
  public static var deviceVerificationEmojiTrophy: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_trophy") 
  }
  /// Trumpet
  public static var deviceVerificationEmojiTrumpet: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_trumpet") 
  }
  /// Turtle
  public static var deviceVerificationEmojiTurtle: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_turtle") 
  }
  /// Umbrella
  public static var deviceVerificationEmojiUmbrella: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_umbrella") 
  }
  /// Unicorn
  public static var deviceVerificationEmojiUnicorn: String { 
    return VectorL10n.tr("Vector", "device_verification_emoji_unicorn") 
  }
  /// Cannot load session information.
  public static var deviceVerificationErrorCannotLoadDevice: String { 
    return VectorL10n.tr("Vector", "device_verification_error_cannot_load_device") 
  }
  /// Verify this session to mark it as trusted. Trusting sessions of partners gives you extra peace of mind when using end-to-end encrypted messages.
  public static var deviceVerificationIncomingDescription1: String { 
    return VectorL10n.tr("Vector", "device_verification_incoming_description_1") 
  }
  /// Verifying this session will mark it as trusted, and also mark your session as trusted to the partner.
  public static var deviceVerificationIncomingDescription2: String { 
    return VectorL10n.tr("Vector", "device_verification_incoming_description_2") 
  }
  /// Incoming Verification Request
  public static var deviceVerificationIncomingTitle: String { 
    return VectorL10n.tr("Vector", "device_verification_incoming_title") 
  }
  /// Compare the unique emoji, ensuring they appear in the same order.
  public static var deviceVerificationSecurityAdviceEmoji: String { 
    return VectorL10n.tr("Vector", "device_verification_security_advice_emoji") 
  }
  /// Compare the numbers, ensuring they appear in the same order.
  public static var deviceVerificationSecurityAdviceNumber: String { 
    return VectorL10n.tr("Vector", "device_verification_security_advice_number") 
  }
  /// Verify the new login accessing your account: %@
  public static func deviceVerificationSelfVerifyAlertMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "device_verification_self_verify_alert_message", p1)
  }
  /// New login. Was this you?
  public static var deviceVerificationSelfVerifyAlertTitle: String { 
    return VectorL10n.tr("Vector", "device_verification_self_verify_alert_title") 
  }
  /// Verify
  public static var deviceVerificationSelfVerifyAlertValidateAction: String { 
    return VectorL10n.tr("Vector", "device_verification_self_verify_alert_validate_action") 
  }
  /// Use this session to verify your new one, granting it access to encrypted messages.
  public static var deviceVerificationSelfVerifyStartInformation: String { 
    return VectorL10n.tr("Vector", "device_verification_self_verify_start_information") 
  }
  /// Start verification
  public static var deviceVerificationSelfVerifyStartVerifyAction: String { 
    return VectorL10n.tr("Vector", "device_verification_self_verify_start_verify_action") 
  }
  /// Waiting…
  public static var deviceVerificationSelfVerifyStartWaiting: String { 
    return VectorL10n.tr("Vector", "device_verification_self_verify_start_waiting") 
  }
  /// This works with %@ and other cross-signing capable Matrix clients.
  public static func deviceVerificationSelfVerifyWaitAdditionalInformation(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "device_verification_self_verify_wait_additional_information", p1)
  }
  /// Verify this session from one of your other sessions, granting it access to encrypted messages.\n\nUse the latest %@ on your other devices:
  public static func deviceVerificationSelfVerifyWaitInformation(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "device_verification_self_verify_wait_information", p1)
  }
  /// Verify this login
  public static var deviceVerificationSelfVerifyWaitNewSignInTitle: String { 
    return VectorL10n.tr("Vector", "device_verification_self_verify_wait_new_sign_in_title") 
  }
  /// If you can't access an existing session
  public static var deviceVerificationSelfVerifyWaitRecoverSecretsAdditionalInformation: String { 
    return VectorL10n.tr("Vector", "device_verification_self_verify_wait_recover_secrets_additional_information") 
  }
  /// Checking for other verification capabilities ...
  public static var deviceVerificationSelfVerifyWaitRecoverSecretsCheckingAvailability: String { 
    return VectorL10n.tr("Vector", "device_verification_self_verify_wait_recover_secrets_checking_availability") 
  }
  /// Use Security Phrase or Key
  public static var deviceVerificationSelfVerifyWaitRecoverSecretsWithPassphrase: String { 
    return VectorL10n.tr("Vector", "device_verification_self_verify_wait_recover_secrets_with_passphrase") 
  }
  /// Use Security Key
  public static var deviceVerificationSelfVerifyWaitRecoverSecretsWithoutPassphrase: String { 
    return VectorL10n.tr("Vector", "device_verification_self_verify_wait_recover_secrets_without_passphrase") 
  }
  /// Complete security
  public static var deviceVerificationSelfVerifyWaitTitle: String { 
    return VectorL10n.tr("Vector", "device_verification_self_verify_wait_title") 
  }
  /// Verify by comparing a short text string
  public static var deviceVerificationStartTitle: String { 
    return VectorL10n.tr("Vector", "device_verification_start_title") 
  }
  /// Nothing appearing? Not all clients support interactive verification yet. Use legacy verification.
  public static var deviceVerificationStartUseLegacy: String { 
    return VectorL10n.tr("Vector", "device_verification_start_use_legacy") 
  }
  /// Use Legacy Verification
  public static var deviceVerificationStartUseLegacyAction: String { 
    return VectorL10n.tr("Vector", "device_verification_start_use_legacy_action") 
  }
  /// Begin Verifying
  public static var deviceVerificationStartVerifyButton: String { 
    return VectorL10n.tr("Vector", "device_verification_start_verify_button") 
  }
  /// Waiting for partner to accept…
  public static var deviceVerificationStartWaitPartner: String { 
    return VectorL10n.tr("Vector", "device_verification_start_wait_partner") 
  }
  /// Got it
  public static var deviceVerificationVerifiedGotItButton: String { 
    return VectorL10n.tr("Vector", "device_verification_verified_got_it_button") 
  }
  /// Verified!
  public static var deviceVerificationVerifiedTitle: String { 
    return VectorL10n.tr("Vector", "device_verification_verified_title") 
  }
  /// Waiting for partner to confirm…
  public static var deviceVerificationVerifyWaitPartner: String { 
    return VectorL10n.tr("Vector", "device_verification_verify_wait_partner") 
  }
  /// Dial pad
  public static var dialpadTitle: String { 
    return VectorL10n.tr("Vector", "dialpad_title") 
  }
  /// %tu rooms
  public static func directoryCellDescription(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "directory_cell_description", p1)
  }
  /// Browse directory
  public static var directoryCellTitle: String { 
    return VectorL10n.tr("Vector", "directory_cell_title") 
  }
  /// Failed to fetch data
  public static var directorySearchFail: String { 
    return VectorL10n.tr("Vector", "directory_search_fail") 
  }
  /// %tu results found for %@
  public static func directorySearchResults(_ p1: Int, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "directory_search_results", p1, p2)
  }
  /// >%tu results found for %@
  public static func directorySearchResultsMoreThan(_ p1: Int, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "directory_search_results_more_than", p1, p2)
  }
  /// Browse directory results
  public static var directorySearchResultsTitle: String { 
    return VectorL10n.tr("Vector", "directory_search_results_title") 
  }
  /// Searching directory…
  public static var directorySearchingTitle: String { 
    return VectorL10n.tr("Vector", "directory_searching_title") 
  }
  /// All native Matrix rooms
  public static var directoryServerAllNativeRooms: String { 
    return VectorL10n.tr("Vector", "directory_server_all_native_rooms") 
  }
  /// All rooms on %@ server
  public static func directoryServerAllRooms(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "directory_server_all_rooms", p1)
  }
  /// Select a directory
  public static var directoryServerPickerTitle: String { 
    return VectorL10n.tr("Vector", "directory_server_picker_title") 
  }
  /// matrix.org
  public static var directoryServerPlaceholder: String { 
    return VectorL10n.tr("Vector", "directory_server_placeholder") 
  }
  /// Type a homeserver to list public rooms from
  public static var directoryServerTypeHomeserver: String { 
    return VectorL10n.tr("Vector", "directory_server_type_homeserver") 
  }
  /// Directory
  public static var directoryTitle: String { 
    return VectorL10n.tr("Vector", "directory_title") 
  }
  /// Do not ask again
  public static var doNotAskAgain: String { 
    return VectorL10n.tr("Vector", "do_not_ask_again") 
  }
  /// Done
  public static var done: String { 
    return VectorL10n.tr("Vector", "done") 
  }
  /// %@ now supports end-to-end encryption but you need to log in again to enable it.\n\nYou can do it now or later from the application settings.
  public static func e2eEnablingOnAppUpdate(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "e2e_enabling_on_app_update", p1)
  }
  /// A new secure message key backup has been detected.\n\nIf this wasn’t you, set a new Security Phrase in Settings.
  public static var e2eKeyBackupWrongVersion: String { 
    return VectorL10n.tr("Vector", "e2e_key_backup_wrong_version") 
  }
  /// Settings
  public static var e2eKeyBackupWrongVersionButtonSettings: String { 
    return VectorL10n.tr("Vector", "e2e_key_backup_wrong_version_button_settings") 
  }
  /// It was me
  public static var e2eKeyBackupWrongVersionButtonWasme: String { 
    return VectorL10n.tr("Vector", "e2e_key_backup_wrong_version_button_wasme") 
  }
  /// New Key Backup
  public static var e2eKeyBackupWrongVersionTitle: String { 
    return VectorL10n.tr("Vector", "e2e_key_backup_wrong_version_title") 
  }
  /// You need to log back in to generate end-to-end encryption keys for this session and submit the public key to your homeserver.\nThis is a once off; sorry for the inconvenience.
  public static var e2eNeedLogInAgain: String { 
    return VectorL10n.tr("Vector", "e2e_need_log_in_again") 
  }
  /// Ignore request
  public static var e2eRoomKeyRequestIgnoreRequest: String { 
    return VectorL10n.tr("Vector", "e2e_room_key_request_ignore_request") 
  }
  /// Your unverified session '%@' is requesting encryption keys.
  public static func e2eRoomKeyRequestMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "e2e_room_key_request_message", p1)
  }
  /// You added a new session '%@', which is requesting encryption keys.
  public static func e2eRoomKeyRequestMessageNewDevice(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "e2e_room_key_request_message_new_device", p1)
  }
  /// Share without verifying
  public static var e2eRoomKeyRequestShareWithoutVerifying: String { 
    return VectorL10n.tr("Vector", "e2e_room_key_request_share_without_verifying") 
  }
  /// Start verification…
  public static var e2eRoomKeyRequestStartVerification: String { 
    return VectorL10n.tr("Vector", "e2e_room_key_request_start_verification") 
  }
  /// Encryption key request
  public static var e2eRoomKeyRequestTitle: String { 
    return VectorL10n.tr("Vector", "e2e_room_key_request_title") 
  }
  /// Activities
  public static var emojiPickerActivityCategory: String { 
    return VectorL10n.tr("Vector", "emoji_picker_activity_category") 
  }
  /// Flags
  public static var emojiPickerFlagsCategory: String { 
    return VectorL10n.tr("Vector", "emoji_picker_flags_category") 
  }
  /// Food & Drink
  public static var emojiPickerFoodsCategory: String { 
    return VectorL10n.tr("Vector", "emoji_picker_foods_category") 
  }
  /// Animals & Nature
  public static var emojiPickerNatureCategory: String { 
    return VectorL10n.tr("Vector", "emoji_picker_nature_category") 
  }
  /// Objects
  public static var emojiPickerObjectsCategory: String { 
    return VectorL10n.tr("Vector", "emoji_picker_objects_category") 
  }
  /// Smileys & People
  public static var emojiPickerPeopleCategory: String { 
    return VectorL10n.tr("Vector", "emoji_picker_people_category") 
  }
  /// Travel & Places
  public static var emojiPickerPlacesCategory: String { 
    return VectorL10n.tr("Vector", "emoji_picker_places_category") 
  }
  /// Symbols
  public static var emojiPickerSymbolsCategory: String { 
    return VectorL10n.tr("Vector", "emoji_picker_symbols_category") 
  }
  /// Reactions
  public static var emojiPickerTitle: String { 
    return VectorL10n.tr("Vector", "emoji_picker_title") 
  }
  /// Enable
  public static var enable: String { 
    return VectorL10n.tr("Vector", "enable") 
  }
  /// Send an encrypted message…
  public static var encryptedRoomMessagePlaceholder: String { 
    return VectorL10n.tr("Vector", "encrypted_room_message_placeholder") 
  }
  /// Send an encrypted reply…
  public static var encryptedRoomMessageReplyToPlaceholder: String { 
    return VectorL10n.tr("Vector", "encrypted_room_message_reply_to_placeholder") 
  }
  /// Add an identity server in your settings to invite by email.
  public static var errorInvite3pidWithNoIdentityServer: String { 
    return VectorL10n.tr("Vector", "error_invite_3pid_with_no_identity_server") 
  }
  /// You can't do this from %@ mobile.
  public static func errorNotSupportedOnMobile(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "error_not_supported_on_mobile", p1)
  }
  /// It looks like you’re trying to connect to another homeserver. Do you want to sign out?
  public static var errorUserAlreadyLoggedIn: String { 
    return VectorL10n.tr("Vector", "error_user_already_logged_in") 
  }
  /// Active video call
  public static var eventFormatterCallActiveVideo: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_active_video") 
  }
  /// Active voice call
  public static var eventFormatterCallActiveVoice: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_active_voice") 
  }
  /// Answer
  public static var eventFormatterCallAnswer: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_answer") 
  }
  /// Call back
  public static var eventFormatterCallBack: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_back") 
  }
  /// Connecting…
  public static var eventFormatterCallConnecting: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_connecting") 
  }
  /// Connection failed
  public static var eventFormatterCallConnectionFailed: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_connection_failed") 
  }
  /// Decline
  public static var eventFormatterCallDecline: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_decline") 
  }
  /// End call
  public static var eventFormatterCallEndCall: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_end_call") 
  }
  /// Call ended
  public static var eventFormatterCallHasEnded: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_has_ended") 
  }
  /// Call ended • %@
  public static func eventFormatterCallHasEndedWithTime(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_call_has_ended_with_time", p1)
  }
  /// Incoming video call
  public static var eventFormatterCallIncomingVideo: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_incoming_video") 
  }
  /// Incoming voice call
  public static var eventFormatterCallIncomingVoice: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_incoming_voice") 
  }
  /// Missed video call
  public static var eventFormatterCallMissedVideo: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_missed_video") 
  }
  /// Missed voice call
  public static var eventFormatterCallMissedVoice: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_missed_voice") 
  }
  /// Retry
  public static var eventFormatterCallRetry: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_retry") 
  }
  /// Ringing…
  public static var eventFormatterCallRinging: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_ringing") 
  }
  /// Call declined
  public static var eventFormatterCallYouDeclined: String { 
    return VectorL10n.tr("Vector", "event_formatter_call_you_declined") 
  }
  /// Group call
  public static var eventFormatterGroupCall: String { 
    return VectorL10n.tr("Vector", "event_formatter_group_call") 
  }
  /// %@ in %@
  public static func eventFormatterGroupCallIncoming(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_group_call_incoming", p1, p2)
  }
  /// Join
  public static var eventFormatterGroupCallJoin: String { 
    return VectorL10n.tr("Vector", "event_formatter_group_call_join") 
  }
  /// Leave
  public static var eventFormatterGroupCallLeave: String { 
    return VectorL10n.tr("Vector", "event_formatter_group_call_leave") 
  }
  /// VoIP conference added by %@
  public static func eventFormatterJitsiWidgetAdded(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_jitsi_widget_added", p1)
  }
  /// You added VoIP conference
  public static var eventFormatterJitsiWidgetAddedByYou: String { 
    return VectorL10n.tr("Vector", "event_formatter_jitsi_widget_added_by_you") 
  }
  /// VoIP conference removed by %@
  public static func eventFormatterJitsiWidgetRemoved(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_jitsi_widget_removed", p1)
  }
  /// You removed VoIP conference
  public static var eventFormatterJitsiWidgetRemovedByYou: String { 
    return VectorL10n.tr("Vector", "event_formatter_jitsi_widget_removed_by_you") 
  }
  /// %tu membership changes
  public static func eventFormatterMemberUpdates(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "event_formatter_member_updates", p1)
  }
  /// (edited)
  public static var eventFormatterMessageEditedMention: String { 
    return VectorL10n.tr("Vector", "event_formatter_message_edited_mention") 
  }
  /// Re-request encryption keys
  public static var eventFormatterRerequestKeysPart1Link: String { 
    return VectorL10n.tr("Vector", "event_formatter_rerequest_keys_part1_link") 
  }
  ///  from your other sessions.
  public static var eventFormatterRerequestKeysPart2: String { 
    return VectorL10n.tr("Vector", "event_formatter_rerequest_keys_part2") 
  }
  /// %@ widget added by %@
  public static func eventFormatterWidgetAdded(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_widget_added", p1, p2)
  }
  /// You added the widget: %@
  public static func eventFormatterWidgetAddedByYou(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_widget_added_by_you", p1)
  }
  /// %@ widget removed by %@
  public static func eventFormatterWidgetRemoved(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_widget_removed", p1, p2)
  }
  /// You removed the widget: %@
  public static func eventFormatterWidgetRemovedByYou(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "event_formatter_widget_removed_by_you", p1)
  }
  /// The link %@ is taking you to another site: %@\n\nAre you sure you want to continue?
  public static func externalLinkConfirmationMessage(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "external_link_confirmation_message", p1, p2)
  }
  /// Double-check this link
  public static var externalLinkConfirmationTitle: String { 
    return VectorL10n.tr("Vector", "external_link_confirmation_title") 
  }
  /// You can favourite a few ways - the quickest is just to press and hold. Tap the star and they’ll automatically appear here for safe keeping.
  public static var favouritesEmptyViewInformation: String { 
    return VectorL10n.tr("Vector", "favourites_empty_view_information") 
  }
  /// Favourite rooms and people
  public static var favouritesEmptyViewTitle: String { 
    return VectorL10n.tr("Vector", "favourites_empty_view_title") 
  }
  /// File upload
  public static var fileUploadErrorTitle: String { 
    return VectorL10n.tr("Vector", "file_upload_error_title") 
  }
  /// File type not supported.
  public static var fileUploadErrorUnsupportedFileTypeMessage: String { 
    return VectorL10n.tr("Vector", "file_upload_error_unsupported_file_type_message") 
  }
  /// Find your contacts
  public static var findYourContactsButtonTitle: String { 
    return VectorL10n.tr("Vector", "find_your_contacts_button_title") 
  }
  /// This can be disabled anytime from settings.
  public static var findYourContactsFooter: String { 
    return VectorL10n.tr("Vector", "find_your_contacts_footer") 
  }
  /// Unable to connect to the identity server.
  public static var findYourContactsIdentityServiceError: String { 
    return VectorL10n.tr("Vector", "find_your_contacts_identity_service_error") 
  }
  /// Let %@ show your contacts so you can quickly start chatting with those you know best.
  public static func findYourContactsMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "find_your_contacts_message", p1)
  }
  /// Start by listing your contacts
  public static var findYourContactsTitle: String { 
    return VectorL10n.tr("Vector", "find_your_contacts_title") 
  }
  /// To continue using the %@ homeserver you must review and agree to the terms and conditions.
  public static func gdprConsentNotGivenAlertMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "gdpr_consent_not_given_alert_message", p1)
  }
  /// Review now
  public static var gdprConsentNotGivenAlertReviewNowAction: String { 
    return VectorL10n.tr("Vector", "gdpr_consent_not_given_alert_review_now_action") 
  }
  /// Home
  public static var groupDetailsHome: String { 
    return VectorL10n.tr("Vector", "group_details_home") 
  }
  /// People
  public static var groupDetailsPeople: String { 
    return VectorL10n.tr("Vector", "group_details_people") 
  }
  /// Rooms
  public static var groupDetailsRooms: String { 
    return VectorL10n.tr("Vector", "group_details_rooms") 
  }
  /// Community Details
  public static var groupDetailsTitle: String { 
    return VectorL10n.tr("Vector", "group_details_title") 
  }
  /// %tu members
  public static func groupHomeMultiMembersFormat(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "group_home_multi_members_format", p1)
  }
  /// %tu rooms
  public static func groupHomeMultiRoomsFormat(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "group_home_multi_rooms_format", p1)
  }
  /// 1 member
  public static var groupHomeOneMemberFormat: String { 
    return VectorL10n.tr("Vector", "group_home_one_member_format") 
  }
  /// 1 room
  public static var groupHomeOneRoomFormat: String { 
    return VectorL10n.tr("Vector", "group_home_one_room_format") 
  }
  /// %@ has invited you to join this community
  public static func groupInvitationFormat(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "group_invitation_format", p1)
  }
  /// INVITES
  public static var groupInviteSection: String { 
    return VectorL10n.tr("Vector", "group_invite_section") 
  }
  /// Add participant
  public static var groupParticipantsAddParticipant: String { 
    return VectorL10n.tr("Vector", "group_participants_add_participant") 
  }
  /// Filter community members
  public static var groupParticipantsFilterMembers: String { 
    return VectorL10n.tr("Vector", "group_participants_filter_members") 
  }
  /// Search / invite by User ID or Name
  public static var groupParticipantsInviteAnotherUser: String { 
    return VectorL10n.tr("Vector", "group_participants_invite_another_user") 
  }
  /// Malformed ID. Should be a Matrix ID like '@localpart:domain'
  public static var groupParticipantsInviteMalformedId: String { 
    return VectorL10n.tr("Vector", "group_participants_invite_malformed_id") 
  }
  /// Invite Error
  public static var groupParticipantsInviteMalformedIdTitle: String { 
    return VectorL10n.tr("Vector", "group_participants_invite_malformed_id_title") 
  }
  /// Are you sure you want to invite %@ to this group?
  public static func groupParticipantsInvitePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "group_participants_invite_prompt_msg", p1)
  }
  /// Confirmation
  public static var groupParticipantsInvitePromptTitle: String { 
    return VectorL10n.tr("Vector", "group_participants_invite_prompt_title") 
  }
  /// INVITED
  public static var groupParticipantsInvitedSection: String { 
    return VectorL10n.tr("Vector", "group_participants_invited_section") 
  }
  /// Are you sure you want to leave the group?
  public static var groupParticipantsLeavePromptMsg: String { 
    return VectorL10n.tr("Vector", "group_participants_leave_prompt_msg") 
  }
  /// Leave group
  public static var groupParticipantsLeavePromptTitle: String { 
    return VectorL10n.tr("Vector", "group_participants_leave_prompt_title") 
  }
  /// Are you sure you want to remove %@ from this group?
  public static func groupParticipantsRemovePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "group_participants_remove_prompt_msg", p1)
  }
  /// Confirmation
  public static var groupParticipantsRemovePromptTitle: String { 
    return VectorL10n.tr("Vector", "group_participants_remove_prompt_title") 
  }
  /// Filter community rooms
  public static var groupRoomsFilterRooms: String { 
    return VectorL10n.tr("Vector", "group_rooms_filter_rooms") 
  }
  /// COMMUNITIES
  public static var groupSection: String { 
    return VectorL10n.tr("Vector", "group_section") 
  }
  /// The all-in-one secure chat app for teams, friends and organisations. Tap the + button below to add people and rooms.
  public static var homeEmptyViewInformation: String { 
    return VectorL10n.tr("Vector", "home_empty_view_information") 
  }
  /// Welcome to %@,\n%@
  public static func homeEmptyViewTitle(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "home_empty_view_title", p1, p2)
  }
  /// Could not connect to the homeserver.
  public static var homeserverConnectionLost: String { 
    return VectorL10n.tr("Vector", "homeserver_connection_lost") 
  }
  /// Add
  public static var identityServerSettingsAdd: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_add") 
  }
  /// Disconnect from the identity server %1$@ and connect to %2$@ instead?
  public static func identityServerSettingsAlertChange(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "identity_server_settings_alert_change", p1, p2)
  }
  /// Change identity server
  public static var identityServerSettingsAlertChangeTitle: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_alert_change_title") 
  }
  /// Disconnect from the identity server %@?
  public static func identityServerSettingsAlertDisconnect(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "identity_server_settings_alert_disconnect", p1)
  }
  /// Disconnect
  public static var identityServerSettingsAlertDisconnectButton: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_alert_disconnect_button") 
  }
  /// You are still sharing your personal data on the identity server %@.\n\nWe recommend that you remove your email addresses and phone numbers from the identity server before disconnecting.
  public static func identityServerSettingsAlertDisconnectStillSharing3pid(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "identity_server_settings_alert_disconnect_still_sharing_3pid", p1)
  }
  /// Disconnect anyway
  public static var identityServerSettingsAlertDisconnectStillSharing3pidButton: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_alert_disconnect_still_sharing_3pid_button") 
  }
  /// Disconnect identity server
  public static var identityServerSettingsAlertDisconnectTitle: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_alert_disconnect_title") 
  }
  /// %@ is not a valid identity server.
  public static func identityServerSettingsAlertErrorInvalidIdentityServer(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "identity_server_settings_alert_error_invalid_identity_server", p1)
  }
  /// You must accept terms of %@ to set it as identity server.
  public static func identityServerSettingsAlertErrorTermsNotAccepted(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "identity_server_settings_alert_error_terms_not_accepted", p1)
  }
  /// The identity server you have chosen does not have any terms of service. Only continue if you trust the owner of the server.
  public static var identityServerSettingsAlertNoTerms: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_alert_no_terms") 
  }
  /// Identity server has no terms of services
  public static var identityServerSettingsAlertNoTermsTitle: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_alert_no_terms_title") 
  }
  /// Change
  public static var identityServerSettingsChange: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_change") 
  }
  /// You are currently using %@ to discover and be discoverable by existing contacts you know.
  public static func identityServerSettingsDescription(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "identity_server_settings_description", p1)
  }
  /// Disconnect
  public static var identityServerSettingsDisconnect: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_disconnect") 
  }
  /// Disconnecting from your identity server will mean you won’t be discoverable by other users and be able to invite others by email or phone.
  public static var identityServerSettingsDisconnectInfo: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_disconnect_info") 
  }
  /// You are not currently using an identity server. To discover and be discoverable by existing contacts, add one above.
  public static var identityServerSettingsNoIsDescription: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_no_is_description") 
  }
  /// Enter an identity server
  public static var identityServerSettingsPlaceHolder: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_place_holder") 
  }
  /// Identity server
  public static var identityServerSettingsTitle: String { 
    return VectorL10n.tr("Vector", "identity_server_settings_title") 
  }
  /// Take photo
  public static var imagePickerActionCamera: String { 
    return VectorL10n.tr("Vector", "image_picker_action_camera") 
  }
  /// Choose from library
  public static var imagePickerActionLibrary: String { 
    return VectorL10n.tr("Vector", "image_picker_action_library") 
  }
  /// Invite
  public static var invite: String { 
    return VectorL10n.tr("Vector", "invite") 
  }
  /// Invite friends to %@
  public static func inviteFriendsAction(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "invite_friends_action", p1)
  }
  /// Hey, talk to me on %@: %@
  public static func inviteFriendsShareText(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "invite_friends_share_text", p1, p2)
  }
  /// Join
  public static var join: String { 
    return VectorL10n.tr("Vector", "join") 
  }
  /// Joined
  public static var joined: String { 
    return VectorL10n.tr("Vector", "joined") 
  }
  /// Done
  public static var keyBackupRecoverDoneAction: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_done_action") 
  }
  /// Use your Security Phrase to unlock your secure message history
  public static var keyBackupRecoverFromPassphraseInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_info") 
  }
  /// Don’t know your Security Phrase? You can 
  public static var keyBackupRecoverFromPassphraseLostPassphraseActionPart1: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_lost_passphrase_action_part1") 
  }
  /// use your Security Key
  public static var keyBackupRecoverFromPassphraseLostPassphraseActionPart2: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_lost_passphrase_action_part2") 
  }
  /// .
  public static var keyBackupRecoverFromPassphraseLostPassphraseActionPart3: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_lost_passphrase_action_part3") 
  }
  /// Enter Phrase
  public static var keyBackupRecoverFromPassphrasePassphrasePlaceholder: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_passphrase_placeholder") 
  }
  /// Enter
  public static var keyBackupRecoverFromPassphrasePassphraseTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_passphrase_title") 
  }
  /// Unlock History
  public static var keyBackupRecoverFromPassphraseRecoverAction: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_passphrase_recover_action") 
  }
  /// Restoring backup…
  public static var keyBackupRecoverFromPrivateKeyInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_private_key_info") 
  }
  /// Use your Security Key to unlock your secure message history
  public static var keyBackupRecoverFromRecoveryKeyInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_recovery_key_info") 
  }
  /// Lost your Security Key You can set up a new one in settings.
  public static var keyBackupRecoverFromRecoveryKeyLostRecoveryKeyAction: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_recovery_key_lost_recovery_key_action") 
  }
  /// Unlock History
  public static var keyBackupRecoverFromRecoveryKeyRecoverAction: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_recovery_key_recover_action") 
  }
  /// Enter Security Key
  public static var keyBackupRecoverFromRecoveryKeyRecoveryKeyPlaceholder: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_recovery_key_recovery_key_placeholder") 
  }
  /// Enter
  public static var keyBackupRecoverFromRecoveryKeyRecoveryKeyTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_from_recovery_key_recovery_key_title") 
  }
  /// Backup could not be decrypted with this phrase: please verify that you entered the correct Security Phrase.
  public static var keyBackupRecoverInvalidPassphrase: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_invalid_passphrase") 
  }
  /// Incorrect Security Phrase
  public static var keyBackupRecoverInvalidPassphraseTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_invalid_passphrase_title") 
  }
  /// Backup could not be decrypted with this key: please verify that you entered the correct Security Key.
  public static var keyBackupRecoverInvalidRecoveryKey: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_invalid_recovery_key") 
  }
  /// Security Key Mismatch
  public static var keyBackupRecoverInvalidRecoveryKeyTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_invalid_recovery_key_title") 
  }
  /// Backup Restored!
  public static var keyBackupRecoverSuccessInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_success_info") 
  }
  /// Secure Messages
  public static var keyBackupRecoverTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_recover_title") 
  }
  /// Messages in encrypted rooms are secured with end-to-end encryption. Only you and the recipient(s) have the keys to read these messages.\n\nSecurely back up your keys to avoid losing them.
  public static var keyBackupSetupIntroInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_intro_info") 
  }
  /// Manually export keys
  public static var keyBackupSetupIntroManualExportAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_intro_manual_export_action") 
  }
  /// (Advanced)
  public static var keyBackupSetupIntroManualExportInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_intro_manual_export_info") 
  }
  /// Start using Key Backup
  public static var keyBackupSetupIntroSetupActionWithoutExistingBackup: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_intro_setup_action_without_existing_backup") 
  }
  /// Connect this device to Key Backup
  public static var keyBackupSetupIntroSetupConnectActionWithExistingBackup: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_intro_setup_connect_action_with_existing_backup") 
  }
  /// Never lose encrypted messages
  public static var keyBackupSetupIntroTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_intro_title") 
  }
  /// Phrase doesn’t match
  public static var keyBackupSetupPassphraseConfirmPassphraseInvalid: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_confirm_passphrase_invalid") 
  }
  /// Confirm phrase
  public static var keyBackupSetupPassphraseConfirmPassphrasePlaceholder: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_confirm_passphrase_placeholder") 
  }
  /// Confirm
  public static var keyBackupSetupPassphraseConfirmPassphraseTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_confirm_passphrase_title") 
  }
  /// Great!
  public static var keyBackupSetupPassphraseConfirmPassphraseValid: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_confirm_passphrase_valid") 
  }
  /// We'll store an encrypted copy of your keys on our server. Protect your backup with a phrase to keep it secure.\n\nFor maximum security, this should be different from your account password.
  public static var keyBackupSetupPassphraseInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_info") 
  }
  /// Try adding a word
  public static var keyBackupSetupPassphrasePassphraseInvalid: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_passphrase_invalid") 
  }
  /// Enter phrase
  public static var keyBackupSetupPassphrasePassphrasePlaceholder: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_passphrase_placeholder") 
  }
  /// Enter
  public static var keyBackupSetupPassphrasePassphraseTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_passphrase_title") 
  }
  /// Great!
  public static var keyBackupSetupPassphrasePassphraseValid: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_passphrase_valid") 
  }
  /// Set Phrase
  public static var keyBackupSetupPassphraseSetPassphraseAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_set_passphrase_action") 
  }
  /// (Advanced) Set up with Security Key
  public static var keyBackupSetupPassphraseSetupRecoveryKeyAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_setup_recovery_key_action") 
  }
  /// Or, secure your backup with a Security Key, saving it somewhere safe.
  public static var keyBackupSetupPassphraseSetupRecoveryKeyInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_setup_recovery_key_info") 
  }
  /// Secure your backup with a Security Phrase
  public static var keyBackupSetupPassphraseTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_passphrase_title") 
  }
  /// You may lose secure messages if you log out or lose your device.
  public static var keyBackupSetupSkipAlertMessage: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_skip_alert_message") 
  }
  /// Skip
  public static var keyBackupSetupSkipAlertSkipAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_skip_alert_skip_action") 
  }
  /// Are you sure?
  public static var keyBackupSetupSkipAlertTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_skip_alert_title") 
  }
  /// Done
  public static var keyBackupSetupSuccessFromPassphraseDoneAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_passphrase_done_action") 
  }
  /// Your keys are being backed up.\n\nYour Security Key is a safety net - you can use it to restore access to your encrypted messages if you forget your passphrase.\n\nKeep your Security Key somewhere very secure, like a password manager (or a safe).
  public static var keyBackupSetupSuccessFromPassphraseInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_passphrase_info") 
  }
  /// Save Security Key
  public static var keyBackupSetupSuccessFromPassphraseSaveRecoveryKeyAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_passphrase_save_recovery_key_action") 
  }
  /// Your keys are being backed up.\n\nMake a copy of this Security Key and keep it safe.
  public static var keyBackupSetupSuccessFromRecoveryKeyInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_recovery_key_info") 
  }
  /// I've made a copy
  public static var keyBackupSetupSuccessFromRecoveryKeyMadeCopyAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_recovery_key_made_copy_action") 
  }
  /// Make a Copy
  public static var keyBackupSetupSuccessFromRecoveryKeyMakeCopyAction: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_recovery_key_make_copy_action") 
  }
  /// Security Key
  public static var keyBackupSetupSuccessFromRecoveryKeyRecoveryKeyTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_recovery_key_recovery_key_title") 
  }
  /// Your keys are being backed up.
  public static var keyBackupSetupSuccessFromSecureBackupInfo: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_from_secure_backup_info") 
  }
  /// Success!
  public static var keyBackupSetupSuccessTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_success_title") 
  }
  /// Key Backup
  public static var keyBackupSetupTitle: String { 
    return VectorL10n.tr("Vector", "key_backup_setup_title") 
  }
  /// You need to bootstrap cross-signing first.
  public static var keyVerificationBootstrapNotSetupMessage: String { 
    return VectorL10n.tr("Vector", "key_verification_bootstrap_not_setup_message") 
  }
  /// Error
  public static var keyVerificationBootstrapNotSetupTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_bootstrap_not_setup_title") 
  }
  /// %@ wants to verify
  public static func keyVerificationIncomingRequestIncomingAlertMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "key_verification_incoming_request_incoming_alert_message", p1)
  }
  /// If they don't match, the security of your communication may be compromised.
  public static var keyVerificationManuallyVerifyDeviceAdditionalInformation: String { 
    return VectorL10n.tr("Vector", "key_verification_manually_verify_device_additional_information") 
  }
  /// Session ID
  public static var keyVerificationManuallyVerifyDeviceIdTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_manually_verify_device_id_title") 
  }
  /// Confirm by comparing the following with the User Settings in your other session:
  public static var keyVerificationManuallyVerifyDeviceInstruction: String { 
    return VectorL10n.tr("Vector", "key_verification_manually_verify_device_instruction") 
  }
  /// Session key
  public static var keyVerificationManuallyVerifyDeviceKeyTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_manually_verify_device_key_title") 
  }
  /// Session name
  public static var keyVerificationManuallyVerifyDeviceNameTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_manually_verify_device_name_title") 
  }
  /// Manually Verify by Text
  public static var keyVerificationManuallyVerifyDeviceTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_manually_verify_device_title") 
  }
  /// Verify
  public static var keyVerificationManuallyVerifyDeviceValidateAction: String { 
    return VectorL10n.tr("Vector", "key_verification_manually_verify_device_validate_action") 
  }
  /// Verify your new session
  public static var keyVerificationNewSessionTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_new_session_title") 
  }
  /// Verify session
  public static var keyVerificationOtherSessionTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_other_session_title") 
  }
  /// Is the other device showing the same shield?
  public static var keyVerificationScanConfirmationScannedDeviceInformation: String { 
    return VectorL10n.tr("Vector", "key_verification_scan_confirmation_scanned_device_information") 
  }
  /// Almost there!
  public static var keyVerificationScanConfirmationScannedTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_scan_confirmation_scanned_title") 
  }
  /// Is %@ showing the same shield?
  public static func keyVerificationScanConfirmationScannedUserInformation(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "key_verification_scan_confirmation_scanned_user_information", p1)
  }
  /// Waiting for other device…
  public static var keyVerificationScanConfirmationScanningDeviceWaitingOther: String { 
    return VectorL10n.tr("Vector", "key_verification_scan_confirmation_scanning_device_waiting_other") 
  }
  /// Almost there! Waiting for confirmation…
  public static var keyVerificationScanConfirmationScanningTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_scan_confirmation_scanning_title") 
  }
  /// Waiting for %@…
  public static func keyVerificationScanConfirmationScanningUserWaitingOther(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "key_verification_scan_confirmation_scanning_user_waiting_other", p1)
  }
  /// Other users may not trust it.
  public static var keyVerificationSelfVerifyCurrentSessionAlertMessage: String { 
    return VectorL10n.tr("Vector", "key_verification_self_verify_current_session_alert_message") 
  }
  /// Verify this session
  public static var keyVerificationSelfVerifyCurrentSessionAlertTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_self_verify_current_session_alert_title") 
  }
  /// Verify
  public static var keyVerificationSelfVerifyCurrentSessionAlertValidateAction: String { 
    return VectorL10n.tr("Vector", "key_verification_self_verify_current_session_alert_validate_action") 
  }
  /// Verify all your sessions to ensure your account & messages are safe.
  public static var keyVerificationSelfVerifyUnverifiedSessionsAlertMessage: String { 
    return VectorL10n.tr("Vector", "key_verification_self_verify_unverified_sessions_alert_message") 
  }
  /// Review where you're logged in
  public static var keyVerificationSelfVerifyUnverifiedSessionsAlertTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_self_verify_unverified_sessions_alert_title") 
  }
  /// Review
  public static var keyVerificationSelfVerifyUnverifiedSessionsAlertValidateAction: String { 
    return VectorL10n.tr("Vector", "key_verification_self_verify_unverified_sessions_alert_validate_action") 
  }
  /// Verify this session
  public static var keyVerificationThisSessionTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_this_session_title") 
  }
  /// Verified
  public static var keyVerificationTileConclusionDoneTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_tile_conclusion_done_title") 
  }
  /// Unstrusted sign in
  public static var keyVerificationTileConclusionWarningTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_tile_conclusion_warning_title") 
  }
  /// Accept
  public static var keyVerificationTileRequestIncomingApprovalAccept: String { 
    return VectorL10n.tr("Vector", "key_verification_tile_request_incoming_approval_accept") 
  }
  /// Decline
  public static var keyVerificationTileRequestIncomingApprovalDecline: String { 
    return VectorL10n.tr("Vector", "key_verification_tile_request_incoming_approval_decline") 
  }
  /// Verification request
  public static var keyVerificationTileRequestIncomingTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_tile_request_incoming_title") 
  }
  /// Verification sent
  public static var keyVerificationTileRequestOutgoingTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_tile_request_outgoing_title") 
  }
  /// You accepted
  public static var keyVerificationTileRequestStatusAccepted: String { 
    return VectorL10n.tr("Vector", "key_verification_tile_request_status_accepted") 
  }
  /// %@ cancelled
  public static func keyVerificationTileRequestStatusCancelled(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "key_verification_tile_request_status_cancelled", p1)
  }
  /// You cancelled
  public static var keyVerificationTileRequestStatusCancelledByMe: String { 
    return VectorL10n.tr("Vector", "key_verification_tile_request_status_cancelled_by_me") 
  }
  /// Data loading…
  public static var keyVerificationTileRequestStatusDataLoading: String { 
    return VectorL10n.tr("Vector", "key_verification_tile_request_status_data_loading") 
  }
  /// Expired
  public static var keyVerificationTileRequestStatusExpired: String { 
    return VectorL10n.tr("Vector", "key_verification_tile_request_status_expired") 
  }
  /// Waiting…
  public static var keyVerificationTileRequestStatusWaiting: String { 
    return VectorL10n.tr("Vector", "key_verification_tile_request_status_waiting") 
  }
  /// Verify them
  public static var keyVerificationUserTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_user_title") 
  }
  /// You can now read secure messages on your new device, and other users will know they can trust it.
  public static var keyVerificationVerifiedNewSessionInformation: String { 
    return VectorL10n.tr("Vector", "key_verification_verified_new_session_information") 
  }
  /// New session verified!
  public static var keyVerificationVerifiedNewSessionTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_verified_new_session_title") 
  }
  /// You can now read secure messages on your other session, and other users will know they can trust it.
  public static var keyVerificationVerifiedOtherSessionInformation: String { 
    return VectorL10n.tr("Vector", "key_verification_verified_other_session_information") 
  }
  /// You can now read secure messages on this device, and other users will know they can trust it.
  public static var keyVerificationVerifiedThisSessionInformation: String { 
    return VectorL10n.tr("Vector", "key_verification_verified_this_session_information") 
  }
  /// Messages with this user are end-to-end encrypted and can't be read by third parties.
  public static var keyVerificationVerifiedUserInformation: String { 
    return VectorL10n.tr("Vector", "key_verification_verified_user_information") 
  }
  /// Can't scan?
  public static var keyVerificationVerifyQrCodeCannotScanAction: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_qr_code_cannot_scan_action") 
  }
  /// Verify by comparing unique emoji.
  public static var keyVerificationVerifyQrCodeEmojiInformation: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_qr_code_emoji_information") 
  }
  /// Scan the code to securely verify each other.
  public static var keyVerificationVerifyQrCodeInformation: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_qr_code_information") 
  }
  /// Scan the code below to verify:
  public static var keyVerificationVerifyQrCodeInformationOtherDevice: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_qr_code_information_other_device") 
  }
  /// Did the other user successfully scan the QR code?
  public static var keyVerificationVerifyQrCodeOtherScanMyCodeTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_qr_code_other_scan_my_code_title") 
  }
  /// Scan their code
  public static var keyVerificationVerifyQrCodeScanCodeAction: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_qr_code_scan_code_action") 
  }
  /// Scan with this device
  public static var keyVerificationVerifyQrCodeScanCodeOtherDeviceAction: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_qr_code_scan_code_other_device_action") 
  }
  /// QR code has been successfully validated.
  public static var keyVerificationVerifyQrCodeScanOtherCodeSuccessMessage: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_qr_code_scan_other_code_success_message") 
  }
  /// Code validated!
  public static var keyVerificationVerifyQrCodeScanOtherCodeSuccessTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_qr_code_scan_other_code_success_title") 
  }
  /// Verify by emoji
  public static var keyVerificationVerifyQrCodeStartEmojiAction: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_qr_code_start_emoji_action") 
  }
  /// Verify by scanning
  public static var keyVerificationVerifyQrCodeTitle: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_qr_code_title") 
  }
  /// For ultimate security, use another trusted means of communication or do this in person.
  public static var keyVerificationVerifySasAdditionalInformation: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_sas_additional_information") 
  }
  /// They don't match
  public static var keyVerificationVerifySasCancelAction: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_sas_cancel_action") 
  }
  /// Compare emoji
  public static var keyVerificationVerifySasTitleEmoji: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_sas_title_emoji") 
  }
  /// Compare numbers
  public static var keyVerificationVerifySasTitleNumber: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_sas_title_number") 
  }
  /// They match
  public static var keyVerificationVerifySasValidateAction: String { 
    return VectorL10n.tr("Vector", "key_verification_verify_sas_validate_action") 
  }
  /// %.1fK
  public static func largeBadgeValueKFormat(_ p1: Float) -> String {
    return VectorL10n.tr("Vector", "large_badge_value_k_format", p1)
  }
  /// Later
  public static var later: String { 
    return VectorL10n.tr("Vector", "later") 
  }
  /// Leave
  public static var leave: String { 
    return VectorL10n.tr("Vector", "leave") 
  }
  /// Leave all rooms and spaces
  public static var leaveSpaceAndAllRoomsAction: String { 
    return VectorL10n.tr("Vector", "leave_space_and_all_rooms_action") 
  }
  /// Are you sure you want to leave %@? Do you also want to leave all rooms and spaces of this space?
  public static func leaveSpaceMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "leave_space_message", p1)
  }
  /// You are admin of this space, ensure that you have transferred admin right to another member before leaving.
  public static var leaveSpaceMessageAdminWarning: String { 
    return VectorL10n.tr("Vector", "leave_space_message_admin_warning") 
  }
  /// Don't leave any rooms
  public static var leaveSpaceOnlyAction: String { 
    return VectorL10n.tr("Vector", "leave_space_only_action") 
  }
  /// Leave %@
  public static func leaveSpaceTitle(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "leave_space_title", p1)
  }
  /// Less
  public static var less: String { 
    return VectorL10n.tr("Vector", "less") 
  }
  /// Close
  public static var locationSharingCloseAction: String { 
    return VectorL10n.tr("Vector", "location_sharing_close_action") 
  }
  /// %@ does not have permission to access your location. You can enable access in Settings > Location
  public static func locationSharingInvalidAuthorizationErrorTitle(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "location_sharing_invalid_authorization_error_title", p1)
  }
  /// Not now
  public static var locationSharingInvalidAuthorizationNotNow: String { 
    return VectorL10n.tr("Vector", "location_sharing_invalid_authorization_not_now") 
  }
  /// Settings
  public static var locationSharingInvalidAuthorizationSettings: String { 
    return VectorL10n.tr("Vector", "location_sharing_invalid_authorization_settings") 
  }
  /// %@ could not load the map. Please try again later.
  public static func locationSharingLoadingMapErrorTitle(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "location_sharing_loading_map_error_title", p1)
  }
  /// %@ could not access your location. Please try again later.
  public static func locationSharingLocatingUserErrorTitle(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "location_sharing_locating_user_error_title", p1)
  }
  /// Open in Apple Maps
  public static var locationSharingOpenAppleMaps: String { 
    return VectorL10n.tr("Vector", "location_sharing_open_apple_maps") 
  }
  /// Open in Google Maps
  public static var locationSharingOpenGoogleMaps: String { 
    return VectorL10n.tr("Vector", "location_sharing_open_google_maps") 
  }
  /// Location sharing
  public static var locationSharingSettingsHeader: String { 
    return VectorL10n.tr("Vector", "location_sharing_settings_header") 
  }
  /// Enable location sharing
  public static var locationSharingSettingsToggleTitle: String { 
    return VectorL10n.tr("Vector", "location_sharing_settings_toggle_title") 
  }
  /// Share
  public static var locationSharingShareAction: String { 
    return VectorL10n.tr("Vector", "location_sharing_share_action") 
  }
  /// Location
  public static var locationSharingTitle: String { 
    return VectorL10n.tr("Vector", "location_sharing_title") 
  }
  /// Got it
  public static var majorUpdateDoneAction: String { 
    return VectorL10n.tr("Vector", "major_update_done_action") 
  }
  /// We're excited to announce we've changed name! Your app is up to date and you're signed in to your account.
  public static var majorUpdateInformation: String { 
    return VectorL10n.tr("Vector", "major_update_information") 
  }
  /// Learn more
  public static var majorUpdateLearnMoreAction: String { 
    return VectorL10n.tr("Vector", "major_update_learn_more_action") 
  }
  /// Riot is now %@
  public static func majorUpdateTitle(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "major_update_title", p1)
  }
  /// SESSION INFO
  public static var manageSessionInfo: String { 
    return VectorL10n.tr("Vector", "manage_session_info") 
  }
  /// Session name
  public static var manageSessionName: String { 
    return VectorL10n.tr("Vector", "manage_session_name") 
  }
  /// Not trusted
  public static var manageSessionNotTrusted: String { 
    return VectorL10n.tr("Vector", "manage_session_not_trusted") 
  }
  /// Sign out of this session
  public static var manageSessionSignOut: String { 
    return VectorL10n.tr("Vector", "manage_session_sign_out") 
  }
  /// Manage session
  public static var manageSessionTitle: String { 
    return VectorL10n.tr("Vector", "manage_session_title") 
  }
  /// Trusted by you
  public static var manageSessionTrusted: String { 
    return VectorL10n.tr("Vector", "manage_session_trusted") 
  }
  /// Library
  public static var mediaPickerLibrary: String { 
    return VectorL10n.tr("Vector", "media_picker_library") 
  }
  /// Select
  public static var mediaPickerSelect: String { 
    return VectorL10n.tr("Vector", "media_picker_select") 
  }
  /// Media library
  public static var mediaPickerTitle: String { 
    return VectorL10n.tr("Vector", "media_picker_title") 
  }
  /// Audio
  public static var mediaTypeAccessibilityAudio: String { 
    return VectorL10n.tr("Vector", "media_type_accessibility_audio") 
  }
  /// File
  public static var mediaTypeAccessibilityFile: String { 
    return VectorL10n.tr("Vector", "media_type_accessibility_file") 
  }
  /// Image
  public static var mediaTypeAccessibilityImage: String { 
    return VectorL10n.tr("Vector", "media_type_accessibility_image") 
  }
  /// Location
  public static var mediaTypeAccessibilityLocation: String { 
    return VectorL10n.tr("Vector", "media_type_accessibility_location") 
  }
  /// Sticker
  public static var mediaTypeAccessibilitySticker: String { 
    return VectorL10n.tr("Vector", "media_type_accessibility_sticker") 
  }
  /// Video
  public static var mediaTypeAccessibilityVideo: String { 
    return VectorL10n.tr("Vector", "media_type_accessibility_video") 
  }
  /// More
  public static var more: String { 
    return VectorL10n.tr("Vector", "more") 
  }
  /// The Internet connection appears to be offline.
  public static var networkOfflinePrompt: String { 
    return VectorL10n.tr("Vector", "network_offline_prompt") 
  }
  /// Next
  public static var next: String { 
    return VectorL10n.tr("Vector", "next") 
  }
  /// %@ is calling you but %@ does not support calls yet.\nYou can ignore this notification and answer the call from another device or you can reject it.
  public static func noVoip(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "no_voip", p1, p2)
  }
  /// Incoming call
  public static var noVoipTitle: String { 
    return VectorL10n.tr("Vector", "no_voip_title") 
  }
  /// Off
  public static var off: String { 
    return VectorL10n.tr("Vector", "off") 
  }
  /// OK
  public static var ok: String { 
    return VectorL10n.tr("Vector", "ok") 
  }
  /// On
  public static var on: String { 
    return VectorL10n.tr("Vector", "on") 
  }
  /// I already have an account
  public static var onboardingSplashLoginButtonTitle: String { 
    return VectorL10n.tr("Vector", "onboarding_splash_login_button_title") 
  }
  /// Secure and independent communication that gives you the same level of privacy as a face-to-face conversation in your own home.
  public static var onboardingSplashPage1Message: String { 
    return VectorL10n.tr("Vector", "onboarding_splash_page_1_message") 
  }
  /// Own your conversations.
  public static var onboardingSplashPage1Title: String { 
    return VectorL10n.tr("Vector", "onboarding_splash_page_1_title") 
  }
  /// Choose where your conversations are kept, giving you control and independence. Connected via Matrix.
  public static var onboardingSplashPage2Message: String { 
    return VectorL10n.tr("Vector", "onboarding_splash_page_2_message") 
  }
  /// You’re in control.
  public static var onboardingSplashPage2Title: String { 
    return VectorL10n.tr("Vector", "onboarding_splash_page_2_title") 
  }
  /// End-to-end encrypted and no phone number required. No ads or datamining.
  public static var onboardingSplashPage3Message: String { 
    return VectorL10n.tr("Vector", "onboarding_splash_page_3_message") 
  }
  /// Secure messaging.
  public static var onboardingSplashPage3Title: String { 
    return VectorL10n.tr("Vector", "onboarding_splash_page_3_title") 
  }
  /// Element is also great for the workplace. It’s trusted by the world’s most secure organisations.
  public static var onboardingSplashPage4Message: String { 
    return VectorL10n.tr("Vector", "onboarding_splash_page_4_message") 
  }
  /// Messaging for your team.
  public static var onboardingSplashPage4TitleNoPun: String { 
    return VectorL10n.tr("Vector", "onboarding_splash_page_4_title_no_pun") 
  }
  /// Create account
  public static var onboardingSplashRegisterButtonTitle: String { 
    return VectorL10n.tr("Vector", "onboarding_splash_register_button_title") 
  }
  /// Open
  public static var `open`: String { 
    return VectorL10n.tr("Vector", "open") 
  }
  /// or
  public static var or: String { 
    return VectorL10n.tr("Vector", "or") 
  }
  /// CONVERSATIONS
  public static var peopleConversationSection: String { 
    return VectorL10n.tr("Vector", "people_conversation_section") 
  }
  /// Chat securely with anyone.\nTap the + to start adding people.
  public static var peopleEmptyViewInformation: String { 
    return VectorL10n.tr("Vector", "people_empty_view_information") 
  }
  /// People
  public static var peopleEmptyViewTitle: String { 
    return VectorL10n.tr("Vector", "people_empty_view_title") 
  }
  /// INVITES
  public static var peopleInvitesSection: String { 
    return VectorL10n.tr("Vector", "people_invites_section") 
  }
  /// No conversations
  public static var peopleNoConversation: String { 
    return VectorL10n.tr("Vector", "people_no_conversation") 
  }
  /// %@ doesn't have permission to access photo library, please change privacy settings
  public static func photoLibraryAccessNotGranted(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "photo_library_access_not_granted", p1)
  }
  /// Create a PIN for security
  public static var pinProtectionChoosePin: String { 
    return VectorL10n.tr("Vector", "pin_protection_choose_pin") 
  }
  /// Welcome back.
  public static var pinProtectionChoosePinWelcomeAfterLogin: String { 
    return VectorL10n.tr("Vector", "pin_protection_choose_pin_welcome_after_login") 
  }
  /// Welcome.
  public static var pinProtectionChoosePinWelcomeAfterRegister: String { 
    return VectorL10n.tr("Vector", "pin_protection_choose_pin_welcome_after_register") 
  }
  /// Confirm your PIN
  public static var pinProtectionConfirmPin: String { 
    return VectorL10n.tr("Vector", "pin_protection_confirm_pin") 
  }
  /// Confirm PIN to change PIN
  public static var pinProtectionConfirmPinToChange: String { 
    return VectorL10n.tr("Vector", "pin_protection_confirm_pin_to_change") 
  }
  /// Confirm PIN to disable PIN
  public static var pinProtectionConfirmPinToDisable: String { 
    return VectorL10n.tr("Vector", "pin_protection_confirm_pin_to_disable") 
  }
  /// Enter your PIN
  public static var pinProtectionEnterPin: String { 
    return VectorL10n.tr("Vector", "pin_protection_enter_pin") 
  }
  /// Setting up a PIN lets you protect data like messages and contacts, so only you can access them by entering the PIN at the start of the app.
  public static var pinProtectionExplanatory: String { 
    return VectorL10n.tr("Vector", "pin_protection_explanatory") 
  }
  /// Forgot PIN
  public static var pinProtectionForgotPin: String { 
    return VectorL10n.tr("Vector", "pin_protection_forgot_pin") 
  }
  /// Too many errors, you've been logged out
  public static var pinProtectionKickUserAlertMessage: String { 
    return VectorL10n.tr("Vector", "pin_protection_kick_user_alert_message") 
  }
  /// Please try again
  public static var pinProtectionMismatchErrorMessage: String { 
    return VectorL10n.tr("Vector", "pin_protection_mismatch_error_message") 
  }
  /// PINs don't match
  public static var pinProtectionMismatchErrorTitle: String { 
    return VectorL10n.tr("Vector", "pin_protection_mismatch_error_title") 
  }
  /// If you can't remember your PIN, tap the forgot PIN button.
  public static var pinProtectionMismatchTooManyTimesErrorMessage: String { 
    return VectorL10n.tr("Vector", "pin_protection_mismatch_too_many_times_error_message") 
  }
  /// For security reasons, this PIN isn’t available. Please try another PIN
  public static var pinProtectionNotAllowedPin: String { 
    return VectorL10n.tr("Vector", "pin_protection_not_allowed_pin") 
  }
  /// Reset
  public static var pinProtectionResetAlertActionReset: String { 
    return VectorL10n.tr("Vector", "pin_protection_reset_alert_action_reset") 
  }
  /// To reset your PIN, you'll need to re-login and create a new one
  public static var pinProtectionResetAlertMessage: String { 
    return VectorL10n.tr("Vector", "pin_protection_reset_alert_message") 
  }
  /// Reset PIN
  public static var pinProtectionResetAlertTitle: String { 
    return VectorL10n.tr("Vector", "pin_protection_reset_alert_title") 
  }
  /// Change PIN
  public static var pinProtectionSettingsChangePin: String { 
    return VectorL10n.tr("Vector", "pin_protection_settings_change_pin") 
  }
  /// Enable PIN
  public static var pinProtectionSettingsEnablePin: String { 
    return VectorL10n.tr("Vector", "pin_protection_settings_enable_pin") 
  }
  /// PIN enabled
  public static var pinProtectionSettingsEnabledForced: String { 
    return VectorL10n.tr("Vector", "pin_protection_settings_enabled_forced") 
  }
  /// To reset your PIN, you'll need to re-login and create a new one.
  public static var pinProtectionSettingsSectionFooter: String { 
    return VectorL10n.tr("Vector", "pin_protection_settings_section_footer") 
  }
  /// PIN
  public static var pinProtectionSettingsSectionHeader: String { 
    return VectorL10n.tr("Vector", "pin_protection_settings_section_header") 
  }
  /// PIN & %@
  public static func pinProtectionSettingsSectionHeaderWithBiometrics(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "pin_protection_settings_section_header_with_biometrics", p1)
  }
  /// Add option
  public static var pollEditFormAddOption: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_add_option") 
  }
  /// Create options
  public static var pollEditFormCreateOptions: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_create_options") 
  }
  /// Create poll
  public static var pollEditFormCreatePoll: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_create_poll") 
  }
  /// Write something
  public static var pollEditFormInputPlaceholder: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_input_placeholder") 
  }
  /// Option %lu
  public static func pollEditFormOptionNumber(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "poll_edit_form_option_number", p1)
  }
  /// Poll question or topic
  public static var pollEditFormPollQuestionOrTopic: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_poll_question_or_topic") 
  }
  /// Poll type
  public static var pollEditFormPollType: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_poll_type") 
  }
  /// Closed poll
  public static var pollEditFormPollTypeClosed: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_poll_type_closed") 
  }
  /// Results are only revealed when you end the poll
  public static var pollEditFormPollTypeClosedDescription: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_poll_type_closed_description") 
  }
  /// Open poll
  public static var pollEditFormPollTypeOpen: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_poll_type_open") 
  }
  /// Voters see results as soon as they have voted
  public static var pollEditFormPollTypeOpenDescription: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_poll_type_open_description") 
  }
  /// Please try again
  public static var pollEditFormPostFailureSubtitle: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_post_failure_subtitle") 
  }
  /// Failed to post poll
  public static var pollEditFormPostFailureTitle: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_post_failure_title") 
  }
  /// Question or topic
  public static var pollEditFormQuestionOrTopic: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_question_or_topic") 
  }
  /// Please try again
  public static var pollEditFormUpdateFailureSubtitle: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_update_failure_subtitle") 
  }
  /// Failed to update poll
  public static var pollEditFormUpdateFailureTitle: String { 
    return VectorL10n.tr("Vector", "poll_edit_form_update_failure_title") 
  }
  /// Please try again
  public static var pollTimelineNotClosedSubtitle: String { 
    return VectorL10n.tr("Vector", "poll_timeline_not_closed_subtitle") 
  }
  /// Failed to end poll
  public static var pollTimelineNotClosedTitle: String { 
    return VectorL10n.tr("Vector", "poll_timeline_not_closed_title") 
  }
  /// 1 vote
  public static var pollTimelineOneVote: String { 
    return VectorL10n.tr("Vector", "poll_timeline_one_vote") 
  }
  /// Final results based on %lu votes
  public static func pollTimelineTotalFinalResults(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "poll_timeline_total_final_results", p1)
  }
  /// Final results based on 1 vote
  public static var pollTimelineTotalFinalResultsOneVote: String { 
    return VectorL10n.tr("Vector", "poll_timeline_total_final_results_one_vote") 
  }
  /// No votes cast
  public static var pollTimelineTotalNoVotes: String { 
    return VectorL10n.tr("Vector", "poll_timeline_total_no_votes") 
  }
  /// 1 vote cast
  public static var pollTimelineTotalOneVote: String { 
    return VectorL10n.tr("Vector", "poll_timeline_total_one_vote") 
  }
  /// 1 vote cast. Vote to the see the results
  public static var pollTimelineTotalOneVoteNotVoted: String { 
    return VectorL10n.tr("Vector", "poll_timeline_total_one_vote_not_voted") 
  }
  /// %lu votes cast
  public static func pollTimelineTotalVotes(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "poll_timeline_total_votes", p1)
  }
  /// %lu votes cast. Vote to the see the results
  public static func pollTimelineTotalVotesNotVoted(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "poll_timeline_total_votes_not_voted", p1)
  }
  /// Sorry, your vote was not registered, please try again
  public static var pollTimelineVoteNotRegisteredSubtitle: String { 
    return VectorL10n.tr("Vector", "poll_timeline_vote_not_registered_subtitle") 
  }
  /// Vote not registered
  public static var pollTimelineVoteNotRegisteredTitle: String { 
    return VectorL10n.tr("Vector", "poll_timeline_vote_not_registered_title") 
  }
  /// %lu votes
  public static func pollTimelineVotesCount(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "poll_timeline_votes_count", p1)
  }
  /// Preview
  public static var preview: String { 
    return VectorL10n.tr("Vector", "preview") 
  }
  /// Public Rooms (at %@):
  public static func publicRoomSectionTitle(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "public_room_section_title", p1)
  }
  /// You seem to be shaking the phone in frustration. Would you like to submit a bug report?
  public static var rageShakePrompt: String { 
    return VectorL10n.tr("Vector", "rage_shake_prompt") 
  }
  /// Reactions
  public static var reactionHistoryTitle: String { 
    return VectorL10n.tr("Vector", "reaction_history_title") 
  }
  /// Read Receipts List
  public static var readReceiptsList: String { 
    return VectorL10n.tr("Vector", "read_receipts_list") 
  }
  /// Read: 
  public static var receiptStatusRead: String { 
    return VectorL10n.tr("Vector", "receipt_status_read") 
  }
  /// Remove
  public static var remove: String { 
    return VectorL10n.tr("Vector", "remove") 
  }
  /// Rename
  public static var rename: String { 
    return VectorL10n.tr("Vector", "rename") 
  }
  /// Please launch %@ on another device that can decrypt the message so it can send the keys to this session.
  public static func rerequestKeysAlertMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "rerequest_keys_alert_message", p1)
  }
  /// Request Sent
  public static var rerequestKeysAlertTitle: String { 
    return VectorL10n.tr("Vector", "rerequest_keys_alert_title") 
  }
  /// Retry
  public static var retry: String { 
    return VectorL10n.tr("Vector", "retry") 
  }
  /// Call
  public static var roomAccessibilityCall: String { 
    return VectorL10n.tr("Vector", "room_accessibility_call") 
  }
  /// Hang up
  public static var roomAccessibilityHangup: String { 
    return VectorL10n.tr("Vector", "room_accessibility_hangup") 
  }
  /// Integrations
  public static var roomAccessibilityIntegrations: String { 
    return VectorL10n.tr("Vector", "room_accessibility_integrations") 
  }
  /// Search
  public static var roomAccessibilitySearch: String { 
    return VectorL10n.tr("Vector", "room_accessibility_search") 
  }
  /// Upload
  public static var roomAccessibilityUpload: String { 
    return VectorL10n.tr("Vector", "room_accessibility_upload") 
  }
  /// Video Call
  public static var roomAccessibilityVideoCall: String { 
    return VectorL10n.tr("Vector", "room_accessibility_video_call") 
  }
  /// Scroll to bottom
  public static var roomAccessiblityScrollToBottom: String { 
    return VectorL10n.tr("Vector", "room_accessiblity_scroll_to_bottom") 
  }
  /// Take photo or video
  public static var roomActionCamera: String { 
    return VectorL10n.tr("Vector", "room_action_camera") 
  }
  /// Reply
  public static var roomActionReply: String { 
    return VectorL10n.tr("Vector", "room_action_reply") 
  }
  /// Send file
  public static var roomActionSendFile: String { 
    return VectorL10n.tr("Vector", "room_action_send_file") 
  }
  /// Send photo or video
  public static var roomActionSendPhotoOrVideo: String { 
    return VectorL10n.tr("Vector", "room_action_send_photo_or_video") 
  }
  /// Send sticker
  public static var roomActionSendSticker: String { 
    return VectorL10n.tr("Vector", "room_action_send_sticker") 
  }
  /// Change room avatar
  public static var roomAvatarViewAccessibilityHint: String { 
    return VectorL10n.tr("Vector", "room_avatar_view_accessibility_hint") 
  }
  /// avatar
  public static var roomAvatarViewAccessibilityLabel: String { 
    return VectorL10n.tr("Vector", "room_avatar_view_accessibility_label") 
  }
  /// You need permission to manage conference call in this room
  public static var roomConferenceCallNoPower: String { 
    return VectorL10n.tr("Vector", "room_conference_call_no_power") 
  }
  /// Account
  public static var roomCreationAccount: String { 
    return VectorL10n.tr("Vector", "room_creation_account") 
  }
  /// Appearance
  public static var roomCreationAppearance: String { 
    return VectorL10n.tr("Vector", "room_creation_appearance") 
  }
  /// Name
  public static var roomCreationAppearanceName: String { 
    return VectorL10n.tr("Vector", "room_creation_appearance_name") 
  }
  /// Chat picture (optional)
  public static var roomCreationAppearancePicture: String { 
    return VectorL10n.tr("Vector", "room_creation_appearance_picture") 
  }
  /// We couldn't create your DM. Please check the users you want to invite and try again.
  public static var roomCreationDmError: String { 
    return VectorL10n.tr("Vector", "room_creation_dm_error") 
  }
  /// No identity server is configured so you cannot add a participant with an email.
  public static var roomCreationErrorInviteUserByEmailWithoutIdentityServer: String { 
    return VectorL10n.tr("Vector", "room_creation_error_invite_user_by_email_without_identity_server") 
  }
  /// User ID, name or email
  public static var roomCreationInviteAnotherUser: String { 
    return VectorL10n.tr("Vector", "room_creation_invite_another_user") 
  }
  /// Keep private
  public static var roomCreationKeepPrivate: String { 
    return VectorL10n.tr("Vector", "room_creation_keep_private") 
  }
  /// Make private
  public static var roomCreationMakePrivate: String { 
    return VectorL10n.tr("Vector", "room_creation_make_private") 
  }
  /// Make public
  public static var roomCreationMakePublic: String { 
    return VectorL10n.tr("Vector", "room_creation_make_public") 
  }
  /// Are you sure you want to make this chat public? Anyone can read your messages and join the chat.
  public static var roomCreationMakePublicPromptMsg: String { 
    return VectorL10n.tr("Vector", "room_creation_make_public_prompt_msg") 
  }
  /// Make this chat public?
  public static var roomCreationMakePublicPromptTitle: String { 
    return VectorL10n.tr("Vector", "room_creation_make_public_prompt_title") 
  }
  /// Privacy
  public static var roomCreationPrivacy: String { 
    return VectorL10n.tr("Vector", "room_creation_privacy") 
  }
  /// This chat is private
  public static var roomCreationPrivateRoom: String { 
    return VectorL10n.tr("Vector", "room_creation_private_room") 
  }
  /// This chat is public
  public static var roomCreationPublicRoom: String { 
    return VectorL10n.tr("Vector", "room_creation_public_room") 
  }
  /// New Chat
  public static var roomCreationTitle: String { 
    return VectorL10n.tr("Vector", "room_creation_title") 
  }
  /// A room is already being created. Please wait.
  public static var roomCreationWaitForCreation: String { 
    return VectorL10n.tr("Vector", "room_creation_wait_for_creation") 
  }
  /// Delete unsent messages
  public static var roomDeleteUnsentMessages: String { 
    return VectorL10n.tr("Vector", "room_delete_unsent_messages") 
  }
  /// Who can access this room?
  public static var roomDetailsAccessSection: String { 
    return VectorL10n.tr("Vector", "room_details_access_section") 
  }
  /// Anyone who knows the room's link, including guests
  public static var roomDetailsAccessSectionAnyone: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_anyone") 
  }
  /// Anyone who knows the room's link, apart from guests
  public static var roomDetailsAccessSectionAnyoneApartFromGuest: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_anyone_apart_from_guest") 
  }
  /// Anyone who knows the link, apart from guests
  public static var roomDetailsAccessSectionAnyoneApartFromGuestForDm: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_anyone_apart_from_guest_for_dm") 
  }
  /// Anyone who knows the link, including guests
  public static var roomDetailsAccessSectionAnyoneForDm: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_anyone_for_dm") 
  }
  /// List this room in room directory
  public static var roomDetailsAccessSectionDirectoryToggle: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_directory_toggle") 
  }
  /// List in room directory
  public static var roomDetailsAccessSectionDirectoryToggleForDm: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_directory_toggle_for_dm") 
  }
  /// Who can access this?
  public static var roomDetailsAccessSectionForDm: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_for_dm") 
  }
  /// Only people who have been invited
  public static var roomDetailsAccessSectionInvitedOnly: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_invited_only") 
  }
  /// To link to a room it must have an address
  public static var roomDetailsAccessSectionNoAddressWarning: String { 
    return VectorL10n.tr("Vector", "room_details_access_section_no_address_warning") 
  }
  /// You will have no main address specified. The default main address for this room will be picked randomly
  public static var roomDetailsAddressesDisableMainAddressPromptMsg: String { 
    return VectorL10n.tr("Vector", "room_details_addresses_disable_main_address_prompt_msg") 
  }
  /// Main address warning
  public static var roomDetailsAddressesDisableMainAddressPromptTitle: String { 
    return VectorL10n.tr("Vector", "room_details_addresses_disable_main_address_prompt_title") 
  }
  /// %@ is not a valid format for an alias
  public static func roomDetailsAddressesInvalidAddressPromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_details_addresses_invalid_address_prompt_msg", p1)
  }
  /// Invalid alias format
  public static var roomDetailsAddressesInvalidAddressPromptTitle: String { 
    return VectorL10n.tr("Vector", "room_details_addresses_invalid_address_prompt_title") 
  }
  /// Addresses
  public static var roomDetailsAddressesSection: String { 
    return VectorL10n.tr("Vector", "room_details_addresses_section") 
  }
  /// Encrypt to verified sessions only
  public static var roomDetailsAdvancedE2eEncryptionBlacklistUnverifiedDevices: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_e2e_encryption_blacklist_unverified_devices") 
  }
  /// Encryption is not enabled in this room.
  public static var roomDetailsAdvancedE2eEncryptionDisabled: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_e2e_encryption_disabled") 
  }
  /// Encryption is not enabled here.
  public static var roomDetailsAdvancedE2eEncryptionDisabledForDm: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_e2e_encryption_disabled_for_dm") 
  }
  /// Encryption is enabled in this room
  public static var roomDetailsAdvancedE2eEncryptionEnabled: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_e2e_encryption_enabled") 
  }
  /// Encryption is enabled here
  public static var roomDetailsAdvancedE2eEncryptionEnabledForDm: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_e2e_encryption_enabled_for_dm") 
  }
  /// Enable encryption (warning: cannot be disabled again!)
  public static var roomDetailsAdvancedEnableE2eEncryption: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_enable_e2e_encryption") 
  }
  /// Room ID:
  public static var roomDetailsAdvancedRoomId: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_room_id") 
  }
  /// ID:
  public static var roomDetailsAdvancedRoomIdForDm: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_room_id_for_dm") 
  }
  /// Advanced
  public static var roomDetailsAdvancedSection: String { 
    return VectorL10n.tr("Vector", "room_details_advanced_section") 
  }
  /// Banned users
  public static var roomDetailsBannedUsersSection: String { 
    return VectorL10n.tr("Vector", "room_details_banned_users_section") 
  }
  /// Copy Room Address
  public static var roomDetailsCopyRoomAddress: String { 
    return VectorL10n.tr("Vector", "room_details_copy_room_address") 
  }
  /// Copy Room ID
  public static var roomDetailsCopyRoomId: String { 
    return VectorL10n.tr("Vector", "room_details_copy_room_id") 
  }
  /// Copy Room URL
  public static var roomDetailsCopyRoomUrl: String { 
    return VectorL10n.tr("Vector", "room_details_copy_room_url") 
  }
  /// Direct Chat
  public static var roomDetailsDirectChat: String { 
    return VectorL10n.tr("Vector", "room_details_direct_chat") 
  }
  /// Fail to add the new room addresses
  public static var roomDetailsFailToAddRoomAliases: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_add_room_aliases") 
  }
  /// Fail to enable encryption in this room
  public static var roomDetailsFailToEnableEncryption: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_enable_encryption") 
  }
  /// Fail to remove the room addresses
  public static var roomDetailsFailToRemoveRoomAliases: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_remove_room_aliases") 
  }
  /// Fail to update the room photo
  public static var roomDetailsFailToUpdateAvatar: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_avatar") 
  }
  /// Fail to update the history visibility
  public static var roomDetailsFailToUpdateHistoryVisibility: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_history_visibility") 
  }
  /// Fail to update the main address
  public static var roomDetailsFailToUpdateRoomCanonicalAlias: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_canonical_alias") 
  }
  /// Fail to update the related communities
  public static var roomDetailsFailToUpdateRoomCommunities: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_communities") 
  }
  /// Fail to update the direct flag of this room
  public static var roomDetailsFailToUpdateRoomDirect: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_direct") 
  }
  /// Fail to update the room directory visibility
  public static var roomDetailsFailToUpdateRoomDirectoryVisibility: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_directory_visibility") 
  }
  /// Fail to update the room guest access
  public static var roomDetailsFailToUpdateRoomGuestAccess: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_guest_access") 
  }
  /// Fail to update the join rule
  public static var roomDetailsFailToUpdateRoomJoinRule: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_join_rule") 
  }
  /// Fail to update the room name
  public static var roomDetailsFailToUpdateRoomName: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_room_name") 
  }
  /// Fail to update the topic
  public static var roomDetailsFailToUpdateTopic: String { 
    return VectorL10n.tr("Vector", "room_details_fail_to_update_topic") 
  }
  /// Favourite
  public static var roomDetailsFavouriteTag: String { 
    return VectorL10n.tr("Vector", "room_details_favourite_tag") 
  }
  /// Uploads
  public static var roomDetailsFiles: String { 
    return VectorL10n.tr("Vector", "room_details_files") 
  }
  /// %@ is not a valid identifier for a community
  public static func roomDetailsFlairInvalidIdPromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_details_flair_invalid_id_prompt_msg", p1)
  }
  /// Invalid format
  public static var roomDetailsFlairInvalidIdPromptTitle: String { 
    return VectorL10n.tr("Vector", "room_details_flair_invalid_id_prompt_title") 
  }
  /// Show flair for communities
  public static var roomDetailsFlairSection: String { 
    return VectorL10n.tr("Vector", "room_details_flair_section") 
  }
  /// Who can read history?
  public static var roomDetailsHistorySection: String { 
    return VectorL10n.tr("Vector", "room_details_history_section") 
  }
  /// Anyone
  public static var roomDetailsHistorySectionAnyone: String { 
    return VectorL10n.tr("Vector", "room_details_history_section_anyone") 
  }
  /// Members only (since the point in time of selecting this option)
  public static var roomDetailsHistorySectionMembersOnly: String { 
    return VectorL10n.tr("Vector", "room_details_history_section_members_only") 
  }
  /// Members only (since they were invited)
  public static var roomDetailsHistorySectionMembersOnlySinceInvited: String { 
    return VectorL10n.tr("Vector", "room_details_history_section_members_only_since_invited") 
  }
  /// Members only (since they joined)
  public static var roomDetailsHistorySectionMembersOnlySinceJoined: String { 
    return VectorL10n.tr("Vector", "room_details_history_section_members_only_since_joined") 
  }
  /// Changes to who can read history will only apply to future messages in this room. The visibility of existing history will be unchanged.
  public static var roomDetailsHistorySectionPromptMsg: String { 
    return VectorL10n.tr("Vector", "room_details_history_section_prompt_msg") 
  }
  /// Privacy warning
  public static var roomDetailsHistorySectionPromptTitle: String { 
    return VectorL10n.tr("Vector", "room_details_history_section_prompt_title") 
  }
  /// Integrations
  public static var roomDetailsIntegrations: String { 
    return VectorL10n.tr("Vector", "room_details_integrations") 
  }
  /// Low priority
  public static var roomDetailsLowPriorityTag: String { 
    return VectorL10n.tr("Vector", "room_details_low_priority_tag") 
  }
  /// Mute notifications
  public static var roomDetailsMuteNotifs: String { 
    return VectorL10n.tr("Vector", "room_details_mute_notifs") 
  }
  /// Add new address
  public static var roomDetailsNewAddress: String { 
    return VectorL10n.tr("Vector", "room_details_new_address") 
  }
  /// Add new address (e.g. #foo%@)
  public static func roomDetailsNewAddressPlaceholder(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_details_new_address_placeholder", p1)
  }
  /// Add new community ID (e.g. +foo%@)
  public static func roomDetailsNewFlairPlaceholder(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_details_new_flair_placeholder", p1)
  }
  /// This room has no local addresses
  public static var roomDetailsNoLocalAddresses: String { 
    return VectorL10n.tr("Vector", "room_details_no_local_addresses") 
  }
  /// This has no local addresses
  public static var roomDetailsNoLocalAddressesForDm: String { 
    return VectorL10n.tr("Vector", "room_details_no_local_addresses_for_dm") 
  }
  /// Notifications
  public static var roomDetailsNotifs: String { 
    return VectorL10n.tr("Vector", "room_details_notifs") 
  }
  /// Members
  public static var roomDetailsPeople: String { 
    return VectorL10n.tr("Vector", "room_details_people") 
  }
  /// Room Photo
  public static var roomDetailsPhoto: String { 
    return VectorL10n.tr("Vector", "room_details_photo") 
  }
  /// Photo
  public static var roomDetailsPhotoForDm: String { 
    return VectorL10n.tr("Vector", "room_details_photo_for_dm") 
  }
  /// Room Name
  public static var roomDetailsRoomName: String { 
    return VectorL10n.tr("Vector", "room_details_room_name") 
  }
  /// Name
  public static var roomDetailsRoomNameForDm: String { 
    return VectorL10n.tr("Vector", "room_details_room_name_for_dm") 
  }
  /// Do you want to save changes?
  public static var roomDetailsSaveChangesPrompt: String { 
    return VectorL10n.tr("Vector", "room_details_save_changes_prompt") 
  }
  /// Search room
  public static var roomDetailsSearch: String { 
    return VectorL10n.tr("Vector", "room_details_search") 
  }
  /// Set as Main Address
  public static var roomDetailsSetMainAddress: String { 
    return VectorL10n.tr("Vector", "room_details_set_main_address") 
  }
  /// Settings
  public static var roomDetailsSettings: String { 
    return VectorL10n.tr("Vector", "room_details_settings") 
  }
  /// Room Details
  public static var roomDetailsTitle: String { 
    return VectorL10n.tr("Vector", "room_details_title") 
  }
  /// Details
  public static var roomDetailsTitleForDm: String { 
    return VectorL10n.tr("Vector", "room_details_title_for_dm") 
  }
  /// Topic
  public static var roomDetailsTopic: String { 
    return VectorL10n.tr("Vector", "room_details_topic") 
  }
  /// Unset as Main Address
  public static var roomDetailsUnsetMainAddress: String { 
    return VectorL10n.tr("Vector", "room_details_unset_main_address") 
  }
  /// No public rooms available
  public static var roomDirectoryNoPublicRoom: String { 
    return VectorL10n.tr("Vector", "room_directory_no_public_room") 
  }
  /// You do not have permission to post to this room
  public static var roomDoNotHavePermissionToPost: String { 
    return VectorL10n.tr("Vector", "room_do_not_have_permission_to_post") 
  }
  /// %@ does not exist
  public static func roomDoesNotExist(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_does_not_exist", p1)
  }
  /// Reason for banning this user
  public static var roomEventActionBanPromptReason: String { 
    return VectorL10n.tr("Vector", "room_event_action_ban_prompt_reason") 
  }
  /// Cancel Download
  public static var roomEventActionCancelDownload: String { 
    return VectorL10n.tr("Vector", "room_event_action_cancel_download") 
  }
  /// Cancel Send
  public static var roomEventActionCancelSend: String { 
    return VectorL10n.tr("Vector", "room_event_action_cancel_send") 
  }
  /// Copy
  public static var roomEventActionCopy: String { 
    return VectorL10n.tr("Vector", "room_event_action_copy") 
  }
  /// Delete
  public static var roomEventActionDelete: String { 
    return VectorL10n.tr("Vector", "room_event_action_delete") 
  }
  /// Are you sure you want to delete this unsent message?
  public static var roomEventActionDeleteConfirmationMessage: String { 
    return VectorL10n.tr("Vector", "room_event_action_delete_confirmation_message") 
  }
  /// Delete unsent message
  public static var roomEventActionDeleteConfirmationTitle: String { 
    return VectorL10n.tr("Vector", "room_event_action_delete_confirmation_title") 
  }
  /// Edit
  public static var roomEventActionEdit: String { 
    return VectorL10n.tr("Vector", "room_event_action_edit") 
  }
  /// End poll
  public static var roomEventActionEndPoll: String { 
    return VectorL10n.tr("Vector", "room_event_action_end_poll") 
  }
  /// Forward
  public static var roomEventActionForward: String { 
    return VectorL10n.tr("Vector", "room_event_action_forward") 
  }
  /// Reason for kicking this user
  public static var roomEventActionKickPromptReason: String { 
    return VectorL10n.tr("Vector", "room_event_action_kick_prompt_reason") 
  }
  /// More
  public static var roomEventActionMore: String { 
    return VectorL10n.tr("Vector", "room_event_action_more") 
  }
  /// Permalink
  public static var roomEventActionPermalink: String { 
    return VectorL10n.tr("Vector", "room_event_action_permalink") 
  }
  /// Quote
  public static var roomEventActionQuote: String { 
    return VectorL10n.tr("Vector", "room_event_action_quote") 
  }
  /// Reaction history
  public static var roomEventActionReactionHistory: String { 
    return VectorL10n.tr("Vector", "room_event_action_reaction_history") 
  }
  /// Show all
  public static var roomEventActionReactionShowAll: String { 
    return VectorL10n.tr("Vector", "room_event_action_reaction_show_all") 
  }
  /// Show less
  public static var roomEventActionReactionShowLess: String { 
    return VectorL10n.tr("Vector", "room_event_action_reaction_show_less") 
  }
  /// Remove
  public static var roomEventActionRedact: String { 
    return VectorL10n.tr("Vector", "room_event_action_redact") 
  }
  /// Remove poll
  public static var roomEventActionRemovePoll: String { 
    return VectorL10n.tr("Vector", "room_event_action_remove_poll") 
  }
  /// Reply
  public static var roomEventActionReply: String { 
    return VectorL10n.tr("Vector", "room_event_action_reply") 
  }
  /// Report content
  public static var roomEventActionReport: String { 
    return VectorL10n.tr("Vector", "room_event_action_report") 
  }
  /// Do you want to hide all messages from this user?
  public static var roomEventActionReportPromptIgnoreUser: String { 
    return VectorL10n.tr("Vector", "room_event_action_report_prompt_ignore_user") 
  }
  /// Reason for reporting this content
  public static var roomEventActionReportPromptReason: String { 
    return VectorL10n.tr("Vector", "room_event_action_report_prompt_reason") 
  }
  /// Resend
  public static var roomEventActionResend: String { 
    return VectorL10n.tr("Vector", "room_event_action_resend") 
  }
  /// Save
  public static var roomEventActionSave: String { 
    return VectorL10n.tr("Vector", "room_event_action_save") 
  }
  /// Share
  public static var roomEventActionShare: String { 
    return VectorL10n.tr("Vector", "room_event_action_share") 
  }
  /// View Decrypted Source
  public static var roomEventActionViewDecryptedSource: String { 
    return VectorL10n.tr("Vector", "room_event_action_view_decrypted_source") 
  }
  /// Encryption Information
  public static var roomEventActionViewEncryption: String { 
    return VectorL10n.tr("Vector", "room_event_action_view_encryption") 
  }
  /// View Source
  public static var roomEventActionViewSource: String { 
    return VectorL10n.tr("Vector", "room_event_action_view_source") 
  }
  /// Failed to send
  public static var roomEventFailedToSend: String { 
    return VectorL10n.tr("Vector", "room_event_failed_to_send") 
  }
  /// 1 member
  public static var roomInfoListOneMember: String { 
    return VectorL10n.tr("Vector", "room_info_list_one_member") 
  }
  /// Other
  public static var roomInfoListSectionOther: String { 
    return VectorL10n.tr("Vector", "room_info_list_section_other") 
  }
  /// %@ members
  public static func roomInfoListSeveralMembers(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_info_list_several_members", p1)
  }
  /// Add people
  public static var roomIntroCellAddParticipantsAction: String { 
    return VectorL10n.tr("Vector", "room_intro_cell_add_participants_action") 
  }
  /// This is the beginning of your direct message with 
  public static var roomIntroCellInformationDmSentence1Part1: String { 
    return VectorL10n.tr("Vector", "room_intro_cell_information_dm_sentence1_part1") 
  }
  /// . 
  public static var roomIntroCellInformationDmSentence1Part3: String { 
    return VectorL10n.tr("Vector", "room_intro_cell_information_dm_sentence1_part3") 
  }
  /// Only the two of you are in this conversation, no one else can join.
  public static var roomIntroCellInformationDmSentence2: String { 
    return VectorL10n.tr("Vector", "room_intro_cell_information_dm_sentence2") 
  }
  /// Only you are in this conversation, unless any of you invites someone to join.
  public static var roomIntroCellInformationMultipleDmSentence2: String { 
    return VectorL10n.tr("Vector", "room_intro_cell_information_multiple_dm_sentence2") 
  }
  /// This is the beginning of 
  public static var roomIntroCellInformationRoomSentence1Part1: String { 
    return VectorL10n.tr("Vector", "room_intro_cell_information_room_sentence1_part1") 
  }
  /// . 
  public static var roomIntroCellInformationRoomSentence1Part3: String { 
    return VectorL10n.tr("Vector", "room_intro_cell_information_room_sentence1_part3") 
  }
  /// Topic: %@
  public static func roomIntroCellInformationRoomWithTopicSentence2(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_intro_cell_information_room_with_topic_sentence2", p1)
  }
  /// Add a topic
  public static var roomIntroCellInformationRoomWithoutTopicSentence2Part1: String { 
    return VectorL10n.tr("Vector", "room_intro_cell_information_room_without_topic_sentence2_part1") 
  }
  ///  to let people know what this room is about.
  public static var roomIntroCellInformationRoomWithoutTopicSentence2Part2: String { 
    return VectorL10n.tr("Vector", "room_intro_cell_information_room_without_topic_sentence2_part2") 
  }
  /// Join
  public static var roomJoinGroupCall: String { 
    return VectorL10n.tr("Vector", "room_join_group_call") 
  }
  /// Jump to unread
  public static var roomJumpToFirstUnread: String { 
    return VectorL10n.tr("Vector", "room_jump_to_first_unread") 
  }
  /// %@, %@ & others are typing…
  public static func roomManyUsersAreTyping(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_many_users_are_typing", p1, p2)
  }
  /// Admin in %@
  public static func roomMemberPowerLevelAdminIn(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_member_power_level_admin_in", p1)
  }
  /// Custom (%@) in %@
  public static func roomMemberPowerLevelCustomIn(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_member_power_level_custom_in", p1, p2)
  }
  /// Moderator in %@
  public static func roomMemberPowerLevelModeratorIn(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_member_power_level_moderator_in", p1)
  }
  /// Admin
  public static var roomMemberPowerLevelShortAdmin: String { 
    return VectorL10n.tr("Vector", "room_member_power_level_short_admin") 
  }
  /// Custom
  public static var roomMemberPowerLevelShortCustom: String { 
    return VectorL10n.tr("Vector", "room_member_power_level_short_custom") 
  }
  /// Mod
  public static var roomMemberPowerLevelShortModerator: String { 
    return VectorL10n.tr("Vector", "room_member_power_level_short_moderator") 
  }
  /// Editing
  public static var roomMessageEditing: String { 
    return VectorL10n.tr("Vector", "room_message_editing") 
  }
  /// Message edits
  public static var roomMessageEditsHistoryTitle: String { 
    return VectorL10n.tr("Vector", "room_message_edits_history_title") 
  }
  /// Send a message (unencrypted)…
  public static var roomMessagePlaceholder: String { 
    return VectorL10n.tr("Vector", "room_message_placeholder") 
  }
  /// Send a reply (unencrypted)…
  public static var roomMessageReplyToPlaceholder: String { 
    return VectorL10n.tr("Vector", "room_message_reply_to_placeholder") 
  }
  /// Send a reply…
  public static var roomMessageReplyToShortPlaceholder: String { 
    return VectorL10n.tr("Vector", "room_message_reply_to_short_placeholder") 
  }
  /// Replying to %@
  public static func roomMessageReplyingTo(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_message_replying_to", p1)
  }
  /// Send a message…
  public static var roomMessageShortPlaceholder: String { 
    return VectorL10n.tr("Vector", "room_message_short_placeholder") 
  }
  /// Unable to open the link.
  public static var roomMessageUnableOpenLinkErrorMessage: String { 
    return VectorL10n.tr("Vector", "room_message_unable_open_link_error_message") 
  }
  /// %@ and others
  public static func roomMultipleTypingNotification(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_multiple_typing_notification", p1)
  }
  /// %d new message
  public static func roomNewMessageNotification(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "room_new_message_notification", p1)
  }
  /// %d new messages
  public static func roomNewMessagesNotification(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "room_new_messages_notification", p1)
  }
  /// You need to be an admin or a moderator to start a call.
  public static var roomNoPrivilegesToCreateGroupCall: String { 
    return VectorL10n.tr("Vector", "room_no_privileges_to_create_group_call") 
  }
  /// Account settings
  public static var roomNotifsSettingsAccountSettings: String { 
    return VectorL10n.tr("Vector", "room_notifs_settings_account_settings") 
  }
  /// All Messages
  public static var roomNotifsSettingsAllMessages: String { 
    return VectorL10n.tr("Vector", "room_notifs_settings_all_messages") 
  }
  /// Cancel
  public static var roomNotifsSettingsCancelAction: String { 
    return VectorL10n.tr("Vector", "room_notifs_settings_cancel_action") 
  }
  /// Done
  public static var roomNotifsSettingsDoneAction: String { 
    return VectorL10n.tr("Vector", "room_notifs_settings_done_action") 
  }
  /// Please note that mentions & keyword notifications are not available in encrypted rooms on mobile.
  public static var roomNotifsSettingsEncryptedRoomNotice: String { 
    return VectorL10n.tr("Vector", "room_notifs_settings_encrypted_room_notice") 
  }
  /// You can manage notifications in %@
  public static func roomNotifsSettingsManageNotifications(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_notifs_settings_manage_notifications", p1)
  }
  /// Mentions and Keywords only
  public static var roomNotifsSettingsMentionsAndKeywords: String { 
    return VectorL10n.tr("Vector", "room_notifs_settings_mentions_and_keywords") 
  }
  /// None
  public static var roomNotifsSettingsNone: String { 
    return VectorL10n.tr("Vector", "room_notifs_settings_none") 
  }
  /// Notify me for
  public static var roomNotifsSettingsNotifyMeFor: String { 
    return VectorL10n.tr("Vector", "room_notifs_settings_notify_me_for") 
  }
  /// Connectivity to the server has been lost.
  public static var roomOfflineNotification: String { 
    return VectorL10n.tr("Vector", "room_offline_notification") 
  }
  /// %@ is typing…
  public static func roomOneUserIsTyping(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_one_user_is_typing", p1)
  }
  /// Ongoing conference call. Join as %@ or %@.
  public static func roomOngoingConferenceCall(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_ongoing_conference_call", p1, p2)
  }
  /// Close
  public static var roomOngoingConferenceCallClose: String { 
    return VectorL10n.tr("Vector", "room_ongoing_conference_call_close") 
  }
  /// Ongoing conference call. Join as %@ or %@. %@ it.
  public static func roomOngoingConferenceCallWithClose(_ p1: String, _ p2: String, _ p3: String) -> String {
    return VectorL10n.tr("Vector", "room_ongoing_conference_call_with_close", p1, p2, p3)
  }
  /// Dial pad
  public static var roomOpenDialpad: String { 
    return VectorL10n.tr("Vector", "room_open_dialpad") 
  }
  /// Ban from this room
  public static var roomParticipantsActionBan: String { 
    return VectorL10n.tr("Vector", "room_participants_action_ban") 
  }
  /// Hide all messages from this user
  public static var roomParticipantsActionIgnore: String { 
    return VectorL10n.tr("Vector", "room_participants_action_ignore") 
  }
  /// Invite
  public static var roomParticipantsActionInvite: String { 
    return VectorL10n.tr("Vector", "room_participants_action_invite") 
  }
  /// Leave this room
  public static var roomParticipantsActionLeave: String { 
    return VectorL10n.tr("Vector", "room_participants_action_leave") 
  }
  /// Mention
  public static var roomParticipantsActionMention: String { 
    return VectorL10n.tr("Vector", "room_participants_action_mention") 
  }
  /// Remove from this room
  public static var roomParticipantsActionRemove: String { 
    return VectorL10n.tr("Vector", "room_participants_action_remove") 
  }
  /// Admin tools
  public static var roomParticipantsActionSectionAdminTools: String { 
    return VectorL10n.tr("Vector", "room_participants_action_section_admin_tools") 
  }
  /// Sessions
  public static var roomParticipantsActionSectionDevices: String { 
    return VectorL10n.tr("Vector", "room_participants_action_section_devices") 
  }
  /// Direct chats
  public static var roomParticipantsActionSectionDirectChats: String { 
    return VectorL10n.tr("Vector", "room_participants_action_section_direct_chats") 
  }
  /// Options
  public static var roomParticipantsActionSectionOther: String { 
    return VectorL10n.tr("Vector", "room_participants_action_section_other") 
  }
  /// Security
  public static var roomParticipantsActionSectionSecurity: String { 
    return VectorL10n.tr("Vector", "room_participants_action_section_security") 
  }
  /// Complete security
  public static var roomParticipantsActionSecurityStatusCompleteSecurity: String { 
    return VectorL10n.tr("Vector", "room_participants_action_security_status_complete_security") 
  }
  /// Loading…
  public static var roomParticipantsActionSecurityStatusLoading: String { 
    return VectorL10n.tr("Vector", "room_participants_action_security_status_loading") 
  }
  /// Verified
  public static var roomParticipantsActionSecurityStatusVerified: String { 
    return VectorL10n.tr("Vector", "room_participants_action_security_status_verified") 
  }
  /// Verify
  public static var roomParticipantsActionSecurityStatusVerify: String { 
    return VectorL10n.tr("Vector", "room_participants_action_security_status_verify") 
  }
  /// Warning
  public static var roomParticipantsActionSecurityStatusWarning: String { 
    return VectorL10n.tr("Vector", "room_participants_action_security_status_warning") 
  }
  /// Make admin
  public static var roomParticipantsActionSetAdmin: String { 
    return VectorL10n.tr("Vector", "room_participants_action_set_admin") 
  }
  /// Reset to normal user
  public static var roomParticipantsActionSetDefaultPowerLevel: String { 
    return VectorL10n.tr("Vector", "room_participants_action_set_default_power_level") 
  }
  /// Make moderator
  public static var roomParticipantsActionSetModerator: String { 
    return VectorL10n.tr("Vector", "room_participants_action_set_moderator") 
  }
  /// Start new chat
  public static var roomParticipantsActionStartNewChat: String { 
    return VectorL10n.tr("Vector", "room_participants_action_start_new_chat") 
  }
  /// Start video call
  public static var roomParticipantsActionStartVideoCall: String { 
    return VectorL10n.tr("Vector", "room_participants_action_start_video_call") 
  }
  /// Start voice call
  public static var roomParticipantsActionStartVoiceCall: String { 
    return VectorL10n.tr("Vector", "room_participants_action_start_voice_call") 
  }
  /// Unban
  public static var roomParticipantsActionUnban: String { 
    return VectorL10n.tr("Vector", "room_participants_action_unban") 
  }
  /// Show all messages from this user
  public static var roomParticipantsActionUnignore: String { 
    return VectorL10n.tr("Vector", "room_participants_action_unignore") 
  }
  /// Add participant
  public static var roomParticipantsAddParticipant: String { 
    return VectorL10n.tr("Vector", "room_participants_add_participant") 
  }
  /// ago
  public static var roomParticipantsAgo: String { 
    return VectorL10n.tr("Vector", "room_participants_ago") 
  }
  /// Filter room members
  public static var roomParticipantsFilterRoomMembers: String { 
    return VectorL10n.tr("Vector", "room_participants_filter_room_members") 
  }
  /// Filter members
  public static var roomParticipantsFilterRoomMembersForDm: String { 
    return VectorL10n.tr("Vector", "room_participants_filter_room_members_for_dm") 
  }
  /// Idle
  public static var roomParticipantsIdle: String { 
    return VectorL10n.tr("Vector", "room_participants_idle") 
  }
  /// Search / invite by User ID, Name or email
  public static var roomParticipantsInviteAnotherUser: String { 
    return VectorL10n.tr("Vector", "room_participants_invite_another_user") 
  }
  /// Malformed ID. Should be an email address or a Matrix ID like '@localpart:domain'
  public static var roomParticipantsInviteMalformedId: String { 
    return VectorL10n.tr("Vector", "room_participants_invite_malformed_id") 
  }
  /// Invite Error
  public static var roomParticipantsInviteMalformedIdTitle: String { 
    return VectorL10n.tr("Vector", "room_participants_invite_malformed_id_title") 
  }
  /// Are you sure you want to invite %@ to this chat?
  public static func roomParticipantsInvitePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_participants_invite_prompt_msg", p1)
  }
  /// Confirmation
  public static var roomParticipantsInvitePromptTitle: String { 
    return VectorL10n.tr("Vector", "room_participants_invite_prompt_title") 
  }
  /// INVITED
  public static var roomParticipantsInvitedSection: String { 
    return VectorL10n.tr("Vector", "room_participants_invited_section") 
  }
  /// Are you sure you want to leave the room?
  public static var roomParticipantsLeavePromptMsg: String { 
    return VectorL10n.tr("Vector", "room_participants_leave_prompt_msg") 
  }
  /// Are you sure you want to leave?
  public static var roomParticipantsLeavePromptMsgForDm: String { 
    return VectorL10n.tr("Vector", "room_participants_leave_prompt_msg_for_dm") 
  }
  /// Leave room
  public static var roomParticipantsLeavePromptTitle: String { 
    return VectorL10n.tr("Vector", "room_participants_leave_prompt_title") 
  }
  /// Leave
  public static var roomParticipantsLeavePromptTitleForDm: String { 
    return VectorL10n.tr("Vector", "room_participants_leave_prompt_title_for_dm") 
  }
  /// %d participants
  public static func roomParticipantsMultiParticipants(_ p1: Int) -> String {
    return VectorL10n.tr("Vector", "room_participants_multi_participants", p1)
  }
  /// now
  public static var roomParticipantsNow: String { 
    return VectorL10n.tr("Vector", "room_participants_now") 
  }
  /// Offline
  public static var roomParticipantsOffline: String { 
    return VectorL10n.tr("Vector", "room_participants_offline") 
  }
  /// 1 participant
  public static var roomParticipantsOneParticipant: String { 
    return VectorL10n.tr("Vector", "room_participants_one_participant") 
  }
  /// Online
  public static var roomParticipantsOnline: String { 
    return VectorL10n.tr("Vector", "room_participants_online") 
  }
  /// Are you sure you want to remove %@ from this chat?
  public static func roomParticipantsRemovePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_participants_remove_prompt_msg", p1)
  }
  /// Confirmation
  public static var roomParticipantsRemovePromptTitle: String { 
    return VectorL10n.tr("Vector", "room_participants_remove_prompt_title") 
  }
  /// Are you sure you want to revoke this invite?
  public static var roomParticipantsRemoveThirdPartyInvitePromptMsg: String { 
    return VectorL10n.tr("Vector", "room_participants_remove_third_party_invite_prompt_msg") 
  }
  /// Messages in this room are end-to-end encrypted.\n\nYour messages are secured with locks and only you and the recipient have the unique keys to unlock them.
  public static var roomParticipantsSecurityInformationRoomEncrypted: String { 
    return VectorL10n.tr("Vector", "room_participants_security_information_room_encrypted") 
  }
  /// Messages here are end-to-end encrypted.\n\nYour messages are secured with locks and only you and the recipient have the unique keys to unlock them.
  public static var roomParticipantsSecurityInformationRoomEncryptedForDm: String { 
    return VectorL10n.tr("Vector", "room_participants_security_information_room_encrypted_for_dm") 
  }
  /// Messages in this room are not end-to-end encrypted.
  public static var roomParticipantsSecurityInformationRoomNotEncrypted: String { 
    return VectorL10n.tr("Vector", "room_participants_security_information_room_not_encrypted") 
  }
  /// Messages here are not end-to-end encrypted.
  public static var roomParticipantsSecurityInformationRoomNotEncryptedForDm: String { 
    return VectorL10n.tr("Vector", "room_participants_security_information_room_not_encrypted_for_dm") 
  }
  /// Loading…
  public static var roomParticipantsSecurityLoading: String { 
    return VectorL10n.tr("Vector", "room_participants_security_loading") 
  }
  /// No identity server is configured so you cannot start a chat with a contact using an email.
  public static var roomParticipantsStartNewChatErrorUsingUserEmailWithoutIdentityServer: String { 
    return VectorL10n.tr("Vector", "room_participants_start_new_chat_error_using_user_email_without_identity_server") 
  }
  /// Participants
  public static var roomParticipantsTitle: String { 
    return VectorL10n.tr("Vector", "room_participants_title") 
  }
  /// Unknown
  public static var roomParticipantsUnknown: String { 
    return VectorL10n.tr("Vector", "room_participants_unknown") 
  }
  /// Voice call
  public static var roomPlaceVoiceCall: String { 
    return VectorL10n.tr("Vector", "room_place_voice_call") 
  }
  /// This room is a continuation of another conversation.
  public static var roomPredecessorInformation: String { 
    return VectorL10n.tr("Vector", "room_predecessor_information") 
  }
  /// Tap here to see older messages.
  public static var roomPredecessorLink: String { 
    return VectorL10n.tr("Vector", "room_predecessor_link") 
  }
  /// You have been invited to join this room by %@
  public static func roomPreviewInvitationFormat(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_preview_invitation_format", p1)
  }
  /// This is a preview of this room. Room interactions have been disabled.
  public static var roomPreviewSubtitle: String { 
    return VectorL10n.tr("Vector", "room_preview_subtitle") 
  }
  /// You are trying to access %@. Would you like to join in order to participate in the discussion?
  public static func roomPreviewTryJoinAnUnknownRoom(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_preview_try_join_an_unknown_room", p1)
  }
  /// a room
  public static var roomPreviewTryJoinAnUnknownRoomDefault: String { 
    return VectorL10n.tr("Vector", "room_preview_try_join_an_unknown_room_default") 
  }
  /// This invitation was sent to %@, which is not associated with this account. You may wish to login with a different account, or add this email to your account.
  public static func roomPreviewUnlinkedEmailWarning(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_preview_unlinked_email_warning", p1)
  }
  /// cancel all
  public static var roomPromptCancel: String { 
    return VectorL10n.tr("Vector", "room_prompt_cancel") 
  }
  /// Resend all
  public static var roomPromptResend: String { 
    return VectorL10n.tr("Vector", "room_prompt_resend") 
  }
  /// ROOMS
  public static var roomRecentsConversationsSection: String { 
    return VectorL10n.tr("Vector", "room_recents_conversations_section") 
  }
  /// Create room
  public static var roomRecentsCreateEmptyRoom: String { 
    return VectorL10n.tr("Vector", "room_recents_create_empty_room") 
  }
  /// ROOM DIRECTORY
  public static var roomRecentsDirectorySection: String { 
    return VectorL10n.tr("Vector", "room_recents_directory_section") 
  }
  /// FAVOURITES
  public static var roomRecentsFavouritesSection: String { 
    return VectorL10n.tr("Vector", "room_recents_favourites_section") 
  }
  /// INVITES
  public static var roomRecentsInvitesSection: String { 
    return VectorL10n.tr("Vector", "room_recents_invites_section") 
  }
  /// Join room
  public static var roomRecentsJoinRoom: String { 
    return VectorL10n.tr("Vector", "room_recents_join_room") 
  }
  /// Type a room id or a room alias
  public static var roomRecentsJoinRoomPrompt: String { 
    return VectorL10n.tr("Vector", "room_recents_join_room_prompt") 
  }
  /// Join a room
  public static var roomRecentsJoinRoomTitle: String { 
    return VectorL10n.tr("Vector", "room_recents_join_room_title") 
  }
  /// LOW PRIORITY
  public static var roomRecentsLowPrioritySection: String { 
    return VectorL10n.tr("Vector", "room_recents_low_priority_section") 
  }
  /// No rooms
  public static var roomRecentsNoConversation: String { 
    return VectorL10n.tr("Vector", "room_recents_no_conversation") 
  }
  /// PEOPLE
  public static var roomRecentsPeopleSection: String { 
    return VectorL10n.tr("Vector", "room_recents_people_section") 
  }
  /// SYSTEM ALERTS
  public static var roomRecentsServerNoticeSection: String { 
    return VectorL10n.tr("Vector", "room_recents_server_notice_section") 
  }
  /// Start chat
  public static var roomRecentsStartChatWith: String { 
    return VectorL10n.tr("Vector", "room_recents_start_chat_with") 
  }
  /// SUGGESTED ROOMS
  public static var roomRecentsSuggestedRoomsSection: String { 
    return VectorL10n.tr("Vector", "room_recents_suggested_rooms_section") 
  }
  /// Can't find this room. Make sure it exists
  public static var roomRecentsUnknownRoomErrorMessage: String { 
    return VectorL10n.tr("Vector", "room_recents_unknown_room_error_message") 
  }
  /// This room has been replaced and is no longer active.
  public static var roomReplacementInformation: String { 
    return VectorL10n.tr("Vector", "room_replacement_information") 
  }
  /// The conversation continues here.
  public static var roomReplacementLink: String { 
    return VectorL10n.tr("Vector", "room_replacement_link") 
  }
  /// Resend unsent messages
  public static var roomResendUnsentMessages: String { 
    return VectorL10n.tr("Vector", "room_resend_unsent_messages") 
  }
  ///  Please 
  public static var roomResourceLimitExceededMessageContact1: String { 
    return VectorL10n.tr("Vector", "room_resource_limit_exceeded_message_contact_1") 
  }
  /// contact your service administrator
  public static var roomResourceLimitExceededMessageContact2Link: String { 
    return VectorL10n.tr("Vector", "room_resource_limit_exceeded_message_contact_2_link") 
  }
  ///  to continue using this service.
  public static var roomResourceLimitExceededMessageContact3: String { 
    return VectorL10n.tr("Vector", "room_resource_limit_exceeded_message_contact_3") 
  }
  /// This homeserver has exceeded one of its resource limits so 
  public static var roomResourceUsageLimitReachedMessage1Default: String { 
    return VectorL10n.tr("Vector", "room_resource_usage_limit_reached_message_1_default") 
  }
  /// This homeserver has hit its Monthly Active User limit so 
  public static var roomResourceUsageLimitReachedMessage1MonthlyActiveUser: String { 
    return VectorL10n.tr("Vector", "room_resource_usage_limit_reached_message_1_monthly_active_user") 
  }
  /// some users will not be able to log in.
  public static var roomResourceUsageLimitReachedMessage2: String { 
    return VectorL10n.tr("Vector", "room_resource_usage_limit_reached_message_2") 
  }
  ///  to get this limit increased.
  public static var roomResourceUsageLimitReachedMessageContact3: String { 
    return VectorL10n.tr("Vector", "room_resource_usage_limit_reached_message_contact_3") 
  }
  /// Slide to end the call for everyone
  public static var roomSlideToEndGroupCall: String { 
    return VectorL10n.tr("Vector", "room_slide_to_end_group_call") 
  }
  /// Invite members
  public static var roomTitleInviteMembers: String { 
    return VectorL10n.tr("Vector", "room_title_invite_members") 
  }
  /// %@ members
  public static func roomTitleMembers(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_title_members", p1)
  }
  /// %@/%@ active members
  public static func roomTitleMultipleActiveMembers(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_title_multiple_active_members", p1, p2)
  }
  /// New room
  public static var roomTitleNewRoom: String { 
    return VectorL10n.tr("Vector", "room_title_new_room") 
  }
  /// %@/%@ active member
  public static func roomTitleOneActiveMember(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_title_one_active_member", p1, p2)
  }
  /// 1 member
  public static var roomTitleOneMember: String { 
    return VectorL10n.tr("Vector", "room_title_one_member") 
  }
  /// %@ & %@ are typing…
  public static func roomTwoUsersAreTyping(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "room_two_users_are_typing", p1, p2)
  }
  /// Are you sure you want to delete all unsent messages in this room?
  public static var roomUnsentMessagesCancelMessage: String { 
    return VectorL10n.tr("Vector", "room_unsent_messages_cancel_message") 
  }
  /// Delete unsent messages
  public static var roomUnsentMessagesCancelTitle: String { 
    return VectorL10n.tr("Vector", "room_unsent_messages_cancel_title") 
  }
  /// Messages failed to send.
  public static var roomUnsentMessagesNotification: String { 
    return VectorL10n.tr("Vector", "room_unsent_messages_notification") 
  }
  /// Message failed to send due to unknown sessions being present.
  public static var roomUnsentMessagesUnknownDevicesNotification: String { 
    return VectorL10n.tr("Vector", "room_unsent_messages_unknown_devices_notification") 
  }
  /// End-to-end encryption is in beta and may not be reliable.\n\nYou should not yet trust it to secure data.\n\nDevices will not yet be able to decrypt history from before they joined the room.\n\nEncrypted messages will not be visible on clients that do not yet implement encryption.
  public static var roomWarningAboutEncryption: String { 
    return VectorL10n.tr("Vector", "room_warning_about_encryption") 
  }
  /// Your avatar URL
  public static var roomWidgetPermissionAvatarUrlPermission: String { 
    return VectorL10n.tr("Vector", "room_widget_permission_avatar_url_permission") 
  }
  /// This widget was added by:
  public static var roomWidgetPermissionCreatorInfoTitle: String { 
    return VectorL10n.tr("Vector", "room_widget_permission_creator_info_title") 
  }
  /// Your display name
  public static var roomWidgetPermissionDisplayNamePermission: String { 
    return VectorL10n.tr("Vector", "room_widget_permission_display_name_permission") 
  }
  /// Using it may share data with %@:\n
  public static func roomWidgetPermissionInformationTitle(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_widget_permission_information_title", p1)
  }
  /// Room ID
  public static var roomWidgetPermissionRoomIdPermission: String { 
    return VectorL10n.tr("Vector", "room_widget_permission_room_id_permission") 
  }
  /// Your theme
  public static var roomWidgetPermissionThemePermission: String { 
    return VectorL10n.tr("Vector", "room_widget_permission_theme_permission") 
  }
  /// Load Widget
  public static var roomWidgetPermissionTitle: String { 
    return VectorL10n.tr("Vector", "room_widget_permission_title") 
  }
  /// Your user ID
  public static var roomWidgetPermissionUserIdPermission: String { 
    return VectorL10n.tr("Vector", "room_widget_permission_user_id_permission") 
  }
  /// Using it may set cookies and share data with %@:\n
  public static func roomWidgetPermissionWebviewInformationTitle(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "room_widget_permission_webview_information_title", p1)
  }
  /// Widget ID
  public static var roomWidgetPermissionWidgetIdPermission: String { 
    return VectorL10n.tr("Vector", "room_widget_permission_widget_id_permission") 
  }
  /// Rooms are great for any group chat, private or public. Tap the + to find existing rooms, or make new ones.
  public static var roomsEmptyViewInformation: String { 
    return VectorL10n.tr("Vector", "rooms_empty_view_information") 
  }
  /// Rooms
  public static var roomsEmptyViewTitle: String { 
    return VectorL10n.tr("Vector", "rooms_empty_view_title") 
  }
  /// Save
  public static var save: String { 
    return VectorL10n.tr("Vector", "save") 
  }
  /// Search
  public static var searchDefaultPlaceholder: String { 
    return VectorL10n.tr("Vector", "search_default_placeholder") 
  }
  /// Files
  public static var searchFiles: String { 
    return VectorL10n.tr("Vector", "search_files") 
  }
  /// Searching…
  public static var searchInProgress: String { 
    return VectorL10n.tr("Vector", "search_in_progress") 
  }
  /// Messages
  public static var searchMessages: String { 
    return VectorL10n.tr("Vector", "search_messages") 
  }
  /// No results
  public static var searchNoResult: String { 
    return VectorL10n.tr("Vector", "search_no_result") 
  }
  /// People
  public static var searchPeople: String { 
    return VectorL10n.tr("Vector", "search_people") 
  }
  /// Search by User ID, Name or email
  public static var searchPeoplePlaceholder: String { 
    return VectorL10n.tr("Vector", "search_people_placeholder") 
  }
  /// Rooms
  public static var searchRooms: String { 
    return VectorL10n.tr("Vector", "search_rooms") 
  }
  /// Create a new room
  public static var searchableDirectoryCreateNewRoom: String { 
    return VectorL10n.tr("Vector", "searchable_directory_create_new_room") 
  }
  /// Name or ID
  public static var searchableDirectorySearchPlaceholder: String { 
    return VectorL10n.tr("Vector", "searchable_directory_search_placeholder") 
  }
  /// %@ Network
  public static func searchableDirectoryXNetwork(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "searchable_directory_x_network", p1)
  }
  /// Forgot or lost all recovery options? 
  public static var secretsRecoveryResetActionPart1: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_reset_action_part_1") 
  }
  /// Reset everything
  public static var secretsRecoveryResetActionPart2: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_reset_action_part_2") 
  }
  /// Access your secure message history and your cross-signing identity for verifying other sessions by entering your Security Key.
  public static var secretsRecoveryWithKeyInformationDefault: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_key_information_default") 
  }
  /// Enter your Security Key to continue.
  public static var secretsRecoveryWithKeyInformationUnlockSecureBackupWithKey: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_key_information_unlock_secure_backup_with_key") 
  }
  /// Enter your Security Phrase to continue.
  public static var secretsRecoveryWithKeyInformationUnlockSecureBackupWithPhrase: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_key_information_unlock_secure_backup_with_phrase") 
  }
  /// Use your Security Key to verify this device.
  public static var secretsRecoveryWithKeyInformationVerifyDevice: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_key_information_verify_device") 
  }
  /// Please verify that you entered the correct Security Key.
  public static var secretsRecoveryWithKeyInvalidRecoveryKeyMessage: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_key_invalid_recovery_key_message") 
  }
  /// Unable to access secret storage
  public static var secretsRecoveryWithKeyInvalidRecoveryKeyTitle: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_key_invalid_recovery_key_title") 
  }
  /// Use Key
  public static var secretsRecoveryWithKeyRecoverAction: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_key_recover_action") 
  }
  /// Enter Security Key
  public static var secretsRecoveryWithKeyRecoveryKeyPlaceholder: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_key_recovery_key_placeholder") 
  }
  /// Enter
  public static var secretsRecoveryWithKeyRecoveryKeyTitle: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_key_recovery_key_title") 
  }
  /// Security Key
  public static var secretsRecoveryWithKeyTitle: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_key_title") 
  }
  /// Access your secure message history and your cross-signing identity for verifying other sessions by entering your Security Phrase.
  public static var secretsRecoveryWithPassphraseInformationDefault: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_passphrase_information_default") 
  }
  /// Use your Security Phrase to verify this device.
  public static var secretsRecoveryWithPassphraseInformationVerifyDevice: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_passphrase_information_verify_device") 
  }
  /// Please verify that you entered the correct Security Phrase.
  public static var secretsRecoveryWithPassphraseInvalidPassphraseMessage: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_passphrase_invalid_passphrase_message") 
  }
  /// Unable to access secret storage
  public static var secretsRecoveryWithPassphraseInvalidPassphraseTitle: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_passphrase_invalid_passphrase_title") 
  }
  /// Don’t know your Security Phrase? You can 
  public static var secretsRecoveryWithPassphraseLostPassphraseActionPart1: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_passphrase_lost_passphrase_action_part1") 
  }
  /// use your Security Key
  public static var secretsRecoveryWithPassphraseLostPassphraseActionPart2: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_passphrase_lost_passphrase_action_part2") 
  }
  /// .
  public static var secretsRecoveryWithPassphraseLostPassphraseActionPart3: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_passphrase_lost_passphrase_action_part3") 
  }
  /// Enter Security Phrase
  public static var secretsRecoveryWithPassphrasePassphrasePlaceholder: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_passphrase_passphrase_placeholder") 
  }
  /// Enter
  public static var secretsRecoveryWithPassphrasePassphraseTitle: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_passphrase_passphrase_title") 
  }
  /// Use Phrase
  public static var secretsRecoveryWithPassphraseRecoverAction: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_passphrase_recover_action") 
  }
  /// Security Phrase
  public static var secretsRecoveryWithPassphraseTitle: String { 
    return VectorL10n.tr("Vector", "secrets_recovery_with_passphrase_title") 
  }
  /// Enter your account password to confirm
  public static var secretsResetAuthenticationMessage: String { 
    return VectorL10n.tr("Vector", "secrets_reset_authentication_message") 
  }
  /// Only do this if you have no other device you can verify this device with.
  public static var secretsResetInformation: String { 
    return VectorL10n.tr("Vector", "secrets_reset_information") 
  }
  /// Reset
  public static var secretsResetResetAction: String { 
    return VectorL10n.tr("Vector", "secrets_reset_reset_action") 
  }
  /// Reset everything
  public static var secretsResetTitle: String { 
    return VectorL10n.tr("Vector", "secrets_reset_title") 
  }
  /// You will restart with no history, no messages, trusted devices or trusted users.
  public static var secretsResetWarningMessage: String { 
    return VectorL10n.tr("Vector", "secrets_reset_warning_message") 
  }
  /// If you reset everything
  public static var secretsResetWarningTitle: String { 
    return VectorL10n.tr("Vector", "secrets_reset_warning_title") 
  }
  /// Done
  public static var secretsSetupRecoveryKeyDoneAction: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_key_done_action") 
  }
  /// Save
  public static var secretsSetupRecoveryKeyExportAction: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_key_export_action") 
  }
  /// Store your Security Key somewhere safe. It can be used to unlock your encrypted messages & data.
  public static var secretsSetupRecoveryKeyInformation: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_key_information") 
  }
  /// Loading…
  public static var secretsSetupRecoveryKeyLoading: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_key_loading") 
  }
  /// ✓ Print it and store it somewhere safe\n✓ Save it on a USB key or backup drive\n✓ Copy it to your personal cloud storage
  public static var secretsSetupRecoveryKeyStorageAlertMessage: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_key_storage_alert_message") 
  }
  /// Keep it safe
  public static var secretsSetupRecoveryKeyStorageAlertTitle: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_key_storage_alert_title") 
  }
  /// Save your Security Key
  public static var secretsSetupRecoveryKeyTitle: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_key_title") 
  }
  /// Don't use your account password.
  public static var secretsSetupRecoveryPassphraseAdditionalInformation: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_passphrase_additional_information") 
  }
  /// Enter your Security Phrase again to confirm it.
  public static var secretsSetupRecoveryPassphraseConfirmInformation: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_passphrase_confirm_information") 
  }
  /// Confirm phrase
  public static var secretsSetupRecoveryPassphraseConfirmPassphrasePlaceholder: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_passphrase_confirm_passphrase_placeholder") 
  }
  /// Confirm
  public static var secretsSetupRecoveryPassphraseConfirmPassphraseTitle: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_passphrase_confirm_passphrase_title") 
  }
  /// Enter a security phrase only you know, used to secure secrets on your server.
  public static var secretsSetupRecoveryPassphraseInformation: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_passphrase_information") 
  }
  /// Remember your Security Phrase. It can be used to unlock your encrypted messages & data.
  public static var secretsSetupRecoveryPassphraseSummaryInformation: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_passphrase_summary_information") 
  }
  /// Save your Security Phrase
  public static var secretsSetupRecoveryPassphraseSummaryTitle: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_passphrase_summary_title") 
  }
  /// Set a Security Phrase
  public static var secretsSetupRecoveryPassphraseTitle: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_passphrase_title") 
  }
  /// Done
  public static var secretsSetupRecoveryPassphraseValidateAction: String { 
    return VectorL10n.tr("Vector", "secrets_setup_recovery_passphrase_validate_action") 
  }
  /// Safeguard against losing access to encrypted messages & data
  public static var secureBackupSetupBannerSubtitle: String { 
    return VectorL10n.tr("Vector", "secure_backup_setup_banner_subtitle") 
  }
  /// Secure Backup
  public static var secureBackupSetupBannerTitle: String { 
    return VectorL10n.tr("Vector", "secure_backup_setup_banner_title") 
  }
  /// If you cancel now, you may lose encrypted messages & data if you lose access to your logins.\n\nYou can also set up Secure Backup & manage your keys in Settings.
  public static var secureKeyBackupSetupCancelAlertMessage: String { 
    return VectorL10n.tr("Vector", "secure_key_backup_setup_cancel_alert_message") 
  }
  /// Are your sure?
  public static var secureKeyBackupSetupCancelAlertTitle: String { 
    return VectorL10n.tr("Vector", "secure_key_backup_setup_cancel_alert_title") 
  }
  /// Delete it
  public static var secureKeyBackupSetupExistingBackupErrorDeleteIt: String { 
    return VectorL10n.tr("Vector", "secure_key_backup_setup_existing_backup_error_delete_it") 
  }
  /// Unlock it to reuse it in the secure backup or delete it to create a new messages backup in the secure backup.
  public static var secureKeyBackupSetupExistingBackupErrorInfo: String { 
    return VectorL10n.tr("Vector", "secure_key_backup_setup_existing_backup_error_info") 
  }
  /// A backup for messages already exists
  public static var secureKeyBackupSetupExistingBackupErrorTitle: String { 
    return VectorL10n.tr("Vector", "secure_key_backup_setup_existing_backup_error_title") 
  }
  /// Unlock it
  public static var secureKeyBackupSetupExistingBackupErrorUnlockIt: String { 
    return VectorL10n.tr("Vector", "secure_key_backup_setup_existing_backup_error_unlock_it") 
  }
  /// Safeguard against losing access to encrypted messages & data by backing up encryption keys on your server.
  public static var secureKeyBackupSetupIntroInfo: String { 
    return VectorL10n.tr("Vector", "secure_key_backup_setup_intro_info") 
  }
  /// Secure Backup
  public static var secureKeyBackupSetupIntroTitle: String { 
    return VectorL10n.tr("Vector", "secure_key_backup_setup_intro_title") 
  }
  /// Generate a security key to store somewhere safe like a password manager or a safe.
  public static var secureKeyBackupSetupIntroUseSecurityKeyInfo: String { 
    return VectorL10n.tr("Vector", "secure_key_backup_setup_intro_use_security_key_info") 
  }
  /// Use a Security Key
  public static var secureKeyBackupSetupIntroUseSecurityKeyTitle: String { 
    return VectorL10n.tr("Vector", "secure_key_backup_setup_intro_use_security_key_title") 
  }
  /// Enter a secret phrase only you know, and generate a key for backup.
  public static var secureKeyBackupSetupIntroUseSecurityPassphraseInfo: String { 
    return VectorL10n.tr("Vector", "secure_key_backup_setup_intro_use_security_passphrase_info") 
  }
  /// Use a Security Phrase
  public static var secureKeyBackupSetupIntroUseSecurityPassphraseTitle: String { 
    return VectorL10n.tr("Vector", "secure_key_backup_setup_intro_use_security_passphrase_title") 
  }
  /// ADVANCED
  public static var securitySettingsAdvanced: String { 
    return VectorL10n.tr("Vector", "security_settings_advanced") 
  }
  /// MESSAGE BACKUP
  public static var securitySettingsBackup: String { 
    return VectorL10n.tr("Vector", "security_settings_backup") 
  }
  /// Never send messages to untrusted sessions
  public static var securitySettingsBlacklistUnverifiedDevices: String { 
    return VectorL10n.tr("Vector", "security_settings_blacklist_unverified_devices") 
  }
  /// Verify all of a users sessions to mark them as trusted and send messages to them.
  public static var securitySettingsBlacklistUnverifiedDevicesDescription: String { 
    return VectorL10n.tr("Vector", "security_settings_blacklist_unverified_devices_description") 
  }
  /// Sorry. This action is not available on %@ iOS yet. Please use another Matrix client to set it up. %@ iOS will use it.
  public static func securitySettingsComingSoon(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "security_settings_coming_soon", p1, p2)
  }
  /// You should complete security on your current session first.
  public static var securitySettingsCompleteSecurityAlertMessage: String { 
    return VectorL10n.tr("Vector", "security_settings_complete_security_alert_message") 
  }
  /// Complete security
  public static var securitySettingsCompleteSecurityAlertTitle: String { 
    return VectorL10n.tr("Vector", "security_settings_complete_security_alert_title") 
  }
  /// CROSS-SIGNING
  public static var securitySettingsCrosssigning: String { 
    return VectorL10n.tr("Vector", "security_settings_crosssigning") 
  }
  /// Set up
  public static var securitySettingsCrosssigningBootstrap: String { 
    return VectorL10n.tr("Vector", "security_settings_crosssigning_bootstrap") 
  }
  /// Complete security
  public static var securitySettingsCrosssigningCompleteSecurity: String { 
    return VectorL10n.tr("Vector", "security_settings_crosssigning_complete_security") 
  }
  /// Your account has a cross-signing identity, but it is not yet trusted by this session. Complete security of this session.
  public static var securitySettingsCrosssigningInfoExists: String { 
    return VectorL10n.tr("Vector", "security_settings_crosssigning_info_exists") 
  }
  /// Cross-signing is not yet set up.
  public static var securitySettingsCrosssigningInfoNotBootstrapped: String { 
    return VectorL10n.tr("Vector", "security_settings_crosssigning_info_not_bootstrapped") 
  }
  /// Cross-signing is ready for use.
  public static var securitySettingsCrosssigningInfoOk: String { 
    return VectorL10n.tr("Vector", "security_settings_crosssigning_info_ok") 
  }
  /// Cross-signing is enabled. You can trust other users and your other sessions based on cross-signing but you cannot cross-sign from this session because it does not have cross-signing private keys. Complete security of this session.
  public static var securitySettingsCrosssigningInfoTrusted: String { 
    return VectorL10n.tr("Vector", "security_settings_crosssigning_info_trusted") 
  }
  /// Reset
  public static var securitySettingsCrosssigningReset: String { 
    return VectorL10n.tr("Vector", "security_settings_crosssigning_reset") 
  }
  /// MY SESSIONS
  public static var securitySettingsCryptoSessions: String { 
    return VectorL10n.tr("Vector", "security_settings_crypto_sessions") 
  }
  /// If you don’t recognise a login, change your password and reset Secure Backup.
  public static var securitySettingsCryptoSessionsDescription2: String { 
    return VectorL10n.tr("Vector", "security_settings_crypto_sessions_description_2") 
  }
  /// Loading sessions…
  public static var securitySettingsCryptoSessionsLoading: String { 
    return VectorL10n.tr("Vector", "security_settings_crypto_sessions_loading") 
  }
  /// CRYPTOGRAPHY
  public static var securitySettingsCryptography: String { 
    return VectorL10n.tr("Vector", "security_settings_cryptography") 
  }
  /// Export keys manually
  public static var securitySettingsExportKeysManually: String { 
    return VectorL10n.tr("Vector", "security_settings_export_keys_manually") 
  }
  /// SECURE BACKUP
  public static var securitySettingsSecureBackup: String { 
    return VectorL10n.tr("Vector", "security_settings_secure_backup") 
  }
  /// Delete Backup
  public static var securitySettingsSecureBackupDelete: String { 
    return VectorL10n.tr("Vector", "security_settings_secure_backup_delete") 
  }
  /// Back up your encryption keys with your account data in case you lose access to your sessions. Your keys will be secured with a unique Security Key.
  public static var securitySettingsSecureBackupDescription: String { 
    return VectorL10n.tr("Vector", "security_settings_secure_backup_description") 
  }
  /// Checking…
  public static var securitySettingsSecureBackupInfoChecking: String { 
    return VectorL10n.tr("Vector", "security_settings_secure_backup_info_checking") 
  }
  /// This session is backing up your keys.
  public static var securitySettingsSecureBackupInfoValid: String { 
    return VectorL10n.tr("Vector", "security_settings_secure_backup_info_valid") 
  }
  /// Reset
  public static var securitySettingsSecureBackupReset: String { 
    return VectorL10n.tr("Vector", "security_settings_secure_backup_reset") 
  }
  /// Restore from Backup
  public static var securitySettingsSecureBackupRestore: String { 
    return VectorL10n.tr("Vector", "security_settings_secure_backup_restore") 
  }
  /// Set up
  public static var securitySettingsSecureBackupSetup: String { 
    return VectorL10n.tr("Vector", "security_settings_secure_backup_setup") 
  }
  /// Security
  public static var securitySettingsTitle: String { 
    return VectorL10n.tr("Vector", "security_settings_title") 
  }
  /// Confirm your identity by entering your account password
  public static var securitySettingsUserPasswordDescription: String { 
    return VectorL10n.tr("Vector", "security_settings_user_password_description") 
  }
  /// Send to %@
  public static func sendTo(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "send_to", p1)
  }
  /// Sending
  public static var sending: String { 
    return VectorL10n.tr("Vector", "sending") 
  }
  /// Accept
  public static var serviceTermsModalAcceptButton: String { 
    return VectorL10n.tr("Vector", "service_terms_modal_accept_button") 
  }
  /// Decline
  public static var serviceTermsModalDeclineButton: String { 
    return VectorL10n.tr("Vector", "service_terms_modal_decline_button") 
  }
  /// This will allow someone to find you if they have your phone number or email saved in their phone contacts.
  public static var serviceTermsModalDescriptionIdentityServer: String { 
    return VectorL10n.tr("Vector", "service_terms_modal_description_identity_server") 
  }
  /// This will allow you to use bots, bridges, widgets and sticker packs.
  public static var serviceTermsModalDescriptionIntegrationManager: String { 
    return VectorL10n.tr("Vector", "service_terms_modal_description_integration_manager") 
  }
  /// This can be disabled anytime in settings.
  public static var serviceTermsModalFooter: String { 
    return VectorL10n.tr("Vector", "service_terms_modal_footer") 
  }
  /// An identity server helps you find your contacts, by looking up their phone number or email address, to see if they already have an account.
  public static var serviceTermsModalInformationDescriptionIdentityServer: String { 
    return VectorL10n.tr("Vector", "service_terms_modal_information_description_identity_server") 
  }
  /// An integration manager lets you add features from third parties.
  public static var serviceTermsModalInformationDescriptionIntegrationManager: String { 
    return VectorL10n.tr("Vector", "service_terms_modal_information_description_integration_manager") 
  }
  /// Identity Server
  public static var serviceTermsModalInformationTitleIdentityServer: String { 
    return VectorL10n.tr("Vector", "service_terms_modal_information_title_identity_server") 
  }
  /// Integration Manager
  public static var serviceTermsModalInformationTitleIntegrationManager: String { 
    return VectorL10n.tr("Vector", "service_terms_modal_information_title_integration_manager") 
  }
  /// Check to accept %@
  public static func serviceTermsModalPolicyCheckboxAccessibilityHint(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "service_terms_modal_policy_checkbox_accessibility_hint", p1)
  }
  /// IDENTITY SERVER TERMS
  public static var serviceTermsModalTableHeaderIdentityServer: String { 
    return VectorL10n.tr("Vector", "service_terms_modal_table_header_identity_server") 
  }
  /// INTEGRATION MANAGER TERMS
  public static var serviceTermsModalTableHeaderIntegrationManager: String { 
    return VectorL10n.tr("Vector", "service_terms_modal_table_header_integration_manager") 
  }
  /// To continue, accept the below terms and conditions
  public static var serviceTermsModalTitleMessage: String { 
    return VectorL10n.tr("Vector", "service_terms_modal_title_message") 
  }
  /// ABOUT
  public static var settingsAbout: String { 
    return VectorL10n.tr("Vector", "settings_about") 
  }
  /// Invalid credentials
  public static var settingsAdd3pidInvalidPasswordMessage: String { 
    return VectorL10n.tr("Vector", "settings_add_3pid_invalid_password_message") 
  }
  /// To continue, please enter your password
  public static var settingsAdd3pidPasswordMessage: String { 
    return VectorL10n.tr("Vector", "settings_add_3pid_password_message") 
  }
  /// Add email address
  public static var settingsAdd3pidPasswordTitleEmail: String { 
    return VectorL10n.tr("Vector", "settings_add_3pid_password_title_email") 
  }
  /// Add phone number
  public static var settingsAdd3pidPasswordTitleMsidsn: String { 
    return VectorL10n.tr("Vector", "settings_add_3pid_password_title_msidsn") 
  }
  /// Add email address
  public static var settingsAddEmailAddress: String { 
    return VectorL10n.tr("Vector", "settings_add_email_address") 
  }
  /// Add phone number
  public static var settingsAddPhoneNumber: String { 
    return VectorL10n.tr("Vector", "settings_add_phone_number") 
  }
  /// ADVANCED
  public static var settingsAdvanced: String { 
    return VectorL10n.tr("Vector", "settings_advanced") 
  }
  /// Send crash and analytics data
  public static var settingsAnalyticsAndCrashData: String { 
    return VectorL10n.tr("Vector", "settings_analytics_and_crash_data") 
  }
  /// Call invitations
  public static var settingsCallInvitations: String { 
    return VectorL10n.tr("Vector", "settings_call_invitations") 
  }
  /// Receive incoming calls on your lock screen. See your %@ calls in the system's call history. If iCloud is enabled, this call history will be shared with Apple.
  public static func settingsCallkitInfo(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_callkit_info", p1)
  }
  /// CALLS
  public static var settingsCallsSettings: String { 
    return VectorL10n.tr("Vector", "settings_calls_settings") 
  }
  /// Allow fallback call assist server
  public static var settingsCallsStunServerFallbackButton: String { 
    return VectorL10n.tr("Vector", "settings_calls_stun_server_fallback_button") 
  }
  /// Allow fallback call assist server %@ when your homeserver does not offer one (your IP address would be shared during a call).
  public static func settingsCallsStunServerFallbackDescription(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_calls_stun_server_fallback_description", p1)
  }
  /// Change password
  public static var settingsChangePassword: String { 
    return VectorL10n.tr("Vector", "settings_change_password") 
  }
  /// Clear cache
  public static var settingsClearCache: String { 
    return VectorL10n.tr("Vector", "settings_clear_cache") 
  }
  /// Homeserver is %@
  public static func settingsConfigHomeServer(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_config_home_server", p1)
  }
  /// No build info
  public static var settingsConfigNoBuildInfo: String { 
    return VectorL10n.tr("Vector", "settings_config_no_build_info") 
  }
  /// Logged in as %@
  public static func settingsConfigUserId(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_config_user_id", p1)
  }
  /// Confirm size when sending
  public static var settingsConfirmMediaSize: String { 
    return VectorL10n.tr("Vector", "settings_confirm_media_size") 
  }
  /// When this is on, you’ll be asked to confirm what size images and videos will be sent as.
  public static var settingsConfirmMediaSizeDescription: String { 
    return VectorL10n.tr("Vector", "settings_confirm_media_size_description") 
  }
  /// confirm password
  public static var settingsConfirmPassword: String { 
    return VectorL10n.tr("Vector", "settings_confirm_password") 
  }
  /// DEVICE CONTACTS
  public static var settingsContacts: String { 
    return VectorL10n.tr("Vector", "settings_contacts") 
  }
  /// Find your contacts
  public static var settingsContactsEnableSync: String { 
    return VectorL10n.tr("Vector", "settings_contacts_enable_sync") 
  }
  /// This will use your identity server to connect you with your contacts, and help them find you.
  public static var settingsContactsEnableSyncDescription: String { 
    return VectorL10n.tr("Vector", "settings_contacts_enable_sync_description") 
  }
  /// Phonebook country
  public static var settingsContactsPhonebookCountry: String { 
    return VectorL10n.tr("Vector", "settings_contacts_phonebook_country") 
  }
  /// Copyright
  public static var settingsCopyright: String { 
    return VectorL10n.tr("Vector", "settings_copyright") 
  }
  /// Encrypt to verified sessions only
  public static var settingsCryptoBlacklistUnverifiedDevices: String { 
    return VectorL10n.tr("Vector", "settings_crypto_blacklist_unverified_devices") 
  }
  /// \nSession ID: 
  public static var settingsCryptoDeviceId: String { 
    return VectorL10n.tr("Vector", "settings_crypto_device_id") 
  }
  /// \nSession key:\n
  public static var settingsCryptoDeviceKey: String { 
    return VectorL10n.tr("Vector", "settings_crypto_device_key") 
  }
  /// Session name: 
  public static var settingsCryptoDeviceName: String { 
    return VectorL10n.tr("Vector", "settings_crypto_device_name") 
  }
  /// Export keys
  public static var settingsCryptoExport: String { 
    return VectorL10n.tr("Vector", "settings_crypto_export") 
  }
  /// CRYPTOGRAPHY
  public static var settingsCryptography: String { 
    return VectorL10n.tr("Vector", "settings_cryptography") 
  }
  /// DEACTIVATE ACCOUNT
  public static var settingsDeactivateAccount: String { 
    return VectorL10n.tr("Vector", "settings_deactivate_account") 
  }
  /// Deactivate my account
  public static var settingsDeactivateMyAccount: String { 
    return VectorL10n.tr("Vector", "settings_deactivate_my_account") 
  }
  /// Default Notifications
  public static var settingsDefault: String { 
    return VectorL10n.tr("Vector", "settings_default") 
  }
  /// Device notifications
  public static var settingsDeviceNotifications: String { 
    return VectorL10n.tr("Vector", "settings_device_notifications") 
  }
  /// SESSIONS
  public static var settingsDevices: String { 
    return VectorL10n.tr("Vector", "settings_devices") 
  }
  /// A session's public name is visible to people you communicate with
  public static var settingsDevicesDescription: String { 
    return VectorL10n.tr("Vector", "settings_devices_description") 
  }
  /// Direct messages
  public static var settingsDirectMessages: String { 
    return VectorL10n.tr("Vector", "settings_direct_messages") 
  }
  /// Accept Identity Server Terms
  public static var settingsDiscoveryAcceptTerms: String { 
    return VectorL10n.tr("Vector", "settings_discovery_accept_terms") 
  }
  /// An error occured. Please retry.
  public static var settingsDiscoveryErrorMessage: String { 
    return VectorL10n.tr("Vector", "settings_discovery_error_message") 
  }
  /// You are not currently using an identity server. To be discoverable by existing contacts you known, add one.
  public static var settingsDiscoveryNoIdentityServer: String { 
    return VectorL10n.tr("Vector", "settings_discovery_no_identity_server") 
  }
  /// DISCOVERY
  public static var settingsDiscoverySettings: String { 
    return VectorL10n.tr("Vector", "settings_discovery_settings") 
  }
  /// Agree to the identity server (%@) Terms of Service to allow yourself to be discoverable by email address or phone number.
  public static func settingsDiscoveryTermsNotSigned(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_discovery_terms_not_signed", p1)
  }
  /// Cancel email validation
  public static var settingsDiscoveryThreePidDetailsCancelEmailValidationAction: String { 
    return VectorL10n.tr("Vector", "settings_discovery_three_pid_details_cancel_email_validation_action") 
  }
  /// Enter SMS activation code
  public static var settingsDiscoveryThreePidDetailsEnterSmsCodeAction: String { 
    return VectorL10n.tr("Vector", "settings_discovery_three_pid_details_enter_sms_code_action") 
  }
  /// Manage preferences for this email address, which other users can use to discover you and use to invite you to rooms. Add or remove email addresses in Accounts.
  public static var settingsDiscoveryThreePidDetailsInformationEmail: String { 
    return VectorL10n.tr("Vector", "settings_discovery_three_pid_details_information_email") 
  }
  /// Manage preferences for this phone number, which other users can use to discover you and use to invite you to rooms. Add or remove phone numbers in Accounts.
  public static var settingsDiscoveryThreePidDetailsInformationPhoneNumber: String { 
    return VectorL10n.tr("Vector", "settings_discovery_three_pid_details_information_phone_number") 
  }
  /// Revoke
  public static var settingsDiscoveryThreePidDetailsRevokeAction: String { 
    return VectorL10n.tr("Vector", "settings_discovery_three_pid_details_revoke_action") 
  }
  /// Share
  public static var settingsDiscoveryThreePidDetailsShareAction: String { 
    return VectorL10n.tr("Vector", "settings_discovery_three_pid_details_share_action") 
  }
  /// Manage email
  public static var settingsDiscoveryThreePidDetailsTitleEmail: String { 
    return VectorL10n.tr("Vector", "settings_discovery_three_pid_details_title_email") 
  }
  /// Manage phone number
  public static var settingsDiscoveryThreePidDetailsTitlePhoneNumber: String { 
    return VectorL10n.tr("Vector", "settings_discovery_three_pid_details_title_phone_number") 
  }
  /// Manage which email addresses or phone numbers other users can use to discover you and use to invite you to rooms. Add or remove email addresses or phone numbers from this list in 
  public static var settingsDiscoveryThreePidsManagementInformationPart1: String { 
    return VectorL10n.tr("Vector", "settings_discovery_three_pids_management_information_part1") 
  }
  /// User Settings
  public static var settingsDiscoveryThreePidsManagementInformationPart2: String { 
    return VectorL10n.tr("Vector", "settings_discovery_three_pids_management_information_part2") 
  }
  /// .
  public static var settingsDiscoveryThreePidsManagementInformationPart3: String { 
    return VectorL10n.tr("Vector", "settings_discovery_three_pids_management_information_part3") 
  }
  /// Display Name
  public static var settingsDisplayName: String { 
    return VectorL10n.tr("Vector", "settings_display_name") 
  }
  /// Email
  public static var settingsEmailAddress: String { 
    return VectorL10n.tr("Vector", "settings_email_address") 
  }
  /// Enter your email address
  public static var settingsEmailAddressPlaceholder: String { 
    return VectorL10n.tr("Vector", "settings_email_address_placeholder") 
  }
  /// Integrated calling
  public static var settingsEnableCallkit: String { 
    return VectorL10n.tr("Vector", "settings_enable_callkit") 
  }
  /// Notifications on this device
  public static var settingsEnablePushNotif: String { 
    return VectorL10n.tr("Vector", "settings_enable_push_notif") 
  }
  /// Rage shake to report bug
  public static var settingsEnableRageshake: String { 
    return VectorL10n.tr("Vector", "settings_enable_rageshake") 
  }
  /// Message bubbles
  public static var settingsEnableRoomMessageBubbles: String { 
    return VectorL10n.tr("Vector", "settings_enable_room_message_bubbles") 
  }
  /// Encrypted direct messages
  public static var settingsEncryptedDirectMessages: String { 
    return VectorL10n.tr("Vector", "settings_encrypted_direct_messages") 
  }
  /// Encrypted group messages
  public static var settingsEncryptedGroupMessages: String { 
    return VectorL10n.tr("Vector", "settings_encrypted_group_messages") 
  }
  /// Fail to update password
  public static var settingsFailToUpdatePassword: String { 
    return VectorL10n.tr("Vector", "settings_fail_to_update_password") 
  }
  /// Fail to update profile
  public static var settingsFailToUpdateProfile: String { 
    return VectorL10n.tr("Vector", "settings_fail_to_update_profile") 
  }
  /// First Name
  public static var settingsFirstName: String { 
    return VectorL10n.tr("Vector", "settings_first_name") 
  }
  /// Show flair where allowed
  public static var settingsFlair: String { 
    return VectorL10n.tr("Vector", "settings_flair") 
  }
  /// Global notification settings are available on your %@ web client
  public static func settingsGlobalSettingsInfo(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_global_settings_info", p1)
  }
  /// Group messages
  public static var settingsGroupMessages: String { 
    return VectorL10n.tr("Vector", "settings_group_messages") 
  }
  /// Using the identity server set above, you can discover and be discoverable by existing contacts you know.
  public static var settingsIdentityServerDescription: String { 
    return VectorL10n.tr("Vector", "settings_identity_server_description") 
  }
  /// No identity server configured
  public static var settingsIdentityServerNoIs: String { 
    return VectorL10n.tr("Vector", "settings_identity_server_no_is") 
  }
  /// You are not currently using an identity server. To discover and be discoverable by existing contacts you know, add one above.
  public static var settingsIdentityServerNoIsDescription: String { 
    return VectorL10n.tr("Vector", "settings_identity_server_no_is_description") 
  }
  /// IDENTITY SERVER
  public static var settingsIdentityServerSettings: String { 
    return VectorL10n.tr("Vector", "settings_identity_server_settings") 
  }
  /// IGNORED USERS
  public static var settingsIgnoredUsers: String { 
    return VectorL10n.tr("Vector", "settings_ignored_users") 
  }
  /// INTEGRATIONS
  public static var settingsIntegrations: String { 
    return VectorL10n.tr("Vector", "settings_integrations") 
  }
  /// Manage integrations
  public static var settingsIntegrationsAllowButton: String { 
    return VectorL10n.tr("Vector", "settings_integrations_allow_button") 
  }
  /// Use an integration manager (%@) to manage bots, bridges, widgets and sticker packs.\n\nIntegration managers receive configuration data, and can modify widgets, send room invites and set power levels on your behalf.
  public static func settingsIntegrationsAllowDescription(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_integrations_allow_description", p1)
  }
  /// KEY BACKUP
  public static var settingsKeyBackup: String { 
    return VectorL10n.tr("Vector", "settings_key_backup") 
  }
  /// Connect this session to Key Backup
  public static var settingsKeyBackupButtonConnect: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_button_connect") 
  }
  /// Start using Key Backup
  public static var settingsKeyBackupButtonCreate: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_button_create") 
  }
  /// Delete Backup
  public static var settingsKeyBackupButtonDelete: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_button_delete") 
  }
  /// Restore from Backup
  public static var settingsKeyBackupButtonRestore: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_button_restore") 
  }
  /// Are you sure? You will lose your encrypted messages if your keys are not backed up properly.
  public static var settingsKeyBackupDeleteConfirmationPromptMsg: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_delete_confirmation_prompt_msg") 
  }
  /// Delete Backup
  public static var settingsKeyBackupDeleteConfirmationPromptTitle: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_delete_confirmation_prompt_title") 
  }
  /// Encrypted messages are secured with end-to-end encryption. Only you and the recipient(s) have the keys to read these messages.
  public static var settingsKeyBackupInfo: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info") 
  }
  /// Algorithm: %@
  public static func settingsKeyBackupInfoAlgorithm(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_algorithm", p1)
  }
  /// Checking…
  public static var settingsKeyBackupInfoChecking: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_checking") 
  }
  /// Your keys are not being backed up from this session.
  public static var settingsKeyBackupInfoNone: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_none") 
  }
  /// This session is not backing up your keys, but you do have an existing backup you can restore from and add to going forward.
  public static var settingsKeyBackupInfoNotValid: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_not_valid") 
  }
  /// Backing up %@ keys…
  public static func settingsKeyBackupInfoProgress(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_progress", p1)
  }
  /// All keys backed up
  public static var settingsKeyBackupInfoProgressDone: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_progress_done") 
  }
  /// Back up your keys before signing out to avoid losing them.
  public static var settingsKeyBackupInfoSignoutWarning: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_signout_warning") 
  }
  /// Backup has an invalid signature from %@
  public static func settingsKeyBackupInfoTrustSignatureInvalidDeviceUnverified(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_trust_signature_invalid_device_unverified", p1)
  }
  /// Backup has an invalid signature from %@
  public static func settingsKeyBackupInfoTrustSignatureInvalidDeviceVerified(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_trust_signature_invalid_device_verified", p1)
  }
  /// Backup has a signature from session with ID: %@
  public static func settingsKeyBackupInfoTrustSignatureUnknown(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_trust_signature_unknown", p1)
  }
  /// Backup has a valid signature from this session
  public static var settingsKeyBackupInfoTrustSignatureValid: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_trust_signature_valid") 
  }
  /// Backup has a signature from %@
  public static func settingsKeyBackupInfoTrustSignatureValidDeviceUnverified(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_trust_signature_valid_device_unverified", p1)
  }
  /// Backup has a valid signature from %@
  public static func settingsKeyBackupInfoTrustSignatureValidDeviceVerified(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_trust_signature_valid_device_verified", p1)
  }
  /// This session is backing up your keys.
  public static var settingsKeyBackupInfoValid: String { 
    return VectorL10n.tr("Vector", "settings_key_backup_info_valid") 
  }
  /// Key Backup Version: %@
  public static func settingsKeyBackupInfoVersion(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_key_backup_info_version", p1)
  }
  /// LABS
  public static var settingsLabs: String { 
    return VectorL10n.tr("Vector", "settings_labs") 
  }
  /// Create conference calls with jitsi
  public static var settingsLabsCreateConferenceWithJitsi: String { 
    return VectorL10n.tr("Vector", "settings_labs_create_conference_with_jitsi") 
  }
  /// End-to-End Encryption
  public static var settingsLabsE2eEncryption: String { 
    return VectorL10n.tr("Vector", "settings_labs_e2e_encryption") 
  }
  /// To finish setting up encryption you must log in again.
  public static var settingsLabsE2eEncryptionPromptMessage: String { 
    return VectorL10n.tr("Vector", "settings_labs_e2e_encryption_prompt_message") 
  }
  /// Ring for group calls
  public static var settingsLabsEnableRingingForGroupCalls: String { 
    return VectorL10n.tr("Vector", "settings_labs_enable_ringing_for_group_calls") 
  }
  /// Polls
  public static var settingsLabsEnabledPolls: String { 
    return VectorL10n.tr("Vector", "settings_labs_enabled_polls") 
  }
  /// React to messages with emoji
  public static var settingsLabsMessageReaction: String { 
    return VectorL10n.tr("Vector", "settings_labs_message_reaction") 
  }
  /// LINKS
  public static var settingsLinks: String { 
    return VectorL10n.tr("Vector", "settings_links") 
  }
  /// Mark all messages as read
  public static var settingsMarkAllAsRead: String { 
    return VectorL10n.tr("Vector", "settings_mark_all_as_read") 
  }
  /// Mentions and Keywords
  public static var settingsMentionsAndKeywords: String { 
    return VectorL10n.tr("Vector", "settings_mentions_and_keywords") 
  }
  /// You won’t get notifications for mentions & keywords in encrypted rooms on mobile.
  public static var settingsMentionsAndKeywordsEncryptionNotice: String { 
    return VectorL10n.tr("Vector", "settings_mentions_and_keywords_encryption_notice") 
  }
  /// Messages by a bot
  public static var settingsMessagesByABot: String { 
    return VectorL10n.tr("Vector", "settings_messages_by_a_bot") 
  }
  /// @room
  public static var settingsMessagesContainingAtRoom: String { 
    return VectorL10n.tr("Vector", "settings_messages_containing_at_room") 
  }
  /// My display name
  public static var settingsMessagesContainingDisplayName: String { 
    return VectorL10n.tr("Vector", "settings_messages_containing_display_name") 
  }
  /// Keywords
  public static var settingsMessagesContainingKeywords: String { 
    return VectorL10n.tr("Vector", "settings_messages_containing_keywords") 
  }
  /// My username
  public static var settingsMessagesContainingUserName: String { 
    return VectorL10n.tr("Vector", "settings_messages_containing_user_name") 
  }
  /// Add new Keyword
  public static var settingsNewKeyword: String { 
    return VectorL10n.tr("Vector", "settings_new_keyword") 
  }
  /// new password
  public static var settingsNewPassword: String { 
    return VectorL10n.tr("Vector", "settings_new_password") 
  }
  /// Night Mode
  public static var settingsNightMode: String { 
    return VectorL10n.tr("Vector", "settings_night_mode") 
  }
  /// NOTIFICATIONS
  public static var settingsNotifications: String { 
    return VectorL10n.tr("Vector", "settings_notifications") 
  }
  /// To enable notifications, go to your device settings.
  public static var settingsNotificationsDisabledAlertMessage: String { 
    return VectorL10n.tr("Vector", "settings_notifications_disabled_alert_message") 
  }
  /// Notifications disabled
  public static var settingsNotificationsDisabledAlertTitle: String { 
    return VectorL10n.tr("Vector", "settings_notifications_disabled_alert_title") 
  }
  /// Notify me for
  public static var settingsNotifyMeFor: String { 
    return VectorL10n.tr("Vector", "settings_notify_me_for") 
  }
  /// old password
  public static var settingsOldPassword: String { 
    return VectorL10n.tr("Vector", "settings_old_password") 
  }
  /// Olm Version %@
  public static func settingsOlmVersion(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_olm_version", p1)
  }
  /// Other
  public static var settingsOther: String { 
    return VectorL10n.tr("Vector", "settings_other") 
  }
  /// Your password has been updated
  public static var settingsPasswordUpdated: String { 
    return VectorL10n.tr("Vector", "settings_password_updated") 
  }
  /// PHONE CONTACTS
  public static var settingsPhoneContacts: String { 
    return VectorL10n.tr("Vector", "settings_phone_contacts") 
  }
  /// Phone
  public static var settingsPhoneNumber: String { 
    return VectorL10n.tr("Vector", "settings_phone_number") 
  }
  /// Pin rooms with missed notifications
  public static var settingsPinRoomsWithMissedNotif: String { 
    return VectorL10n.tr("Vector", "settings_pin_rooms_with_missed_notif") 
  }
  /// Pin rooms with unread messages
  public static var settingsPinRoomsWithUnread: String { 
    return VectorL10n.tr("Vector", "settings_pin_rooms_with_unread") 
  }
  /// Privacy Policy
  public static var settingsPrivacyPolicy: String { 
    return VectorL10n.tr("Vector", "settings_privacy_policy") 
  }
  /// Profile Picture
  public static var settingsProfilePicture: String { 
    return VectorL10n.tr("Vector", "settings_profile_picture") 
  }
  /// Are you sure you want to remove the email address %@?
  public static func settingsRemoveEmailPromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_remove_email_prompt_msg", p1)
  }
  /// Are you sure you want to remove the phone number %@?
  public static func settingsRemovePhonePromptMsg(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_remove_phone_prompt_msg", p1)
  }
  /// Confirmation
  public static var settingsRemovePromptTitle: String { 
    return VectorL10n.tr("Vector", "settings_remove_prompt_title") 
  }
  /// Report bug
  public static var settingsReportBug: String { 
    return VectorL10n.tr("Vector", "settings_report_bug") 
  }
  /// Room invitations
  public static var settingsRoomInvitations: String { 
    return VectorL10n.tr("Vector", "settings_room_invitations") 
  }
  /// Room upgrades
  public static var settingsRoomUpgrades: String { 
    return VectorL10n.tr("Vector", "settings_room_upgrades") 
  }
  /// SECURITY
  public static var settingsSecurity: String { 
    return VectorL10n.tr("Vector", "settings_security") 
  }
  /// SENDING IMAGES AND VIDEOS
  public static var settingsSendingMedia: String { 
    return VectorL10n.tr("Vector", "settings_sending_media") 
  }
  /// Show decrypted content
  public static var settingsShowDecryptedContent: String { 
    return VectorL10n.tr("Vector", "settings_show_decrypted_content") 
  }
  /// Show NSFW public rooms
  public static var settingsShowNSFWPublicRooms: String { 
    return VectorL10n.tr("Vector", "settings_show_NSFW_public_rooms") 
  }
  /// Show website preview
  public static var settingsShowUrlPreviews: String { 
    return VectorL10n.tr("Vector", "settings_show_url_previews") 
  }
  /// Previews will only be shown in unencrypted rooms.
  public static var settingsShowUrlPreviewsDescription: String { 
    return VectorL10n.tr("Vector", "settings_show_url_previews_description") 
  }
  /// Sign Out
  public static var settingsSignOut: String { 
    return VectorL10n.tr("Vector", "settings_sign_out") 
  }
  /// Are you sure?
  public static var settingsSignOutConfirmation: String { 
    return VectorL10n.tr("Vector", "settings_sign_out_confirmation") 
  }
  /// You will lose your end-to-end encryption keys. That means you will no longer be able to read old messages in encrypted rooms on this device.
  public static var settingsSignOutE2eWarn: String { 
    return VectorL10n.tr("Vector", "settings_sign_out_e2e_warn") 
  }
  /// Surname
  public static var settingsSurname: String { 
    return VectorL10n.tr("Vector", "settings_surname") 
  }
  /// Terms & Conditions
  public static var settingsTermConditions: String { 
    return VectorL10n.tr("Vector", "settings_term_conditions") 
  }
  /// Third-party Notices
  public static var settingsThirdPartyNotices: String { 
    return VectorL10n.tr("Vector", "settings_third_party_notices") 
  }
  /// Manage which email addresses or phone numbers you can use to log in or recover your account here. Control who can find you in 
  public static var settingsThreePidsManagementInformationPart1: String { 
    return VectorL10n.tr("Vector", "settings_three_pids_management_information_part1") 
  }
  /// Discovery
  public static var settingsThreePidsManagementInformationPart2: String { 
    return VectorL10n.tr("Vector", "settings_three_pids_management_information_part2") 
  }
  /// .
  public static var settingsThreePidsManagementInformationPart3: String { 
    return VectorL10n.tr("Vector", "settings_three_pids_management_information_part3") 
  }
  /// Settings
  public static var settingsTitle: String { 
    return VectorL10n.tr("Vector", "settings_title") 
  }
  /// Language
  public static var settingsUiLanguage: String { 
    return VectorL10n.tr("Vector", "settings_ui_language") 
  }
  /// Theme
  public static var settingsUiTheme: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme") 
  }
  /// Auto
  public static var settingsUiThemeAuto: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_auto") 
  }
  /// Black
  public static var settingsUiThemeBlack: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_black") 
  }
  /// Dark
  public static var settingsUiThemeDark: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_dark") 
  }
  /// Light
  public static var settingsUiThemeLight: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_light") 
  }
  /// "Auto" uses your device's "Invert Colours" settings
  public static var settingsUiThemePickerMessageInvertColours: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_picker_message_invert_colours") 
  }
  /// "Auto" matches your device's system theme
  public static var settingsUiThemePickerMessageMatchSystemTheme: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_picker_message_match_system_theme") 
  }
  /// Select a theme
  public static var settingsUiThemePickerTitle: String { 
    return VectorL10n.tr("Vector", "settings_ui_theme_picker_title") 
  }
  /// Show all messages from %@?
  public static func settingsUnignoreUser(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_unignore_user", p1)
  }
  /// USER INTERFACE
  public static var settingsUserInterface: String { 
    return VectorL10n.tr("Vector", "settings_user_interface") 
  }
  /// USER SETTINGS
  public static var settingsUserSettings: String { 
    return VectorL10n.tr("Vector", "settings_user_settings") 
  }
  /// Version %@
  public static func settingsVersion(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "settings_version", p1)
  }
  /// Your Keywords
  public static var settingsYourKeywords: String { 
    return VectorL10n.tr("Vector", "settings_your_keywords") 
  }
  /// Login in the main app to share content
  public static var shareExtensionAuthPrompt: String { 
    return VectorL10n.tr("Vector", "share_extension_auth_prompt") 
  }
  /// Failed to send. Check in the main app the encryption settings for this room
  public static var shareExtensionFailedToEncrypt: String { 
    return VectorL10n.tr("Vector", "share_extension_failed_to_encrypt") 
  }
  /// Send in %@ for better quality, or send in low quality below.
  public static func shareExtensionLowQualityVideoMessage(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "share_extension_low_quality_video_message", p1)
  }
  /// Video will be sent in low quality
  public static var shareExtensionLowQualityVideoTitle: String { 
    return VectorL10n.tr("Vector", "share_extension_low_quality_video_title") 
  }
  /// Send now
  public static var shareExtensionSendNow: String { 
    return VectorL10n.tr("Vector", "share_extension_send_now") 
  }
  /// Feedback
  public static var sideMenuActionFeedback: String { 
    return VectorL10n.tr("Vector", "side_menu_action_feedback") 
  }
  /// Help
  public static var sideMenuActionHelp: String { 
    return VectorL10n.tr("Vector", "side_menu_action_help") 
  }
  /// Invite friends
  public static var sideMenuActionInviteFriends: String { 
    return VectorL10n.tr("Vector", "side_menu_action_invite_friends") 
  }
  /// Settings
  public static var sideMenuActionSettings: String { 
    return VectorL10n.tr("Vector", "side_menu_action_settings") 
  }
  /// Version %@
  public static func sideMenuAppVersion(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "side_menu_app_version", p1)
  }
  /// Left panel
  public static var sideMenuRevealActionAccessibilityLabel: String { 
    return VectorL10n.tr("Vector", "side_menu_reveal_action_accessibility_label") 
  }
  /// Sign out
  public static var signOutExistingKeyBackupAlertSignOutAction: String { 
    return VectorL10n.tr("Vector", "sign_out_existing_key_backup_alert_sign_out_action") 
  }
  /// Are you sure you want to sign out?
  public static var signOutExistingKeyBackupAlertTitle: String { 
    return VectorL10n.tr("Vector", "sign_out_existing_key_backup_alert_title") 
  }
  /// I'll wait
  public static var signOutKeyBackupInProgressAlertCancelAction: String { 
    return VectorL10n.tr("Vector", "sign_out_key_backup_in_progress_alert_cancel_action") 
  }
  /// I don't want my encrypted messages
  public static var signOutKeyBackupInProgressAlertDiscardKeyBackupAction: String { 
    return VectorL10n.tr("Vector", "sign_out_key_backup_in_progress_alert_discard_key_backup_action") 
  }
  /// Key backup in progress. If you sign out now you’ll lose access to your encrypted messages.
  public static var signOutKeyBackupInProgressAlertTitle: String { 
    return VectorL10n.tr("Vector", "sign_out_key_backup_in_progress_alert_title") 
  }
  /// I don't want my encrypted messages
  public static var signOutNonExistingKeyBackupAlertDiscardKeyBackupAction: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_alert_discard_key_backup_action") 
  }
  /// Start using Secure Backup
  public static var signOutNonExistingKeyBackupAlertSetupSecureBackupAction: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_alert_setup_secure_backup_action") 
  }
  /// You’ll lose access to your encrypted messages if you sign out now
  public static var signOutNonExistingKeyBackupAlertTitle: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_alert_title") 
  }
  /// Backup
  public static var signOutNonExistingKeyBackupSignOutConfirmationAlertBackupAction: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_sign_out_confirmation_alert_backup_action") 
  }
  /// You'll lose access to your encrypted messages unless you back up your keys before signing out.
  public static var signOutNonExistingKeyBackupSignOutConfirmationAlertMessage: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_sign_out_confirmation_alert_message") 
  }
  /// Sign out
  public static var signOutNonExistingKeyBackupSignOutConfirmationAlertSignOutAction: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_sign_out_confirmation_alert_sign_out_action") 
  }
  /// You'll lose your encrypted messages
  public static var signOutNonExistingKeyBackupSignOutConfirmationAlertTitle: String { 
    return VectorL10n.tr("Vector", "sign_out_non_existing_key_backup_sign_out_confirmation_alert_title") 
  }
  /// Skip
  public static var skip: String { 
    return VectorL10n.tr("Vector", "skip") 
  }
  /// Continue with %@
  public static func socialLoginButtonTitleContinue(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "social_login_button_title_continue", p1)
  }
  /// Sign In with %@
  public static func socialLoginButtonTitleSignIn(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "social_login_button_title_sign_in", p1)
  }
  /// Sign Up with %@
  public static func socialLoginButtonTitleSignUp(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "social_login_button_title_sign_up", p1)
  }
  /// Continue with
  public static var socialLoginListTitleContinue: String { 
    return VectorL10n.tr("Vector", "social_login_list_title_continue") 
  }
  /// Or
  public static var socialLoginListTitleSignIn: String { 
    return VectorL10n.tr("Vector", "social_login_list_title_sign_in") 
  }
  /// Or
  public static var socialLoginListTitleSignUp: String { 
    return VectorL10n.tr("Vector", "social_login_list_title_sign_up") 
  }
  /// Change space avatar
  public static var spaceAvatarViewAccessibilityHint: String { 
    return VectorL10n.tr("Vector", "space_avatar_view_accessibility_hint") 
  }
  /// avatar
  public static var spaceAvatarViewAccessibilityLabel: String { 
    return VectorL10n.tr("Vector", "space_avatar_view_accessibility_label") 
  }
  /// BETA
  public static var spaceBetaAnnounceBadge: String { 
    return VectorL10n.tr("Vector", "space_beta_announce_badge") 
  }
  /// Spaces are a new way to group rooms and people. They’re not on iOS yet, but you can use them now on Web and Desktop.
  public static var spaceBetaAnnounceInformation: String { 
    return VectorL10n.tr("Vector", "space_beta_announce_information") 
  }
  /// The new version of communities
  public static var spaceBetaAnnounceSubtitle: String { 
    return VectorL10n.tr("Vector", "space_beta_announce_subtitle") 
  }
  /// Spaces are coming soon
  public static var spaceBetaAnnounceTitle: String { 
    return VectorL10n.tr("Vector", "space_beta_announce_title") 
  }
  /// Spaces are a new way to group rooms and people.\n\nThey’ll be here soon. For now, if you join one on another platform, you will be able to access any rooms you join here.
  public static var spaceFeatureUnavailableInformation: String { 
    return VectorL10n.tr("Vector", "space_feature_unavailable_information") 
  }
  /// Spaces aren't on iOS yet, but you can use them now on Web and Desktop
  public static var spaceFeatureUnavailableSubtitle: String { 
    return VectorL10n.tr("Vector", "space_feature_unavailable_subtitle") 
  }
  /// Spaces aren’t here yet
  public static var spaceFeatureUnavailableTitle: String { 
    return VectorL10n.tr("Vector", "space_feature_unavailable_title") 
  }
  /// Show all rooms
  public static var spaceHomeShowAllRooms: String { 
    return VectorL10n.tr("Vector", "space_home_show_all_rooms") 
  }
  /// Ban from this space
  public static var spaceParticipantsActionBan: String { 
    return VectorL10n.tr("Vector", "space_participants_action_ban") 
  }
  /// Remove from this space
  public static var spaceParticipantsActionRemove: String { 
    return VectorL10n.tr("Vector", "space_participants_action_remove") 
  }
  /// Private space
  public static var spacePrivateJoinRule: String { 
    return VectorL10n.tr("Vector", "space_private_join_rule") 
  }
  /// Public space
  public static var spacePublicJoinRule: String { 
    return VectorL10n.tr("Vector", "space_public_join_rule") 
  }
  /// space
  public static var spaceTag: String { 
    return VectorL10n.tr("Vector", "space_tag") 
  }
  /// Adding rooms coming soon
  public static var spacesAddRoomsComingSoonTitle: String { 
    return VectorL10n.tr("Vector", "spaces_add_rooms_coming_soon_title") 
  }
  /// This feature hasn’t been implemented here, but it’s on the way. For now, you can do that with %@ on your computer.
  public static func spacesComingSoonDetail(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "spaces_coming_soon_detail", p1)
  }
  /// Coming soon
  public static var spacesComingSoonTitle: String { 
    return VectorL10n.tr("Vector", "spaces_coming_soon_title") 
  }
  /// Some rooms may be hidden because they’re private and you need an invite.
  public static var spacesEmptySpaceDetail: String { 
    return VectorL10n.tr("Vector", "spaces_empty_space_detail") 
  }
  /// This space has no rooms (yet)
  public static var spacesEmptySpaceTitle: String { 
    return VectorL10n.tr("Vector", "spaces_empty_space_title") 
  }
  /// Explore rooms
  public static var spacesExploreRooms: String { 
    return VectorL10n.tr("Vector", "spaces_explore_rooms") 
  }
  /// Home
  public static var spacesHomeSpaceTitle: String { 
    return VectorL10n.tr("Vector", "spaces_home_space_title") 
  }
  /// Invites coming soon
  public static var spacesInvitesComingSoonTitle: String { 
    return VectorL10n.tr("Vector", "spaces_invites_coming_soon_title") 
  }
  /// Spaces
  public static var spacesLeftPanelTitle: String { 
    return VectorL10n.tr("Vector", "spaces_left_panel_title") 
  }
  /// Looking for someone not in %@? For now, you can invite them on web or desktop.
  public static func spacesNoMemberFoundDetail(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "spaces_no_member_found_detail", p1)
  }
  /// No results found
  public static var spacesNoResultFoundTitle: String { 
    return VectorL10n.tr("Vector", "spaces_no_result_found_title") 
  }
  /// Some results may be hidden because they’re private and you need an invite to join them.
  public static var spacesNoRoomFoundDetail: String { 
    return VectorL10n.tr("Vector", "spaces_no_room_found_detail") 
  }
  /// Suggested
  public static var spacesSuggestedRoom: String { 
    return VectorL10n.tr("Vector", "spaces_suggested_room") 
  }
  /// Start
  public static var start: String { 
    return VectorL10n.tr("Vector", "start") 
  }
  /// Element is a new type of messenger and collaboration app that:\n\n1. Puts you in control to preserve your privacy\n2. Lets you communicate with anyone in the Matrix network, and even beyond by integrating with apps such as Slack\n3. Protects you from advertising, datamining, backdoors and walled gardens\n4. Secures you through end-to-end encryption, with cross-signing to verify others\n\nElement is completely different from other messaging and collaboration apps because it is decentralised and open source.\n\nElement lets you self-host - or choose a host - so that you have privacy, ownership and control of your data and conversations. It gives you access to an open network; so you’re not just stuck speaking to other Element users only. And it is very secure.\n\nElement is able to do all this because it operates on Matrix - the standard for open, decentralised communication. \n\nElement puts you in control by letting you choose who hosts your conversations. From the Element app, you can choose to host in different ways:\n\n1. Get a free account on the matrix.org public server\n2. Self-host your account by running a server on your own hardware\n3. Sign up for an account on a custom server by simply subscribing to the Element Matrix Services hosting platform\n\nWhy choose Element?\n\nOWN YOUR DATA: You decide where to keep your data and messages. You own it and control it, not some MEGACORP that mines your data or gives access to third parties.\n\nOPEN MESSAGING AND COLLABORATION: You can chat with anyone else in the Matrix network, whether they’re using Element or another Matrix app, and even if they are using a different messaging system of the likes of Slack, IRC or XMPP.\n\nSUPER-SECURE: Real end-to-end encryption (only those in the conversation can decrypt messages), and cross-signing to verify the devices of conversation participants.\n\nCOMPLETE COMMUNICATION: Messaging, voice and video calls, file sharing, screen sharing and a whole bunch of integrations, bots and widgets. Build rooms, communities, stay in touch and get things done.\n\nEVERYWHERE YOU ARE: Stay in touch wherever you are with fully synchronised message history across all your devices and on the web at https://element.io/app.
  public static var storeFullDescription: String { 
    return VectorL10n.tr("Vector", "store_full_description") 
  }
  /// Privacy-preserving chat and collaboration app, on an open network. Decentralised to put you in control. No datamining, no backdoors and no third party access.
  public static var storePromotionalText: String { 
    return VectorL10n.tr("Vector", "store_promotional_text") 
  }
  /// Secure decentralised chat/VoIP
  public static var storeShortDescription: String { 
    return VectorL10n.tr("Vector", "store_short_description") 
  }
  /// Switch
  public static var `switch`: String { 
    return VectorL10n.tr("Vector", "switch") 
  }
  /// Favourites
  public static var titleFavourites: String { 
    return VectorL10n.tr("Vector", "title_favourites") 
  }
  /// Communities
  public static var titleGroups: String { 
    return VectorL10n.tr("Vector", "title_groups") 
  }
  /// Home
  public static var titleHome: String { 
    return VectorL10n.tr("Vector", "title_home") 
  }
  /// People
  public static var titlePeople: String { 
    return VectorL10n.tr("Vector", "title_people") 
  }
  /// Rooms
  public static var titleRooms: String { 
    return VectorL10n.tr("Vector", "title_rooms") 
  }
  /// Today
  public static var today: String { 
    return VectorL10n.tr("Vector", "today") 
  }
  /// This room contains unknown sessions which have not been verified.\nThis means there is no guarantee that the sessions belong to the users they claim to.\nWe recommend you go through the verification process for each session before continuing, but you can resend the message without verifying if you prefer.
  public static var unknownDevicesAlert: String { 
    return VectorL10n.tr("Vector", "unknown_devices_alert") 
  }
  /// Room contains unknown sessions
  public static var unknownDevicesAlertTitle: String { 
    return VectorL10n.tr("Vector", "unknown_devices_alert_title") 
  }
  /// Answer Anyway
  public static var unknownDevicesAnswerAnyway: String { 
    return VectorL10n.tr("Vector", "unknown_devices_answer_anyway") 
  }
  /// Call Anyway
  public static var unknownDevicesCallAnyway: String { 
    return VectorL10n.tr("Vector", "unknown_devices_call_anyway") 
  }
  /// Send Anyway
  public static var unknownDevicesSendAnyway: String { 
    return VectorL10n.tr("Vector", "unknown_devices_send_anyway") 
  }
  /// Unknown sessions
  public static var unknownDevicesTitle: String { 
    return VectorL10n.tr("Vector", "unknown_devices_title") 
  }
  /// Verify…
  public static var unknownDevicesVerify: String { 
    return VectorL10n.tr("Vector", "unknown_devices_verify") 
  }
  /// Change user avatar
  public static var userAvatarViewAccessibilityHint: String { 
    return VectorL10n.tr("Vector", "user_avatar_view_accessibility_hint") 
  }
  /// avatar
  public static var userAvatarViewAccessibilityLabel: String { 
    return VectorL10n.tr("Vector", "user_avatar_view_accessibility_label") 
  }
  /// If you didn’t sign in to this session, your account may be compromised.
  public static var userVerificationSessionDetailsAdditionalInformationUntrustedCurrentUser: String { 
    return VectorL10n.tr("Vector", "user_verification_session_details_additional_information_untrusted_current_user") 
  }
  /// Until this user trusts this session, messages sent to and from it are labelled with warnings. Alternatively, you can manually verify it.
  public static var userVerificationSessionDetailsAdditionalInformationUntrustedOtherUser: String { 
    return VectorL10n.tr("Vector", "user_verification_session_details_additional_information_untrusted_other_user") 
  }
  /// This session is trusted for secure messaging because you verified it:
  public static var userVerificationSessionDetailsInformationTrustedCurrentUser: String { 
    return VectorL10n.tr("Vector", "user_verification_session_details_information_trusted_current_user") 
  }
  /// This session is trusted for secure messaging because 
  public static var userVerificationSessionDetailsInformationTrustedOtherUserPart1: String { 
    return VectorL10n.tr("Vector", "user_verification_session_details_information_trusted_other_user_part1") 
  }
  ///  verified it:
  public static var userVerificationSessionDetailsInformationTrustedOtherUserPart2: String { 
    return VectorL10n.tr("Vector", "user_verification_session_details_information_trusted_other_user_part2") 
  }
  /// Verify this session to mark it as trusted & grant it access to encrypted messages:
  public static var userVerificationSessionDetailsInformationUntrustedCurrentUser: String { 
    return VectorL10n.tr("Vector", "user_verification_session_details_information_untrusted_current_user") 
  }
  ///  signed in using a new session:
  public static var userVerificationSessionDetailsInformationUntrustedOtherUser: String { 
    return VectorL10n.tr("Vector", "user_verification_session_details_information_untrusted_other_user") 
  }
  /// Trusted
  public static var userVerificationSessionDetailsTrustedTitle: String { 
    return VectorL10n.tr("Vector", "user_verification_session_details_trusted_title") 
  }
  /// Not Trusted
  public static var userVerificationSessionDetailsUntrustedTitle: String { 
    return VectorL10n.tr("Vector", "user_verification_session_details_untrusted_title") 
  }
  /// Interactively Verify
  public static var userVerificationSessionDetailsVerifyActionCurrentUser: String { 
    return VectorL10n.tr("Vector", "user_verification_session_details_verify_action_current_user") 
  }
  /// Manually Verify by Text
  public static var userVerificationSessionDetailsVerifyActionCurrentUserManually: String { 
    return VectorL10n.tr("Vector", "user_verification_session_details_verify_action_current_user_manually") 
  }
  /// Manually verify
  public static var userVerificationSessionDetailsVerifyActionOtherUser: String { 
    return VectorL10n.tr("Vector", "user_verification_session_details_verify_action_other_user") 
  }
  /// Messages with this user in this room are end-to-end encrypted and can’t be read by third parties.
  public static var userVerificationSessionsListInformation: String { 
    return VectorL10n.tr("Vector", "user_verification_sessions_list_information") 
  }
  /// Trusted
  public static var userVerificationSessionsListSessionTrusted: String { 
    return VectorL10n.tr("Vector", "user_verification_sessions_list_session_trusted") 
  }
  /// Not trusted
  public static var userVerificationSessionsListSessionUntrusted: String { 
    return VectorL10n.tr("Vector", "user_verification_sessions_list_session_untrusted") 
  }
  /// Sessions
  public static var userVerificationSessionsListTableTitle: String { 
    return VectorL10n.tr("Vector", "user_verification_sessions_list_table_title") 
  }
  /// Trusted
  public static var userVerificationSessionsListUserTrustLevelTrustedTitle: String { 
    return VectorL10n.tr("Vector", "user_verification_sessions_list_user_trust_level_trusted_title") 
  }
  /// Unknown
  public static var userVerificationSessionsListUserTrustLevelUnknownTitle: String { 
    return VectorL10n.tr("Vector", "user_verification_sessions_list_user_trust_level_unknown_title") 
  }
  /// Warning
  public static var userVerificationSessionsListUserTrustLevelWarningTitle: String { 
    return VectorL10n.tr("Vector", "user_verification_sessions_list_user_trust_level_warning_title") 
  }
  /// To be secure, do this in person or use another way to communicate.
  public static var userVerificationStartAdditionalInformation: String { 
    return VectorL10n.tr("Vector", "user_verification_start_additional_information") 
  }
  /// For extra security, verify 
  public static var userVerificationStartInformationPart1: String { 
    return VectorL10n.tr("Vector", "user_verification_start_information_part1") 
  }
  ///  by checking a one-time code on both your devices.
  public static var userVerificationStartInformationPart2: String { 
    return VectorL10n.tr("Vector", "user_verification_start_information_part2") 
  }
  /// Start verification
  public static var userVerificationStartVerifyAction: String { 
    return VectorL10n.tr("Vector", "user_verification_start_verify_action") 
  }
  /// Waiting for %@…
  public static func userVerificationStartWaitingPartner(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "user_verification_start_waiting_partner", p1)
  }
  /// We are no longer supporting %@ on iOS %@. To continue using %@ to its full potential, we advise you to upgrade your version of iOS.
  public static func versionCheckBannerSubtitleDeprecated(_ p1: String, _ p2: String, _ p3: String) -> String {
    return VectorL10n.tr("Vector", "version_check_banner_subtitle_deprecated", p1, p2, p3)
  }
  /// We will soon be ending support for %@ on iOS %@. To continue using %@ to its full potential, we advise you to upgrade your version of iOS.
  public static func versionCheckBannerSubtitleSupported(_ p1: String, _ p2: String, _ p3: String) -> String {
    return VectorL10n.tr("Vector", "version_check_banner_subtitle_supported", p1, p2, p3)
  }
  /// We’re no longer supporting iOS %@
  public static func versionCheckBannerTitleDeprecated(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "version_check_banner_title_deprecated", p1)
  }
  /// We’re ending support for iOS %@
  public static func versionCheckBannerTitleSupported(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "version_check_banner_title_supported", p1)
  }
  /// Find out how
  public static var versionCheckModalActionTitleDeprecated: String { 
    return VectorL10n.tr("Vector", "version_check_modal_action_title_deprecated") 
  }
  /// Got it
  public static var versionCheckModalActionTitleSupported: String { 
    return VectorL10n.tr("Vector", "version_check_modal_action_title_supported") 
  }
  /// We've been working on enhancing %@ for a faster and more polished experience. Unfortunately your current version of iOS is not  compatible with some of those fixes and is no longer supported.\nWe're advising you to upgrade your operating system to use %@ to its full potential.
  public static func versionCheckModalSubtitleDeprecated(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "version_check_modal_subtitle_deprecated", p1, p2)
  }
  /// We've been working on enhancing %@ for a faster and more polished experience. Unfortunately your current version of iOS is not compatible with some of those fixes and will no longer be supported.\nWe're advising you to upgrade your operating system to use %@ to its full potential.
  public static func versionCheckModalSubtitleSupported(_ p1: String, _ p2: String) -> String {
    return VectorL10n.tr("Vector", "version_check_modal_subtitle_supported", p1, p2)
  }
  /// We’re no longer supporting iOS %@
  public static func versionCheckModalTitleDeprecated(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "version_check_modal_title_deprecated", p1)
  }
  /// We’re ending support for iOS %@
  public static func versionCheckModalTitleSupported(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "version_check_modal_title_supported", p1)
  }
  /// Video
  public static var video: String { 
    return VectorL10n.tr("Vector", "video") 
  }
  /// View
  public static var view: String { 
    return VectorL10n.tr("Vector", "view") 
  }
  /// Voice
  public static var voice: String { 
    return VectorL10n.tr("Vector", "voice") 
  }
  /// Voice message
  public static var voiceMessageLockScreenPlaceholder: String { 
    return VectorL10n.tr("Vector", "voice_message_lock_screen_placeholder") 
  }
  /// Hold to record, release to send
  public static var voiceMessageReleaseToSend: String { 
    return VectorL10n.tr("Vector", "voice_message_release_to_send") 
  }
  /// %@s left
  public static func voiceMessageRemainingRecordingTime(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "voice_message_remaining_recording_time", p1)
  }
  /// Tap on your recording to stop or listen
  public static var voiceMessageStopLockedModeRecording: String { 
    return VectorL10n.tr("Vector", "voice_message_stop_locked_mode_recording") 
  }
  /// Warning
  public static var warning: String { 
    return VectorL10n.tr("Vector", "warning") 
  }
  /// Widget creation has failed
  public static var widgetCreationFailure: String { 
    return VectorL10n.tr("Vector", "widget_creation_failure") 
  }
  /// Failed to send request.
  public static var widgetIntegrationFailedToSendRequest: String { 
    return VectorL10n.tr("Vector", "widget_integration_failed_to_send_request") 
  }
  /// You need to enable integration manager in settings
  public static var widgetIntegrationManagerDisabled: String { 
    return VectorL10n.tr("Vector", "widget_integration_manager_disabled") 
  }
  /// Missing room_id in request.
  public static var widgetIntegrationMissingRoomId: String { 
    return VectorL10n.tr("Vector", "widget_integration_missing_room_id") 
  }
  /// Missing user_id in request.
  public static var widgetIntegrationMissingUserId: String { 
    return VectorL10n.tr("Vector", "widget_integration_missing_user_id") 
  }
  /// You are not in this room.
  public static var widgetIntegrationMustBeInRoom: String { 
    return VectorL10n.tr("Vector", "widget_integration_must_be_in_room") 
  }
  /// You need to be able to invite users to do that.
  public static var widgetIntegrationNeedToBeAbleToInvite: String { 
    return VectorL10n.tr("Vector", "widget_integration_need_to_be_able_to_invite") 
  }
  /// You do not have permission to do that in this room.
  public static var widgetIntegrationNoPermissionInRoom: String { 
    return VectorL10n.tr("Vector", "widget_integration_no_permission_in_room") 
  }
  /// Power level must be positive integer.
  public static var widgetIntegrationPositivePowerLevel: String { 
    return VectorL10n.tr("Vector", "widget_integration_positive_power_level") 
  }
  /// This room is not recognised.
  public static var widgetIntegrationRoomNotRecognised: String { 
    return VectorL10n.tr("Vector", "widget_integration_room_not_recognised") 
  }
  /// Room %@ is not visible.
  public static func widgetIntegrationRoomNotVisible(_ p1: String) -> String {
    return VectorL10n.tr("Vector", "widget_integration_room_not_visible", p1)
  }
  /// Unable to create widget.
  public static var widgetIntegrationUnableToCreate: String { 
    return VectorL10n.tr("Vector", "widget_integration_unable_to_create") 
  }
  /// Failed to connect to integrations server
  public static var widgetIntegrationsServerFailedToConnect: String { 
    return VectorL10n.tr("Vector", "widget_integrations_server_failed_to_connect") 
  }
  /// Open in browser
  public static var widgetMenuOpenOutside: String { 
    return VectorL10n.tr("Vector", "widget_menu_open_outside") 
  }
  /// Refresh
  public static var widgetMenuRefresh: String { 
    return VectorL10n.tr("Vector", "widget_menu_refresh") 
  }
  /// Remove for everyone
  public static var widgetMenuRemove: String { 
    return VectorL10n.tr("Vector", "widget_menu_remove") 
  }
  /// Revoke access for me
  public static var widgetMenuRevokePermission: String { 
    return VectorL10n.tr("Vector", "widget_menu_revoke_permission") 
  }
  /// No integrations server configured
  public static var widgetNoIntegrationsServerConfigured: String { 
    return VectorL10n.tr("Vector", "widget_no_integrations_server_configured") 
  }
  /// You need permission to manage widgets in this room
  public static var widgetNoPowerToManage: String { 
    return VectorL10n.tr("Vector", "widget_no_power_to_manage") 
  }
  /// Manage integrations…
  public static var widgetPickerManageIntegrations: String { 
    return VectorL10n.tr("Vector", "widget_picker_manage_integrations") 
  }
  /// Integrations
  public static var widgetPickerTitle: String { 
    return VectorL10n.tr("Vector", "widget_picker_title") 
  }
  /// You don't currently have any stickerpacks enabled.
  public static var widgetStickerPickerNoStickerpacksAlert: String { 
    return VectorL10n.tr("Vector", "widget_sticker_picker_no_stickerpacks_alert") 
  }
  /// Add some now?
  public static var widgetStickerPickerNoStickerpacksAlertAddNow: String { 
    return VectorL10n.tr("Vector", "widget_sticker_picker_no_stickerpacks_alert_add_now") 
  }
  /// Yesterday
  public static var yesterday: String { 
    return VectorL10n.tr("Vector", "yesterday") 
  }
  /// You
  public static var you: String { 
    return VectorL10n.tr("Vector", "you") 
  }
}
// swiftlint:enable function_parameter_count identifier_name line_length type_body_length

// MARK: - Implementation Details

extension VectorL10n {
  static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    let locale: Locale
    if let providedLocale = LocaleProvider.locale {
      locale = providedLocale
    } else {
      locale = Locale.current
    }        

      return String(format: format, locale: locale, arguments: args)
    }
}

private final class BundleToken {}
