Changes in 1.3.2 (2021-04-16)
=================================================

✨ Features
 * 

🙌 Improvements
 * 

🐛 Bugfix
 * Self-verification: Fix compatibility with Element-Web (#4217).
 * Notifications: Fix sender display name that can miss (#4222). 

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.14.9](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.9)).

Changes in 1.3.1 (2021-04-14)
=================================================

✨ Features
 * 

🙌 Improvements
 * 

🐛 Bugfix
 * 

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.14.8](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.8)).

Changes in 1.3.0 (2021-04-09)
=================================================

✨ Features
 * Composer Update - Typing and sending a message (#4085)
 * Switching composer between text mode & action mode (#4087)
 * Explore typing notifications inspired by web (#4134)

🙌 Improvements
 * Make the application settings more configurable (#4171)
 * Possibility to lock some room creation parameters from settings (#4181)
 * Enable / disable external friends invite (#4173)
 * Composer update - UI enhancements (#4133)
 * Increase grow/shrink animation speed in new composer (#4187)
 * Limit typing notifications timeline jumps (#4176)
 * Consider displaying names in typing notifications (#4175)

🐛 Bugfix
 * If you start typing while the new attachment sending mode is on, the send button appears (#4155)
 * The final frames of the appearance animation of the new composer buttons are missing (#4160)
 * Crash in [RoomViewController setupActions] (#4162)
 * Too much vertical whitespace when replying (#4164)
 * Black theme uses dark background for composer (#4192)
 * Vertical layout of typing notifs can go wonky (#4159)
 * Crash in [RoomViewController refreshTypingNotification] (#4161)

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.14.7](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.7)).

Changes in 1.2.8 (2021-03-26)
=================================================

✨ Features
 * 

🙌 Improvements
 * 

🐛 Bugfix
 * Xcodegen: Unit tests are broken (#4152).

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:


Changes in 1.2.7 (2021-03-24)
=================================================

✨ Features
 * 

🙌 Improvements
 * Pods: Update FlowCommoniOS, GBDeviceInfo, KeychainAccess, MatomoTracker, SwiftJWT, SwiftLint (#4120).
 * Room lists: Remove shields on room avatars (#4115).

🐛 Bugfix
 * RoomVC: Fix timeline blink on sending.
 * RoomVC: Fix not visible last bubble issue.
 * Room directory: Fix crash (#4137).

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.14.6](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.6)).

Changes in 1.2.6 (2021-03-11)
=================================================

✨ Features
 * Improve the status of send messages (sending, sent, received, failed) (#4014)
 * Retrying & deleting failed messages (#4013)
 * Composer Update - Typing and sending a message (#4085)

🙌 Improvements
 * 

🐛 Bugfix
 * 

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.14.5](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.5)).

Changes in 1.2.5 (2021-03-03)
=================================================

✨ Features
 * 

🙌 Improvements
 * Settings: Add option to show NSFW public rooms (off by default).

🐛 Bugfix
 * Emoji store: Include short name when searching emojis (#4063).

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.14.4](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.4)).

Changes in 1.2.4 (2021-03-01)
=================================================

✨ Features
 * 

🙌 Improvements
 * 

🐛 Bugfix
 * Social login: Fix a crash when selecting a social login provider.

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:


Changes in 1.2.3 (2021-02-26)
=================================================

✨ Features
 * 

🙌 Improvements
 * 

🐛 Bugfix
 * 

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.14.3](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.3)).

Changes in 1.2.2 (2021-02-24)
=================================================

✨ Features
 * Enable encryption for accounts, contacts and keys in the crypto database (#3867).

🙌 Improvements
 * Home: Show room directory on join room action (#3775).
 * RoomVC: Add quick actions in timeline on room creation (#3776).

🐛 Bugfix
 * 

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * XcodeGen: .xcodeproj files are now built from readable yml file: [New Build instructions](README.md#build-instructions) (#3812).
 * Podfile: Use MatrixKit for all targets and remove MatrixKit/AppExtension.
 * Fastlane: Use the "New Build System" to build releases.
 * Fastlane: Re-enable parallelised builds.

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.14.2](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.2)).

Changes in 1.2.1 (2021-02-12)
=================================================

✨ Features
 * 

🙌 Improvements
 * User-Interactive Authentication: Add UIA support for device deletion and add user 3PID action (#4016).

🐛 Bugfix
 * NSE: Wait for VoIP push request if any before calling contentHandler (#4018).
 * VoIP: Show dial pad option only if PSTN is supported (#4029).

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.14.1](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.1)).

Changes in 1.2.0 (2021-02-11)
=================================================

✨ Features
 * 

🙌 Improvements
 * Cross-signing: Setup cross-signing without authentication parameters when a grace period is enabled after login (#4006).
 * VoIP: Implement DTMF on call screen (#3929).
 * VoIP: Implement call transfer screen (#3962).
 * VoIP: Implement call tiles on timeline (#3955).

🐛 Bugfix
 * 

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.14.0](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.0)).

Changes in 1.1.7 (2021-02-03)
=================================================

✨ Features
 * 

🙌 Improvements
 * Social login: Handle new identity provider brand field in order to customize buttons (#3980).
 * Widgets: Support $matrix_room_id and $matrix_widget_id parameters (#3987).
 * matrix.to: Support room preview when the permalink has parameters (like "via=").
 * Avoid megolm share requests if the device is not verified (#3969)
 * Handle User-Interactive Authentication fallback (#3995).

🐛 Bugfix
 * Push: Fix PushKit crashes due to undecryptable call invites (#3986).
 * matrix.to: Cannot open links with query parameters (#3990).
 * matrix.to: Cannot open/preview a new room given by alias (#3991).
 * matrix.to: The app does not open a permalink from matrix.to (#3993).
 * Logs: Add a size limitation so that we can upload them in bug reports (#3903).

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.13.9](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.9)).

Changes in 1.1.6 (2021-01-27)
=================================================

✨ Features
 * 

🙌 Improvements
 * 

🐛 Bugfix
 * Navigation: Unable to open a room from a room list (#3863).
 * AuthVC: Fix social login layout issue.

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.13.8](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.8)).

Changes in 1.1.5 (2021-01-18)
=================================================

✨ Features
 * 

🙌 Improvements
 * 

🐛 Bugfix
 * 

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.13.7](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.7)).

Changes in 1.1.4 (2021-01-15)
=================================================

✨ Features
 * Change Pin inside the app (#3881)
 * AuthVC: Add social login (#3846).
 * Invite friends: Add the ability to invite friends outside of Element in a few places (#3840).

🙌 Improvements
 * Bug report: Add "Continue in background" button  (#3816).
 * Show user id in the room invite preview screen (#3839)
 * AuthVC: SSO authentication now use redirect URL instead of fallback page (#3846).

🐛 Bugfix
 * Crash report cannot be submitted (on small phones) (#3819)
 * Prevent navigation controller from pushing same view controller (#3924)
 * AuthVC: Fix recaptcha view cropping (#3940).

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.13.6](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.6)).

Changes in 1.1.3 (2020-12-18)
=================================================

✨ Features
 * 

🙌 Improvements
 * AuthVC: Update SSO button wording.
 * Log NSE memory footprint for debugging purposes.

🐛 Bugfix
 * Refresh account details on NSE runs (#3719).

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.13.3](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.3)).
 * Upgrade MatrixKit version ([v0.13.4](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.4)).

Changes in 1.1.2 (2020-12-02)
=================================================

✨ Features
 * Added blur background support for iPhone and iPad (#3842)

🙌 Improvements
 * Room History: Remove the report option for outgoing messages.
 * Empty views: Add empty screen when there is nothing to display on home, people, favourites and rooms screen (#3836).
 * BuildSettings.messageDetailsAllowShare now hide /show action button in document preview (#3864).

🐛 Bugfix
 * Restore the modular widget events in the rooms histories.

⚠️ API Changes
 * Slight API changes for SlidingModalPresenter to avoid race conditions while sharing a presenter. (#3842)

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.13.2](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.2)).

Changes in 1.1.1 (2020-11-24)
=================================================

✨ Features
 * 

🙌 Improvements
 * Home: Add empty screen when there is nothing to display (#3823).

🐛 Bugfix
 * 

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.13.1](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.1)).

Changes in 1.1.0 (2020-11-17)
=================================================

✨ Features
 * 

🙌 Improvements
 * Upgrade to Xcode 12 (#3712).
 * Xcode 12: Make Xcode 12 and fastlane(xcodebuild) happy while some pods are not updated.
 * Update Gemfile.lock.
 * MXAnalyticsDelegate: Make it fully agnostic on tracked data.
 * MXProfiler: Use this new module to track launch animation time reliably.
 * KeyValueStore improvements.
 * Jitsi: Support authenticated Jitsi widgets (#3655).
 * Room invites: Allow to accept a room invite without preview.

🐛 Bugfix
 * Fix analytics in order to track performance improvements.
 * Fix long placeholder cropping in room input toolbar. Prevent long placeholder to be displayed on small devices (#3790).

⚠️ API Changes
 * Xcode 12 is now mandatory to build the project.
 * CocoaPods 1.10.0 is mandatory.
 * Remove MXDecryptionFailureDelegate in flavor of agnostic MXAnalyticsDelegate.

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.13.0](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.0)).

Changes in 1.0.18 (2020-10-27)
=================================================

✨ Features
 * 

🙌 Improvements
 * Secure backup: Add possibility to not expose recovery key when creating a secure backup.
 * BuildSettings: Centralise RoomInputToolbar compression mode setting.
 * Update GBDeviceInfo to 6.4.0 (#3570).
 * Update FlowCommoniOS to 1.9.0 (#3570).
 * Update KeychainAccess to 4.2.1 (#3570).
 * Update MatomoTracker to 7.2.2 (#3570).
 * Update SwiftGen to 6.3.0 (#3570).
 * Update SwiftLint to 0.40.3 (#3570).
 * NSE: Utilize MXBackgroundService on pushes, to make messages available when the app is foregrounded (#3579).

🐛 Bugfix
 * Fix typos in UI

⚠️ API Changes
 *

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.12.26](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.26)).

Changes in 1.0.17 (2020-10-14)
=================================================

✨ Features
 * 

🙌 Improvements
 * Device verification: Do not check for existing key backup after SSSS & Cross-Signing reset.
 * Cross-signing: Detect when cross-signing keys have been changed.
 * Make copying & pasting media configurable.

🐛 Bugfix
 * 

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.12.25](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.25)).

Changes in 1.0.16 (2020-10-13)
=================================================

✨ Features
 * 

🙌 Improvements
 * Self-verification: Update complete security screen wording (#3743).

🐛 Bugfix
 * 

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.12.24](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.24)).

Changes in 1.0.15 (2020-10-09)
=================================================

✨ Features
 * 

🙌 Improvements
 * Room: Make topic links tappable (#3713).
 * Room: Add more to long room topics (#3715).
 * Security screens: Update automatically shields when the trust changes.
 * Room: Add floating action button to invite members.
 * Pasteboard: Use MXKPasteboardManager.pasteboard on copy operations (#3732).

🐛 Bugfix
 * Push: Check crypto has keys to decrypt an event before decryption attempt, avoid sync loops on failure.

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.12.23](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.23)).

Changes in 1.0.14 (2020-10-02)
=================================================

✨ Features
 * 

🙌 Improvements
 * i18n: Add Estonian (et).
 * MXSession: Make vc_canSetupSecureBackup reusable.

🐛 Bugfix
 * Settings: New phone number is invisible in dark theme (#3218).
 * Handle call actions on other devices on VoIP pushes (#3677).
 * Fix "Unable to open the link" error when using non-Safari browsers (#3673).
 * Biometrics: Handle retry case.
 * Room: Remove membership events from room creation modal (#3679).
 * PIN: Fix layout on small screens.
 * PIN: Fix code bypass on fast switching.

⚠️ API Changes
 * 

🗣 Translations
 * 
    
🧱 Build
 * 

Others
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.12.22](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.22)).

Changes in 1.0.13 (2020-09-30)
=================================================

✨ Features
 *

🙌 Improvements
 * Room: Differentiate wordings for DMs.
 * Room: New Room Settings screen.
 * PIN code: Implement not allowed PINs feature. There is no restriction by default.
 * PIN code: Do not show notification content and disable replies when protection set.
 * PIN code: Log out user automatically after some wrong PINs/biometrics (#3623).
 * Complete Security: Come back to the root screen if device verification is cancelled.
 * Device verification: Add possibility to reset SSSS & Cross-Signing when recovery passphrase or key are lost.
 * Architecture: Use coordinator pattern for legacy screen flows (#3597).
 * Architecture: Create AppDelegate.handleAppState() as central point to handle application state.

🐛 Bugfix
 * Timeline: Hide encrypted history (pre-invite) (#3660).
 * PIN Code: Do not show verification dialog at the top of PIN code.
 * Complete Security: Let the authentication flow display it if this flow is not complete yet.
 * Device verification: Fix inactive cancel action issue in self verification flow.
 * Fix floating action buttons' images.
 * Various theme fixes.
 * Room: Fix message not shown after push issue (#3672).

⚠️ API Changes
 *

🗣 Translations
 *
    
🧱 Build
 *

Others
 *

Changes in 1.0.12 (2020-09-16)

✨ Features
 *

🙌 Improvements
 *

🐛 Bugfix
 *

⚠️ API Changes
 *

🗣 Translations
 *
    
🧱 Build
 *

Others
 *

Improvements:
 * Upgrade MatrixKit version ([v0.12.21](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.21)).
 * Upgrade MatrixKit version ([v0.12.20](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.20)).

Changes in 1.0.11 (2020-09-15)
=================================================

✨ Features
 *

🙌 Improvements
 * Room: Collapse state messages on room creation (#3629).
 * AuthVC: Make force PIN working for registration as well.
 * AppDelegate: Do not show incoming key verification requests while authenticating.

🐛 Bugfix
 * AuthVC: Fix PIN setup that broke cross-signing bootstrap.
 * Loading animation: Fix the bug where, after authentication, the animation disappeared too early and made auth screen flashed.

⚠️ API Changes
 *

🗣 Translations
 *
    
🧱 Build
 *

Others
 * buildRelease.sh: Pass a `git_tag` parameter to fastlane because fastlane `git_branch` method can fail.

Improvements:


Changes in 1.0.10 (2020-09-08)
=================================================

✨ Features
 *
    
🙌 Improvements
 * AppDelegate: Convert to Swift (#3594).
 * Contextualize floating button actions per tab (#3627).
    
🐛 Bugfix
 * Show pin code screen on every foreground (#3620).
 * Close keyboard on pin code screen (#3622).
 * Fix content leakage on pin code protection (#3624).
    
⚠️ API Changes
 *
    
🗣 Translations
 *
    
🧱 Build
 * buildRelease.sh: Make sure it works for both branches and tags
    
Others
 *

Improvements:
 * Upgrade MatrixKit version ([v0.12.18](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.18)).

Changes in 1.0.9 (2020-09-03)
=================================================

Features:
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.12.17](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.17)).
 * 

Bugfix:
 * 

API Change:
 * 

Translations:
 * 

Others:
 * 

Build:
 * 

Test:
 * 

Changes in 1.0.8 (2020-09-03)
=================================================

Features:
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.12.17](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.17)).
 * 

Bugfix:
 * PushKit: Add more logs when removing PushKit pusher (#3577).
 * PushKit: Check all registered pushers and remove PushKit ones (#3577).

API Change:
 * 

Translations:
 * 

Others:
 * 

Build:
 * 

Test:
 * 

Changes in 1.0.7 (2020-08-28)
=================================================

Features:
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.12.16](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.16)).
 * 

Bugfix:
 * Update room input toolbar on theme change (#3445).
 * Explicitly remove PushKit pushers (#3577).
 * Fix launch animation on clear cache (#3580).

API Change:
 * 

Translations:
 * 

Others:
 * 

Build:
 * 

Test:
 * 

Changes in 1.0.6 (2020-08-26)
=================================================

Features:
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.12.15](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.15)).
 * Config fixes.
 * Introduce TableViewSections. Refactor RoomSettingsViewController & SettingsViewController.
 * AuthenticationVC: Make forgot password button and phone number text field configurable.
 * Introduce httpAdditionalHeaders in BuildSettings.

Bugfix:
 * Fix biometry name null case (#3551).
 * Avoid email validation link to redirect to web app (#3513).
 * Wait for first sync complete before stopping loading screen (#3336).
 * Disable key backup on extensions (#3371).
 * Gracefully cancel verification on iOS 13 drag gesture (#3556).

API Change:
 * 

Translations:
 * 

Others:
 * Ignore fastlane/Preview.html
 * SonarCloud: Fix some code smells.

Build:
 * 

Test:
 * 

Changes in 1.0.5 (2020-08-13)
=================================================

Features:
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.12.12](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.12)).
 * 

Bugfix:
 * Fix pin code cell selection. 
 * Fix default orientation crash.
 * Fix rooms list swipe actions tint colors (#3507).

API Change:
 * 

Translations:
 * 

Others:
 * 

Build:
 * Integrate fastlane deliver (#3519).

Test:
 * 

Changes in 1.0.4 (2020-08-07)
=================================================

Features:
 * 

Improvements:
 * Upgrade MatrixKit version ([v0.12.11](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.11)).
 * 

Bugfix:
 * 

API Change:
 * 

Translations:
 * 

Others:
 * 

Build:
 * 

Test:
 * 

Changes in 1.0.3 (2020-08-05)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.12.10](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.10)).
 * Implement PIN protection (#3436).
 * Biometrics protection: Implement TouchID/FaceID protection (#3437).
 * Build: Make the app build if JitsiMeetSDK is not in the Podfile.
 * Configuration: Add CommonConfiguration and AppConfiguratio classes as central points to configure all targets in the same way.
 * Xcconfig: Add Common config and app and share extension config files.
 * BuildSettings: A new class that entralises build settings and exposes xcconfig variable.
 * AuthenticationVC: Make custom server options and register button configurable.
 * Xcconfig: Add product bundle identifiers for each target.
 * BuildSettings: Namespace some settings.
 * BuildSettings: Reuse base bundle identifier for various settings.

Bug fix:
 * Rebranding: Remove Riot from app name (#3497).
 * AuthenticationViewController: Fix custom homeserver textfield scroll issue (#3467).
 * Rebranding: Update provisioning universal link domain (#3483).

Changes in 1.0.2 (2020-07-28)
===============================================

Bug fix:
 * Registration: Do not display the skip button if email is mandatory (#3417).
 * NotificationService: Do not cache showDecryptedContentInNotifications setting (#3444).

Changes in 1.0.1 (2020-07-17)
===============================================
 
Bug fix:
 * SettingsViewController: Fix crash when scrolling to Discovery (#3401).
 * Main.storyboard: Set storyboard identifier for SettingsViewController (#3398).
 * Universal links: Fix broken links for web apps (#3420).
 * SettingsViewController: Fix pan gesture crash (#3396).
 * RecentsViewController: Fix crash on dequeue some cells (#3433).
 * NotificationService: Fix losing sound when not showing decrypted content in notifications (#3423).

Changes in 1.0.0 (2020-07-13)
===============================================

Improvements:
 * Rename Riot to Element
 * Update deployment target to iOS 11.0. Required for Jitsi > 2.8.x.
 * Theme: Customize UISearchBar with new iOS 13 properties (#3270).
 * NSE: Make extension reusable (#3326).
 * Strings: Use you instead of display name on notice events (#3282).
 * Third-party licences: Add license for FlowCommoniOS (#3415).
 * Lazy-loading: Remove lazy loading labs setting, enable it by default (#3389).
 * Room: Show alert if link text does not match link target (#3137).
 
Bug fix:
 * Xcode11: Fix content change error when dragging start chat page (PR #3075).
 * Xcode11: Fix status bar styles for many screens (PR #3077).
 * Xcode11: Replace deprecated MPMoviePlayerController with AVPlayerViewController (PR #3092).
 * Xcode11: Show AuthenticationViewController fullscreen (PR #3093).
 * Xcode11: Fix font used for `org.matrix.custom.html`messages in timeline (#3241).
 * Settings: New phone number is invisible in dark theme (#3218).
 * SettingsViewController: Fix notifications on this device setting to use APNS pusher (#3291).
 * Xcode11: Fix decryption on notifications when the key is not present (#3295).
 * SettingsViewController: Fix PushKit references with APNS correspondents (PR #3298).
 * Xcode11: Fix notification reply with new pushes (#3301).
 * Xcode11: Fix notification doubling on replies (#3308).
 * Xcode11: Fix selected background color on cells, for iOS 13+ (#3309).
 * Xcode11: Respect system dark mode setting (#2628).
 * Xcode11: Fix noisy notifications (#3316).
 * Xcode11: Temporary workaround for navigation bar bg color on emoji selection screen (#3271).
 * Project: Remove GoogleService-Info.plist (#3329).
 * Xcode11: Various bug fixes about NSE (PR #3345).
 * Xcode11: Fix session user display name (PR #3349).
 * Xcode11: Fix rebooted and unlocked case for NSE (PR #3353).
 * Xcode11: New localization keys for push notifications, include room display name in fallback content (#3325).
 * Xcode11: Disable voip background mode to avoid VoIP pushes (#3369).
 * Xcode11: Disable key backup on push extension (#3371).
 * RoomMembershipBubbleCell: Fix message textview leading constraint (#3226).
 * SettingsViewController: Fix crash when scrolling to Discovery (#3401).
 * Main.storyboard: Set storyboard identifier for SettingsViewController (#3398).
 * Universal links: Fix broken links for web apps (#3420).
 * SettingsViewController: Fix pan gesture crash (#3396).
 * RecentsViewController: Fix crash on dequeue some cells (#3433).
 * NotificationService: Fix losing sound when not showing decrypted content in notifications (#3423).

Changes in 0.11.6 (2020-06-30)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.12.7](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.7)).
 * PushNotificationService: Move all notification related code to a new class (PR #3100).
 * Cross-signing: Bootstrap cross-sign on registration (and login if applicable). This action is now invisible to the user (#3292).
 * Cross-signing: Setup cross-signing for existing users (#3299).
 * Authentication: Redirect the webview (SSO) javascript logs to iOS native logs.
 * Timeline: Hide encrypted history (pre-invite) (#3239).
 * Complete security: Add recovery from 4S (#3304).
 * Key backup: Connect/restore backup created with SSSS (#3124).
 * E2E by default: Disable it if the HS admin disabled it (#3305).
 * Key backup: Add secure backup creation flow (#3344).
 * Add AuthenticatedSessionViewControllerFactory to set up a authenticated flow for a given CS API request.
 * Set up SSSS from banners (#3293).

Bug fix:
 * CallVC: Declined calls now properly reset call view controller, thanks to @Legi429 (#2877).
 * PreviewRoomTitleView: Fix inviter display name (#2520).

Changes in 0.11.5 (2020-05-18)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.12.6](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.6)).

Bug fix:
 * AuthenticationViewController: Adapt UIWebView changes in MatrixKit (PR #3242).
 * Share extension & Siri intent: Do not fail when sending to locally unverified devices (#3252).
 * CountryPickerVC: Search field is invisible in dark theme (#3219).

Changes in 0.11.4 (2020-05-08)
===============================================

Bug fix:
 * App asks to verify all devices on every startup for no valid reason (#3221).

Changes in 0.11.3 (2020-05-07)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.12.3](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.3)).
 * Cross-signing: Display "Verify your other sessions" modal at every startup if needed (#3180).
 * Cross-signing: The "Complete Security" button now triggers a verification request to all user devices.
 * Secrets: On startup, request again private keys we are missing locally.

Bug fix:
 * KeyVerificationSelfVerifyStartViewController has no navigation (#3195).
 * Self-verification: QR code scanning screen refers to other-person scanning (#3189).

Changes in 0.11.2 (2020-05-01)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.12.2](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.2)).
 * Registration / Email addition: Support email verification link from homeserver (#3167).
 * Verification requests: Hide incoming request modal when it is no more pending (#3033).
 * Self-verification: Do not display incoming self verification requests at the top of the Complete Security screen.
 * Verification: Do not talk about QR code if only emoji is possible (#3035).
 * Registration: Prefill email field when opened with universal link (PR #3173).
 * Cross-signing: Display "Verify this session" modal at every startup if needed (#3179).
 * Complete Security: Support SAS verification start (#3183).

Bug fix:
 * AuthenticationViewController: Remove fallback to matrix.org when authentication failed (PR #3165).

Changes in 0.11.1 (2020-04-24)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.12.1](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.1)).
 * New icons.
 * Cross-signing: Allow incoming device verification request from other user (#3139).
 * Cross-signing: Allow to verify each device of users with no cross-signing (#3138).
 * Jitsi: Make Jitsi widgets compatible with Matrix Widget API v2. This allows to use any Jitsi servers (#3150).

Bug fix:
 * Settings: Security, present complete security when my device is not trusted (#3127).
 * Settings: Security: Do not ask to complete security if there is no cross-signing (#3147).

Changes in 0.11.0 (2020-04-17)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.12.0](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.0)).
 * Crypto: Enable E2EE by default for DM
 * Crypto: Cross-signing support
 * Crypto: Do not warn anymore for unknown devices. Trust on First Use.
 * RoomVC: Update encryption decoration with shields (#2934, #2930, #2906).
 * Settings: Remove "End-to-End Encryption" from the LABS section (#2941).
 * Room decoration: Use shields instead of padlocks (#2906).
 * Room decoration: Remove horizontal empty space when there is no decoration badge to set on room message (#2978).
 * RoomVC: For a room preview use room canonical alias if present when joining a room.
 * Update Matomo app id (#3001)
 * Verification by DM: Support QR code (#2921).
 * Cross-Signing: Detect and expose new sign-ins (#2918).
 * Cross-signing: Complete security at the end of sign in process( #3003).
 * Make decoration uniform (#2972).
 * DeactivateAccountViewController: Respect active theme (PR #3107).
 * Verification by emojis: Center emojis in screen horizontally (PR #3119).
 
Bug fix:
 * Key backup banner is not hidden correctly (#2899). 

Bug fix:
 * Considered safe area insets for some screens (PR #3084).

Changes in 0.10.5 (2020-04-01)
===============================================

Bug fix:
 * Fix error when joining some public rooms, thanks to @chrismoos (PR #2888).
 * Fix crash due to malformed widget (#2997).
 * Push notifications: Avoid any automatic deactivation (vector-im/riot-ios#3017).
 * Fix links breaking user out of SSO flow, thanks to @schultetwin (#3039).

Changes in 0.10.4 (2019-12-11)
===============================================

Improvements:
 * ON/OFF Cross-signing development in a Lab setting (#2855).

Bug fix:
 * Device Verification: Stay in infinite waiting (#2878).

Changes in 0.10.3 (2019-12-05)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.11.3](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.11.3)).
 * Integrations: Use the integrations manager provided by the homeserver admin via .well-known (#2815).
 * i18n: Add Welsh (cy).
 * i18n: Add Italian (it).
 * SerializationService: Add deserialisation of Any.
 * RiotSharedSettings: New class to handle user settings shared accross Riot apps.
 * Widgets: Check user permission before opening a widget (#2833).
 * Widgets: Check user permission before opening jitsi (#2842).
 * Widgets: Add a contextual menu to refresh, open outside, remove and revoke the permission (#2834).
 * Settings: Add an option for disabling use of the integration manager (#2843).
 * Jitsi: Display room name, user name and user avatar in the conference screen.
 * Improve UNNotificationSound compatibility with MA4 (IMA/ADPCM) file, thanks to @pixlwave (PR #2847).

Bug fix:
 * Accessibility: Make checkboxes accessible in terms of service screen.
 * RoomVC: Tapping on location links gives 'unable to open link' (#2803).
 * RoomVC: Reply to links fail with 'unable to open link' (#2804).

Changes in 0.10.2 (2019-11-15)
===============================================

Bug fix:
 * Integrations: Fix terms consent display when they are required.

Changes in 0.10.1 (2019-11-06)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.11.2](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.11.2)).
 * Settings: Add User-Interactive Auth for adding email and msidsn to user's account (vector-im/riot-ios#2744).
 * Improve UIApplication background task management.

Bug fix:
 * Room cell: The states of direct chat and favorite buttons are reversed in the menu (#2788).
 * Pasteboard: Fix a crash when passing a nil object to UIPasteboard.
 * RoomVC: Fix crash occurring when tap on an unsent media with retrieved event equal to nil.
 * Emoji Picker: Background color is not white (#2630).
 * Device Verification: Selecting 'start verification' from a keyshare request wedges you in an entirely blank verification screen (#2504).
 * Tab bar icons are not centered vertically on iOS 13 (#2802).

Changes in 0.10.0 (2019-10-11)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.11.1](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.11.1)).
 * Upgrade MatrixKit version ([v0.11.0](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.11.0)).
 * Widgets: Whitelist [MSC1961](https://github.com/matrix-org/matrix-doc/pull/1961) widget urls.
 * Settings: CALLS section: Always display the CallKit option but grey it out when not available (only on China).
 * VoIP: Fallback to matrix.org STUN server with a confirmation dialog (#2646).
 * Widgets: Whitelist [MSC1961](https://github.com/matrix-org/matrix-doc/pull/1961) widget urls
 * i18n: Enable Polish (pl).
 * Room members: third-party invites can now be revoked
 * Privacy: Prompt to accept integration manager policies on use (#2600).
 * Privacy: Make clear that device names are publicly readable (#2662).
 * Privacy: Remove the ability to set an IS at login/registration (#2661).
 * Privacy: Remove the bind true flag from 3PID calls on registration (#2648).
 * Privacy: Remove the bind true flag from 3PID adds in settings (#2650).
 * Privacy: Email help text on registration should be updated without binding (#2675).
 * Privacy: Use MXIdentityService to perform identity server requests (#2647).
 * Privacy: Support identity server v2 API authentication (#2603).
 * Privacy: Use the hashed v2 lookup API for 3PIDs (#2652).
 * Privacy: Prompt to accept identity server policies on firt use (#2602).
 * Privacy: Settings: Allow adding 3pids when no IS (#2659).
 * Privacy: Allow password reset when no IS (#2658).
 * Privacy: Allow email registration when no IS (#2657).
 * Privacy: Settings: Add a Discovery section (#2606).
 * Privacy: Make NSContactsUsageDescription more generic and mention that 3pids are now uploaded hashed (#2521).
 * Privacy: Settings: Add IDENTITY SERVER section (#2604).
 * Privacy: Make IS terms wording clearer when we fallback to vector.im (#2760).

Bug fix:
 * Theme: Make button theming work (#2734).

Changes in 0.9.5 (2019-09-20)
===============================================

Bug fix:
 * VoiceOver: RoomVC: Fix some missing accessibility labels for buttons (#2722).
 * VoiceOver: RoomVC: Make VoiceOver focus on the contextual menu when selecting an event (#2721).
 * VoiceOver: RoomVC: Do not lose the focus on the timeline when paginating (with 3 fingers) (#2720).
 * VoiceOver: RoomVC: No VoiceOver on media (#2726).

Changes in 0.9.4 (2019-09-13)
===============================================

Improvements:
 * Authentication: Improve the webview used for SSO (#2715).

Changes in 0.9.3 (2019-09-10)
===============================================

Improvements:
 * Support Riot configuration link to customise HS and IS (#2703).
 * Authentication: Create a way to filter and prioritise flows (with handleSupportedFlowsInAuthenticationSession).

Changes in 0.9.2 (2019-08-08)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.10.2](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.10.2)).
 * Soft logout: Support soft logout (#2540).
 * Reactions: Emoji picker (#2370).
 * Widgets: Whitelist https://scalar-staging.vector.im/api (#2612).
 * Reactions: Show who reacted (#2591).
 * Media picking: Use native camera and use separate actions for camera and media picker (#638).
 * Ability to disable all identity server functionality via the config file (#2643).

Bug fix:
 * Crash when leaving settings due to backup section refresh animation.
 * Reactions: Do not display reactions on redacted events in timeline.
 * Fix crash for search bar customisation in iOS13 (#2626).
 * Build: Fix build based on git tag.

Changes in 0.9.1 (2019-07-17)
===============================================

Bug fix:
 * Edits history: Original event is missing (#2585).

Changes in 0.9.0 (2019-07-16)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.10.1](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.10.1)).
 * Upgrade MatrixKit version ([v0.10.0](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.10.0)).
 * RoomVC: When replying, use a "Reply" button instead of "Send".
 * RoomVC: New message actions (#2394).
 * Room upgrade: Autojoin the upgraded room when the user taps on the tombstone banner (#2486).
 * Room upgrade: Use the `server_name` parameter when joining the new room (#2550).
 * Join Room: Support via parameters to better handle federation (#2547).
 * Reactions: Display existing reactions below the message (#2396).
 * Menu actions: Display message time (#2463).
 * Reactions Menu: Fix position (#2447).
 * Context menu polish (#2466).
 * Upgrade Piwik/MatomoTracker (v6.0.1) (#2159).	
 * Message Editing: Annotate edited messages in timeline (#2400).	
 * Message Editing: Editing in the timeline (#2404).	
 * Read receipts: They are now counted at the MatrixKit level.
 * Migrate to Swift 5.0.
 * Reactions: Update quick reactions (#2459).
 * Message Editing: Handle reply edition (#2492).
 * RoomVC: Add ability to upload a file that comes from outside the app’s sandbox (#2019).
 * Share extension: Enable any file upload (max 5).
 * Tools: Create filterCryptoLogs.sh to filter logs related to e2ee from Riot logs.

Bug fix:
 * Device Verification: Fix user display name and device id colors in dark theme
 * Device Verification: Name for 🔒 is "Lock" (#2526).
 * Device Verification: Name for ⏰ is "Clock.
 * Registration with an email is broken (#2417).
 * Reactions: Bad position (#2462).
 * Reactions: It lets you react to join/leave events (#2476).
 * Adjust size of the insert button in the People tab, thanks to @dcordero (PR #2473).

Changes in 0.8.6 (2019-05-06)
===============================================

Bug fix:
 * Device Verification: Fix bell emoji name.
 * Device Verification: Fix buttons colors in dark theme.

Changes in 0.8.5 (2019-05-03)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.9.9](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.9.9)).
 * Push: Add more logs to track spontaneously disabling (#2348).
 * Widgets: Use scalar prod urls in Riot mobile apps (#2349).
 * Productiviy: Create templates (see Tools/Templates/README.md).
 * Notifications: Use UserNotifications framework for local notifications (iOS 10+), thanks to @fridtjof (PR #2207).
 * Notifications: Added titles to notifications on iOS 10+, thanks to @fridtjof (PR #2347).
 * iOS 12 Notification: Group them by room (#2337 and PR #2347 thanks to @fridtjof).
 * Notifications: When navigate to a room, remove associated delivered notifications (#2337).
 * Key backup: Adjust wording for untrusted backup to match Riot Web.
 * Jitsi integration: Use the matching WebRTC framework (#1483).
 * Fastlane: Set iCloud container environment (PR #2385).
 * Remove code used for iOS 9 only (PR #2386).

Bug fix:
 * Share extension: Fix a crash when receive a memory warning (PR #2352).
 * Upgraded rooms show up in the share extension twice (#2293).
 * +N read receipt text is invisible on dark theme (#2294).
 * Avoid crashes with tableview reload animation in settings and room settings (PR #2364).
 * Media picker: Fix some retain cycles (PR #2382).

Changes in 0.8.4 (2019-03-21)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.9.8](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.9.8)).
 * Share extension: Remove image large size resizing choice if output dimension is too high to prevent memory limit exception (PR #2342).

Bug fix:
 * Unable to open a file attachment of a room message (#2338).

Changes in 0.8.3 (2019-03-13)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.9.7](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.9.7)).

Bug fix:
 * Widgets: Attempt to re-register for a scalar token if ours is invalid (#2326).
 * Widgets: Pass scalar_token only when required.


Changes in 0.8.2 (2019-03-11)
===============================================

Improvements:
 * Upgrade MatrixKit version ([v0.9.6](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.9.6)).
 * Maintenance: Update cocopoads and pods. Automatic update to Swift4.2.
 * Add app store description as app string resource to make them available for translation on weblate (#2201).
 * Update deprecated contact availability checks (#2222).
 * RoomVC: Remove the beta warning modal when enabling e2e in a room (#2239).
 * RoomVC: Use accent color (green) for the ongoing conference call banner.
 * Fastlane: Update to Xcode 10.1 (#2202).
 * Use SwiftLint to enforce Swift style and conventions (PR #2300).
 * Fix SWIFT_VERSION configuration in post install hook of Podfile (PR #2302).
 * Authentication: support SSO by using the fallback URL (#2307).
 * Authentication: .well-known support (#2117).
 * Reskin: Colorise users displaynames (#2287).

Bug fix:
 * Reskin: status bar text is no more readable on iPad (#2276).
 * Reskin: Text in badges should be white in dark theme (#2283).
 * Reskin: HomeVC: use notices colors for badges background in section headers (#2292).
 * Crash in Settings in 0.8.1 (#2295).
 * Quickly tapping on a URL in a message highlights the message rather than opening the URL (#728).
 * 3D touching a link can lock the app (#1818).
 * Do not display key backup UI if the user has no e2e rooms (#2304).

Changes in 0.8.1 (2019-02-19)
===============================================

Improvements:
 * Key backup: avoid to refresh the home room list on every backup state change (#2265).

Bug fix:
 * Fix text color in room preview (PR #2261).
 * Fix navigation bar background after accepting an invite (PR #2261)
 * Tabs at the top of Room Details are hard to see in dark theme (#2260).

Changes in 0.8.0 (2019-02-15)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.9.5 - https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.9.5).
 * Theming: Create ThemeService to make theming easier. Use it to reskin Riot.
 * Use modern literals and array/dictionary syntax where possible (PR #2160).
 * Add SwiftGen pod in order to generate Swift constants for assets (#2177).
 * RoomVC: Remove the beta warning modal when opening an e2e room (#2239).
 * RoomVC: `Redact` has been renamed to `Remove` to match riot/web (#2134).
 * Clean up iOS version checking (#2190).
 * Key backup: Implement setup screen (#2198).
 * Key backup: Implement recover screen (#2196).
 * Key backup: Add a dedicated section to settings (#2193).
 * Key backup: Implement setup reminder (#2211).
 * Key backup: Implement recover reminder (#2206).
 * Key backup: Update key backup setup UI and UX (PR #2243).
 * Key backup: Logout warning (#2245).
 * Key backup: new recover method detected (#2230).

Bug fix:
 * Use white scroll bar on dark themes (#2158).
 * Registration: fix tap gesture on checkboxes in the terms screen.
 * Registration: improve validation UX on the terms screen (#2164).
 * Registration: improve scrolling on the reCaptcha screen (#2165).
 * Infinite loading wheel when taping on a fake room alias (#679).
 * Ban and kick reasons are silently discarded (#2162).
 * Room Version Upgrade: Clicking the link in the room continuation event to go back to the old version of the room doesn't work (#2179).
 * Share extension: Fail to send screenshot (#2168).
 * Share extension: Handle rich item sharing (image + text + URL) (#2224).
 * Share extension: Sharing pages from Firefox only shares their title (#2163).
 * Share extension: Fix unloaded theme (PR #2235).
 * Reskin: Jump to first unread message doesn't show up in 0.7.12 TF (#2218).
 * Reskin: Sometimes the roomVC navigation bar is tranparent (#2252).

Changes in 0.7.11 (2019-01-08)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.9.3).
 * Fix almost all the warnings caused by -Wstrict-prototypes, thanks to @fridtjof (PR #2155).

Changes in 0.7.10 (2019-01-04)
===============================================

Bug fix:
 * Share extension: Fix screenshot sharing (#2022). Improve image sharing performance to avoid out of memory crash.

Changes in 0.7.9 (2019-01-04)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.9.2).

Bug fix:
 * Registration: email or phone number is no more skippable (#2140).

Changes in 0.7.8 (2018-12-12)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.9.1).
 * Replace the deprecated MXMediaManager and MXMediaLoader interfaces use (see matrix-org/matrix-ios-sdk/pull/593).
 * Replace the deprecated MXKAttachment and MXKImageView interfaces use (see matrix-org/matrix-ios-kit/pull/487).
 * i18n: Enable Japanese (ja)
 * i18n: Enable Hungarian (hu)
 
Bug fix:
 * Registration: reCAPTCHA does not work anymore on iOS 10 (#2119).

Changes in 0.7.7 (2018-10-31)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.8.6).

Bug fix:
 * Notifications: old notifications can reappear (#1985).

Changes in 0.7.6 (2018-10-05)
===============================================

Bug fix:
 * Wrong version number.

Changes in 0.7.5 (2018-10-05)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.8.5).
 * Server Quota Notices: Implement the blue banner (#1937).

Changes in 0.7.4 (2018-09-26)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.8.4).
 * Lazy loading: Enable it by default (if the homeserver supports it).
 * i18n: Add Spanish (sp).
 * Settings: Make advanced info copyable (#2023).
 * Settings: Made cryptography info copyable, thanks to @daverPL (PR #1999).
 * Room settings: Anyone can now set a room alias (#2033).

Bug fix:
 * Fix missing read receipts when lazy-loading room members.
 * Weird text color when selecting a message (#2046).

Changes in 0.7.3 (2018-08-27)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.8.3).

Bug fix:
 * Fix input toolbar reset in RoomViewController on MXSession state change (#2006 and #2008).
 * Fix user interaction disabled in master view of UISplitViewContoller when selecting a room (#2005).

Changes in 0.7.2 (2018-08-24)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.8.2).
 * Server Quota Notices in Riot (#1937).
 
Bug fix:
 * User defaults: the preset application language (if any) is ignored.
 * Recents: Avoid to open a room twice (it crashed on room creation on quick HSes).
 * Riot-bot: Do not try to create a room with it if the user homeserver is not federated.

Changes in 0.7.1 (2018-08-17)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.8.1).
 
Bug fix:
 * Empty app if initial /sync fails (#1975).
 * Direct rooms can be lost on an initial /sync (vector-im/riot-ios/issues/1983).
 * Fix possible race conditions in direct rooms management.

Changes in 0.7.0 (2018-08-10)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.8.0).
 * RoomVC: Add "view decrypted source" option on the selected event (#1642).
 * RoomVC: Implement replies sending (#1911).
 * Support room versioning (#1938).
 * Add support of lazy-loading of room members (#1931) (disabled for now).
 * i18n: Add Traditional Chinese (zh_Hant).
 * i18n: Add Albanian (sq).
 * Update project structure. Organize UI related files by feature (PR#1932).
 * Move image files to xcassets (PR#1932).
 * Replies: Implement sending (#1911).
 * Support room versioning (#1938).
 * Add support of lazy-loading of room members (#1931).
 * Chat screen: Add "view decrypted source" option on the selected event (#1642).
 * Improve GDPR consent webview management (#1952).

Bug fix:
 * Multiple rooms can be opened (#1967).

Changes in 0.6.20 (2018-07-13)
===============================================

Improvements:
 * Update contact permission text in order to be clearer about the reasons for access to the address book.

Changes in 0.6.19 (2018-07-05)
===============================================

Improvements:

Bug fix:
* RoomVC: Fix duplicated read receipts (regression due to read receipts performance improvement).

Changes in 0.6.18 (2018-07-03)
===============================================

Improvements:
 * RoomVC: Add a re-request keys button on message unable to decrypt (#1879).
 * Analytics: Move code from AppDelegate to a dedicated class: Analytics.
 * Analytics: Track Matrix SDK stats (time to startup the app).
 * Crypto: Add telemetry for events unable to decrypt (UTDs).
 * Added the i18n localisation strings to the accessibility labels (#1842), thanks to @einMarco (PR#1906).
 * Added titles to sound files ID3 tags.

Bug fix:
 * RoomVC: Read receipts processing dramatically slows down UI (#1899).
 * Lag in typing (#1820).
 * E2E messages not decrypted in notifs after logging back in (#1914).

Changes in 0.6.17 (2018-06-01)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.14).
 * Send Stickers (#1860).
 * Settings: Add deactivate account (#1870).
 * Widgets: Update from UIWebView to WKWebView to improve performance.
 
Bug fix:
 * Quotes (by themselves) render as white blocks (#1877).
 * GDPR: consent screen could not be closed (#1883).
 * GDPR: Do not display error alert when receiving GDPR Consent not given (#1886).
 
Translations:
 * Enable Icelandic.

Changes in 0.6.16 (2018-05-23)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.12).
 * Display quick replies in timeline (#1858).
 * Beginning of "Send sticker" support (#1860).
 * Use existing message.mp3 for notification sounds, thanks to @pixlwave (PR #1835).
 * GDPR: Display the consent tool in case of M_CONSENT_NOT_GIVEN error (#1871).
 
Bug fix:
 * Fix the display of side borders of HTML blockquotes (#1857).
 * Moved UI update to main queue, thanks to @Taiwo (PR #1854).
 * Timestamps say 'Yesterday' when it is today (#1274), thanks to @pixlwave (PR #1865).
 * RoomVC: messages with link blink forever #1869

Changes in 0.6.15 (2018-04-23)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.11).
 
Bug fix:
 * Regression: Sending a photo from the photo library causes a crash.
 
Changes in 0.6.14 (2018-04-20)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.10).
 * The minimal iOS version is now 9.0.
 * Render stickers in the timeline (#1819).
 * Support specifying kick and ban msgs (#1816), thanks to @atabrizian (PR #1824).
 * Confirmation popup when leaving room (#1793), thanks to @atabrizian (PR #1828).

Bug fixes:
 * Global Messages search: some search results are missing.
 * Crash on URL like https://riot.im/#/app/register?hs_url=... (#1838).
 * All rooms showing the same avatar (#1673).
 * App fails to logout on unknown token (#1839).

Changes in 0.6.13 (2018-03-30)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.9).
 * Make state event redaction handling gentler with homeserver (vector-im/riot-ios#1823).

Bug fixes:
 * Room summary is not updated after redaction of the room display name (vector-im/riot-ios#1822). 

Changes in 0.6.12 (2018-03-12)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.8).
 * Add Catalan, thanks to @salvadorpla.
 * Add Bulgarian, thanks to @rbozhkova. 
 * Add quick reply to notifications (#625), thanks to @joeywatts(PR #1777).
 * Room: Inform user when they cannot post to a room because of low power level.
 * Matrix Apps: Enable them by default. Remove the settings from LABS section (#1795).
 * Improve server load on event redaction (vector-im/riot-ios#1730).
 
Bug Fix:
 * Push: Missing push notifications after answering a call (vector-im/riot-ios#1757).
 * Fix screen flashing at startup (#1798).
 * Cannot join from a room preview for room with a long topic (#1645).
 * Groups: Room summary should not display notices about groups (vector-im/riot-ios#1780).
 * MXKEventFormatter: Emotes which contain a single emoji are expanded to be enormous (vector-im/riot-ios#1558).
 * Crypto: e2e devices list not shown (#1782).
 * Direct Chat: a room was marked as direct by mistake when I joined it.
 
Changes in 0.6.11 (2018-02-27)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.7).

Bug Fix:
 * My communities screen is empty despite me being in several groups (#1792).

Changes in 0.6.10 (2018-02-14)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.6).
 * Group Details: Put the name of the community in the title.

Bug Fix:
 * App crashes on cold start if no account is defined.
 * flair labels are a bit confusing (#1772).

Changes in 0.6.9 (2018-02-10)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.5).
 * Add a new tab to list the user's communities (vector-im/riot-meta#114).
 * Add new screens to display the community details, edition is not supported yet (vector-im/riot-meta#115, vector-im/riot-meta#116, vector-im/riot-meta#117).
 * Room Settings: handle the related communities in order to show flair for them.
 * User Settings: Let the user enable his community flair in rooms configured to show it.
 * Replace Google Analytic by Matomo(Piwik) (PR #1753).
 * Spontaneous logout: Try to detect it in AuthenticationViewController and crash the app if it happens (PR #1761).
 * Share: Make sure the progress bar is always displayed.
 * Jitsi: update lib to jitsi-meet_2794 tag.

Bug Fix:
 * iPad: export e2e keys failed, there pops no window up where to save the keys (#1733).
 * Widget can display "Forbidden" (#1723).
 * keyboard is not dark when entering bug report in dark theme (#1720), thanks to @daverPL (PR #1729).
 * Contact Details: The contact avatar quality is very low when the contact details screen is opened from a link.
 * Cancel Buttons use style Cancel (PR #1737), thanks to @tellowkrinkle.
 * Share Extension: Fix crash on a weak self (PR #1744).
 * Share: The extension crashes if you try to share a GIF image (#1759)
 
Translations:
 * Catalan, added thanks to @sim6 and @salvadorpla (PR #1767).

Changes in 0.6.8 (2018-01-03)
===============================================

Improvements:
 * AppDelegate: Enable log to file earlier.

Bug Fix:
 * AppDelegate: Disable again loop on [application isProtectedDataAvailable] because it sometimes makes an OS watchdog kill the app.
 * Missing Push Notifications (#1696): Show a notification even if the app fails to sync with its hs.

Changes in 0.6.7 (2017-12-27)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.4).

Bug Fix:
 * Share extension is not localized? (#1701).
 * Widget: Fix crash with unexpected widget data (#1703).
 * Silent crash at startup in [MXKContactManager loadCachedMatrixContacts] (#1711).
 * Should fix missing push notifications (#1696).
 * Should fix the application crash on "Failed to grow buffer" when loading local phonebook contacts (https://github.com/matrix-org/riot-ios-rageshakes/issues/779).

Changes in 0.6.6 (2017-12-21)
===============================================

Bug Fix:
 * Widget: Integrate widget data into widget URL (https://github.com/vector-im/riot-meta/issues/125).
 * VoIP: increase call invite lifetime from 30 to 60s (https://github.com/vector-im/riot-meta/issues/129).

Changes in 0.6.5 (2017-12-19)
===============================================

Bug Fix:
 * Push Notifications: Missing push notifications (#1696).

Changes in 0.6.4 (2017-12-05)
===============================================

Bug Fix:
 * Crypto: The share key dialog can appear with a 'null' device (#1683).

Changes in 0.6.3 (2017-11-30)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.3).
 * Crypto: Add key sharing dialog for incoming room key requests (PR #1652, PR #1655).
 * Update developing instructions in README, thanks to @aaronraimist.
 * Add basic OLED black theme, thanks to @aaronraimist (PR #1665).
 * Make code compatible with `!use_frameworks` in Podfile.

Bug Fix:
 * Failed to send photos which are not stored on the local device and must be downloaded from iCloud (#1654).
 * Spontaneous logouts (#1643).
 * Dark theme: Make the keyboard dark (#1620), thanks to @aaronraimist.
 * App crashes when user wants to share a message (matrix-org/riot-ios-rageshakes#676).
 * Fix UICollectionView warning: The behavior of the UICollectionViewFlowLayout is not defined...
 
Translations:
 * Vietnamese, enabled thanks to @loulsle.
 * Simplified Chinese, updated thanks to @tonghuix.
 * German, updated thanks to @dccs and @fkalis.
 * Japanese, updated thanks to @yuurii and @libraryxhime.
 * Russian, updated thanks to @Walter.

Changes in 0.6.2 (2017-11-13)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.2).

Bug Fix:
 * Share extension silently fails on big pics - eg panoramas (#1627).
 * Share extension improvements: display the search input by default,... (#1611).

Changes in 0.6.1 (2017-10-27)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.1).
 * Add support for sending messages via Siri in e2e rooms, thanks to @morozkin (PR #1613).

Bug Fix:
 * Jitsi: Crash if the user display name has several components (#1616).
 * CallKit - When I reject or answer a call on one device, it should stop ringing on all other iOS devices (#1618).
 * The Call View Controller is displayed whereas the call has been cancelled.

Changes in 0.6.0 (2017-10-23)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.7.0).
 * Add Riot to the system share options, thanks to @aramsargsyan.
 * Add support of Callkit, thanks to @morozkin
   - Matrix incoming calls are displayed by the system including on the lock screen.
   - Matrix Calls are listed in the system call history.
 * Add support of Pushkit, thanks to @morozkin: 
   - Message content in notifications does not go anymore through Apple service.
   - Riot can display decrypted message.
   - Riot shows the system incoming screen on Matrix incoming call notifications.
 * RoomVC: Add the ability to cancel the sending of a room message and improve the cancellation of a media upload (PR #1550).
 * BugReportVC: Do not send empty report (bis) (PR #1573).
 * Refactor the Podfile to make extensions management easier (PR #1586).
 * Logs: Logs app extensions into separate files (console-share.log & console-siri.log) (PR #1602).
 * Add message sending to non-e2e rooms via Siri, thanks to @morozkin (PR #1606).

Bug Fix:
 * Switching network filter in room directory is ignored when searching the dir (part of #1496, PR #1584).
 * Search in directory: Fix crash in Simplified Chinese (PR #1588).
 * Member Info page avatars are systematically cropped (iOS 11) (#1590, PR #1604).
 * Room Preview: the room name and avatar are missing for somepublic rooms (#1603, PR #1605).

Changes in 0.5.6 (2017-10-05)
===============================================

Improvements:
 * Settings: Pin rooms with missed notifs and unread msg by default (PR #1556).

Bug Fix:
 * Fix RAM peak usage when doing an initial sync with large rooms (PR #1553).

Changes in 0.5.5 (2017-10-04)
===============================================

Improvements:
 * Rageshake: Add a setting to enable (disable) it (PR #1552).

Bug Fix:
 * Some rooms have gone nameless after upgrade (PR #1551).

Changes in 0.5.4 (2017-10-03)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.6.3).
 * Show the "Integrations Manager" into a webview (PR #1511).
 * Widgets: list active widgets in a room (#1535).
 * Jitsi widget: Add notices for jitsi widget in rooms histories (PR #1488).
 * Add screen for incoming calls, thanks to @morozkin (PR #1477).
 * Update strings for push notifications, thanks to @morozkin (PR #1486).
 * Handle the room display name and its avatar at the room summary level (PR #1510).
 * Create DM with Riot-bot on new account creation (vector-im/riot-meta#94).
 * Add WidgetViewController (PR #1514).
 * BugReportVC: Force users to add a description in crash reports (PR #1520).
 * Jitsi: Enable the "Create conference calls with jitsi" settings by default (PR #1549).
 
Bug Fixes:
 * Fix inbound video calls don't have speakerphone turned on by default (#933).
 * Room settings: the displayed room access settings is wrong (#1494).
 * When receiving an invite tagged as DM it's filed in rooms (#1308).
 * Altering DMness of rooms is broken (#1370).
 * Alert about incoming call isn't displayed (#1480), thanks to @morozkin (#1481).
 * Dark theme - Improvements (#1444).
 * Settings: some of the labels push the switch controls off screen (#1506).
 * Settings: The "Sign out" button and other buttons of this page sometimes blinks (#1354).
 * [iOS11] "Smart [colors] Invert" renders badly in the app (#1524).
 * [iOS11] Room member details: the member's avatar is cropped in the header (#1531).
 * [iOS11] Fix layout disruptions (PR #1537).
 * Return key on hardware keyboards now sends messages, thanks to @vivlim (PR #1513).
 * MediaPickerViewController: Add sanity checks to avoid crashes (#1532).
 * RoomsViewController: Crash in [RoomsViewController prepareForSegue:… (#1533).
 
Translations:
 * Enable Basque, thanks to @osoitz.
 * Enable Simplified Chinese, thanks to @tonghuix (Note: the push notifications are not translated yet).

Changes in 0.5.3 (2017-08-25)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.6.2).
 * Support dark theme (vector-im/riot-meta#22).
 * Set the application group identifier to be able to share userDefaults object.
 
Bug Fixes:
 * SettingsViewController: Release correctly the pushed view controller.
 * App have crashed whilst uploading photos (#1445).
 * Register for remote notifications only if user provides access to notification feature, thanks to @aramsargsyan (#1467).
 * Improvements in notification registration flow, thanks to @aramsargsyan (#1472).
 
Translations:
 * Enable Russian.

Changes in 0.5.2 (2017-08-01)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.6.1).
 * Emojis: Boost size of messages containing only emojis (not only one).
 * Bug Report: Make the crash dump appear in GH issues created for crashes

Changes in 0.5.1 (2017-08-01)
===============================================

Improvements:
 * Fix a build issue that appeared after merging to master.

Changes in 0.5.0 (2017-08-01)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.6.0).
 * MXKRoomViewController: Merge of membership events (MELS).
 * Language can be changed at runtime from the settings.
 * Add the m.audio attachments support (https://github.com/vector-im/riot-ios#1102).
 * Improve opening of a room. No more white screen with a loading wheel.
 * Remove MXKAlert, use UIAlertViewController instead.
 * UX Rework: Add edition mode support to the home page (vector-im/riot-meta#75).
 * RoomTableViewCell: Replace the direct chat icon with a green ring.
 * People: Use the user directory api from the homeserver to search people (vector-im/riot-meta#95).
 * Add support of matrix.to links to users (#1410).
 * RoomVC: Send button: Fix its width adjustability to support other languages.

Translations:
 * Note: Only Dutch, German and French have been added to Riot. Other translations are not complete yet.
 * Dutch, thanks to @nvbln (PR #1317).
 * German, thanks to @krombel, @esackbauer, @Bamstam.
 * French, thanks to @krombel, @kaiyou, @babolivier and @bestspyever.
 * Russian, thanks to @gabrin, @Andrey and @shvchk.
 * Simplified Chinese, thanks to @tonghuix.
 * Latvian, thanks to @lauris79.
 * Spanish, thanks to @javierquevedo.
 
Bug fixes:
 * Home: On iOS <= 9.0, the rooms collection scrolls to the left on room edition.
 * Home: Fix the flickering effects observed when user edits a room on iOS < 10.
 * Camera preview is broken after a second try (#686).
 * Fix the wrong preview layout on iPad described in PR #1372.
 * Room settings: ticks are badly refreshed (#681).

Changes in 0.4.3 (2017-07-05)
===============================================

Improvement:
 * Update the application title with "Riot.im".


Changes in 0.4.2 (2017-06-30)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.5.2).
 * Chat: Expand read receipts when user taps on it #59, thanks to @aramsargsyan (#1341).
 * GA: Disable GA in debug as it pollutes stats and crashes.
 * Home: Display room name on 2 lines.
 
Bug fixes:
 * Fix: Crash when scrolling in the public rooms from Unified Search (#1355).
 * Chat screen: the message overlaps its timestamp.
 * Chat screen: several encryption icons are displayed on the same event.
 * Blank pages with random "unread msgs" bars whilst they load.
 * Fix a crash when rotating + debackgrounding the app (#1362).
 * Bug report: Remove the old requirement for an existing email account.
 * Crash report: Do not loose what the user typed when debackgrounding the app.

Changes in 0.4.1 (2017-06-23)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.5.1).
 
Bug fixes:
 * Room Chat: Scrolling manually to the bottom of the no live timeline doesn't flip it to read/write view (#1312).
 * Enhancement - UX Rework: Update the buttons of the room expanded header (vector-im/riot-meta#76).
 * Contact search: Unexpected empty search result.
 * tap-on-tab should include the top-of-page location in its cycle of options (#1316).
 * Fix crash on decline button, thanks to @morozkin (#1330).
 * Room directory: stuck after the 20 first items (#1329).
 * Room directory: "No public rooms available" is displayed while loading (#1336).
 * Room directory: Clicking on "No public rooms available" make the app crash.
 * Crash when hitting a room header after some special steps (#1340).
 * Chat screen: the search icon is missing after switching in live from a non live timeline (#1344).
 * Crash when hitting room from unified search/browse directory (#1342).
 * tapping on an unread room on home page takes you to the wrong room (#1304).
 * Read marker: when being kicked, the "Jump to first unread message" shouldn't be displayed (#1338).

Changes in 0.4.0 (2017-06-16)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.5.0).
 * Full UX rework.
 * Add read markers synchronisation across matrix clients.
 * Add a new popup dialog for reporting bugs and crashes
 * Add a picker to select a server directory.
 * Add an option to join room by id or alias.
 * Pods: Update Cocoapods and reduce Riot/OLM coupling, thanks to @hberenger (PR #1220).
 
Bug fixes:
 * Files search: display the attachment thumbnail (#1135).
 * Chevron to exit roomview after clicking through from search results can disappear (#841).
 * Public rooms: Fix the infinite loading of the public rooms list after logging out & in.
 * iOS should have 'Send a message (encrypted)' in placeholder (#1231).
 * Fix dangling in the memory CallViewController, thanks to @morozkin (#1248).
 * Fix crash in MediaPickerViewController (#1252).
 * Fix crash in global search (https://github.com/matrix-org/riot-ios-rageshakes#32).
 * Fix crash in [MXKContactManager localContactsSplitByContactMethod] (https://github.com/matrix-org/riot-ios-rageshakes#36).
 * Fix App crashes on [AvatarGenerator imageFromText:withBackgroundColor:] (#657).

Changes in 0.3.13 (2017-03-23)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.4.11).
 
Bug fixes:
 * Chat screen: image thumbnails management is broken (#1121).
 * Image viewer repeatedly loses overlay menu (#1109).

Changes in 0.3.12 (2017-03-21)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.4.10).
 
Bug fixes: 
 * Registration with email failed when the email address is validated on the mobile phone.
 * Chat screen - The missed discussions badge is missing in the navigation bar.


Changes in 0.3.11 (2017-03-16)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.4.9).
 * Crypto: manage unknown devices when placing or answering a call (#1058).
 
Bug fixes: 
 * [Direct Chat] No placeholder avatar and display name from the member details view (#923).
 * MSIDSN registration.
 * [Tablet / split mode] The room member details page is not popped after signing out (#1062).

Changes in 0.3.10 (2017-03-10)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.4.8).
 * RoomActivitiesViews: Automatically update its height according to the messageTextView content.
 * Room preview: If no data is available for this room, we name it with the known room alias if any.
 * Crypto: Show an alert when sending a message while there are unknown devices in the room.
 * Crypto: Add the screen that list unknown devices (UsersDevicesViewController).
 * Crypto: Add global and per-room settings to blacklist unverified devices.
 * Crypto: Warn unknown devices: Add a send anyway button.
 * Crypto: Display an alert warning about the beta state of e2e encryption when entering the first time in an encrypted room.
 * Settings: Add mobile phone numbers in user's profile.
 * Settings: Support the third-party identifier deletion in the user's profile.
 * Registration: Support the login flow based on a mobile phone number (msisdn).
 * Login: Support the new login API with different types of identifiers (id, thirdparty and phone). We keep supporting the old login API.
 * Improve the people invite screens: Discover Riot/Matrix users by using the local phone numbers (#904).
 
Bug fixes:
 * Avatars (and probably other media) do not display with account on a self-signed server (#816)
 * App crashes on new start chat.
 * Corrupted room state: some joined rooms appear in Invites section (#1029).
 * Remove Riot animation (if any) in case of a forced logout.
 * Registration: support the dummy authentication flow (#912).
 * Settings: Disable 'Save' button on saving.
 * Default room avatar for an empty room should not be your own face (#1044).
 * Resend msgs now? needs cancel button if you want to discard them (#306).
 * Crypto: After importing keys, the newly decrypted msg have a forbidden icon (#1028).

Changes in 0.3.9 (2017-02-08)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.4.7).
 * E2E keys export: Add an "Export keys" button to the settings
 * Update WebRTC pod to 56.10.15101 (#991).
 * Trying to delete 3pid invites fails with terrible error (#999).
 * Hide/show the non-matrix-enabled contacts from the local contacts section (#904).
 * Show riot enabled local contacts in known contacts too (#1001).
 * Local contact section should be collapsable even when no search is started (#1017).
 
Bug fixes:
 * App stuck in Riot animation on cold start (#964).
 * Got stuck syncing forever (#1008).
 * Duplicated msg when going into room details (#970).
 * Local echoes for typed messages stay (far) longer in grey (#1007).
 * App crashes a few seconds after a successful login (#965).
 * Unexpected red navigation bar.
 * Rageshake on membership list doesn't work (#987).
 * New invite button should still be visible when the keyboard is shown (#961).
 * RoomDataSource: some room data listeners are not removed correctly.
 * Emoji displaynames aren't correctly initialed (#979).
 * App crash: [MXKRoomInputToolbarView contentEditingInputsForAssets:withResult:onComplete:] (#1015).
 * App crash: [__NSCFString replaceCharactersInRange:withString:]: nil argument (#990).

Changes in 0.3.8 (2017-01-24)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.4.6).
 * Crypto: Prevent people from relogging when upgrading from v0.3.4, the current app store version (PR https://github.com/matrix-org/matrix-ios-sdk/pull/226).
 * AuthenticationViewController: update layout on iPhone 7.
 * ContactsTableViewController: refresh the matrix ids in the local contacts when view will appear.
 * ContactTableViewCell: Let ContactsTableViewController update the matrix ids of the local contacts.
 * Warn that logging out will lose E2E keys (#950).
 * Logs: Log versions of app, MatrixKit, MatrixSDK etc at startup.
 
Bug fixes:
 * Room details members: wrong unknown wording (#941).
 * App may crash when user rotates the device while he joins a room.

Changes in 0.3.7 (2017-01-19)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.4.5).
 * The contact book is used to search for users by email or phone number on Riot.
 * Ask to the existing users the permission to upload emails when the contact access is already granted.
 * ContactTableViewCell: Highlight the Matrix-enabled contacts in local contacts section.
 * Improve the people invite screens (#904).
 * "Add contact" button has been added on Room Member list (#905).
 * Google Analytics: enable MXSession GA stats and send stat on launch screen display time.
 
Bug fixes:
 * Resend now function doesn't work on canceled upload file (#890).
 * Riot is picking up my name within words and highlighting them (#893).
 * Failure to decrypt megolm event despite receiving the keys (#913).
 * Cloned rooms in rooms list (#889).
 * Riot looks to me like I'm sending the same message twice (#894).
 * matrix.to links containing room ids are not hyperlinked (#886).
 * Integer negative wraparound in upload progress meter (#892).
 * Performance on searching people when inviting is terrible (#887).
 * App crashes when the user taps on an avatar in a search result (#895).
 * Hit File tab from room details view make Riot crash (#931).
 * Crash on Create a room button (#935).
 * Local contacts are missing when the user logs in again (PR #942).

Changes in 0.3.6 (2016-12-23)
===============================================

Improvements:
 * Add descriptions for access permissions to Camera, Microphone, Photo Gallery and Contacts.

Changes in 0.3.5 (2016-12-19)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.4.4).
 * Update Riot icons. 
 * Launch screen is now animated.
 * Crypto: many improvements (including no more UI freeze) and bug fixes in sdk.
 * Crypto: Show a popup when log out and in is required.
 * Chat screen - Encrypted room: messages being encrypted are now displayed in green.
 * Room member details: Add devices sections.
 * User settings: Display the cryptography info before the devices list.
 * Update rageshake email content.
 * Recognise iPhone7.
 
Bug fixes:
 * Voip : decline call when room opened freeze riot (#764).
 * Wrong room name of a direct chat in user's profile (#824).
 * Direct Message: No little green man in direct chats from member's detail (#781).
 * Messages: swipe is broken when user did try to swipe on invited room (#838).
 * Chat screen - Encrypted room: the encryption icon may not be aligned with the last sent message.
 * Recents: App crashes on recents.
 * Messages: App crashes during drag and drop.
 * Possible fix of app crash on exception: "UITableView dataSource is not set".

Changes in 0.3.4 (2016-11-23)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.4.3).
 * Settings: User Settings: List user's devices and add the ability to rename or delete them.
 
Bug fixes:
 * User settings: The toggle buttons are disabled by mistake.
 * Typing indicator should stop when the user sends his message (https://github.com/vector-im/vector-ios#809).
 * Crypto: Do not allow to redact the event that enabled encryption in a room.
 * Crypto: Made attachments work better cross platform.

Changes in 0.3.3 (2016-11-22)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.4.2).
 * Settings: Add cryptography information.
 
Bug fixes:
 * Crypto: Do not allow to redact the event that enabled encryption in a room.

Changes in 0.3.2 (2016-11-18)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.4.1).
 
Bug fixes:
 * Make share/save/copy work for e2e attachments.
 * Wrong thumbnail shown whilst uploading e2e image  (https://github.com/vector-im/vector-ios#795).
 * [Register flow] Register with a mail address fails (https://github.com/vector-im/vector-ios#799).

Changes in 0.3.1 (2016-11-17)
===============================================

Bug fixes:
 * Fix padlock icons on text messages.
 * Fix a random crash when uploading an e2e attachment.

Changes in 0.3.0 (2016-11-17)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.4.0).
 * Add end-to-end encryption UI/UX #723.
 * Update the services supported by Riot by adding the voip service #648.
 * Add Files tab in global search screen #652.
 * Add Files index in room settings screen #652.
 * Showing DMs in the UI (as little green men) #715.
 * Add ability to tag/untag direct rooms in Messages screen #715.
 * Reuse the existing direct room when hitting 'start chat' from Messages screen #715.
 * List all the current direct rooms with a user in the Member/Contact details #715.
 
Bug fixes:
 * Search messages tab: background picture covering up the tabs when device is turned horizontaly #654.
 * Changing notif setting from swipe menu should change the room apparence in the list #525

Changes in 0.2.3 (2016-09-30)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.19).
 * RoomSearchDataSource: Remove the matrix session from the parameters in `initWithRoomDataSource` API.
 * Enhance the messages search display.
 
Bug fixes:
 * App crashes when user taps on room alias with multiple # in chat history #668.
 * Room message search: the message date & time are not displayed #361.
 * Room message search: the search pattern is not highlighted in results #660.

Changes in 0.2.2 (2016-09-27)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.18).
 * Media picker: Support video capture #533.
 * VoIP call screen: Update call controls icons #598.
 * Media picker: Switching camera button and exit button are not very visible #610.
 
Bug fixes:
 * Login screen: Stuck on flashing loading wheel in case of invalid credentials #637.
 * Settings screen headers slide down over the already fully displayed screen #636.
 * Chat screen: Wrong display after placing a conf call in a room with unsent messages #633.
 * Quoting a msg overrides what I already typed #641.
 * Crash due to a race condition in read receipts management #645.
 * App may crash when the user logs out while a request is pending.

Changes in 0.2.1 (2016-09-15)
===============================================

Bug fixes:
 * Use Apple version for T&C.
 * Revert the default IS.

Changes in 0.2.0 (2016-09-15)
===============================================

Improvements:
 * Update name & icons
 * Upgrade MatrixKit version (v0.3.17).
 * Screen when placing a voip call can be incredibly ugly #597.
 * Tap on avatar in Member Info page to zoom to view avatar full page #517.
 * Change the message edit edit like in web #591
 * Messages: "Start chat" is the suggestion to replace 'invite people'.
 * Contact details: Enable voip call options.
 * People tab: support email and matrix id selection.
 
Bug fixes:
 * Tapping notifications doesn't take you to the right room in iOS 10 #599.
 * iOS10: App crashes when it wants to access user's data (Photos, Contacts, Camera, Mic) #605.
 * Chat screen: Hang up icon overlap the send button #614.

Changes in Vector iOS in 0.1.17 (2016-09-08)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.16).
 * Enhancement: Improve room creation process #529
 * VoIP and conference call features are enabled by default.
 * Custom audio call sounds.
 * Hyperlink mxids and room aliases: open room member detail or contact detail screen when clicking on a mxid #442.
 * Intercept and create matrix.to URLs within the app #547.
 * Chat screen: We should put an unread room count next to the back button #467.
 * Chat screen: New message(s) notification #532.
 * Chat screen: Add "view source" option on the selected event #459.
 * Chat screen: Context menu should have option to quote a message #502.
 * Chat screen: Cut the context menu in 2 pages. The 2nd page of options is displayed when pressing "More" #502.
 * Room Settings: Ability to copy permalinks for rooms and msgs #276.
 * Call screen: use white as the background colour on VC on iOS.
 * Conference call: Let users join confs as voice or video #574.
 * Settings: Add 'mark all as read' option #541.

Bug fixes:
 * Fix crash in [SettingsViewController heightForHeaderInSection:].
 * Fix crash with incoming calls: "Application tried to present a nil modal view controller on target <UISplitViewController: 0x13f833800>".
 * On iPad, after you use room search, there's no way to leave the search view #440.
 * Chat screen: The navigation bar is missing #414.
 * Chat screen: Hide the expanded header when user has left the current room.
 * Chat screen: The collapse point for scrolling down the keyboard should include the activities view #280.
 * Chat screen: missed discussions badge would go red only if the user missed a highlight #563.
 * Chat screen: Conference call banner: hide the 1px separator view that rendered badly with the banner.
 * Chat screen: wrong attachment is opened #387.
 * Chat screen: mention the member name at the cursor position (not a the end) #385.
 * Chat screen: Add feedback when user clicks on attached files #534.
 * Chat screen: Attachment viewer: Video controls are buggy #460.
 * Chat screen: Preview on world readable room failed #556.
 * Chat screen: Until e2e is impl'd, encrypted msgs should be shown in the UI as unencryptable warning text #559.
 * Chat screen: Kick reason should displayed like the webclient #549.
 * Room screen: mention the member name at the cursor position (not a the end) #163.
 * Room activities: Allow to display the info on 2 lines so that "Connectivity to the server has been lost" can be displayed on iPhone5 in portrait.
 * Room Settings: tap on existing room address is ignored #503.
 * Room Settings: some addresses are missing #528.
 * Room members: a member is displayed offline by mistake #406.
 * Room participants: the same email address is coming up twice #367.
 * Room participants: Folks expect hitting 'done' when entering an mxid to invite, rather than having to hit + #487.
 * Call: The "Return to call" banner does not rotate with the device #482.
 * Call: there is no timeout on outgoing call #577.
 * Call: When screen is locked, rotating the screen landscape makes local video preview go upside down #519.
 * Call: Locking phone whilst setting up a call interrupts the call setup #161.
 * AppDelegate: Notification display failed when a view controller is presented modally.
 * Settings: Trim leading/trailing space when setting display names #554.
 * Vector automatically marks incoming messages as read in background #558.
 * Sync has got stuck while the app was backgrounded #506.
 * Handle 404 (Event not found) on permalinks #484.

Changes in Vector iOS in 0.1.16 (2016-08-25)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.15).

Bug fixes:
 * Rooms list: Fix crash when computing recents.
 * Settings: Fix crash when logging out.

Changes in Vector iOS in 0.1.15 (2016-08-25)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.14).
 * Add conference call.
 * Add the Vector VoIP call screen #455.
 * Speed up app startup #376.
 * Call: Update the libjingle lib to its latest version. We now use the pod from https://github.com/Anakros/WebRTC-iOS.
 * Conference call: Add an enabler button in Settings > LABS.
 * Conference call: Add ongoing conference call banner.
 * Banned user list are shown in room settings #450.
 * Display the list of ignored users in user settings #451.
 * Media Picker: Allow multi selection of pictures #301.
 * Settings: Adjust the section header display.
 
Bug fixes:
 * Redacting membership events should immediately reset the displayname & avatar of room members #443.
 * Profile changes shouldn't reorder the room list #494.
 * Media album: The aspect fill ratio is not respected #495.
 * "Return to call" banner: Use the Vector green for the background #482.
 * Tapping on the room details for Matrix HQ freezes the app for about 5s #499.
 * Crash in [AppDelegate applicationDidBecomeActive:] #489.
 * Chat screen: tapping resend now does nothing #510.
 * Conference call: The initialisation of a conference call silently fails when the room member has not enough power level (https://github.com/vector-im/vector-im/vector-web#1948).
 * When the last message is redacted, [MXKRecentCellData update] makes paginations loops #520.
 * MXSession: Do not send kMXSessionIgnoredUsersDidChangeNotification when the session loads the data from the store #491.
 * MXHTTPClient: Fix crash: "Task created in a session that has been invalidated" #490.
 * Call: the remote and local video are not scaled to fill the video container #537.
 
Changes in Vector iOS in 0.1.14 (2016-08-01)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.13).
 * The "Placing VoIP/Video call" feature in now under the LABS settings of the settings page.
 * Call: Check permissions before accessing to the camera and the microphone.
 * Call Better handle call invites when the app resumes.
 * Call: Improve the sending of local ICE candidates to avoid HTTP 429(Too Many Requests) response
 * Crash report: In addition to GA report, prompt the user to report the crash by email.
 
Bug fixes:
 * Call: Fixed the missing return_to_call translation.
 * Call: Make audio continue to work when backgrounding the app.
 * Call: Added sanity check on creation of RTCICEServer objects as crashes have been reported.
 * Vector is turning off my music now that VoIP is implemented #476
 * Call button should be greyed or not be displayed in room with more than 2 users #477.
 * Call: call must be available in 1:1 rooms (invited and banned users do not count).
 * Fixed crash in the room screen reported by GA.
 * Fixed crash in [AppDelegate applicationDidBecomeActive:] #489.

Changes in Vector iOS in 0.1.13 (2016-07-26)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.12).
 * Enable VoIP for 1:1 room #454.
 
Bug fixes:
 * Confirmation prompt before opping someone to same power level #461.
 * Room Settings: The room privacy setting text doesn't fit in phone mode #429.

Changes in Vector iOS in 0.1.12 (2016-07-15)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.11).
 * Chat Screen: Set the right tint color of the "send" button.
 * Messages: Add pink red badge on each invitation #426.
 * Add 'leave' button to room settings #417.
 * Settings: Set the right label text color.
 * Room Settings: Add "Addresses" section #412.
 * Messages: switch decline and preview buttons on invites #447.
 
Bug fixes:
 * App crashes when the user leaves Settings whereas an email binding is in progress.
 * App crashes during [AppDelegate applicationDidEnterBackground:] #452.
 * Room Participants: Admin badge is missing sometimes.
 * Room Participants: The swipe to Leave/Kick is broken.
 * Markdown swallows leading #'s even if there are less than 3 #423.
 * HTML blockquote is badly rendered: some characters can miss #437.
 * Room Settings: check room permissions and grey out those boxes (disable) if you can't change them #430.
 * Room Settings: if there isn't a topic (new rooms) you can't actually change/set it. #441.

Changes in Vector iOS in 0.1.11 (2016-07-01)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.10).
 * Room preview: Show a preview of messages.
 * Room preview: Improve header in landscape
 * Add missing slash commands: /invite, /part and /topic #223.
 * Add Markdown typing support and display of "org.matrix.custom.html" messages body #403
 * Room search: search result includes the search pattern when it corresponds to a valid room alias or id #328
 * Room search: Room preview is used when the user selects a public room that he did not join yet #329.
 * Rooms global search: Refresh the current search results when view will appear.
 * Directory: handle tap on clock status bar.
 * Search Screen: add People tab and contact picker.
 * Chat screen: Mark event in permalinks or search results.
 * Chat screen: Show bing in pink red #410.
 * Chat screen: Show links in green.
 * Room Participants: Validate correctly matrix user identifier during search session.
 * Room Settings: Prompt user to save changes when Members list tab is selected.
 * Room Settings: Add favourite/low prio toggle in room settings #218.
 * Room Settings: Have proper room settings (Room access, History visibility) #337.
 
Bug fixes:
 * Room screen:  Tap on attached video does nothing #380.
 * Hitting back after search results does not refresh results #190.
 * App crashes on : [<__NSDictionaryM> valueForUndefinedKey:] this class is not key value coding-compliant for the key <redacted>.
 * MXKEventFormatter: Add sanity check on event content values to fix "-[__NSCFDictionary length]: unrecognized selector sent to instance" exception.
 * MXKRoomActivitiesView: Fix exception on undefined MXKRoomActivitiesView.xib.
 * App freezes on iOS8 when user goes back on Recents from a Room Chat.
 * Room Preview: the room avatar is missing on invited room received by email #371.
 * Authentication view is not presented when app is launched offline #375.
 * Initial launch flickers up a blank Messages page before the Login page is shown #287.
 * Can't view MemberInfo when inviting users without actually inviting them #271.
 * Room Participants: Idle contacts must be listed before offline contacts in search result.
 * Media Picker: move the camera roll at the top of the folders #373.
 * Room members: double loading wheel #180.
 * App crashes on '/join' command when no param is provided.

Changes in Vector iOS in 0.1.10 (2016-06-04)
===============================================

Improvements:
 * Directory section is displayed by default in Messages when recents list is empty.
 * Support GA services #335.
 * Room Participants: Increase the search field from 44px to 50px high to give it slightly more prominence.
 * Room Participants - Search bar: Adjust green separator to make it more obviously tappable and less like a header.

Changes in Vector iOS in 0.1.9 (2016-06-02)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.9).
 * Remove the 'optional' in the email registration field #352.
 * Restore matrix.org as default homeserver.

Bug fixes:
 * Directory item in search doesn't open the directory if I don't search #353.
 * Room avatars on matrix.org are badly rendered in the directory from a vector.im account #355.
 * Authentication: "Send Reset Email" is truncated on iPhone 4S.

Changes in Vector iOS in 0.1.8 (2016-06-01)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.8).
 * Authentication: Support forgot password option.
 * Messages: Display badges for missed notifications and unread msgs #290.
 * Handle missing VoIP better #323.
 * Add login information to the settings page #330.
 * Directory should be accessible from search even if the search field is empty #104.
 * Settings: Publish third party licenses #304.
 * Settings: Prompt user when notifications are denied.
 * Settings: Disable spell-checking on add email field.
 * Permalinks: Use the beta path of the web app instead of /develop.
 * Authentication: Update the default login flow to the vector.im HS.
 * Authentication: Support automatic fallback to matrix.org HS for existing users.
 * Chat screen: Improved images & videos sending failure UX: Show a red border when the attachment sending failed.
 * Change App badge handling: Replace the missed notifications count with the missed discussions count.
 * Created Room: replace active member label with "invite members" #346.

Bug fixes:
 * Settings: App crashes when user goes back during saving #345.
 * Tapping on icons in recents view doesn't work #298.
 * Crash when the ?, the punctuation mark, is considered as part of a link #320.
 * Messages: All blank after upgrade; no spinner #311.
 * The client should automatically log out when the password is updated from another client #247.
 * Application can crash when a video failed to be converted before sending #318.
 * Room Participants - Search result: the user id should be displayed when 2 members has the same display name #293.
 * Loading one image thumbnail in a sequence seems to set all fullres images downloading #316.
 * It's too hard to press names to auto-insert nicks #309.
 * Need to check push notification registration #333.
 * Option to autocomplete nicknames from their member info page #317.
 * Messages: Apply apple look&feel on overscroll #179.
 * It sounds like something is filling up the logs #344.
 * When images & videos fail to send, it is not clear that they are stuck as 'red' unsent messges #313.
 * Chat screen: Tap on clock status bar should scroll you up #289.
 * tap-on-recents-status-bar doesn't scroll me to top #125.
 * Signout button gives zero user feedback when tapped #302.
 * Champagne search bubbles appears over the rooms list while searching a room member #64.
 * Settings: Profile avatar is not clickable #351.
 * Default text in the memberlist search box would be less confusing if it was 'Search/invite by...' instead of the other way around #349.

Changes in Vector iOS in 0.1.6 (2016-05-04)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.7).
 * Room member details: Order members by power levels (me, admins then moderators then others).
 * Room member details: Sort members with the same algo as Vector web client.
 * Universal link: Add www.vector.im as associated domain.
 * Chat screen: Open member details on tap-on-avatar #294.
 * Ability to report abuse #295.
 * Ability to ignore users #295.

Bug fixes:
 * 6+/iPad: Better manage user with no room in landscape #268.
 * Handle the error on joining a room where everyone has left #283.
 * Video playback stops when you rotate the device #266.
 * 'Enable notifications on your device' toggle spills over the side on an iPhone 5 display #167.
 * Media Picker: user's albums are missing #208.
 * Authentication screen: inputs fields are missing (blank screen) on first app launch.
 * Room member details: only the "start chat" text is clickable, not that whole button area. #282
 * Media Picker: Fix icons used on video preview.
 * Room Participants - Search session: the return key must be 'Done' instead of 'Search' #292.

Changes in Vector iOS in 0.1.5 (2016-04-27)
===============================================

Improvements:
 * Chat Screen: Ability to copy event permalinks into the pasteboard from the edit menu #225

Bug fixes:
 * Fix crash when rotating 6+ or iPad at app start-up.
 * Universal link on an unjoined room + an event iD is not properly managed #246.

Changes in Vector iOS in 0.1.4 (2016-04-26)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.6).
 * Universal link: Support universal links declared at https://vector.im.
 * Room Members: Add Admin/Moderator badge on members's picture.
 * Room members: Support search option #154.
 * Room member details: display matrix id when user taps on display name #129.
 * Expanded Header: adjust labels position when room topic is empty #134.
 * Expanded Header: the height is now variable.
 * Chat screen: Support room preview.
 * Support room preview from email invitation.
 * Chat Screen: Expand header on new created room #229.
 * Chat Screen: Collapse expander header when user scrolls it down.
 * Chat Screen: Keep visible the expanded header or the preview in case of screen rotation, except on iPad and iPhone 6 plus.
 * Universal link: Handle universal links clicked within the app.
 * Universal link: Manage email validation link as universal link
 * AppDelegate: Improved popToHomeViewControllerAnimated: there is now a completion callback called when we are sure that HomeVC is the visibility VC.
 * AppDelegate: Added fixURLWithSeveralHashKeys method in order to fix iOS NSURLs with several hash keys in it.
 * VoIP: Show an action sheet when the user clicks on the call button. He will be able to select Voice or Video Call.

Bug fixes:
 * Store: Detect and remove corrupted room data #160.
 * Cannot paginate to the origin of the room #214.
 * Wrong application icon badge number #254.
 * The hint text animated weirdly horizontally after i send msgs #124.
 * Cancelling registration while waiting for email validation does not actually cancel it #240.
 * Chat screen: lag during the history scrolling. #192.
 * Chat screen: wrong attachment is opened #237.
 * Add nextLink to registration link #202.
 * Room members: Add a specific section INVITED #132.
 * Room Members: Handle correctly the power level.
 * Messages: The user should be able to shrink/expand each section (Invites, Favourites, Conversations...).
 * Chat header: Room details opening is delayed #181.
 * Messages: Room creation button does not respond #249.

Changes in Vector iOS in 0.1.3 (2016-04-08)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.5).
 * Room members: Make UI more intuitive.
 * Registration support - Support the 2 following flows: m.login.email.identity and m.login.recaptcha.
 * Settings: Handle user's linked emails.
 * Room members: Include address book emails in search result #196.

Bug fixes:
 * App crashes when the user did not grant permission to access Photos.
 * Member details: Multiple invitations on Start Chat action.
 * Room members: Invite text box uses the email keyboard which has no colon! #146.
 * Messages - Wait for the end of action before hiding swipe menu
#52.
 * Messages - Plus button (new room creation) is inactive.
 * Chat screen: the user's avatar is missing in input toolbar.
 * App crashes on iPhone 6S in case of rotation on login screen.
 * Do not stop registration process when app is backgrounded.
 * Authentication screen: Handle correctly custom server options.
 * Tapping on room name in expanded header should let you edit it #195.
 * Chat screen: Resume on empty room (Please select a room) #128.
 * Room members: Keyboard is dismissed at each tap (when search result has been scrolled once).

Changes in Vector iOS in 0.1.2 (2016-03-17)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.4).
 * Chat screen: Update timestamp and message edition display.
 * Chat screen: Leave message edition mode when user is typing.
 * Media Picker: Enlarge touch area of the X and switch-camera.
 * Media Picker: Remove red placeholder images on videos #157.
 * Room Creation: handle new created room as an empty room.

Bug fixes:
 * Sliding animation on recents entries can be quite stuttery #162.
 * People search is shown in UI but not yet implemented #165.
 * Outgoing calls in the timeline are shown as Incoming calls in recents #102.
 * T&Cs and Privacy Policy buttons need that text #143.
 * Call button is still visible in production builds #142.
 * I get sometimes typing notifications for myself #123.
 * Room member details: "reset to normal user" option #149.
 * Messages: Unread room handling #159.
 * White screen on first launch #114.
 * Chat: All messages are displayed twice #139.
 * Updating favourites on the web is not reflected on mobile #136.
 * Chat: scrolling to bottom when opening new rooms seems unreliable #148.
 * Chat: persistent unsent messages #164.

Changes in Vector iOS in 0.1.1 (2016-03-07)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.3).
 * Network reachability: Check the network when app becomes active.
 * Chat room: Add expanded header.
 * Chat room: Display network status, and handle unsent messages.
 * Room members: Support invitation by email.
 * Add Room member details screen.
 * Media picker: Remove navigation bar (Cancel/Camera).
 * Media picker: Do not save captured media in user's library
 * Message search: Enable display of timeline from a search result.
 * AvatorGenerator: Made it use colors defined by VectorDesignValues.

Bug fixes:
 * SYIOS-202: IOS should no longer reset badge count on launch.
 * Blank screen after restarting the app #90.
 * Blank chat screen #55.
 * Room members: Swipe mode is not available on iphone 5c iOS 8 #70.
 * The active area of Edit button is too small #77.
 * Please can we have default ios long-tap to select and clipboard behaviour again? #87.
 * I see my avatar moving down from the header down to the text input field when entering a room #96.
 * Clicking into a favourite room and then back to recents can leave you scrolled to the 'wrong' point in the recents list #105.
 * Chat: message timestamp is misaligned #100.
 * RoomTitleView: Center horizontally the display name and the avatar.
 * Media Picker: fix layout issues.
 * Media Picker: Launch must be speed up.

Changes in Vector iOS in 0.1.0 (2016-01-29)
===============================================

 * Upgrade MatrixKit version (v0.3.1).
 * Implement Visual Design v1.3 (80% done).

Changes in Vector iOS in 0.0.1 (2015-11-16)
===============================================

 * Creation : The first implementation of Vector application based on Matrix iOS Kit v0.2.7.
