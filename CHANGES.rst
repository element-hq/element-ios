Changes in Console in 0.5.5 (2015-11-06)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.2.5).
 * APNS handling: APNS registration is forced only at the first launch. 
 * Fix screen flickering on logout.
 * AppDelegate: Handle unrecognized certificates by prompting user during authentication challenge.
 * Allow Chrome to be set as the default link handler.
 * SettingsViewController: reload table view only when it is visible.

Bug fixes:
 * HomeViewController: Public room selection is ignored during search session.

Changes in Console in 0.5.4 (2015-10-14)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.2.4): fix App crash on iOS 9.

Changes in Console in 0.5.3 (2015-09-14)
===============================================

Improvements:
 * Upgrade MatrixKit version (v0.2.3).

Bug fixes:
 * Bug Fix: App crashes on iPad iOS7.

Changes in Console in 0.5.2 (2015-08-13)
===============================================

 * Upgrade MatrixKit version (v0.2.2).

Changes in Console in 0.5.1 (2015-08-10)
===============================================

Improvements:
 * Add localized strings (see MatrixConsole.strings)
 * Error handling: Alert user on MatrixKit error.
 * RecentsViewController: release the current room resources when user selects another room.

Bug fixes:
 * Bug Fix: Settings - The slider related to the maximum cache size is not working.
 * Bug Fix: Settings - The user is logged out when he press "Clear cache" button.

Changes in Console in 0.5.0 (2015-07-10)
===============================================

Improvements:
 * Update Console by applying MatrixKit changes (see Changes in 0.2.0).
 * Support multi-sessions.
 * Multi-session handling: Prompt user to select an account before starting
   chat with someone.
 * Multi-session handling: Recents are interleaved.

Bug fixes:
 * Bug Fix "grey-stuck-can't-click recent bug". The selected room was not
   reset correctly.
 * Room view controller: remove properly members listener.
 * Memory leaks: Dispose properly view controller resources.
 * Bug Fix: RoomViewController - Clicking on the user in the chat room
   displays the user's details but not his avatar.
 * RageShakeManager: Check whether the user can send email before prompting
   him.

Changes in Console in 0.4.0 (2015-04-23)
===============================================

Improvements:
 * Console has its own git repository.
 * Integration of MatrixKit. Most part of the code of Console-pre-0.4.0 has
   been redesigned and moved to MatrixKit.
 * Stability. MatrixKit better seperates model and viewcontroller which fixes
   random multithreading issues Console encountered.
 * Room page: unsent messages are no more lost when the user changes the room
 

Changes in Matrix iOS Console in 0.3.2 and before
=================================================
Console was hosted in the Matrix iOS SDK GitHub repository.
Changes for these versions can be found here:
https://github.com/matrix-org/matrix-ios-sdk/blob/v0.3.2/CHANGES.rst





