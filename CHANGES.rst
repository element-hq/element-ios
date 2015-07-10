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





