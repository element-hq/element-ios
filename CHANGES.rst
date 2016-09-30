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