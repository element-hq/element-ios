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
