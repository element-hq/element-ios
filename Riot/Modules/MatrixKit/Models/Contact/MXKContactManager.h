/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>
#import <Contacts/Contacts.h>

#import <MatrixSDK/MatrixSDK.h>

#import "MXKSectionedContacts.h"
#import "MXKContact.h"

/**
 Posted when the matrix contact list is loaded or updated.
 The notification object is:
 - a contact Id when a matrix contact has been added/updated/removed.
 or
 - nil when all matrix contacts are concerned.
 */
extern NSString * _Nonnull const kMXKContactManagerDidUpdateMatrixContactsNotification;

/**
 Posted when the local contact list is loaded and updated.
 The notification object is:
 - a contact Id when a local contact has been added/updated/removed.
 or
 - nil when all local contacts are concerned.
 */
extern NSString * _Nonnull const kMXKContactManagerDidUpdateLocalContactsNotification;

/**
 Posted when local contact matrix ids is updated.
 The notification object is:
 - a contact Id when a local contact has been added/updated/removed.
 or
 - nil when all local contacts are concerned.
 */
extern NSString * _Nonnull const kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification;

/**
 Posted when the presence of a matrix user linked at least to one contact has changed.
 The notification object is the matrix Id. The `userInfo` dictionary contains an `MXPresenceString` object under the `kMXKContactManagerMatrixPresenceKey` key, representing the matrix user presence.
 */
extern NSString * _Nonnull const kMXKContactManagerMatrixUserPresenceChangeNotification;
extern NSString * _Nonnull const kMXKContactManagerMatrixPresenceKey;

/**
 Posted when all phonenumbers of local contacts have been internationalized.
 The notification object is nil.
 */
extern NSString * _Nonnull const kMXKContactManagerDidInternationalizeNotification;

/**
 Used to identify the type of data when requesting MXKeyProvider
 */
extern NSString * _Nonnull const MXKContactManagerDataType;

/**
 Define the contact creation for the room members
 */
typedef NS_ENUM(NSInteger, MXKContactManagerMXRoomSource) {
    MXKContactManagerMXRoomSourceNone        = 0,   // the MXMember does not create any new contact.
    MXKContactManagerMXRoomSourceDirectChats = 1,   // the direct chat users have their own contact even if they are not defined in the device contacts book
    MXKContactManagerMXRoomSourceAll         = 2,   // all the room members have their own contact even if they are not defined in the device contacts book
};

/**
 This manager handles 2 kinds of contact list:
 - The local contacts retrieved from the device phonebook.
 - The matrix contacts retrieved from the matrix one-to-one rooms.
 
 Note: The local contacts handling depends on the 'syncLocalContacts' and 'phonebookCountryCode' properties
 of the shared application settings object '[MXKAppSettings standardAppSettings]'.
 */
@interface MXKContactManager : NSObject

/**
 The shared instance of contact manager.
 */
+ (MXKContactManager* _Nonnull)sharedManager;

/**
 Block called (if any) to discover the Matrix users bound to a set of third-party identifiers (email addresses, phone numbers).
 If this property is unset, the contact manager will consider the potential identity server URL (see the `identityServer` property)
 to build its own Restclient and trigger `lookup3PIDs` requests.
 
 @param threepids the list of 3rd party ids: [[<(MX3PIDMedium)media1>, <(NSString*)address1>], [<(MX3PIDMedium)media2>, <(NSString*)address2>], ...].
 @param success a block object called when the operation succeeds. It provides the array of the discovered users:
 [[<(MX3PIDMedium)media>, <(NSString*)address>, <(NSString*)userId>], ...].
 @param failure a block object called when the operation fails.
 */
typedef void(^MXKContactManagerDiscoverUsersBoundTo3PIDs)(NSArray<NSArray<NSString *> *> * _Nonnull threepids,
                                                          void (^ _Nonnull success)(NSArray<NSArray<NSString *> *> *_Nonnull),
                                                          void (^ _Nonnull failure)(NSError *_Nonnull));
@property (nonatomic, nullable) MXKContactManagerDiscoverUsersBoundTo3PIDs discoverUsersBoundTo3PIDsBlock;

/**
 Define if the room member must have their dedicated contact even if they are not define in the device contacts book.
 The default value is MXKContactManagerMXRoomSourceDirectChats;
 */
@property (nonatomic) MXKContactManagerMXRoomSource contactManagerMXRoomSource;

/**
 Associated matrix sessions (empty by default).
 */
