Changes in Vector iOS in 0.1.6 (2016-05-04)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.3.7).
 * Room member details: Order members by power levels (me, admins then moderators then others).
 * Room member details: Sort members with the same algo as Vector web client.
 * Universal link: Add www.vector.im as associated domain.
 * Chat screen: Open member details on tap-on-avatar #294.

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