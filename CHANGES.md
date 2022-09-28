## Changes in 1.9.7 (2022-09-28)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.19](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.19)).

🐛 Bugfixes

- Missing decoration for events decrypted with untrusted Megolm sessions ([Security advisory](https://github.com/vector-im/element-ios/security/advisories/GHSA-fm8m-99j7-323g))
- Fix crash when scrolling chat list ([#6749](https://github.com/vector-im/element-ios/issues/6749))


## Changes in 1.9.6 (2022-09-20)

🙌 Improvements

- Sentry: Disable unnecessary network breadcrumbs ([#6726](https://github.com/vector-im/element-ios/pull/6726))

🐛 Bugfixes

- Fix crash when some opus audio files are added to a room. ([#6584](https://github.com/vector-im/element-ios/issues/6584))
- Fixed failed to join room (was not legal room) ([#6653](https://github.com/vector-im/element-ios/issues/6653))
- Fix crash presenting Sign Out or Invite to Element menu items on iPad. ([#6654](https://github.com/vector-im/element-ios/issues/6654))
- Fix crash on logout when syncing is currently in progress ([#6705](https://github.com/vector-im/element-ios/issues/6705))
- New layout: Fixed Low priority rooms titles obscured by bottom bar when side scrolling ([#6707](https://github.com/vector-im/element-ios/issues/6707))
- Message Composer: Stop the keyboard jumping after sending a message on certain devices. ([#6708](https://github.com/vector-im/element-ios/issues/6708))
- New App Layout: Make sure the green loading spinner is dismissed after clearing the cache. ([#6709](https://github.com/vector-im/element-ios/issues/6709))
- Fix a crash when previewing a room. ([#6712](https://github.com/vector-im/element-ios/issues/6712))
- Fix login crash on Xcode 14 builds ([#6722](https://github.com/vector-im/element-ios/issues/6722))
- Fix replied event content parsing for nested replies ([#6729](https://github.com/vector-im/element-ios/issues/6729))
- Room: Fix a composer crash after long unsent messages. ([#6734](https://github.com/vector-im/element-ios/issues/6734))
- New App Layout: fixed rooms list doesn't update after log out and log into another account ([#6739](https://github.com/vector-im/element-ios/issues/6739))


## Changes in 1.9.5 (2022-09-12)

🐛 Bugfixes

- Fix timeline items text height calculation ([#6702](https://github.com/vector-im/element-ios/pull/6702))

🚧 In development 🚧

- Device manager: Add other sessions section read only in user sessions overview screen. ([#6672](https://github.com/vector-im/element-ios/issues/6672))


## Changes in 1.9.4 (2022-09-09)

✨ Features

- Create DM room only on first message - Create the DM and navigate to the new room after sending an event ([#5864](https://github.com/vector-im/element-ios/issues/5864))

🐛 Bugfixes

- Fix composer expansion on Start DM as you enter the message in deferred mode. ([#6689](https://github.com/vector-im/element-ios/issues/6689))
- [Group DM] send a new message in an existing DM invite again one of left member. ([#6691](https://github.com/vector-im/element-ios/issues/6691))


## Changes in 1.9.3 (2022-09-07)

✨ Features

- CryptoV2: Self-verification flow ([#6589](https://github.com/vector-im/element-ios/issues/6589))

🙌 Improvements

- Analytics: Measure performance in Sentry ([#6647](https://github.com/vector-im/element-ios/pull/6647))
- Crypto: Slash command to discard outbound session ([#6668](https://github.com/vector-im/element-ios/pull/6668))
- Upgrade MatrixSDK version ([v0.23.18](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.18)).
- Removed labs flag and enabled New App Layout ([#6673](https://github.com/vector-im/element-ios/issues/6673))
- Update empty states as per latest design update ([#6674](https://github.com/vector-im/element-ios/issues/6674))
- Reset allChatsOnboardingHasBeenDisplayed on logout ([#6676](https://github.com/vector-im/element-ios/issues/6676))

🐛 Bugfixes

- Fixed incorrect iOS 16 timeline item text height calculations leading to empty gaps. ([#6441](https://github.com/vector-im/element-ios/issues/6441))
- Fix mention pills display on iOS 16 ([#6442](https://github.com/vector-im/element-ios/issues/6442))
- Fixed last message time ellipsis ([#6512](https://github.com/vector-im/element-ios/issues/6512))
- Glitchy room list header when scrolling ([#6513](https://github.com/vector-im/element-ios/issues/6513))
- Performance issues with new App Layout ([#6537](https://github.com/vector-im/element-ios/issues/6537))
- Fixed UI glitches in dark mode ([#6645](https://github.com/vector-im/element-ios/issues/6645))
- Fix mention pills display when coming back to a room with an unsent message ([#6670](https://github.com/vector-im/element-ios/issues/6670))
- Fixed last scrolling glitches in All Chats screen ([#6680](https://github.com/vector-im/element-ios/issues/6680))


## Changes in 1.9.2 (2022-08-31)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.17](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.17)).


## Changes in 1.9.1 (2022-08-29)

🙌 Improvements

- Added Labs flag for the new App Layout. ([#6649](https://github.com/vector-im/element-ios/issues/6649))

🐛 Bugfixes

- Render the PIN entry screen correctly on landscape ([#6629](https://github.com/vector-im/element-ios/pull/6629))
- Ensure rest client async responses are processed on the main queue ([#6642](https://github.com/vector-im/element-ios/pull/6642))
- Stop waiting for biometric unlock if disabled system wide ([#5279](https://github.com/vector-im/element-ios/issues/5279))
- App Layout: added support for transparent avatar icons in the all chats screen ([#6556](https://github.com/vector-im/element-ios/issues/6556))
- App Layout: fixed reactions background in timeline ([#6557](https://github.com/vector-im/element-ios/issues/6557))
- App Layout: Removed Low Priority Rooms from Filters ([#6577](https://github.com/vector-im/element-ios/issues/6577))
- App Layout: Updated missing image for Onboarding screen page 2 ([#6624](https://github.com/vector-im/element-ios/issues/6624))
- App Layout: fixed limited number of invites in the All Chats screen ([#6625](https://github.com/vector-im/element-ios/issues/6625))
- Fix notification issues for threads. ([#6628](https://github.com/vector-im/element-ios/issues/6628))


## Changes in 1.9.0 (2022-08-24)

🙌 Improvements

- KeyBackup: Adapt changes from sdk, add an entry into encryption info view of a message. ([#6555](https://github.com/vector-im/element-ios/pull/6555))
- Upgrade MatrixSDK version ([v0.23.16](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.16)).
- Display the option "Share invite link" only when the room is accessible by link. ([#6496](https://github.com/vector-im/element-ios/issues/6496))
- New App Layout: Added missing empty states in room list and space bottom sheet ([#6514](https://github.com/vector-im/element-ios/issues/6514))
- Groups: Support for groups has been removed now that Spaces are fully available. ([#6523](https://github.com/vector-im/element-ios/issues/6523))
- Change text when swiping on room from Delete to Leave. ([#6568](https://github.com/vector-im/element-ios/issues/6568))
- New App Layout: added suppport for room invites in the all chats screen ([#6600](https://github.com/vector-im/element-ios/issues/6600))
- App Layout: UI tweaks for Tabs ([#6605](https://github.com/vector-im/element-ios/issues/6605))
- New App Layout: Added onboarding screen ([#6607](https://github.com/vector-im/element-ios/issues/6607))
- App Layout: last UI tweaks before RC ([#6608](https://github.com/vector-im/element-ios/issues/6608))
- App Layout: Activated feature in BuildSettings ([#6616](https://github.com/vector-im/element-ios/issues/6616))
- App Layout: Added usage measures ([#6618](https://github.com/vector-im/element-ios/issues/6618))

🐛 Bugfixes

- RoomViewController: Wait for table view updates before checing read marker visibility. ([#5932](https://github.com/vector-im/element-ios/issues/5932))
- Add a login and signup fallback SSO option for homeservers that don't offer a list of identity providers. ([#6569](https://github.com/vector-im/element-ios/issues/6569))
- App Layout: fixed Cancel and Back on Spaces Bottom Sheet ([#6572](https://github.com/vector-im/element-ios/issues/6572))
- App Layout: updated context menus according to last design update ([#6574](https://github.com/vector-im/element-ios/issues/6574))
- App Layout: reintroduced existing Notification left markers on room cells ([#6578](https://github.com/vector-im/element-ios/issues/6578))
- App Layout: Leaving a Space now sends user to All Chats ([#6581](https://github.com/vector-im/element-ios/issues/6581))
- App Layout: added space invites in space bottom sheet ([#6599](https://github.com/vector-im/element-ios/issues/6599))

⚠️ API Changes

- Reverts #6275, bringing the local DesignKit package back. ([#6586](https://github.com/vector-im/element-ios/pull/6586))
- Communities: GroupsViewController etc have all been removed now that Spaces are available in the app. ([#6523](https://github.com/vector-im/element-ios/issues/6523))

🚧 In development 🚧

- Device manager: Add new session management screen. ([#6585](https://github.com/vector-im/element-ios/issues/6585))

Others

- Sentry: Upload Dsyms to Sentry when building Alpha ([#6413](https://github.com/vector-im/element-ios/pull/6413))
- Analytics: Log all errors to analytics ([#6611](https://github.com/vector-im/element-ios/pull/6611))


## Changes in 1.8.27 (2022-08-12)

Others

- Update camera, contacts and photos usage strings for App Store review. ([#6559](https://github.com/vector-im/element-ios/issues/6559))


## Changes in 1.8.26 (2022-08-10)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.15](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.15)).

🐛 Bugfixes

- Media: Fix a potential crash when dismissing an image. ([#6548](https://github.com/vector-im/element-ios/issues/6548))

Others

- Contacts Prompt: Clarify how contacts are used in the app. ([#6549](https://github.com/vector-im/element-ios/issues/6549))


## Changes in 1.8.25 (2022-08-09)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.14](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.14)).
- App Layout: Feature flag new App Layout ([#6406](https://github.com/vector-im/element-ios/issues/6406))
- App Layout: Update All chats screen with latest design ([#6407](https://github.com/vector-im/element-ios/issues/6407))
- App Layout: Change the App theme according to new design ([#6409](https://github.com/vector-im/element-ios/issues/6409))
- App Layout: Implemented the new Space selector bottom sheet ([#6410](https://github.com/vector-im/element-ios/issues/6410))
- Authentication: Update the ReCaptcha icon. ([#6427](https://github.com/vector-im/element-ios/issues/6427))
- Location sharing: Improve live location sharing expanded map state when no more live location shares. ([#6488](https://github.com/vector-im/element-ios/issues/6488))
- Location sharing: Render fallback UI when tile server unavailable. ([#6493](https://github.com/vector-im/element-ios/issues/6493))
- In-app notifications will now also be delivered to Notification Centre. ([#6503](https://github.com/vector-im/element-ios/issues/6503))
- Authentication: Don't show personalisation steps after registering with a generic SSO provider. ([#6530](https://github.com/vector-im/element-ios/issues/6530))

🐛 Bugfixes

- Room Directory: Show the "switch" button even if there are no public rooms in the homeserver's room directory. ([#4700](https://github.com/vector-im/element-ios/issues/4700))
- Share Extension: Fix a bug where sending multiple images sometimes resulted in additional duplicates being sent. ([#5922](https://github.com/vector-im/element-ios/issues/5922))
- Stop using an ephemeral web browser session for SSO authentication. ([#6462](https://github.com/vector-im/element-ios/issues/6462))
- Media Attachments Viewer: Fixed an issue where dismissing GIFs would show the WebView playing the animation below the interaction transition animation. ([#6475](https://github.com/vector-im/element-ios/issues/6475))
- Media: Fix a bug where the navigation bar shown when viewing an image wasn't taking the safe area into account. ([#6486](https://github.com/vector-im/element-ios/issues/6486))
- Home: Use the correct status bar colour when using the dark theme with dark mode disabled. ([#6487](https://github.com/vector-im/element-ios/issues/6487))
- Authentication: Always start a new authentication flow with the default homeserver (or the provisioning link if set). ([#6489](https://github.com/vector-im/element-ios/issues/6489))
- Universal Links: Fix an infinite loop when handling a universal link for an unjoined room (or in some cases a crash). ([#6492](https://github.com/vector-im/element-ios/issues/6492))
- App Layout: Conditionally hide favourite and people list tabs ([#6515](https://github.com/vector-im/element-ios/issues/6515))
- Apply current theme to all the UI components ([#6526](https://github.com/vector-im/element-ios/issues/6526))
- Some UI tweaks for New App Layout ([#6534](https://github.com/vector-im/element-ios/issues/6534))
- Widgets: Fix a crash when loading the widget manager. ([#6539](https://github.com/vector-im/element-ios/issues/6539))

⚠️ API Changes

- Update the app's bundle name to show Element during SSO. ([#6462](https://github.com/vector-im/element-ios/issues/6462))

📄 Documentation

- Add docs/Customisation.md. ([#6473](https://github.com/vector-im/element-ios/issues/6473))

🚧 In development 🚧

- App Layout: Edit layout experiment ([#6079](https://github.com/vector-im/element-ios/issues/6079))


## Changes in 1.8.24 (2022-07-26)

✨ Features

- Enable the new authentication and personalisation flows in the onboarding coordinator. ([#5151](https://github.com/vector-im/element-ios/issues/5151))
- Read tile server URL from .well-known (PSG-592) ([#6472](https://github.com/vector-im/element-ios/issues/6472))

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.13](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.13)).
- Replaces the usage of ffmpeg in the app again(Change was previously reverted). ([#6419](https://github.com/vector-im/element-ios/issues/6419))
- Location sharing: Handle live location sharing start event reply in the timeline. ([#6423](https://github.com/vector-im/element-ios/issues/6423))
- Location sharing: Show map credits on live location timeline tile only when map is shown. ([#6448](https://github.com/vector-im/element-ios/issues/6448))
- Location sharing: Handle live location sharing delete in the timeline. ([#6470](https://github.com/vector-im/element-ios/issues/6470))
- Location sharing: Display clearer error message when the user doesn't have permission to share location in the room. ([#6477](https://github.com/vector-im/element-ios/issues/6477))

🐛 Bugfixes

- Registration: Trim any whitespace away when verifying the user's email address. ([#2594](https://github.com/vector-im/element-ios/issues/2594))
- AuthenticationViewController is now correctly configured for a deep link if the link is opened before the view gets shown. ([#6425](https://github.com/vector-im/element-ios/issues/6425))

🧱 Build

- Fix UI tests failing on CI but not being reported by prefixing all tests with `test`. ([#6432](https://github.com/vector-im/element-ios/issues/6432))

🚧 In development 🚧

- Update strings for FTUE authentication flow following final review. ([#6427](https://github.com/vector-im/element-ios/issues/6427))
- Check for a phone number during login and send an MSISDN when using the new flow. ([#6428](https://github.com/vector-im/element-ios/issues/6428))
- Fix ReCaptcha form sometimes being slow to react to taps in the new flow. ([#6429](https://github.com/vector-im/element-ios/issues/6429))
- When entering a full MXID during registration on the new flow, update the homeserver to match. ([#6430](https://github.com/vector-im/element-ios/issues/6430))
- Always perform the dummy stage in the registration wizard, irregardless of whether it is mandatory or optional. ([#6459](https://github.com/vector-im/element-ios/issues/6459))

Others

- Crypto: Convert verification request and transaction to protocols ([#6444](https://github.com/vector-im/element-ios/pull/6444))


## Changes in 1.8.23 (2022-07-15)

🙌 Improvements

- Reword account deactivation button on the Settings screen. ([#6436](https://github.com/vector-im/element-ios/issues/6436))


## Changes in 1.8.22 (2022-07-13)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.12](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.12)).

🐛 Bugfixes

- Fix a bug where the login screen is shown after choosing to create an account. ([#6417](https://github.com/vector-im/element-ios/pull/6417))


## Changes in 1.8.21 (2022-07-12)

✨ Features

- Analytics: Track non-fatal issues if consent provided ([#6308](https://github.com/vector-im/element-ios/pull/6308))
- Notifications: Add a setting for in-app notifications and use the value with existing functionality in PushNotificationService. ([#1108](https://github.com/vector-im/element-ios/issues/1108))
- Server Offline Activity Indicator ([#5607](https://github.com/vector-im/element-ios/issues/5607))

🙌 Improvements

- Add formatter build reply HTML unit tests ([#6380](https://github.com/vector-im/element-ios/pull/6380))
- Upgrade MatrixSDK version ([v0.23.11](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.11)).
- Update Files component ([#5372](https://github.com/vector-im/element-ios/issues/5372))
- Location sharing: Update map credits display and behavior. ([#6108](https://github.com/vector-im/element-ios/issues/6108))
- Location sharing: Add view to promote live location sharing labs flag on the sharing screen. ([#6238](https://github.com/vector-im/element-ios/issues/6238))
- Remove legacy Riot-Defaults property list ([#6273](https://github.com/vector-im/element-ios/issues/6273))
- DesignKit: Replace the local DesignKit target with the shared Swift package from ElementX. ([#6276](https://github.com/vector-im/element-ios/issues/6276))
- Enhance the VectorHostingController to be presented as a bottom sheet ([#6376](https://github.com/vector-im/element-ios/issues/6376))
- Location sharing: Live location sharing UI polishing. ([#6382](https://github.com/vector-im/element-ios/issues/6382))

🐛 Bugfixes

- VectorHostingController: Fix infinite loop due to the safe area insets fix. ([#6381](https://github.com/vector-im/element-ios/pull/6381))
- Fix layout issues in timeline poll cells (PSB-125) ([#5326](https://github.com/vector-im/element-ios/issues/5326))
- Fixed Invite user UI is always hidden by the keyboard ([#5341](https://github.com/vector-im/element-ios/issues/5341))
- Cross-Signing: Use ZXing library to generate QR codes ([#6358](https://github.com/vector-im/element-ios/issues/6358))
- Location sharing: Fix live location sharing lab flag activation, no more app relaunch needed. ([#6361](https://github.com/vector-im/element-ios/issues/6361))
- Display fallback when replied event content is partially missing ([#6371](https://github.com/vector-im/element-ios/issues/6371))
- Fix a few failing UI tests. ([#6386](https://github.com/vector-im/element-ios/issues/6386))
- Rename riot-keys.txt to element-keys.txt. ([#6391](https://github.com/vector-im/element-ios/issues/6391))
- Fix inoperant room links with alias/identifiers ([#6395](https://github.com/vector-im/element-ios/issues/6395))
- Fix slash commands from room composer ([#6398](https://github.com/vector-im/element-ios/issues/6398))

⚠️ API Changes

- Replace DesignKit framework with [DesignKit package](https://github.com/vector-im/element-x-ios/tree/develop/DesignKit/Sources). Colours are now generated in the [DesignTokens repo](https://github.com/vector-im/element-design-tokens) to be shared across all of our apps. ([#6275](https://github.com/vector-im/element-ios/pull/6275))

🧱 Build

- Update Podfile.lock ([#6387](https://github.com/vector-im/element-ios/pull/6387))
- Split `IntentHandler` into smaller, dedicated entities ([#6203](https://github.com/vector-im/element-ios/issues/6203))

Others

- Revert some font changes made when merging #6392. ([#6392](https://github.com/vector-im/element-ios/issues/6392))


## Changes in 1.8.20 (2022-06-28)

✨ Features

- Added "Mark as read" option to the room context menu. ([#6278](https://github.com/vector-im/element-ios/issues/6278))

🙌 Improvements

- Use dedicated HTMLFormatter and improve post format operations performance ([#6261](https://github.com/vector-im/element-ios/pull/6261))
- Security fix: prevent playback on already read messages through push notifications, enable on device silencing. ([#6265](https://github.com/vector-im/element-ios/pull/6265))
- Expose live location sharing labs flag (default: false) and re-enable background location access ([#6324](https://github.com/vector-im/element-ios/pull/6324))
- Enable reporting of live location shares ([#6326](https://github.com/vector-im/element-ios/pull/6326))
- Upgrade MatrixSDK version ([v0.23.10](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.10)).
- Update Reactions component ([#5370](https://github.com/vector-im/element-ios/issues/5370))
- Handle longpress on back buttons ([#5971](https://github.com/vector-im/element-ios/issues/5971))
- De-labs use only latest user avatar and name ([#6312](https://github.com/vector-im/element-ios/issues/6312))

🐛 Bugfixes

- Fix settings screens items alignment ([#6311](https://github.com/vector-im/element-ios/pull/6311))
- Accessibility: VoiceOver: Added an accessibility label and hint to the Record Voice Message button. ([#6323](https://github.com/vector-im/element-ios/pull/6323))
- Make quoting context menu action work again ([#6328](https://github.com/vector-im/element-ios/pull/6328))
- Display mandatory backup only if session is running ([#6331](https://github.com/vector-im/element-ios/pull/6331))
- Authentication: Don't attempt to login if the user presses the return key whilst loading a homeserver parsed from a username. ([#6338](https://github.com/vector-im/element-ios/pull/6338))
- Media: Fix size issues when opening media on an iPad whilst multi-tasking. ([#6339](https://github.com/vector-im/element-ios/pull/6339))
- Timeline: Fixes the font when running Element on a Mac with Apple Silicon. ([#6340](https://github.com/vector-im/element-ios/pull/6340))
- Accessibility: VoiceOver: Voice Messages: Properly end the active audio session so that VoiceOver audio returns to the main speaker when audio recording finishes. ([#6343](https://github.com/vector-im/element-ios/pull/6343))
- Authentication: Trim whitespace and trailing slashes from the entered homeserver address. ([#995](https://github.com/vector-im/element-ios/issues/995))
- Share extension: Fix background colour in dark mode. ([#3029](https://github.com/vector-im/element-ios/issues/3029))
- Fix Invites are collapsed incorrectly ([#4102](https://github.com/vector-im/element-ios/issues/4102))
- Timeline: Reduce the tap target size for the sender's name so it no longer overlaps the first message. ([#4324](https://github.com/vector-im/element-ios/issues/4324))
- Directory: Add some bottom space to the directory list. ([#5113](https://github.com/vector-im/element-ios/issues/5113))
- Message Composer: Element no longer shows a banner about pasting from another app when selecting text. ([#5324](https://github.com/vector-im/element-ios/issues/5324))
- Make avatar view tappable in bubble layout ([#5572](https://github.com/vector-im/element-ios/issues/5572))
- Room: Update actions on the input toolbar when refreshed. ([#5584](https://github.com/vector-im/element-ios/issues/5584))
- Room: Hide add people button on room intro header if user not allowed. ([#5731](https://github.com/vector-im/element-ios/issues/5731))
- Soft logout: Fix a bug where clearing all data from soft logout didn't present the login screen. ([#5881](https://github.com/vector-im/element-ios/issues/5881))
- Timeline: When an attachment is named like an email address, open the file instead of Mail.app when tapped. ([#6031](https://github.com/vector-im/element-ios/issues/6031))
- Room: Add some additional spacing between the Jitsi and Threads buttons. ([#6033](https://github.com/vector-im/element-ios/issues/6033))
- Room: Present loading indicator immediately on pagination and change wording. ([#6271](https://github.com/vector-im/element-ios/issues/6271))
- Fix threads out of labs notice HTML formatting ([#6283](https://github.com/vector-im/element-ios/issues/6283))
- AppDelegate: Do not show launch animation for `backgroundSyncInProgress` state. ([#6288](https://github.com/vector-im/element-ios/issues/6288))
- Use latest user data for mention pills ([#6302](https://github.com/vector-im/element-ios/issues/6302))
- Authentication: Fix splash screen stuttering on some devices. ([#6319](https://github.com/vector-im/element-ios/issues/6319))

🧱 Build

- locheck-script: fix build fails when there is space character on PROJECT_DIR's path. By Hudzaifah Lutfi. ([#6296](https://github.com/vector-im/element-ios/issues/6296))
- Add Codecov and sonarcloud. ([#6306](https://github.com/vector-im/element-ios/issues/6306))

🚧 In development 🚧

- Authentication: Add custom string representations of view model/coordinator results. ([#5151](https://github.com/vector-im/element-ios/issues/5151))

Others

- Fix workflow syntax of the P1 action. ([#6321](https://github.com/vector-im/element-ios/pull/6321))
- Clean up iOS 14 availability checks ([#6333](https://github.com/vector-im/element-ios/pull/6333))


## Changes in 1.8.19 (2022-06-14)

✨ Features

- AuthenticationLoginCoordinator: Implement forgot password flow. ([#5655](https://github.com/vector-im/element-ios/issues/5655))
- FTUE: Implement soft logout screen. ([#6181](https://github.com/vector-im/element-ios/issues/6181))

🙌 Improvements

- Partial implementation of rich replies ([#6155](https://github.com/vector-im/element-ios/pull/6155))
- Upgrade MatrixSDK version ([v0.23.9](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.9)).
- Display redacted messages in the timeline ([#2180](https://github.com/vector-im/element-ios/issues/2180))
- Room: Do not group events containing thread roots. ([#5502](https://github.com/vector-im/element-ios/issues/5502))
- Settings: Implement logging out all devices when changing password. ([#6175](https://github.com/vector-im/element-ios/issues/6175))
- AuthenticationService: Use identity server from well-known if provided when creating the client. ([#6177](https://github.com/vector-im/element-ios/issues/6177))
- FTUE: Support server provisioning links in the authentication flow. ([#6180](https://github.com/vector-im/element-ios/issues/6180))
- De-labs message bubbles ([#6285](https://github.com/vector-im/element-ios/pull/6285))

🐛 Bugfixes

- Security fix: Prevent the session verification alert and flows from being displayed on top of the Pin entry screen, allowing another session to be verified from a locked app. ([#6249](https://github.com/vector-im/element-ios/pull/6249))
- Remove render edit flag and fix a nil room state crash ([#6251](https://github.com/vector-im/element-ios/pull/6251))
- Fix in reply to links appearing outside of mx-quote ([#4586](https://github.com/vector-im/element-ios/issues/4586))
- Settings: Allow account deactivation when the account was created using SSO. ([#4685](https://github.com/vector-im/element-ios/issues/4685))
- Fix reply to usernames containing HTML escape characters ([#5526](https://github.com/vector-im/element-ios/issues/5526))
- Room preview unexpectedly triggering within the room ([#5939](https://github.com/vector-im/element-ios/issues/5939))
- Room: Add cancel action to contextual menu in every case. ([#5989](https://github.com/vector-im/element-ios/issues/5989))
- Fixed home screen room avatars being sometimes square. ([#6095](https://github.com/vector-im/element-ios/issues/6095))
- Room Creation: Fix crash when scrolling to bottom of the page. ([#6231](https://github.com/vector-im/element-ios/issues/6231))
- Prevent random crashes when tapping links. Avoid displaying the confirmation alert for plain text ones. ([#6241](https://github.com/vector-im/element-ios/issues/6241))
- Room: Avoid merging of bubbles if current timeline style does not allow. ([#6242](https://github.com/vector-im/element-ios/issues/6242))
- Universal Link: Url decode url fragment before splitting up. ([#6207](https://github.com/vector-im/element-ios/issues/6207))
- Room: Do not show redacted reactions in the timeline. ([#6293](https://github.com/vector-im/element-ios/issues/6293))

🚧 In development 🚧

- Authentication: Add reveal password button and use a rounded checkbox ([#6268](https://github.com/vector-im/element-ios/pull/6268))
- Authentication: Update labels and confetti in new flow. Tidy up onboarding presentation. ([#5151](https://github.com/vector-im/element-ios/issues/5151))
- Add an unrecognised certificate alert to the new authentication flow. ([#6174](https://github.com/vector-im/element-ios/issues/6174))
- Authentication: Add tests covering the authentication service and wizards. ([#6179](https://github.com/vector-im/element-ios/issues/6179))
- Location sharing: Support sending location in background. ([#6236](https://github.com/vector-im/element-ios/issues/6236))


## Changes in 1.8.18 (2022-06-03)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.8](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.8)).
- Show user indicators when paginating a room ([#5746](https://github.com/vector-im/element-ios/issues/5746))
- Authentication: Display fallback screens on registration & login according to the HS needs. ([#6176](https://github.com/vector-im/element-ios/issues/6176))
- WellKnown: support outbound keys presharing strategy ([#6214](https://github.com/vector-im/element-ios/issues/6214))

🐛 Bugfixes

- Location sharing: Improve automatic detection of pin drop state ([#6202](https://github.com/vector-im/element-ios/issues/6202))

🧱 Build

- Ensure that warnings from CocoaPods dependencies do not show up in Xcode ([#6196](https://github.com/vector-im/element-ios/pull/6196))
- CI: Use macOS 12 and Xcode 13.4 ([#6204](https://github.com/vector-im/element-ios/pull/6204))

🚧 In development 🚧

- Authentication: Add the login screen to the new flow and support SSO on both login and registration flows. ([#5654](https://github.com/vector-im/element-ios/issues/5654))


## Changes in 1.8.17 (2022-05-31)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.7](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.7)).
- Location sharing: Add a spinner view for starting state in timeline cell ([#6101](https://github.com/vector-im/element-ios/issues/6101))
- Location sharing: Add labs flag for live location sharing ([#6195](https://github.com/vector-im/element-ios/issues/6195))

🐛 Bugfixes

- Added attempt at fixing random crashes while calculating timeline cell heights. ([#6188](https://github.com/vector-im/element-ios/pull/6188))
- Fix ITMS Warning on CFBundleDocumentTypes ([#6159](https://github.com/vector-im/element-ios/issues/6159))
- RoomViewController: Fix confirmation for RTL overridden links. ([#6208](https://github.com/vector-im/element-ios/issues/6208))
- Fix issue with mention pill avatar consuming tap gestures ([#6212](https://github.com/vector-im/element-ios/issues/6212))

🚧 In development 🚧

- Authentication: Add Email/Terms/ReCaptcha screens into the flow. ([#5151](https://github.com/vector-im/element-ios/issues/5151))
- Authentication: Implement msisdn verification screen. ([#6182](https://github.com/vector-im/element-ios/issues/6182))
- Location sharing: Support sending live device location. ([#5722](https://github.com/vector-im/element-ios/issues/5722))
- Authentication: Implement the LoginWizard to match Element Android. ([#5896](https://github.com/vector-im/element-ios/issues/5896))
- Location sharing: Support restarting location sending after app kill. ([#6199](https://github.com/vector-im/element-ios/issues/6199))


## Changes in 1.8.16 (2022-05-19)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.6](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.6)).

🐛 Bugfixes

- Fixed home screen shrinking too much on opening the keyboard. ([#6184](https://github.com/vector-im/element-ios/pull/6184))
- Fixed filtering search bar not resetting properly when cancelling or switching tabs. ([#6130](https://github.com/vector-im/element-ios/issues/6130))


## Changes in 1.8.15 (2022-05-18)

✨ Features

- Allow video rooms to be shown in the rooms list. ([#6149](https://github.com/vector-im/element-ios/issues/6149))

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.5](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.5)).
- Add mention pills to timeline & composer ([#3526](https://github.com/vector-im/element-ios/issues/3526))
- [Room settings] Hide or disable search in the encrypted rooms ([#5725](https://github.com/vector-im/element-ios/issues/5725))
- ThreadRoomTitleView: Reduce spaces between title and room avatar & room name. ([#5878](https://github.com/vector-im/element-ios/issues/5878))
- Analytics: Log decryption error details as context in AnalyticsEvent ([#6046](https://github.com/vector-im/element-ios/issues/6046))
- Authentication: New user accounts are now tracked in analytics if the user opted in. ([#6074](https://github.com/vector-im/element-ios/issues/6074))
- Location sharing: update UI to latest design ([#6162](https://github.com/vector-im/element-ios/issues/6162))

🐛 Bugfixes

- Fixed crash when opening rooms where the current user doesn't have permission to post messages. ([#6165](https://github.com/vector-im/element-ios/pull/6165))
- Media gallery: Don't show a thumbnail for the hidden album. ([#6096](https://github.com/vector-im/element-ios/issues/6096))
- Location sharing: fix bad interaction between static and live location cell ([#6099](https://github.com/vector-im/element-ios/issues/6099))
- Location sharing: handle correctly timeline refresh after reception of beacon from live location sharing ([#6103](https://github.com/vector-im/element-ios/issues/6103))
- Location sharing: fix stop button in timeline ([#6110](https://github.com/vector-im/element-ios/issues/6110))
- Location sharing: handle correctly visibility of the live banner in room ([#6111](https://github.com/vector-im/element-ios/issues/6111))
- Presence: fix live updates on Home & DM list ([#6144](https://github.com/vector-im/element-ios/issues/6144))
- Stop deleting audio recording when sending fails. ([#6160](https://github.com/vector-im/element-ios/issues/6160))

🚧 In development 🚧

- Onboarding: Tidy up SwiftUI and Onboarding screens. ([#6139](https://github.com/vector-im/element-ios/pull/6139))
- Onboarding: Rename completion to callback and simplify actor usage ([#6141](https://github.com/vector-im/element-ios/pull/6141))
- Authentication: Create email verification screen. ([#5649](https://github.com/vector-im/element-ios/issues/5649))
- Authentication: Create terms and ReCaptcha screens. ([#5650](https://github.com/vector-im/element-ios/issues/5650))


## Changes in 1.8.14 (2022-05-05)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.4](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.4)).
- Spaces: Bring leaving space experience in line with Web ([#4850](https://github.com/vector-im/element-ios/issues/4850))
- Location sharing: Add cell for live location sharing in timeline ([#6029](https://github.com/vector-im/element-ios/issues/6029))
- Location sharing: Add timer selector when start live location sharing ([#6071](https://github.com/vector-im/element-ios/issues/6071))
- Location sharing: Connect SDK to location sharing timeline cell ([#6077](https://github.com/vector-im/element-ios/issues/6077))

🐛 Bugfixes

- RoomNavigationParameters: Fix initializer by not defining convenience. ([#5883](https://github.com/vector-im/element-ios/issues/5883))
- Fail to open a sub space ([#5965](https://github.com/vector-im/element-ios/issues/5965))
- RecentsViewController: Fix disappearing filter on search cancellation & empty view on the first screen appearing. ([#6076](https://github.com/vector-im/element-ios/issues/6076))
- RoomsViewController: Avoid crash by fixing section index to scroll. ([#6086](https://github.com/vector-im/element-ios/issues/6086))
- Search: Prevent crash when searching ([#6115](https://github.com/vector-im/element-ios/issues/6115))

🗣 Translations

- Localisations: Remove strings with bad formatting and add a run script to detect errors at compile time. ([#5990](https://github.com/vector-im/element-ios/issues/5990))

🧱 Build

- UI Tests: Fix broken tests and add a check on PRs. ([#6050](https://github.com/vector-im/element-ios/issues/6050))

🚧 In development 🚧

- Authentication: Begin implementing authentication flow with a Service, Registration screen and Server Selection screen. ([#5648](https://github.com/vector-im/element-ios/issues/5648))
- Location sharing: Add live location viewer screen. ([#5723](https://github.com/vector-im/element-ios/issues/5723))
- Location sharing: Support live location event in the timeline. ([#6057](https://github.com/vector-im/element-ios/issues/6057))
- Location sharing: Integrate live location viewer screen with room screen. ([#6081](https://github.com/vector-im/element-ios/issues/6081))


## Changes in 1.8.13 (2022-04-20)

✨ Features

- Onboarding: Enable profile personalisation screens after registration. ([#5652](https://github.com/vector-im/element-ios/issues/5652))

🙌 Improvements

- SwiftUI Templates: The coordinators now include a basic implementation of the new UserIndicators. ([#6014](https://github.com/vector-im/element-ios/pull/6014))
- Upgrade MatrixSDK version ([v0.23.3](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.3)).
- Open the room when user accepts an invite from the room list ([#4986](https://github.com/vector-im/element-ios/issues/4986))
- Display presence indicator on home, DM list & details ([#5933](https://github.com/vector-im/element-ios/issues/5933))
- Location sharing: Create a screen specific for viewing static shared location ([#5982](https://github.com/vector-im/element-ios/issues/5982))
- Presence: add an optional setting for offline mode ([#5995](https://github.com/vector-im/element-ios/issues/5995))
- Context menu: Room preview do not update the read receipt any more ([#6008](https://github.com/vector-im/element-ios/issues/6008))
- Pods: Stop excluding ARM64 simulator builds following an update to JitsiMeetSDK. ([#6018](https://github.com/vector-im/element-ios/issues/6018))
- Settings: Add threads discourage view when server doesn't support threads. ([#6038](https://github.com/vector-im/element-ios/issues/6038))

🐛 Bugfixes

- Home: Reduce the number of unnecessary home page reloads ([#5619](https://github.com/vector-im/element-ios/issues/5619))
- Add button in create room dialog can be pressed multiple times ([#5901](https://github.com/vector-im/element-ios/issues/5901))
- Rooms: Register unique cells for home screen sections ([#5958](https://github.com/vector-im/element-ios/issues/5958))
- Wrong copy for upgrade room message ([#5997](https://github.com/vector-im/element-ios/issues/5997))
- Reset home filters when switching tabs. ([#6004](https://github.com/vector-im/element-ios/issues/6004))
- Fix contact details view layout to safe area ([#6012](https://github.com/vector-im/element-ios/issues/6012))
- Element: Fix some crashes after 1.8.10. ([#6023](https://github.com/vector-im/element-ios/issues/6023))

🗣 Translations

- Fix notifications showing NOTIFICATION instead of Notification when a translation isn't available. ([#6011](https://github.com/vector-im/element-ios/pull/6011))

🚧 In development 🚧

- Location sharing: Support live location sharing start. ([#5929](https://github.com/vector-im/element-ios/issues/5929))

Others

- Analytics: Update debug configuration. ([#6020](https://github.com/vector-im/element-ios/pull/6020))
- Warn users about incoming iOS 12 and 13 support drop. ([#6024](https://github.com/vector-im/element-ios/pull/6024))
- Fix some warnings. ([#6032](https://github.com/vector-im/element-ios/pull/6032))


## Changes in 1.8.12 (2022-04-06)

🐛 Bugfixes

- RecentsViewController: Room context preview dismissed unexpectedly ([#5992](https://github.com/vector-im/element-ios/issues/5992))
- Notifications: Strings now fall back to English if they're missing for the current language. ([#5996](https://github.com/vector-im/element-ios/issues/5996))


## Changes in 1.8.11 (2022-04-05)

✨ Features

- RoomViewController: Display threads notice if not displayed before. ([#5770](https://github.com/vector-im/element-ios/issues/5770))
- Addded support for Apple context menus in matrix items list screens ([#5953](https://github.com/vector-im/element-ios/issues/5953))

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.2](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.2)).
- Threads: Strip `ìn reply to` from thread summaries and latest messages. ([#5488](https://github.com/vector-im/element-ios/issues/5488))
- Room: New loading indicators when joining room ([#5604](https://github.com/vector-im/element-ios/issues/5604))
- Room: New loading indicators when creating a room ([#5606](https://github.com/vector-im/element-ios/issues/5606))
- Location Sharing: Update UI on location sharing view ([#5720](https://github.com/vector-im/element-ios/issues/5720))
- Update suggested room preview to behave the same way in all cases ([#5771](https://github.com/vector-im/element-ios/issues/5771))
- RoomViewController: Enable thread menu option and display opt-in screen if threads disabled. ([#5772](https://github.com/vector-im/element-ios/issues/5772))
- Add "Invite people" to the space menu in the left panel and update menu order ([#5810](https://github.com/vector-im/element-ios/issues/5810))
- Allow empty Jitsi default URL in BuildSettings ([#5837](https://github.com/vector-im/element-ios/issues/5837))
- Location sharing: Add the ability for the user to share static location of a pin anywhere on the map ([#5858](https://github.com/vector-im/element-ios/issues/5858))
- Restrict UI components on authentication screen to readable width ([#5898](https://github.com/vector-im/element-ios/issues/5898))

🐛 Bugfixes

- Fixed the regular expression used for link detection in attributed strings. ([#5926](https://github.com/vector-im/element-ios/pull/5926))
- Jitsi: fix app not leaving call when widget is removed ([#1575](https://github.com/vector-im/element-ios/issues/1575))
- Space preview shows wrong number of members ([#4842](https://github.com/vector-im/element-ios/issues/4842))
- Room: Enable joining a room via identifier from another home server ([#4858](https://github.com/vector-im/element-ios/issues/4858))
- MXKRoomDataSource: Fix retain cycle ([#5058](https://github.com/vector-im/element-ios/issues/5058))
- Sync Spaces order with web ([#5134](https://github.com/vector-im/element-ios/issues/5134))
- Fix “It is not possible to join an empty room” on some suggested rooms. ([#5170](https://github.com/vector-im/element-ios/issues/5170))
- Fixed "Add Space" error message ([#5797](https://github.com/vector-im/element-ios/issues/5797))
- RoomDataSource: Reload thread data source without notifying the screen for the first reply. ([#5838](https://github.com/vector-im/element-ios/issues/5838))
- VoiceMessagePlainCell: Fix cell height by adding missing thread summary displayable conformance. ([#5870](https://github.com/vector-im/element-ios/issues/5870))
- Authentication: Ensure the login button is always visible ([#5875](https://github.com/vector-im/element-ios/issues/5875))
- Threads: Tweaks for design review. ([#5878](https://github.com/vector-im/element-ios/issues/5878))
- Search: prevent crash when searching for rooms ([#5883](https://github.com/vector-im/element-ios/issues/5883))
- Room: Fix typing performance by avoiding expensive UI operations ([#5906](https://github.com/vector-im/element-ios/issues/5906))
- The "Swipe to see all rooms" hint is sometimes presented at the wrong time ([#5911](https://github.com/vector-im/element-ios/issues/5911))
- Push notifications: show space preview if user taps invite notification ([#5915](https://github.com/vector-im/element-ios/issues/5915))
- Fix session handling of the call presenter. ([#5938](https://github.com/vector-im/element-ios/issues/5938))
- m.room.join_rules not properly set for private access ([#5943](https://github.com/vector-im/element-ios/issues/5943))
- Fix for app occasionally getting stuck during launch after Login/Register. ([#5948](https://github.com/vector-im/element-ios/issues/5948))

⚠️ API Changes

- Remove unused Bindings in RoundedBorderTextField/Editor ([#5910](https://github.com/vector-im/element-ios/pull/5910))

🗣 Translations

- Translations: Enable all languages rather than waiting for an 80% translation. RTL languages are still disabled due to layout and formatting bugs. ([#5935](https://github.com/vector-im/element-ios/issues/5935))

🚧 In development 🚧

- Onboarding: Add celebration screen after display name and avatar screens. ([#5651](https://github.com/vector-im/element-ios/issues/5651))


## Changes in 1.8.10 (2022-03-31)

🐛 Bugfixes

- Message Composer: Fix a crash when sending a photo using the camera. ([#5951](https://github.com/vector-im/element-ios/issues/5951))


## Changes in 1.8.9 (2022-03-28)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.1](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.1)).
- Update suggested room preview to behave the same way in all cases ([#5771](https://github.com/vector-im/element-ios/issues/5771))
- Add "Invite people" to the space menu in the left panel and update menu order ([#5810](https://github.com/vector-im/element-ios/issues/5810))

🐛 Bugfixes

- Sync Spaces order with web ([#5134](https://github.com/vector-im/element-ios/issues/5134))
- Fixed "Add Space" error message ([#5797](https://github.com/vector-im/element-ios/issues/5797))
- Authentication: Ensure the login button is always visible ([#5875](https://github.com/vector-im/element-ios/issues/5875))
- Room: Fix typing performance by avoiding expensive UI operations ([#5906](https://github.com/vector-im/element-ios/issues/5906))
- Push notifications: show space preview if user taps invite notification ([#5915](https://github.com/vector-im/element-ios/issues/5915))


## Changes in 1.8.8 (2022-03-22)

✨ Features

- Invite to Space in room landing ([#5225](https://github.com/vector-im/element-ios/issues/5225))
- Implement FAB journeys & rough edge warnings ([#5226](https://github.com/vector-im/element-ios/issues/5226))
- Space panel overflow journeys & rough edge warnings ([#5227](https://github.com/vector-im/element-ios/issues/5227))
- Let people know when rooms have moved. ([#5228](https://github.com/vector-im/element-ios/issues/5228))
- Room Settings bottom sheet ([#5229](https://github.com/vector-im/element-ios/issues/5229))
- Adding Rooms to Spaces ([#5230](https://github.com/vector-im/element-ios/issues/5230))
- Spaces: Update room settings for Spaces ([#5231](https://github.com/vector-im/element-ios/issues/5231))
- Spaces: Long press on rooms in space room lists ([#5232](https://github.com/vector-im/element-ios/issues/5232))
- Space Settings ([#5233](https://github.com/vector-im/element-ios/issues/5233))

🙌 Improvements

- Upgrade MatrixSDK version ([v0.23.0](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.23.0)).
- Space creation: Added entire space creation flow. ([#5224](https://github.com/vector-im/element-ios/issues/5224))
- Instrument metrics for the IA project. ([#5401](https://github.com/vector-im/element-ios/issues/5401))
- RoomDataSource: Reload thread screen for the first message. ([#5441](https://github.com/vector-im/element-ios/issues/5441))
- Change behaviour of avatar/self in left menu to match common paradigm and take user to their own profile/settings ([#5500](https://github.com/vector-im/element-ios/issues/5500))
- Secure Backup: Add support for mandatory backup/verification ([#5745](https://github.com/vector-im/element-ios/issues/5745))
- Thread Notifications: Open thread & reply to thread from notifications. ([#5749](https://github.com/vector-im/element-ios/issues/5749))
- IA Metrics: added trigger to JoinedRoom event and implemented ViewRoom event ([#5769](https://github.com/vector-im/element-ios/issues/5769))
- Activity Indicators: Replace user indicator presenting view controller with context ([#5780](https://github.com/vector-im/element-ios/issues/5780))
- MXKEventFormatter: Extend reply fallback for also non-thread events. ([#5816](https://github.com/vector-im/element-ios/issues/5816))
- Location sharing: Support multiple user annotation views on the map. ([#5827](https://github.com/vector-im/element-ios/issues/5827))
- MXKRoomDataSource: Pass threadId of room data source for replies. ([#5829](https://github.com/vector-im/element-ios/issues/5829))
- MXKEventFormatter: Fix edit fallback usage for edited events. ([#5841](https://github.com/vector-im/element-ios/issues/5841))
- RoomViewController: Remove thread list bar button item badge count. ([#5853](https://github.com/vector-im/element-ios/issues/5853))

🐛 Bugfixes

- Fix user suggestions not showing up when re-entering a room. ([#5876](https://github.com/vector-im/element-ios/pull/5876))
- Prevent the homescreen from resetting on every appearance. ([#5885](https://github.com/vector-im/element-ios/pull/5885))
- UserSuggestionViewModel: Fix retain cycle ([#5058](https://github.com/vector-im/element-ios/issues/5058))
- Green launch spinner is sometimes dismissed too early causing the incorrect onboarding screen to be displayed. ([#5472](https://github.com/vector-im/element-ios/issues/5472))
- Home: Fix crash when pressing tabs ([#5547](https://github.com/vector-im/element-ios/issues/5547))
- Selection impossible when filtering in add room screen. ([#5757](https://github.com/vector-im/element-ios/issues/5757))
- Room: Refresh header when call actions become available (member count changes) ([#5800](https://github.com/vector-im/element-ios/issues/5800))
- Share Extension: Stop logging crashes due to intentional exception that frees up memory and handle changes to MXRoom in the SDK. ([#5805](https://github.com/vector-im/element-ios/issues/5805))
- Crash after leaving last space. ([#5825](https://github.com/vector-im/element-ios/issues/5825))
- Authentication: Fix a crash that occurred when using the app with an account that had a soft logout. ([#5846](https://github.com/vector-im/element-ios/issues/5846))
- MXAccount: Do not clear cache if there are no stored filters ([#5873](https://github.com/vector-im/element-ios/issues/5873))

⚠️ API Changes

- Rename scrollEdgesAppearance → scrollEdgeAppearance to match UIKit. ([#5826](https://github.com/vector-im/element-ios/pull/5826))

🚧 In development 🚧

- Onboarding: Add screens for setting a display name and avatar when signing up for the first time. ([#5652](https://github.com/vector-im/element-ios/issues/5652))
- Location sharing: Handle live location banner view in room screen. ([#5857](https://github.com/vector-im/element-ios/issues/5857))


## Changes in 1.8.7 (2022-03-18)

🙌 Improvements

- Room: Allow ignoring invited users that have not joined a room yet ([#5866](https://github.com/vector-im/element-ios/issues/5866))


## Changes in 1.8.6 (2022-03-14)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.22.6](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.22.6)).
- Room: Ignore the sender of a room invite without needing to join the room first ([#5807](https://github.com/vector-im/element-ios/issues/5807))

🐛 Bugfixes

- Activity Indicators: Do not show user indicators when the view controller is not visible ([#5801](https://github.com/vector-im/element-ios/issues/5801))
- Authentication: Fix social login buttons visibility during registration flow and other minor navigation tweaks. ([#5879](https://github.com/vector-im/element-ios/issues/5879))


## Changes in 1.8.5 (2022-03-09)

🐛 Bugfixes

- Room: Only render missing messages for m.room.message types ([#5783](https://github.com/vector-im/element-ios/issues/5783))


## Changes in 1.8.4 (2022-03-08)

🙌 Improvements

- Add a generic SwiftUI Error type with support for showing NSErrors. ([#5742](https://github.com/vector-im/element-ios/pull/5742))
- Upgrade MatrixSDK version ([v0.22.5](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.22.5)).
- Move chat/room invites to dedicated sections and enable collapsing sections ([#5222](https://github.com/vector-im/element-ios/issues/5222))
- Invites: remove exclamation mark badge ([#5249](https://github.com/vector-im/element-ios/issues/5249))
- Localisation: Merge MatrixKit.strings into Vector.strings and de-dupe. ([#5325](https://github.com/vector-im/element-ios/issues/5325))
- Analytics: Adapt to latest analytics repo & add screens, events & interactions for threads. ([#5365](https://github.com/vector-im/element-ios/issues/5365))
- Activity Indicators: Add updated indicators to room loading ([#5603](https://github.com/vector-im/element-ios/issues/5603))
- Activity Indicators: Update loading and success messages when leaving room ([#5605](https://github.com/vector-im/element-ios/issues/5605))
- Enable activity indicators on the home screen ([#5663](https://github.com/vector-im/element-ios/issues/5663))
- Activity Indicators: Enable updated UI for activity indicators and success messages ([#5696](https://github.com/vector-im/element-ios/issues/5696))
- Labs/Room: Add a setting to use only latest sender profiles ([#5726](https://github.com/vector-im/element-ios/issues/5726))
- Timeline: track and show error message when an event cannot be converted to attributed string ([#5739](https://github.com/vector-im/element-ios/issues/5739))
- Activity Indicators: Use new activity indicators on all tabs ([#5750](https://github.com/vector-im/element-ios/issues/5750))
- Analytics: Instrument missing screen metrics. ([#5763](https://github.com/vector-im/element-ios/issues/5763))

🐛 Bugfixes

- Removed unnecessary and cropped room info avatar shadow. ([#5714](https://github.com/vector-im/element-ios/pull/5714))
- Started applying navigation bar theme styles to iOS 13 and 14 too. ([#5715](https://github.com/vector-im/element-ios/pull/5715))
- Input Tool Bar: Show it when you jump to an old message (last unread message, direct link or from unified search) ([#3779](https://github.com/vector-im/element-ios/issues/3779))
- MXKEventFormatter: Fix text color and font for regular reply events. ([#5552](https://github.com/vector-im/element-ios/issues/5552))
- Timeline: Show start of conversation header for every user and only at the actual start of the timeline ([#5581](https://github.com/vector-im/element-ios/issues/5581))
- Fixed partially hidden room invitation header. ([#5691](https://github.com/vector-im/element-ios/issues/5691))
- MXKEventFormatter: Fix font size for emoji-only replies. ([#5712](https://github.com/vector-im/element-ios/issues/5712))
- Room lists: Show the getting started hints again when there are no rooms in a tab. ([#5727](https://github.com/vector-im/element-ios/issues/5727))
- Activity Indicator: Use split controller's top navigation controller to present toasts ([#5752](https://github.com/vector-im/element-ios/issues/5752))

🗣 Translations

- Add new languages: Ukrainian ([#5759](https://github.com/vector-im/element-ios/pull/5759))

🚧 In development 🚧

- Onboarding: Add Congratulations screen. ([#5651](https://github.com/vector-im/element-ios/issues/5651))

Others

- Disable the default analytics configurations for forks. ([#5687](https://github.com/vector-im/element-ios/issues/5687))


## Changes in 1.8.3 (2022-02-25)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.22.4](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.22.4)).

🐛 Bugfixes

- Unified Search: Fix a bug where the room directory wasn't working. ([#5672](https://github.com/vector-im/element-ios/issues/5672))
- Fixed crashes on implicitly unwrapped optionals in the PlainRoomTimelineCellDecorator. ([#5673](https://github.com/vector-im/element-ios/issues/5673))
- L10n: Fix defaulting to English language ([#5674](https://github.com/vector-im/element-ios/issues/5674))
- RoomDataSource: Do not reload room data source on back pagination for new threads. ([#5694](https://github.com/vector-im/element-ios/issues/5694))


## Changes in 1.8.2 (2022-02-22)

✨ Features

- Add Onboarding Use Case selection screen after the splash screen. ([#5160](https://github.com/vector-im/element-ios/issues/5160))

🙌 Improvements

- Upgrade MatrixSDK version ([v0.22.2](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.22.2)).
- ActivityCenter: Use ActivityCenter to show loading indicators on the home screen (in DEBUG builds only) ([#4829](https://github.com/vector-im/element-ios/issues/4829))
- Enabled poll editing and undisclosed polls. Added support for unstable poll prefixes. ([#5114](https://github.com/vector-im/element-ios/issues/5114))
- Filter: update placeholder text and icon ([#5250](https://github.com/vector-im/element-ios/issues/5250))
- Create Room: Update avatar placeholder & add remove button ([#5251](https://github.com/vector-im/element-ios/issues/5251))
- Search: remove bubbles background ([#5471](https://github.com/vector-im/element-ios/issues/5471))
- Exclude all files and directories from iCloud and iTunes backup ([#5498](https://github.com/vector-im/element-ios/issues/5498))
- ThreadListViewModel: Use new apis to fetch threads. ([#5540](https://github.com/vector-im/element-ios/issues/5540))
- Search: Use bundled aggregations if provided. ([#5562](https://github.com/vector-im/element-ios/issues/5562))
- MXKRoomDataSource: Stop pagination in a thread when the root event received. ([#5582](https://github.com/vector-im/element-ios/issues/5582))
- Add support for UserProperties to analytics and capture FTUE use case selection. ([#5590](https://github.com/vector-im/element-ios/issues/5590))
- Add attribution to location sharing maps. ([#5609](https://github.com/vector-im/element-ios/issues/5609))
- Onboarding: Use a different green spinner during onboarding and use the one presented by the LegacyAppDelegate only when logged in. ([#5621](https://github.com/vector-im/element-ios/issues/5621))
- MXKRoomDataSource: Enable usage of thread timelines. ([#5629](https://github.com/vector-im/element-ios/issues/5629))

🐛 Bugfixes

- Home Tab: Initial support for navigating through the room lists using voiceover. ([#1433](https://github.com/vector-im/element-ios/issues/1433))
- Authent: fix phone number validation through custom URL ([#3562](https://github.com/vector-im/element-ios/issues/3562))
- Fix registration to be compliant with the Matrix specification. This allows registering for accounts on Conduit servers. Contributed by @aaronraimist. ([#3736](https://github.com/vector-im/element-ios/issues/3736))
- Fix proximity sensor staying on and sleep timer staying disabled after call ends ([#4103](https://github.com/vector-im/element-ios/issues/4103))
- Fonts: Fix dynamic type only working after a fresh launch on SwiftUI views. ([#5027](https://github.com/vector-im/element-ios/issues/5027))
- Fixed arithmetical exception errors when changing poll responses. ([#5114](https://github.com/vector-im/element-ios/issues/5114))
- Wordings: Replace "kick" and all affiliate word by "remove" ([#5346](https://github.com/vector-im/element-ios/issues/5346))
- Markdown/HTML: Fix HTTP links containing Markdown formatting ([#5355](https://github.com/vector-im/element-ios/issues/5355))
- Message Bubbles: Fix read marker appearing part way thru a message. ([#5521](https://github.com/vector-im/element-ios/issues/5521))
- HomeViewController: Refresh section badges and tab bar badges on updates. ([#5537](https://github.com/vector-im/element-ios/issues/5537))
- Update the tintColor in ThemeV1 to sRGB to match the Compound and ThemeV2. ([#5545](https://github.com/vector-im/element-ios/issues/5545))
- Message bubbles: Increase text message width. ([#5550](https://github.com/vector-im/element-ios/issues/5550))
- Message bubbles: Fix edited text message `edited` link not working. ([#5553](https://github.com/vector-im/element-ios/issues/5553))
- Message bubbles: Fix horizontal lines between messages. ([#5555](https://github.com/vector-im/element-ios/issues/5555))
- App Launch: Fix a potential issue where the green spinner is kept on screen when the room lists are ready. ([#5559](https://github.com/vector-im/element-ios/issues/5559))
- Authentication: Fix reCaptcha failing to indicate success. ([#5602](https://github.com/vector-im/element-ios/issues/5602))
- Timeline: scroll to the bottom when opening a notification ([#5639](https://github.com/vector-im/element-ios/issues/5639))

Others

- Fixed or ignored various project warnings for better DevX ([#5513](https://github.com/vector-im/element-ios/pull/5513))
- SwiftGen: Objective-C support for assets helpers ([#5533](https://github.com/vector-im/element-ios/pull/5533))
- Fix introspect not being able to theme the SwiftUI navigation bars. ([#5556](https://github.com/vector-im/element-ios/pull/5556))
- Message bubbles: Reduce sender name bottom margin for text message. ([#5634](https://github.com/vector-im/element-ios/pull/5634))
- Message bubbles: Use layout constants instead magic numbers. ([#5409](https://github.com/vector-im/element-ios/issues/5409))


## Changes in 1.8.1 (2022-02-16)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.22.1](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.22.1)).

🐛 Bugfixes

- Settings: Fix a bug where tapping a toggle could change multiple settings. ([#5463](https://github.com/vector-im/element-ios/issues/5463))
- Fix for images sometimes being sent unencrypted inside an encrypted room. ([#5564](https://github.com/vector-im/element-ios/issues/5564))


## Changes in 1.8.0 (2022-02-09)

✨ Features

- Threads: Add `View in room` action to the thread root event. ([#5117](https://github.com/vector-im/element-ios/issues/5117))
- Add a splash screen before authentication is shown. ([#5159](https://github.com/vector-im/element-ios/issues/5159))
- Remove location sharing settings entry and enable it by default. Add .well-known configuration support for tile server and map styles. ([#5298](https://github.com/vector-im/element-ios/issues/5298))

🙌 Improvements

- Show target user avatars for collapsed membership changes ([#4148](https://github.com/vector-im/element-ios/pull/4148))
- Updated available emojis with data from https://github.com/missive/emoji-mart/blob/master/data/apple.json ([#5517](https://github.com/vector-im/element-ios/pull/5517))
- Upgrade MatrixSDK version ([v0.22.0](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.22.0)).
- Permalinks: Create for thread events & handle navigations. ([#5094](https://github.com/vector-im/element-ios/issues/5094))
- Search: Navigate to thread view for search results in threads. ([#5095](https://github.com/vector-im/element-ios/issues/5095))
- Search: display matching pattern with a highlight color ([#5252](https://github.com/vector-im/element-ios/issues/5252))

🐛 Bugfixes

- Share: Handle jpeg and png UTType properly ([#3636](https://github.com/vector-im/element-ios/issues/3636))
- Timeline: automatically scroll timeline to the bottom when opening a room or rotating device. ([#4524](https://github.com/vector-im/element-ios/issues/4524))
- Fix bugs when building with Xcode 13: bar appearance / header padding / space avatar content size. Additionally, use UIKit context menus on the home screen. ([#4883](https://github.com/vector-im/element-ios/issues/4883))
- joining a space seemed to noop ([#5171](https://github.com/vector-im/element-ios/issues/5171))
- Accepting a Space Invite has shouty button labels ([#5175](https://github.com/vector-im/element-ios/issues/5175))
- RoomDataSource: Avoid reloading of data source on thread screen itself. ([#5263](https://github.com/vector-im/element-ios/issues/5263))
- MXKAccount: Gracefully pause the session. ([#5426](https://github.com/vector-im/element-ios/issues/5426))
- HomeViewController: Reload section if total number of rooms changed. ([#5448](https://github.com/vector-im/element-ios/issues/5448))
- Selecting Transfer in a call should immediately put the the other person on hold until the call connects or the Transfer is cancelled. ([#5451](https://github.com/vector-im/element-ios/issues/5451))
- Avatar view prevents to select space in space list ([#5454](https://github.com/vector-im/element-ios/issues/5454))
- Fixes media library freezing under iOS 15.2. ([#5465](https://github.com/vector-im/element-ios/issues/5465))
- Room Settings: Fix incorrect header title. ([#5525](https://github.com/vector-im/element-ios/issues/5525))

🗣 Translations

- Localisation: Add Indonesian and Slovak languages. ([#5048](https://github.com/vector-im/element-ios/issues/5048))

🧱 Build

- Fix CI builds for external contributors using forked repos. ([#5496](https://github.com/vector-im/element-ios/pull/5496), [#5491](https://github.com/vector-im/element-ios/issues/5491))
- Use Xcode 13.2 to build the project. ([#4883](https://github.com/vector-im/element-ios/issues/4883))

Others

- Add WIP to towncrier. ([#5446](https://github.com/vector-im/element-ios/pull/5446))
- Add a simple screen SwiftUI template. ([#5349](https://github.com/vector-im/element-ios/issues/5349))
- Added a new automation for FTUE and WTF Project boards ([#5493](https://github.com/vector-im/element-ios/issues/5493))
- Fix the indentation in the project board automation file on FTU and WTF labels ([#5504](https://github.com/vector-im/element-ios/issues/5504))


## Changes in 1.7.0 (2022-01-25)

✨ Features

- Message bubbles: Text message layout. ([#5208](https://github.com/vector-im/element-ios/issues/5208))
- Message Bubbles: Layout for Media. ([#5209](https://github.com/vector-im/element-ios/issues/5209))
- Message Bubbles: Support URL Previews. ([#5212](https://github.com/vector-im/element-ios/issues/5212))
- Message Bubbles: Support reactions. ([#5214](https://github.com/vector-im/element-ios/issues/5214))
- Added static location sharing sending and rendering support. ([#5298](https://github.com/vector-im/element-ios/issues/5298))
- Message bubbles: Add settings and build flag. ([#5321](https://github.com/vector-im/element-ios/issues/5321))

🙌 Improvements

- Upgrade MatrixSDK version ([v0.21.0](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.21.0)).
- Using mutable room list fetch sort options after chaning them to be a structure. Adaptation to MXStore api changes. ([#4384](https://github.com/vector-im/element-ios/issues/4384))
- Reduce grace period to report decryption failure ([#5345](https://github.com/vector-im/element-ios/issues/5345))

🐛 Bugfixes

- Fixed home screen not updating properly on theme changes. ([#4208](https://github.com/vector-im/element-ios/issues/4208))
- Fixes DTMF(dial tones) during voice calls. ([#5375](https://github.com/vector-im/element-ios/issues/5375))
- Fix crash when uploading a video on iPad when "Confirm size when sending" is enabled in settings. ([#5399](https://github.com/vector-im/element-ios/issues/5399))
- Fix BuildSetting to show/hide the "Invite Friends" button in the side SideMenu. ([#5402](https://github.com/vector-im/element-ios/issues/5402))
- Add BuildSetting to hide social login in favour of the simple SSO button. ([#5404](https://github.com/vector-im/element-ios/issues/5404))
- Fix grey spinner showing indefinitely over the home view after launch. ([#5407](https://github.com/vector-im/element-ios/issues/5407))
- RecentsViewController: Update tab bar badges on section-only updates. ([#5421](https://github.com/vector-im/element-ios/issues/5421))

Others

- Fix graphql warnings in issue workflow automation ([#5294](https://github.com/vector-im/element-ios/issues/5294))


## Changes in 1.6.12 (2022-01-11)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.20.16](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.20.16)).
- Analytics: Replace Matomo with PostHog. ([#5035](https://github.com/vector-im/element-ios/issues/5035))

🐛 Bugfixes

- RoomVC: Fix left room reason label memory management. ([#5311](https://github.com/vector-im/element-ios/issues/5311))


## Changes in 1.6.11 (2021-12-14)

✨ Features

- Added support for creating, displaying and interacting with polls in the timeline. ([#5114](https://github.com/vector-im/element-ios/issues/5114))

🙌 Improvements

- Upgrade MatrixSDK version ([v0.20.15](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.20.15)).
- Room member details: Display user Matrix ID and make it copyable. ([#4568](https://github.com/vector-im/element-ios/issues/4568))

🐛 Bugfixes

- Fix crash when trying to scroll the people's tab to the top. ([#5190](https://github.com/vector-im/element-ios/issues/5190))

🧱 Build

- Fix SwiftGen only generating strings for MatrixKit. ([#5280](https://github.com/vector-im/element-ios/issues/5280))

Others

- Update issue workflow automation for the Delight team ([#5285](https://github.com/vector-im/element-ios/issues/5285))
- Update workflow to add automation for the new Message Bubbles board ([#5289](https://github.com/vector-im/element-ios/issues/5289))


## Changes in 1.6.10 (2021-12-09)

🙌 Improvements

- Upgrade MatrixSDK version ([v0.20.14](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.20.14))

🧱 Build

- BuildRelease.sh: Add an option to build the ipa from local source code copy


## Changes in 1.6.9 (2021-12-07)

✨ Features

- Allow audio file attachments to be played back inline by reusing the existing voice message UI. Prevent unnecessary conversions if final file already exists on disk. ([#4753](https://github.com/vector-im/element-ios/issues/4753))
- SpaceExploreRoomViewModel: Support pagination in the Space Summary API ([#4893](https://github.com/vector-im/element-ios/issues/4893))
- Adds clientPermalinkBaseUrl for a custom permalink base url. ([#4981](https://github.com/vector-im/element-ios/issues/4981))
- Remember keyboard layout per room and restore it when opening the room again. ([#5067](https://github.com/vector-im/element-ios/issues/5067))

🙌 Improvements

- Upgrade MatrixSDK version ([v0.20.13](https://github.com/matrix-org/matrix-ios-sdk/releases/tag/v0.20.13)).
- Forward original message content and remove the need to re-upload media. ([#5014](https://github.com/vector-im/element-ios/issues/5014))
- Use DTCoreText's callback option to sanitise formatted messages ([#5165](https://github.com/vector-im/element-ios/issues/5165))

🐛 Bugfixes

- Remove duplicate sources for some strings files in Riot/target.yml. ([#3908](https://github.com/vector-im/element-ios/issues/3908))
- Invalid default value set for clientPermalinkBaseUrl. ([#5098](https://github.com/vector-im/element-ios/issues/5098))
- Ignore badge updates from virtual rooms. ([#5155](https://github.com/vector-im/element-ios/issues/5155))
- Fix rooms that should be hidden(such as virtual rooms) from showing. ([#5185](https://github.com/vector-im/element-ios/issues/5185))
- Improve generated Swift header imports. ([#5194](https://github.com/vector-im/element-ios/issues/5194))
- Fix bug where VoIP calls would not connect reliably after signout/signin. ([#5199](https://github.com/vector-im/element-ios/issues/5199))

🧱 Build

- Only run Build CI on develop, as it is already covered by Tests and Alpha. ([#5112](https://github.com/vector-im/element-ios/pull/5112))
- Add concurrency to the GitHub workflows to auto-cancel older runs of each action for PRs. ([#5039](https://github.com/vector-im/element-ios/issues/5039))

Others

- Improve the Obj-C Generated Interface Header Name definition ([#4722](https://github.com/vector-im/element-ios/issues/4722))
- Fix redundancy in heading in the bug report issue form ([#4984](https://github.com/vector-im/element-ios/issues/4984))
- Update automation for issue triage ([#5153](https://github.com/vector-im/element-ios/issues/5153))
- Improve issue automation workflows ([#5235](https://github.com/vector-im/element-ios/issues/5235))


## Changes in 1.6.8 (2021-11-17)

🙌 Improvements

- Upgrade MatrixKit version ([v0.16.10](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.16.10)).
- Using mutable room list fetch sort options after chaning them to be a structure. ([#4384](https://github.com/vector-im/element-ios/issues/4384))
- Share Extension: Remove the image compression prompt when the showMediaSizeSelection setting is disabled. ([#4815](https://github.com/vector-im/element-ios/issues/4815))
- Replaced GrowingTextView with simpler, custom implementation.  Cleaned up the RoomInputToolbar header. ([#4976](https://github.com/vector-im/element-ios/issues/4976))
- Settings: Update about section footer text. ([#5090](https://github.com/vector-im/element-ios/issues/5090))
- MXSession: Add logs to track if E2EE is enabled by default on the current HS. ([#5129](https://github.com/vector-im/element-ios/issues/5129))

🐛 Bugfixes

- Fixed share extension and message forwarding room list accessory view icon. ([#5041](https://github.com/vector-im/element-ios/issues/5041))
- Fixed message composer not following keyboard when swiping to dismiss. ([#5042](https://github.com/vector-im/element-ios/issues/5042))
- RoomVC: Fix retain cycles that prevents `RoomViewController` to be deallocated. ([#5055](https://github.com/vector-im/element-ios/issues/5055))
- Share Extension: Fix missing avatars and don't list spaces as rooms. ([#5057](https://github.com/vector-im/element-ios/issues/5057))
- Fix retain cycles that prevents deallocation in several classes. ([#5058](https://github.com/vector-im/element-ios/issues/5058))
- Fixed retain cycles between the user suggestion coordinator and the suggestion service, and in the suggestion service currentTextTrigger subject sink. ([#5063](https://github.com/vector-im/element-ios/issues/5063))
- Ensure alerts with weak references are retained until they've been presented. ([#5071](https://github.com/vector-im/element-ios/issues/5071))
- Message Composer: Ensure there is no text view when the user isn't allowed to send messages. ([#5079](https://github.com/vector-im/element-ios/issues/5079))
- Home: Fix bug where favourited DM would be shown in both Favourites and People section. ([#5081](https://github.com/vector-im/element-ios/issues/5081))
- Fix a crash when selected space is not home and a clear cache or logout is performed. ([#5082](https://github.com/vector-im/element-ios/issues/5082))
- Room Previews: Fix room previews not loading. ([#5083](https://github.com/vector-im/element-ios/issues/5083))
- Do not make the placeholder appearing when leaving a room on iPhone. ([#5084](https://github.com/vector-im/element-ios/issues/5084))
- Fix room ordering when switching between Home and People/Rooms/Favourites. ([#5105](https://github.com/vector-im/element-ios/issues/5105))

Others

- Improve wording around rageshakes in the defect issue template. ([#4987](https://github.com/vector-im/element-ios/issues/4987))


## Changes in 1.6.6 (2021-10-21)

✨ Features

- M10.4.1 Home space data filtering ([#4570](https://github.com/vector-im/element-ios/issues/4570))
- Implemented message forwarding from within the main application. Updated the share extension designs. ([#5009](https://github.com/vector-im/element-ios/issues/5009))

🙌 Improvements

- Settings: Refresh the appearance of headers and footers, with a few minor tweaks to the organisation. ([#5011](https://github.com/vector-im/element-ios/pull/5011))
- Upgrade MatrixKit version ([v0.16.9](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.16.9)).
- RecentsDataSource: Refactorings for lazy loading room summaries. ([#4384](https://github.com/vector-im/element-ios/issues/4384))
- Contacts Access: Request access via a button tap in the new Find Your Contacts footer instead of doing it automatically. ([#4484](https://github.com/vector-im/element-ios/issues/4484))
- Navigation: Create RoomCoordinator. ([#4734](https://github.com/vector-im/element-ios/issues/4734))
- Navigation: Enable room stacking. ([#4834](https://github.com/vector-im/element-ios/issues/4834))
- SwiftUI: Add FramePreferenceKey for use in ViewFrameReader. ([#4974](https://github.com/vector-im/element-ios/issues/4974))
- URL Previews: Stop requesting URL previews if the feature has been disabled on the homeserver. ([#5002](https://github.com/vector-im/element-ios/issues/5002))
- VectorWellKnown: Make all properties optional. ([#5008](https://github.com/vector-im/element-ios/issues/5008))

🐛 Bugfixes

- Message Composer: Pasting images from Safari now pastes the image and not its URL. ([#2076](https://github.com/vector-im/element-ios/issues/2076))
- Fixed private space invite should use lock icon instead of planet ([#4886](https://github.com/vector-im/element-ios/issues/4886))
- Room Lists: Fix generated avatar colours not matching Element Web. ([#4978](https://github.com/vector-im/element-ios/issues/4978))
- Contacts Sync: Move call to validateSyncLocalContactsState into MatrixKit. ([#4989](https://github.com/vector-im/element-ios/issues/4989))
- Timeline: Selecting a message now correctly selects any reactions and URL previews too. ([#4992](https://github.com/vector-im/element-ios/issues/4992))

🧱 Build

- Build: Update to Xcode 12.5 in the Fastfile and macOS 11 in the GitHub actions. ([#4998](https://github.com/vector-im/element-ios/pull/4998))

Others

- Replaced deprecated HPGrowingTextView with GrowingTextView. ([#4976](https://github.com/vector-im/element-ios/issues/4976))
- Move new issues into incoming column and move X-Needs-Info into Need info column on the issue triage board ([#5012](https://github.com/vector-im/element-ios/issues/5012))


## Changes in 1.6.5 (2021-10-14)

🙌 Improvements

- Upgrade MatrixKit version ([v0.16.7](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.16.7)).


## Changes in 1.6.4 (2021-10-12)

🙌 Improvements

- Upgrade MatrixKit version ([v0.16.6](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.16.6)).

🐛 Bugfixes

- RoomVC: Fix a crash when previewing a room. ([#4982](https://github.com/vector-im/element-ios/issues/4982))


## Changes in 1.6.2 (2021-10-08)

🙌 Improvements

- Upgrade MatrixKit version ([v0.16.5](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.16.5)).
- URL Previews: Use attributed string whitespace for cell heights and stop breaking up the bubble data. ([#4896](https://github.com/vector-im/element-ios/issues/4896))
- Replaced localizable strings with generated ones throughout the code. Fixed various translation issues. ([#4899](https://github.com/vector-im/element-ios/issues/4899))
- Voice Message scrubbing should require a slightly longer press, to avoid accidental scrubbing when scrolling the timeline ([#4935](https://github.com/vector-im/element-ios/issues/4935))
- Pods: Update ffmpeg-kit-ios-audio, FLEX, FlowCommoniOS, Reusable and SwiftLint. ([#4939](https://github.com/vector-im/element-ios/issues/4939))
- Service Terms: Track an analytics value on accept/decline of an identity server. ([#4955](https://github.com/vector-im/element-ios/issues/4955))

🐛 Bugfixes

- RecentsDataSource: Memory leak in [RecentsDataSource dataSource:didStateChange:]. ([#4193](https://github.com/vector-im/element-ios/pull/4193))
- i18n: Standardise casing of identity server and integration manager. ([#4559](https://github.com/vector-im/element-ios/issues/4559))
- MasterTabBarController: Listen to `MXSpaceNotificationCounter` to update the notification badge ([#4898](https://github.com/vector-im/element-ios/issues/4898))
- Fixed unintentional voice message drafts on automatically cancelled recordings (under 1 second) ([#4970](https://github.com/vector-im/element-ios/issues/4970))

🧱 Build

- Element Alpha: Build on macOS 11 to fix iOS 15 installation error. ([#4937](https://github.com/vector-im/element-ios/issues/4937))
- Bundler: Update CocoaPods and fastlane and xcode-install. ([#4951](https://github.com/vector-im/element-ios/issues/4951))

📄 Documentation

- Update PR template with a checkbox for accessibility and self review. ([#4920](https://github.com/vector-im/element-ios/issues/4920))


## Changes in 1.6.1 (2021-09-30)

🙌 Improvements

- Upgrade MatrixKit version ([v0.16.4](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.16.4)).
- Upgrade MatrixKit version ([v0.16.3](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.16.3)).
- AvatarViewData: Make `mediaManager` property optional (#4930). ([#4930](https://github.com/vector-im/element-ios/issues/4930))

🐛 Bugfixes

- fixed Spaces still visible after logging in with another account ([#4916](https://github.com/vector-im/element-ios/issues/4916))
- fixed App may not start in 1.6.0 ([#4919](https://github.com/vector-im/element-ios/issues/4919))
- AppDelegate: Fix a crash when backgrounding the app. ([#4932](https://github.com/vector-im/element-ios/issues/4932))


## Changes in 1.6.0 (2021-09-24)

✨ Features

- Spaces chooser ([#4052](https://github.com/vector-im/element-ios/issues/4052))
- SDK: Support Spaces summary ([#4068](https://github.com/vector-im/element-ios/issues/4068))
- Space home view inherits title from previously viewed tab ([#4493](https://github.com/vector-im/element-ios/issues/4493))
- Added Space menu ([#4494](https://github.com/vector-im/element-ios/issues/4494))
- Filter rooms for a given space ([#4495](https://github.com/vector-im/element-ios/issues/4495))
- Space invite ([#4496](https://github.com/vector-im/element-ios/issues/4496))
- Space preview bottom sheet ([#4497](https://github.com/vector-im/element-ios/issues/4497))
- Handle space link ([#4498](https://github.com/vector-im/element-ios/issues/4498))
- Support suggested rooms ([#4500](https://github.com/vector-im/element-ios/issues/4500))
- Show suggested in room lists ([#4501](https://github.com/vector-im/element-ios/issues/4501))
- Show space name in navigation bar title view for each root tab bar navigation controllers ([#4502](https://github.com/vector-im/element-ios/issues/4502))
- Space switching ([#4503](https://github.com/vector-im/element-ios/issues/4503))
- Added Show spaces in left panel ([#4509](https://github.com/vector-im/element-ios/issues/4509))
- Explore rooms ([#4571](https://github.com/vector-im/element-ios/issues/4571))
- Browsing users in a space ([#4682](https://github.com/vector-im/element-ios/issues/4682), [#4982](https://github.com/vector-im/element-ios/issues/4982))

🙌 Improvements

- Upgrade MatrixKit version ([v0.16.2](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.16.2)).
- URL Previews: Enable by default and remove from labs. ([#4828](https://github.com/vector-im/element-ios/issues/4828))
- Automatically dismissing invites for empty rooms after failing to join. ([#4830](https://github.com/vector-im/element-ios/issues/4830))
- Using the bundle display name as the app name in localizable .strings files. Exposing generated .strings and info.plist members to Objective-C. ([#4881](https://github.com/vector-im/element-ios/issues/4881))
- Voice Messages: Pause playback when changing rooms while retaining the playback position when re-entering. ([#47773](https://github.com/vector-im/element-ios/issues/47773))

🐛 Bugfixes

- Cannot disable Face ID after disabling pin. ([#4415](https://github.com/vector-im/element-ios/issues/4415))
- Fixes "PIN & (NULL)" security section header when device biometrics are not available or not enrolled into. ([#4461](https://github.com/vector-im/element-ios/issues/4461))
- SSO: Fix redirection issue when logging in with single sign on. Contributed by Chelsea Finnie. ([#4785](https://github.com/vector-im/element-ios/issues/4785))
- Fix incorrect theme being shown in the notification settings screens. ([#4816](https://github.com/vector-im/element-ios/issues/4816))
- Fix incorrect theme being shown in the notification settings screens after launch. ([#4835](https://github.com/vector-im/element-ios/issues/4835))
- No notification for space invitation ([#4840](https://github.com/vector-im/element-ios/issues/4840))
- Prevent home screen horizontal scroll views from capturing side menu swipe gestures. ([#4843](https://github.com/vector-im/element-ios/issues/4843))
- Odd error message in Space member list ([#4845](https://github.com/vector-im/element-ios/issues/4845))
- Space view has communities tab at the bottom of the screen ([#4846](https://github.com/vector-im/element-ios/issues/4846))
- Take user to space overview after joining space ([#4848](https://github.com/vector-im/element-ios/issues/4848))
- Refresh suggested room list in the home view when room is (un)marked as suggested ([#4849](https://github.com/vector-im/element-ios/issues/4849))
- Bring leaving space experience in line with Web ([#4850](https://github.com/vector-im/element-ios/issues/4850))
- Space home view inherits title from previously viewed tab ([#4851](https://github.com/vector-im/element-ios/issues/4851))
- Remove search filter when switching space ([#4852](https://github.com/vector-im/element-ios/issues/4852))
- URL Previews: Fix layout on 4" devices. ([#4855](https://github.com/vector-im/element-ios/issues/4855))
- RecentsViewController: Fix a crash when scrolling to a room in the room list. ([#4874](https://github.com/vector-im/element-ios/issues/4874))
- Explore rooms list in space has odd ordering ([#4890](https://github.com/vector-im/element-ios/issues/4890))
- Fixed suggested spaces appear as suggested rooms ([#4903](https://github.com/vector-im/element-ios/issues/4903))

🧱 Build

- Bumped the minimum deployment target to iOS 12.1 ([#4693](https://github.com/vector-im/element-ios/issues/4693))


## Changes in 1.5.4 (2021-09-16)

🙌 Improvements

- Upgrade MatrixKit version ([v0.16.1](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.16.1)).

🐛 Bugfixes

- RoomBubbleCellData: Fix crash when creating a URL preview when the link didn't end up in the last bubble component. ([#4823](https://github.com/vector-im/element-ios/issues/4823))


## Changes in 1.5.3 (2021-09-09)

✨ Features

- Timeline: Add URL previews under a labs setting. ([#888](https://github.com/vector-im/element-ios/issues/888))
- Media: Add an (optional) prompt when sending video to select the resolution of the sent video. ([#4638](https://github.com/vector-im/element-ios/issues/4638))

🙌 Improvements

- Camera: The quality of video when filming in-app is significantly higher. ([#4721](https://github.com/vector-im/element-ios/pull/4721))
- Upgrade MatrixKit version ([v0.16.0](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.16.0)).
- Media: Add settings for whether image/video resize prompts are shown when sending media (off by default). ([#4479](https://github.com/vector-im/element-ios/issues/4479))
- Mark iOS 11 as deprecated and show different version check alerts. ([#4693](https://github.com/vector-im/element-ios/issues/4693))
- Moved converted voice messages to their own folder. Cleaning up all temporary files on on reload and logout. ([#4770](https://github.com/vector-im/element-ios/issues/4770))
- AppDelegate: Wait for the room list data to be ready to hide the launch animation. ([#4797](https://github.com/vector-im/element-ios/issues/4797))

🐛 Bugfixes

- Fixed home view being clipped when search is active. ([#4449](https://github.com/vector-im/element-ios/issues/4449))
- DirectoryViewController: Make room preview data to use canonical alias for public rooms. ([#4778](https://github.com/vector-im/element-ios/issues/4778))
- AppDelegate: Wait for sync response when clearing cache. ([#4801](https://github.com/vector-im/element-ios/issues/4801))

Others

- Issue templates: modernise and sync with element-web ([#4744](https://github.com/vector-im/element-ios/pull/4744))
- Using a property wrapper for UserDefaults backed application settings (RiotSettings). ([#4755](https://github.com/vector-im/element-ios/pull/4755))
- Templates: Add input parameters classes to coordinators and use `Protocol` suffix for protocols. ([#4792](https://github.com/vector-im/element-ios/issues/4792))


## Changes in 1.5.2 (2021-08-27)

✨ Features

- Account Notification Settings: Enable/disable notification settings (Default, Mentions & Keywords and Other) and edit Keywords. ([#4467](https://github.com/vector-im/element-ios/issues/4467))
- Implemented dialogs to inform users about Element iOS11 deprecation. ([#4693](https://github.com/vector-im/element-ios/issues/4693))

🙌 Improvements

- Upgrade MatrixKit version ([v0.15.8](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.15.8)).
- Popping the user back to the home screen after leaving a room. ([#1482](https://github.com/vector-im/element-ios/issues/1482))
- Notifications: Replace "Message" fallback with "Notification" as the event may not be a message. ([#4132](https://github.com/vector-im/element-ios/issues/4132))
- MXSessionState: Use Swifty versions. ([#4471](https://github.com/vector-im/element-ios/issues/4471))
- Notifications: Show the body of all message event types. ([#4653](https://github.com/vector-im/element-ios/issues/4653))
- Notifications: Replies now hide the referenced content. ([#4660](https://github.com/vector-im/element-ios/issues/4660))
- Room Notification Settings: This screen is now implemented in SwiftUI for users on iOS14 or above. ([#4669](https://github.com/vector-im/element-ios/issues/4669))

🐛 Bugfixes

- Fixed flickering voice message cells while being sent. ([#4714](https://github.com/vector-im/element-ios/issues/4714))
- Fastfile: Update build number in AppVersion.xcconfig instead of AppIdentifiers.xcconfig. ([#4726](https://github.com/vector-im/element-ios/issues/4726))
- Disabled the create room button while creating a room, preventing duplicates from being created. ([#4746](https://github.com/vector-im/element-ios/issues/4746))
- Fixed cached callbacks race condition, serialized all async operations, properly cleaning up callbacks on failure. ([#4748](https://github.com/vector-im/element-ios/issues/4748))
- Notification Settings: Keywords Notification Setting should be "On" by default. ([#4759](https://github.com/vector-im/element-ios/issues/4759))

🧱 Build

- Support building Ad-hoc alpha release on pull request (#4635). ([#4635](https://github.com/vector-im/element-ios/issues/4635))
- Move app version from AppIdentifiers.xcconfig into a dedicated config file (#4715). ([#4715](https://github.com/vector-im/element-ios/issues/4715))


## Changes in 1.5.1 (2021-08-12)

🐛 Bugfixes

- People Tab: Fix crash when showing an invite. ([#4698](https://github.com/vector-im/element-ios/issues/4698))


## Changes in 1.5.0 (2021-08-11)

✨ Features

- Voice messages: Remove labs setting and enable them by default. ([#4671](https://github.com/vector-im/element-ios/issues/4671))

🙌 Improvements

- Upgrade MatrixKit version ([v0.15.7](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.15.7)).
- Settings: The notifications toggle no longer detects the system's "Deliver Quietly" configuration as disabled. ([#2368](https://github.com/vector-im/element-ios/issues/2368))
- SSO: Stable ids for MSC 2858. ([#4362](https://github.com/vector-im/element-ios/issues/4362))
- Room: Remove the green border from direct message room avatars. ([#4520](https://github.com/vector-im/element-ios/issues/4520))
- Settings: Adds a link to open the Settings app to quickly configure app notifications. ([#4575](https://github.com/vector-im/element-ios/issues/4575))
- Add support for Functional Members. ([#4609](https://github.com/vector-im/element-ios/issues/4609))
- VoIP: Additional changes on call tiles. ([#4642](https://github.com/vector-im/element-ios/issues/4642))
- Voice messages: Allow voice message playback control from the iOS lock screen and control center. ([#4655](https://github.com/vector-im/element-ios/issues/4655))
- Voice messages: Stop recording and go into locked mode when the application becomes inactive. ([#4656](https://github.com/vector-im/element-ios/issues/4656))
- Voice messages: Improve audio recording quality. ([#4671](https://github.com/vector-im/element-ios/issues/4671))

🐛 Bugfixes

- fix typo in email settings ([#4480](https://github.com/vector-im/element-ios/issues/4480))

🧱 Build

- CHANGES.md: Use towncrier to manage the change log. More info in [CONTRIBUTING](CONTRIBUTING.md#changelog). ([#4689](https://github.com/vector-im/element-ios/pull/4689), [#4393](https://github.com/vector-im/element-ios/issues/4393))
- Add a script to initialize quickly and easily the project. ([#4596](https://github.com/vector-im/element-ios/issues/4596))

📄 Documentation

- Convert CHANGES to MarkDown. ([#4393](https://github.com/vector-im/element-ios/issues/4393))
- Add reference to AppIdentifiers.xcconfig in INSTALL.md. ([#4674](https://github.com/vector-im/element-ios/issues/4674))

Others

- Contacts: Fix implicitly retained self warnings. ([#4677](https://github.com/vector-im/element-ios/issues/4677))


## Changes in 1.4.9 (2021-08-03)

🙌 Improvements

 * Voice Messages: Increased recording state microphone icon size
 * Voice Messages: Using "Voice message - MM.dd.yyyy HH.mm.ss" as the format for recorded audio files

🐛 Bugfix

 * Voice Messages: Fixed race conditions when sending voice messages (#4641)
    
## Changes in 1.4.8 (2021-07-29)

🙌 Improvements

 * Room: Added support for Voice Messages (#4090, #4091, #4092, #4094, #4095, #4096)
 * Rooms Tab: Remove the directory section (#4521).
 * Notifications: Show decrypted content is enabled by default (#4519).
 * People Tab: Remove the local contacts section (#4523).
 * Contacts: Delay access to local contacts until they're needed for display (#4616).
 * RecentsDataSource: Factorize section reset in one place (target #4591).
 * Voice Messages: Tap/hold to send voice messages isn't intuitive (#4601).
 * Voice Messages: copy could be improved (#4604).
 * Slide to lock should be more generous (#4602).

🐛 Bugfix

 * Room: Fixed mentioning users from room info member details (#4583)
 * Settings: Disabled autocorrection when entering an identity server (#4593).
 * Room Notification Settings: Fix Crash when opening the new Room Notification Settings Screen (Not yet released) (#4599).
 * AuthenticationViewController: Fix crash on authentication if an intermediate view was presented (#4606).
 * Room: Fixed crash when opening a read-only room (#4620).
 * Voice Messages: Tapping on waveform in composer glitches UI (#4603).

Others

 * Separated CI jobs into individual actions
 * Update Gemfile.lock

Improvements:
 * Upgrade MatrixKit version ([v0.15.6](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.15.6)).

## Changes in 1.4.7 (2021-07-22)
    
Others

 * Updated issue templates.

Improvements:
 * Upgrade MatrixKit version ([v0.15.5](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.15.5)).

## Changes in 1.4.6 (2021-07-16)

🙌 Improvements

 * Room Notification Settings: Ability to change between "All Messages", "Mentions and Keywords" and "None". Not yet exposed in Element UI. (#4458).
 * Add support for sending slow motion videos (#4483).

🐛 Bugfix

 * VoIP: Do not present ended calls.
 * More fixes to Main.storyboard layout on iPhone 12 Pro Max (#4527)
 * Fix crash on Apple Silicon Macs.
 * Media Picker: Generate video thumbnails with the correct orientation (#4515).
 * Directory List (pop-up one): Fix duplicate rooms being shown (#4537).
 * Use different title for scan button for self verification (#4525).
 * it's easy for the back button to trigger a leftpanel reveal (#4438).
 * Show / hide reset button in secrets recovery screen (#4546).
 * Share Extension: Fix layout when searching (#4258).
 * Timeline: Fix incorrect crop of media thumbnails (#4552).

    
Others

 * Silenced some documentation, deprecations and SwiftLint warnings.
 
Improvements:
 * Upgrade MatrixKit version ([v0.15.4](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.15.4)).

## Changes in 1.4.5 (2021-07-07)

🐛 Bugfix

 * Notifications: Fix an issue where the app is unresponsive after getting some notifications (#4534).

## Changes in 1.4.4 (2021-06-30)

🙌 Improvements

 * DesignKit: Add Fonts (#4356).
 * VoIP: Implement audio output router menu in call screen.

🐛 Bugfix

 * SSO: Handle login callback URL with HTML entities (#4129).
 * Share extension: Fix theme in dark mode (#4486).
 * Theme: Fix authentication activity indicator colour when using a dark theme (#4485).

    
Improvements:
 * Upgrade MatrixKit version ([v0.15.3](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.15.3)).

## Changes in 1.4.3 (2021-06-24)

🙌 Improvements

 * Room lists: Hide invited rooms if auto-accept option enabled.

🐛 Bugfix

 * Fixed retain cycle between the RoomTitleView and RoomViewController

    
Improvements:
 * Upgrade MatrixKit version ([v0.15.2](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.15.2)).

## Changes in 1.4.2 (2021-06-21)

✨ Features

 * Add left panel (#4398).

🙌 Improvements

 * MXRoomSummary: Adapt room summary changes on MatrixSDK (#4360).
 * EncryptionKeyManager: Create keys for room last message data type.
 * Integrated FLEX for debug builds.
 * VoIP: Add dial pad for PSTN capable servers to menu on homescreen.
 * VoIP: Replace call bar with PiP tiles for every type of calls.
 * Security settings: Display the cross-signing section (#4430).
 * Security settings: The Secure backup section has been updated to match element-web UX (#4430).
 * Wording: Replace Recovery Passphrase and Recovery Key by Security Phrase and Security Key (#4268).
 * Room directory: Join room by alias or id (#4429).
 * Room lists: Avoid app freezes by building them on a separated thread (#3777).

🐛 Bugfix

 * StartChatViewController: Add more helpful message when trying to start DM with a user that does not exist (#224).
 * RoomDirectCallStatusBubbleCell: Fix crash when entering a DM after a call is hung-up/rejected while being answered (#4403).
 * ContactsDataSource: iPad Crashes when you select a contact in search and then collapse a section or clear the query text (#4414).
 * SettingsViewController: Fix "auto" theme message to clarify that it matches the system theme on iOS 13+ (#2860).
 * VoIP: Handle application inactive state too for VoIP pushes (#4269).
 * VoIP: Do not terminate the app if protected data not available (#4419).
 * KeyVerification: Listen for request state changes and show QR reader option when it's ready.
 * NSE: Recreate background sync service if credentials changed (#3695).
 * HomeViewController: Don't clip the home view when searching for rooms on iPhone 12 Pro Max (#4450).

    
🧱 Build

 * GH Actions: Make sure we use the latest version of MatrixKit.

Others

 *
 
Improvements:
 * Upgrade MatrixKit version ([v0.15.1](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.15.1)).

 ## Changes in 1.4.1 (2021-06-08)

🐛 Bugfix

 * SettingsViewController: Fix crash when changing the app language (#4377).
 * UserSessionsService: Fix room lists lost after a reset cache (#4395).

## Changes in 1.4.0 (2021-06-03)

🙌 Improvements

 * Crypto: Do not decrypt synchronously. It asynchronously happens upstream now (#4306). 
 * Navigation: Start decoupling view controllers managed by MasterTabBarController (#3596 and #3618).
 * Jitsi: Include optional server name field on JitsiJWTPayloadContextMatrix.
 * CallPresenter: Add more logs for group calls.
 * Logging: Adopted MXLog throughout the application (vector-im/element-ios/issues/4351).

🐛 Bugfix

 * buildRelease.sh: Make bundler operations in the cloned repository folder.
 * VoIP: Fix call bar layout issue for landscape.

🗣 Translations

 * Fix missing translation files for Icelandic.
 * Enable Esperanto, Portuguese (Brazil), Kabyle, Norwegian Bokmål (nb), Swedish, Japanese and Welsh.
    
Improvements:
 * Upgrade MatrixKit version ([v0.15.0](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.15.0)).

## Changes in 1.3.9 (2021-05-18)

🐛 Bugfix

 * RecentsDataSource: Present the secure backup banner only if key backup is disabled.

    
## Changes in 1.3.8 (2021-05-17)

🐛 Bugfix

 * RecentsDataSource: Do not display secure backup banner when keys upload is in process.

    
## Changes in 1.3.7 (2021-05-12)

🙌 Improvements

 * NSE: Add logs for notification delay.
 * Templates: Update bridge presenter template to auto-implement iOS 13 pull-down gesture.

🐛 Bugfix

 * NSE: Fixes to avoid PushKit crashes (#4269).
 * Handle pull-down gesture for reactions history view (#4293).

    
Improvements:
 * Upgrade MatrixKit version ([v0.14.12](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.12)).

## Changes in 1.3.6 (2021-05-07)

🙌 Improvements

 * Jitsi: Use Jitsi server from homeserver's Well Known, if present, to create conferences (#3158).
 * RoomMemberDetailsVC: Enable / disable "Hide all messages from this user" from settings (#4281).
 * RoomVC: Show / Hide More and Report Content contextual menu from settings (#4285).
 * SettingsVC: Show / hide NSFW and decrypted content options from build settings (#4290).
 * RoomVC: Tweaked Scroll to Bottom FAB button (#4272).
 * DesignKit: Introduce a new framework to manage design components.
 * Add Jitsi widget remove banner for privileged users.
 * Update "Jump to unread" banner to a pill style button.
 * CallVC: Add transfer button.
 * Spaces: Hide spaces from room list and home but keep space invites (#4252).
 * Spaces: Show space invites and advertise that they are not available (#4277).
 * Advertise that spaces are not available when tapping on a space link or a space invite (#4279).

🐛 Bugfix

 * RoomVC: Avoid navigation to integration management using integration popup with settings set to integration disabled (#4261).
 * RiotSettings: Logging out resets RiotSettings (#4259).
 * RoomVC: Crash in `setScrollToBottomHidden` method (#4270).
 * Notifications: Make them work in debug mode (#4274).
 * VoIP: Fix call bar layout issue (#4300).

    
🧱 Build

 * GH Actions: Make jobs use the right version of MatrixKit and MatrixSDK.

Improvements:
 * Upgrade MatrixKit version ([v0.14.11](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.11)).

## Changes in 1.3.5 (2021-04-22)

🙌 Improvements

 * Add `gitter.im` to list of default room directories
 * MasterTabBarController: Show/Hide Home Screen tabs (#4234).
 * RoomVC: Enable / Disable VoIP feature in Rooms (#4236).
 * UnifiedSearchRecentsDataSource: Show/Hide public directory (#4242).
 * DirectoryRecentTableViewCell: Do not use "directory_search_results_more_than" string when there is no rooms and the search is on.
 * RecentsVC: Make joining public rooms configurable (#4211).
 * Make room settings screen configurable dynamically (#4219).
 * RoomVC: Show / Hide integrations and actions (#4245).

🐛 Bugfix

 * PublicRoomsDirectoryDataSource: Fix search when NSFW filter is off.
 * RoomVC: Fix navigation issue when a room left.
 * RoomVC: Fix a crash when scroll to bottom tapped on a left room.

    
🧱 Build

 * GH Actions: Start using them for CI to check simulator build and tests.

Improvements:
 * Upgrade MatrixKit version ([v0.14.10](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.10)).

## Changes in 1.3.4 (2021-04-19)

🐛 Bugfix

 * RoomVC: Crash in refreshTypingNotification (#4230).

    
## Changes in 1.3.3 (2021-04-16)

    
Improvements:
 * Upgrade MatrixKit version ([v0.14.9](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.9)).

## Changes in 1.3.2 (2021-04-16)

🐛 Bugfix

 * Self-verification: Fix compatibility with Element-Web (#4217).
 * Notifications: Fix sender display name that can miss (#4222). 

    
Improvements:
 * Upgrade MatrixKit version ([v0.14.9](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.9)).

## Changes in 1.3.1 (2021-04-14)

    
Improvements:
 * Upgrade MatrixKit version ([v0.14.8](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.8)).

## Changes in 1.3.0 (2021-04-09)

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

    
Improvements:
 * Upgrade MatrixKit version ([v0.14.7](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.7)).

## Changes in 1.2.8 (2021-03-26)

🐛 Bugfix

 * Xcodegen: Unit tests are broken (#4152).

    
## Changes in 1.2.7 (2021-03-24)

🙌 Improvements

 * Pods: Update FlowCommoniOS, GBDeviceInfo, KeychainAccess, MatomoTracker, SwiftJWT, SwiftLint (#4120).
 * Room lists: Remove shields on room avatars (#4115).

🐛 Bugfix

 * RoomVC: Fix timeline blink on sending.
 * RoomVC: Fix not visible last bubble issue.
 * Room directory: Fix crash (#4137).

    
Improvements:
 * Upgrade MatrixKit version ([v0.14.6](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.6)).

## Changes in 1.2.6 (2021-03-11)

✨ Features

 * Improve the status of send messages (sending, sent, received, failed) (#4014)
 * Retrying & deleting failed messages (#4013)
 * Composer Update - Typing and sending a message (#4085)

    
Improvements:
 * Upgrade MatrixKit version ([v0.14.5](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.5)).

## Changes in 1.2.5 (2021-03-03)

🙌 Improvements

 * Settings: Add option to show NSFW public rooms (off by default).

🐛 Bugfix

 * Emoji store: Include short name when searching emojis (#4063).

    
Improvements:
 * Upgrade MatrixKit version ([v0.14.4](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.4)).

## Changes in 1.2.4 (2021-03-01)

🐛 Bugfix

 * Social login: Fix a crash when selecting a social login provider.

    
## Changes in 1.2.3 (2021-02-26)

    
Improvements:
 * Upgrade MatrixKit version ([v0.14.3](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.3)).

## Changes in 1.2.2 (2021-02-24)

✨ Features

 * Enable encryption for accounts, contacts and keys in the crypto database (#3867).

🙌 Improvements

 * Home: Show room directory on join room action (#3775).
 * RoomVC: Add quick actions in timeline on room creation (#3776).

    
🧱 Build

 * XcodeGen: .xcodeproj files are now built from readable yml file: [New Build instructions](README.md#build-instructions) (#3812).
 * Podfile: Use MatrixKit for all targets and remove MatrixKit/AppExtension.
 * Fastlane: Use the "New Build System" to build releases.
 * Fastlane: Re-enable parallelised builds.

Improvements:
 * Upgrade MatrixKit version ([v0.14.2](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.2)).

## Changes in 1.2.1 (2021-02-12)

🙌 Improvements

 * User-Interactive Authentication: Add UIA support for device deletion and add user 3PID action (#4016).

🐛 Bugfix

 * NSE: Wait for VoIP push request if any before calling contentHandler (#4018).
 * VoIP: Show dial pad option only if PSTN is supported (#4029).

    
Improvements:
 * Upgrade MatrixKit version ([v0.14.1](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.1)).

## Changes in 1.2.0 (2021-02-11)

🙌 Improvements

 * Cross-signing: Setup cross-signing without authentication parameters when a grace period is enabled after login (#4006).
 * VoIP: Implement DTMF on call screen (#3929).
 * VoIP: Implement call transfer screen (#3962).
 * VoIP: Implement call tiles on timeline (#3955).

    
Improvements:
 * Upgrade MatrixKit version ([v0.14.0](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.14.0)).

## Changes in 1.1.7 (2021-02-03)

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

    
Improvements:
 * Upgrade MatrixKit version ([v0.13.9](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.9)).

## Changes in 1.1.6 (2021-01-27)

🐛 Bugfix

 * Navigation: Unable to open a room from a room list (#3863).
 * AuthVC: Fix social login layout issue.

    
Improvements:
 * Upgrade MatrixKit version ([v0.13.8](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.8)).

## Changes in 1.1.5 (2021-01-18)

    
Improvements:
 * Upgrade MatrixKit version ([v0.13.7](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.7)).

## Changes in 1.1.4 (2021-01-15)

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

    
Improvements:
 * Upgrade MatrixKit version ([v0.13.6](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.6)).

## Changes in 1.1.3 (2020-12-18)

🙌 Improvements

 * AuthVC: Update SSO button wording.
 * Log NSE memory footprint for debugging purposes.

🐛 Bugfix

 * Refresh account details on NSE runs (#3719).

    
Improvements:
 * Upgrade MatrixKit version ([v0.13.3](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.3)).
 * Upgrade MatrixKit version ([v0.13.4](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.4)).

## Changes in 1.1.2 (2020-12-02)

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

    
Improvements:
 * Upgrade MatrixKit version ([v0.13.2](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.2)).

## Changes in 1.1.1 (2020-11-24)

🙌 Improvements

 * Home: Add empty screen when there is nothing to display (#3823).

    
Improvements:
 * Upgrade MatrixKit version ([v0.13.1](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.1)).

## Changes in 1.1.0 (2020-11-17)

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

    
Improvements:
 * Upgrade MatrixKit version ([v0.13.0](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.13.0)).

## Changes in 1.0.18 (2020-10-27)

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

    
Improvements:
 * Upgrade MatrixKit version ([v0.12.26](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.26)).

## Changes in 1.0.17 (2020-10-14)

🙌 Improvements

 * Device verification: Do not check for existing key backup after SSSS & Cross-Signing reset.
 * Cross-signing: Detect when cross-signing keys have been changed.
 * Make copying & pasting media configurable.

    
Improvements:
 * Upgrade MatrixKit version ([v0.12.25](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.25)).

## Changes in 1.0.16 (2020-10-13)

🙌 Improvements

 * Self-verification: Update complete security screen wording (#3743).

    
Improvements:
 * Upgrade MatrixKit version ([v0.12.24](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.24)).

## Changes in 1.0.15 (2020-10-09)

🙌 Improvements

 * Room: Make topic links tappable (#3713).
 * Room: Add more to long room topics (#3715).
 * Security screens: Update automatically shields when the trust changes.
 * Room: Add floating action button to invite members.
 * Pasteboard: Use MXKPasteboardManager.pasteboard on copy operations (#3732).

🐛 Bugfix

 * Push: Check crypto has keys to decrypt an event before decryption attempt, avoid sync loops on failure.

    
Improvements:
 * Upgrade MatrixKit version ([v0.12.23](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.23)).

## Changes in 1.0.14 (2020-10-02)

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

    
Improvements:
 * Upgrade MatrixKit version ([v0.12.22](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.22)).

## Changes in 1.0.13 (2020-09-30)

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

## Changes in 1.0.12 (2020-09-16)

🐛 Bugfix

 *

Improvements:
 * Upgrade MatrixKit version ([v0.12.21](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.21)).
 * Upgrade MatrixKit version ([v0.12.20](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.20)).

## Changes in 1.0.11 (2020-09-15)

🙌 Improvements

 * Room: Collapse state messages on room creation (#3629).
 * AuthVC: Make force PIN working for registration as well.
 * AppDelegate: Do not show incoming key verification requests while authenticating.

🐛 Bugfix

 * AuthVC: Fix PIN setup that broke cross-signing bootstrap.
 * Loading animation: Fix the bug where, after authentication, the animation disappeared too early and made auth screen flashed.

Others

 * buildRelease.sh: Pass a `git_tag` parameter to fastlane because fastlane `git_branch` method can fail.

## Changes in 1.0.10 (2020-09-08)

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
    
🧱 Build

 * buildRelease.sh: Make sure it works for both branches and tags
    
Improvements:
 * Upgrade MatrixKit version ([v0.12.18](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.18)).

## Changes in 1.0.9 (2020-09-03)

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

## Changes in 1.0.8 (2020-09-03)

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

## Changes in 1.0.7 (2020-08-28)

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

## Changes in 1.0.6 (2020-08-26)

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

## Changes in 1.0.5 (2020-08-13)

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

## Changes in 1.0.4 (2020-08-07)

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

## Changes in 1.0.3 (2020-08-05)

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

## Changes in 1.0.2 (2020-07-28)

Bug fix:
 * Registration: Do not display the skip button if email is mandatory (#3417).
 * NotificationService: Do not cache showDecryptedContentInNotifications setting (#3444).

## Changes in 1.0.1 (2020-07-17)
 
Bug fix:
 * SettingsViewController: Fix crash when scrolling to Discovery (#3401).
 * Main.storyboard: Set storyboard identifier for SettingsViewController (#3398).
 * Universal links: Fix broken links for web apps (#3420).
 * SettingsViewController: Fix pan gesture crash (#3396).
 * RecentsViewController: Fix crash on dequeue some cells (#3433).
 * NotificationService: Fix losing sound when not showing decrypted content in notifications (#3423).

## Changes in 1.0.0 (2020-07-13)

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

## Changes in 0.11.6 (2020-06-30)

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

## Changes in 0.11.5 (2020-05-18)

Improvements:
 * Upgrade MatrixKit version ([v0.12.6](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.6)).

Bug fix:
 * AuthenticationViewController: Adapt UIWebView ## Changes in MatrixKit (PR #3242).
 * Share extension & Siri intent: Do not fail when sending to locally unverified devices (#3252).
 * CountryPickerVC: Search field is invisible in dark theme (#3219).

## Changes in 0.11.4 (2020-05-08)

Bug fix:
 * App asks to verify all devices on every startup for no valid reason (#3221).

## Changes in 0.11.3 (2020-05-07)

Improvements:
 * Upgrade MatrixKit version ([v0.12.3](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.3)).
 * Cross-signing: Display "Verify your other sessions" modal at every startup if needed (#3180).
 * Cross-signing: The "Complete Security" button now triggers a verification request to all user devices.
 * Secrets: On startup, request again private keys we are missing locally.

Bug fix:
 * KeyVerificationSelfVerifyStartViewController has no navigation (#3195).
 * Self-verification: QR code scanning screen refers to other-person scanning (#3189).

## Changes in 0.11.2 (2020-05-01)

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

## Changes in 0.11.1 (2020-04-24)

Improvements:
 * Upgrade MatrixKit version ([v0.12.1](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.12.1)).
 * New icons.
 * Cross-signing: Allow incoming device verification request from other user (#3139).
 * Cross-signing: Allow to verify each device of users with no cross-signing (#3138).
 * Jitsi: Make Jitsi widgets compatible with Matrix Widget API v2. This allows to use any Jitsi servers (#3150).

Bug fix:
 * Settings: Security, present complete security when my device is not trusted (#3127).
 * Settings: Security: Do not ask to complete security if there is no cross-signing (#3147).

## Changes in 0.11.0 (2020-04-17)

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

## Changes in 0.10.5 (2020-04-01)

Bug fix:
 * Fix error when joining some public rooms, thanks to @chrismoos (PR #2888).
 * Fix crash due to malformed widget (#2997).
 * Push notifications: Avoid any automatic deactivation (vector-im/riot-ios#3017).
 * Fix links breaking user out of SSO flow, thanks to @schultetwin (#3039).

## Changes in 0.10.4 (2019-12-11)

Improvements:
 * ON/OFF Cross-signing development in a Lab setting (#2855).

Bug fix:
 * Device Verification: Stay in infinite waiting (#2878).

## Changes in 0.10.3 (2019-12-05)

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

## Changes in 0.10.2 (2019-11-15)

Bug fix:
 * Integrations: Fix terms consent display when they are required.

## Changes in 0.10.1 (2019-11-06)

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

## Changes in 0.10.0 (2019-10-11)

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

## Changes in 0.9.5 (2019-09-20)

Bug fix:
 * VoiceOver: RoomVC: Fix some missing accessibility labels for buttons (#2722).
 * VoiceOver: RoomVC: Make VoiceOver focus on the contextual menu when selecting an event (#2721).
 * VoiceOver: RoomVC: Do not lose the focus on the timeline when paginating (with 3 fingers) (#2720).
 * VoiceOver: RoomVC: No VoiceOver on media (#2726).

## Changes in 0.9.4 (2019-09-13)

Improvements:
 * Authentication: Improve the webview used for SSO (#2715).

## Changes in 0.9.3 (2019-09-10)

Improvements:
 * Support Riot configuration link to customise HS and IS (#2703).
 * Authentication: Create a way to filter and prioritise flows (with handleSupportedFlowsInAuthenticationSession).

## Changes in 0.9.2 (2019-08-08)

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

## Changes in 0.9.1 (2019-07-17)

Bug fix:
 * Edits history: Original event is missing (#2585).

## Changes in 0.9.0 (2019-07-16)

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

## Changes in 0.8.6 (2019-05-06)

Bug fix:
 * Device Verification: Fix bell emoji name.
 * Device Verification: Fix buttons colors in dark theme.

## Changes in 0.8.5 (2019-05-03)

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

## Changes in 0.8.4 (2019-03-21)

Improvements:
 * Upgrade MatrixKit version ([v0.9.8](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.9.8)).
 * Share extension: Remove image large size resizing choice if output dimension is too high to prevent memory limit exception (PR #2342).

Bug fix:
 * Unable to open a file attachment of a room message (#2338).

## Changes in 0.8.3 (2019-03-13)

Improvements:
 * Upgrade MatrixKit version ([v0.9.7](https://github.com/matrix-org/matrix-ios-kit/releases/tag/v0.9.7)).

Bug fix:
 * Widgets: Attempt to re-register for a scalar token if ours is invalid (#2326).
 * Widgets: Pass scalar_token only when required.


## Changes in 0.8.2 (2019-03-11)

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

## Changes in 0.8.1 (2019-02-19)

Improvements:
 * Key backup: avoid to refresh the home room list on every backup state change (#2265).

Bug fix:
 * Fix text color in room preview (PR #2261).
 * Fix navigation bar background after accepting an invite (PR #2261)
 * Tabs at the top of Room Details are hard to see in dark theme (#2260).

## Changes in 0.8.0 (2019-02-15)

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

## Changes in 0.7.11 (2019-01-08)

Improvements:
 * Upgrade MatrixKit version (v0.9.3).
 * Fix almost all the warnings caused by -Wstrict-prototypes, thanks to @fridtjof (PR #2155).

## Changes in 0.7.10 (2019-01-04)

Bug fix:
 * Share extension: Fix screenshot sharing (#2022). Improve image sharing performance to avoid out of memory crash.

## Changes in 0.7.9 (2019-01-04)

Improvements:
 * Upgrade MatrixKit version (v0.9.2).

Bug fix:
 * Registration: email or phone number is no more skippable (#2140).

## Changes in 0.7.8 (2018-12-12)

Improvements:
 * Upgrade MatrixKit version (v0.9.1).
 * Replace the deprecated MXMediaManager and MXMediaLoader interfaces use (see matrix-org/matrix-ios-sdk/pull/593).
 * Replace the deprecated MXKAttachment and MXKImageView interfaces use (see matrix-org/matrix-ios-kit/pull/487).
 * i18n: Enable Japanese (ja)
 * i18n: Enable Hungarian (hu)
 
Bug fix:
 * Registration: reCAPTCHA does not work anymore on iOS 10 (#2119).

## Changes in 0.7.7 (2018-10-31)

Improvements:
 * Upgrade MatrixKit version (v0.8.6).

Bug fix:
 * Notifications: old notifications can reappear (#1985).

## Changes in 0.7.6 (2018-10-05)

Bug fix:
 * Wrong version number.

## Changes in 0.7.5 (2018-10-05)

Improvements:
 * Upgrade MatrixKit version (v0.8.5).
 * Server Quota Notices: Implement the blue banner (#1937).

## Changes in 0.7.4 (2018-09-26)

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

## Changes in 0.7.3 (2018-08-27)

Improvements:
 * Upgrade MatrixKit version (v0.8.3).

Bug fix:
 * Fix input toolbar reset in RoomViewController on MXSession state change (#2006 and #2008).
 * Fix user interaction disabled in master view of UISplitViewContoller when selecting a room (#2005).

## Changes in 0.7.2 (2018-08-24)

Improvements:
 * Upgrade MatrixKit version (v0.8.2).
 * Server Quota Notices in Riot (#1937).
 
Bug fix:
 * User defaults: the preset application language (if any) is ignored.
 * Recents: Avoid to open a room twice (it crashed on room creation on quick HSes).
 * Riot-bot: Do not try to create a room with it if the user homeserver is not federated.

## Changes in 0.7.1 (2018-08-17)

Improvements:
 * Upgrade MatrixKit version (v0.8.1).
 
Bug fix:
 * Empty app if initial /sync fails (#1975).
 * Direct rooms can be lost on an initial /sync (vector-im/riot-ios/issues/1983).
 * Fix possible race conditions in direct rooms management.

## Changes in 0.7.0 (2018-08-10)

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

## Changes in 0.6.20 (2018-07-13)

Improvements:
 * Update contact permission text in order to be clearer about the reasons for access to the address book.

## Changes in 0.6.19 (2018-07-05)

Improvements:

Bug fix:
* RoomVC: Fix duplicated read receipts (regression due to read receipts performance improvement).

## Changes in 0.6.18 (2018-07-03)

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

## Changes in 0.6.17 (2018-06-01)

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

## Changes in 0.6.16 (2018-05-23)

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

## Changes in 0.6.15 (2018-04-23)

Improvements:
 * Upgrade MatrixKit version (v0.7.11).
 
Bug fix:
 * Regression: Sending a photo from the photo library causes a crash.
 
## Changes in 0.6.14 (2018-04-20)

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

## Changes in 0.6.13 (2018-03-30)

Improvements:
 * Upgrade MatrixKit version (v0.7.9).
 * Make state event redaction handling gentler with homeserver (vector-im/riot-ios#1823).

Bug fixes:
 * Room summary is not updated after redaction of the room display name (vector-im/riot-ios#1822). 

## Changes in 0.6.12 (2018-03-12)

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
 
## Changes in 0.6.11 (2018-02-27)

Improvements:
 * Upgrade MatrixKit version (v0.7.7).

Bug Fix:
 * My communities screen is empty despite me being in several groups (#1792).

## Changes in 0.6.10 (2018-02-14)

Improvements:
 * Upgrade MatrixKit version (v0.7.6).
 * Group Details: Put the name of the community in the title.

Bug Fix:
 * App crashes on cold start if no account is defined.
 * flair labels are a bit confusing (#1772).

## Changes in 0.6.9 (2018-02-10)

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

## Changes in 0.6.8 (2018-01-03)

Improvements:
 * AppDelegate: Enable log to file earlier.

Bug Fix:
 * AppDelegate: Disable again loop on [application isProtectedDataAvailable] because it sometimes makes an OS watchdog kill the app.
 * Missing Push Notifications (#1696): Show a notification even if the app fails to sync with its hs.

## Changes in 0.6.7 (2017-12-27)

Improvements:
 * Upgrade MatrixKit version (v0.7.4).

Bug Fix:
 * Share extension is not localized? (#1701).
 * Widget: Fix crash with unexpected widget data (#1703).
 * Silent crash at startup in [MXKContactManager loadCachedMatrixContacts] (#1711).
 * Should fix missing push notifications (#1696).
 * Should fix the application crash on "Failed to grow buffer" when loading local phonebook contacts (https://github.com/matrix-org/riot-ios-rageshakes/issues/779).

## Changes in 0.6.6 (2017-12-21)

Bug Fix:
 * Widget: Integrate widget data into widget URL (https://github.com/vector-im/riot-meta/issues/125).
 * VoIP: increase call invite lifetime from 30 to 60s (https://github.com/vector-im/riot-meta/issues/129).

## Changes in 0.6.5 (2017-12-19)

Bug Fix:
 * Push Notifications: Missing push notifications (#1696).

## Changes in 0.6.4 (2017-12-05)

Bug Fix:
 * Crypto: The share key dialog can appear with a 'null' device (#1683).

## Changes in 0.6.3 (2017-11-30)

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

## Changes in 0.6.2 (2017-11-13)

Improvements:
 * Upgrade MatrixKit version (v0.7.2).

Bug Fix:
 * Share extension silently fails on big pics - eg panoramas (#1627).
 * Share extension improvements: display the search input by default,... (#1611).

## Changes in 0.6.1 (2017-10-27)

Improvements:
 * Upgrade MatrixKit version (v0.7.1).
 * Add support for sending messages via Siri in e2e rooms, thanks to @morozkin (PR #1613).

Bug Fix:
 * Jitsi: Crash if the user display name has several components (#1616).
 * CallKit - When I reject or answer a call on one device, it should stop ringing on all other iOS devices (#1618).
 * The Call View Controller is displayed whereas the call has been cancelled.

## Changes in 0.6.0 (2017-10-23)

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

## Changes in 0.5.6 (2017-10-05)

Improvements:
 * Settings: Pin rooms with missed notifs and unread msg by default (PR #1556).

Bug Fix:
 * Fix RAM peak usage when doing an initial sync with large rooms (PR #1553).

## Changes in 0.5.5 (2017-10-04)

Improvements:
 * Rageshake: Add a setting to enable (disable) it (PR #1552).

Bug Fix:
 * Some rooms have gone nameless after upgrade (PR #1551).

## Changes in 0.5.4 (2017-10-03)

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

## Changes in 0.5.3 (2017-08-25)

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

## Changes in 0.5.2 (2017-08-01)

Improvements:
 * Upgrade MatrixKit version (v0.6.1).
 * Emojis: Boost size of messages containing only emojis (not only one).
 * Bug Report: Make the crash dump appear in GH issues created for crashes

## Changes in 0.5.1 (2017-08-01)

Improvements:
 * Fix a build issue that appeared after merging to master.

## Changes in 0.5.0 (2017-08-01)

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

## Changes in 0.4.3 (2017-07-05)

Improvement:
 * Update the application title with "Riot.im".


## Changes in 0.4.2 (2017-06-30)

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

## Changes in 0.4.1 (2017-06-23)

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

## Changes in 0.4.0 (2017-06-16)

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

## Changes in 0.3.13 (2017-03-23)

Improvements:
 * Upgrade MatrixKit version (v0.4.11).
 
Bug fixes:
 * Chat screen: image thumbnails management is broken (#1121).
 * Image viewer repeatedly loses overlay menu (#1109).

## Changes in 0.3.12 (2017-03-21)

Improvements:
 * Upgrade MatrixKit version (v0.4.10).
 
Bug fixes: 
 * Registration with email failed when the email address is validated on the mobile phone.
 * Chat screen - The missed discussions badge is missing in the navigation bar.


## Changes in 0.3.11 (2017-03-16)

Improvements:
 * Upgrade MatrixKit version (v0.4.9).
 * Crypto: manage unknown devices when placing or answering a call (#1058).
 
Bug fixes: 
 * [Direct Chat] No placeholder avatar and display name from the member details view (#923).
 * MSIDSN registration.
 * [Tablet / split mode] The room member details page is not popped after signing out (#1062).

## Changes in 0.3.10 (2017-03-10)

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

## Changes in 0.3.9 (2017-02-08)

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

## Changes in 0.3.8 (2017-01-24)

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

## Changes in 0.3.7 (2017-01-19)

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

## Changes in 0.3.6 (2016-12-23)

Improvements:
 * Add descriptions for access permissions to Camera, Microphone, Photo Gallery and Contacts.

## Changes in 0.3.5 (2016-12-19)

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

## Changes in 0.3.4 (2016-11-23)

Improvements:
 * Upgrade MatrixKit version (v0.4.3).
 * Settings: User Settings: List user's devices and add the ability to rename or delete them.
 
Bug fixes:
 * User settings: The toggle buttons are disabled by mistake.
 * Typing indicator should stop when the user sends his message (https://github.com/vector-im/vector-ios#809).
 * Crypto: Do not allow to redact the event that enabled encryption in a room.
 * Crypto: Made attachments work better cross platform.

## Changes in 0.3.3 (2016-11-22)

Improvements:
 * Upgrade MatrixKit version (v0.4.2).
 * Settings: Add cryptography information.
 
Bug fixes:
 * Crypto: Do not allow to redact the event that enabled encryption in a room.

## Changes in 0.3.2 (2016-11-18)

Improvements:
 * Upgrade MatrixKit version (v0.4.1).
 
Bug fixes:
 * Make share/save/copy work for e2e attachments.
 * Wrong thumbnail shown whilst uploading e2e image  (https://github.com/vector-im/vector-ios#795).
 * [Register flow] Register with a mail address fails (https://github.com/vector-im/vector-ios#799).

## Changes in 0.3.1 (2016-11-17)

Bug fixes:
 * Fix padlock icons on text messages.
 * Fix a random crash when uploading an e2e attachment.

## Changes in 0.3.0 (2016-11-17)

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

## Changes in 0.2.3 (2016-09-30)

Improvements:
 * Upgrade MatrixKit version (v0.3.19).
 * RoomSearchDataSource: Remove the matrix session from the parameters in `initWithRoomDataSource` API.
 * Enhance the messages search display.
 
Bug fixes:
 * App crashes when user taps on room alias with multiple # in chat history #668.
 * Room message search: the message date & time are not displayed #361.
 * Room message search: the search pattern is not highlighted in results #660.

## Changes in 0.2.2 (2016-09-27)

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

## Changes in 0.2.1 (2016-09-15)

Bug fixes:
 * Use Apple version for T&C.
 * Revert the default IS.

## Changes in 0.2.0 (2016-09-15)

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

## Changes in Vector iOS in 0.1.17 (2016-09-08)

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

## Changes in Vector iOS in 0.1.16 (2016-08-25)

Improvements:
 * Upgrade MatrixKit version (v0.3.15).

Bug fixes:
 * Rooms list: Fix crash when computing recents.
 * Settings: Fix crash when logging out.

## Changes in Vector iOS in 0.1.15 (2016-08-25)

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
 
## Changes in Vector iOS in 0.1.14 (2016-08-01)

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

## Changes in Vector iOS in 0.1.13 (2016-07-26)

Improvements:
 * Upgrade MatrixKit version (v0.3.12).
 * Enable VoIP for 1:1 room #454.
 
Bug fixes:
 * Confirmation prompt before opping someone to same power level #461.
 * Room Settings: The room privacy setting text doesn't fit in phone mode #429.

## Changes in Vector iOS in 0.1.12 (2016-07-15)

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

## Changes in Vector iOS in 0.1.11 (2016-07-01)

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

## Changes in Vector iOS in 0.1.10 (2016-06-04)

Improvements:
 * Directory section is displayed by default in Messages when recents list is empty.
 * Support GA services #335.
 * Room Participants: Increase the search field from 44px to 50px high to give it slightly more prominence.
 * Room Participants - Search bar: Adjust green separator to make it more obviously tappable and less like a header.

## Changes in Vector iOS in 0.1.9 (2016-06-02)

Improvements:
 * Upgrade MatrixKit version (v0.3.9).
 * Remove the 'optional' in the email registration field #352.
 * Restore matrix.org as default homeserver.

Bug fixes:
 * Directory item in search doesn't open the directory if I don't search #353.
 * Room avatars on matrix.org are badly rendered in the directory from a vector.im account #355.
 * Authentication: "Send Reset Email" is truncated on iPhone 4S.

## Changes in Vector iOS in 0.1.8 (2016-06-01)

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

## Changes in Vector iOS in 0.1.6 (2016-05-04)

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

## Changes in Vector iOS in 0.1.5 (2016-04-27)

Improvements:
 * Chat Screen: Ability to copy event permalinks into the pasteboard from the edit menu #225

Bug fixes:
 * Fix crash when rotating 6+ or iPad at app start-up.
 * Universal link on an unjoined room + an event iD is not properly managed #246.

## Changes in Vector iOS in 0.1.4 (2016-04-26)

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

## Changes in Vector iOS in 0.1.3 (2016-04-08)

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

## Changes in Vector iOS in 0.1.2 (2016-03-17)

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

## Changes in Vector iOS in 0.1.1 (2016-03-07)

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

## Changes in Vector iOS in 0.1.0 (2016-01-29)

 * Upgrade MatrixKit version (v0.3.1).
 * Implement Visual Design v1.3 (80% done).

## Changes in Vector iOS in 0.0.1 (2015-11-16)

 * Creation : The first implementation of Vector application based on Matrix iOS Kit v0.2.7.