@property (nonatomic, readonly, nonnull) NSArray *mxSessions;

/**
 The current list of the contacts extracted from matrix data. Depends on 'contactManagerMXRoomSource'.
 */
@property (nonatomic, readonly, nullable) NSArray *matrixContacts;

/**
 The current list of the local contacts (nil by default until the contacts are loaded).
 */
@property (nonatomic, readonly, nullable) NSArray *localContacts;

/**
 The current list of the local contacts who have contact methods which can be used to invite them or to discover matrix users.
 */
@property (nonatomic, readonly, nullable) NSArray *localContactsWithMethods;

/**
 The contacts list obtained by splitting each local contact by contact method.
 This list is alphabetically sorted.
 Each contact has one and only one contact method.
 */
//- (void)localContactsSplitByContactMethod:(void (^)(NSArray<MXKContact*> *localContactsSplitByContactMethod))onComplete;

@property (nonatomic, readonly, nullable) NSArray *localContactsSplitByContactMethod;

/**
 The current list of the contacts for whom a direct chat exists.
 */
@property (nonatomic, readonly, nonnull) NSArray *directMatrixContacts;

/// Flag to allow local contacts access or not. Default value is YES.
@property (nonatomic, assign) BOOL allowLocalContactsAccess;

/**
 Add/remove matrix session. The matrix contact list is automatically updated (see kMXKContactManagerDidUpdateMatrixContactsNotification event).
 */
- (void)addMatrixSession:(MXSession* _Nonnull)mxSession;
- (void)removeMatrixSession:(MXSession* _Nonnull)mxSession;

/**
 Takes into account the state of the identity service's terms, local contacts access authorization along with
 whether the user has left the app for the Settings app to update the contacts access, and enables/disables
 the `syncLocalContacts` property of `MXKAppSettings` when necessary.
 @param mxSession The session who's identity service shall be used.
 */
- (void)validateSyncLocalContactsStateForSession:(MXSession *)mxSession;

/**
 Load and/or refresh the local contacts. Observe kMXKContactManagerDidUpdateLocalContactsNotification to know when local contacts are available.
 */
- (void)refreshLocalContacts;

/**
 Delete contacts info
 */
- (void)reset;

/**
 Get contact by its identifier.
 
 @param contactID the contact identifier.
 @return the contact defined with the provided id.
 */
- (MXKContact* _Nullable)contactWithContactID:(NSString* _Nonnull)contactID;

/**
 Refresh matrix IDs for a specific local contact. See kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification
 posted when update is done.
 
 @param contact the local contact to refresh.
 */
- (void)updateMatrixIDsForLocalContact:(MXKContact* _Nonnull)contact;

/**
 Refresh matrix IDs for all local contacts. See kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification
 posted when update for all local contacts is done.
 */
- (void)updateMatrixIDsForAllLocalContacts;

/**
 The contacts list obtained by splitting each local contact by contact method.
 This list is alphabetically sorted.
 Each contact has one and only one contact method.
 */
//- (void)localContactsSplitByContactMethod:(void (^)(NSArray<MXKContact*> *localContactsSplitByContactMethod))onComplete;

/**
 Sort a contacts array in sectioned arrays to be displayable in a UITableview
 */
- (MXKSectionedContacts* _Nullable)getSectionedContacts:(NSArray* _Nonnull)contactList;

/**
 Sort alphabetically an array of contacts.
 
 @param contactsArray the array of contacts to sort.
 */
- (void)sortAlphabeticallyContacts:(NSMutableArray<MXKContact*> * _Nonnull)contactsArray;

/**
 Sort an array of contacts by last active, with "active now" first.
 ...and then alphabetically.
 
 @param contactsArray the array of contacts to sort.
 */
- (void)sortContactsByLastActiveInformation:(NSMutableArray<MXKContact*> * _Nonnull)contactsArray;

/**
 Refresh the international phonenumber of the local contacts (See kMXKContactManagerDidInternationalizeNotification).
 
 @param countryCode the country code.
 */
- (void)internationalizePhoneNumbers:(NSString* _Nonnull)countryCode;

/**
 Request user permission for syncing local contacts.

 @param viewController the view controller to attach the dialog to the user.
 @param handler the block called with the result of requesting access
 */
+ (void)requestUserConfirmationForLocalContactsSyncInViewController:(UIViewController* _Nonnull)viewController
                                                  completionHandler:(void (^_Nonnull)(BOOL granted))handler;

@end
