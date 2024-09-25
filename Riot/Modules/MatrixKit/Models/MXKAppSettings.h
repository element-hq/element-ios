/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */
#import <MatrixSDK/MatrixSDK.h>

typedef NS_ENUM(NSUInteger, MXKKeyPreSharingStrategy)
{
    MXKKeyPreSharingNone = 0,
    MXKKeyPreSharingWhenEnteringRoom = 1,
    MXKKeyPreSharingWhenTyping = 2
};

/**
 `MXKAppSettings` represents the application settings. Most of them are used to handle matrix session data.
 
 The shared object `standardAppSettings` provides the default application settings defined in `standardUserDefaults`.
 Any property change of this shared settings is reported into `standardUserDefaults`.
 
 Developper may define their own `MXKAppSettings` instances to handle specific setting values without impacting the shared object.
 */
@interface MXKAppSettings : NSObject

#pragma mark - /sync filter

/**
 Lazy load room members when /syncing with the homeserver.
 */
@property (nonatomic) BOOL syncWithLazyLoadOfRoomMembers;

#pragma mark - Room display

/**
 Display all received events in room history (Only recognized events are displayed, presently `custom` events are ignored).
 
 This boolean value is defined in shared settings object with the key: `showAllEventsInRoomHistory`.
 Return NO if no value is defined.
 */
@property (nonatomic) BOOL showAllEventsInRoomHistory;

/**
 The types of events allowed to be displayed in room history.
 Its value depends on `showAllEventsInRoomHistory`.
 */
@property (nonatomic, readonly) NSArray<MXEventTypeString> *eventsFilterForMessages;

/**
 All the event types which may be displayed in the room history.
 */
@property (nonatomic, readonly) NSArray<MXEventTypeString> *allEventTypesForMessages;

/**
 An allow list for the types of events allowed to be displayed as the last message.
 
 When `nil`, there is no list and all events are allowed.
 */
@property (nonatomic, readonly) NSArray<MXEventTypeString> *lastMessageEventTypesAllowList;

/**
 Add event types to `eventsFilterForMessages` and `eventsFilterForMessages`.
 
 @param eventTypes the event types to add.
 */
- (void)addSupportedEventTypes:(NSArray<MXEventTypeString> *)eventTypes;

/**
 Remove event types from `eventsFilterForMessages` and `eventsFilterForMessages`.

 @param eventTypes the event types to remove.
 */
- (void)removeSupportedEventTypes:(NSArray<MXEventTypeString> *)eventTypes;

/**
 Display redacted events in room history.
 
 This boolean value is defined in shared settings object with the key: `showRedactionsInRoomHistory`.
 Return NO if no value is defined.
 */
@property (nonatomic) BOOL showRedactionsInRoomHistory;

/**
 Display unsupported/unexpected events in room history.
 
 This boolean value is defined in shared settings object with the key: `showUnsupportedEventsInRoomHistory`.
 Return NO if no value is defined.
 */
@property (nonatomic) BOOL showUnsupportedEventsInRoomHistory;

/**
 Scheme with which to open HTTP links. e.g. if this is set to "googlechrome", any http:// links displayed in a room will be rewritten to use the googlechrome:// scheme.
 Defaults to "http".
 */
@property (nonatomic) NSString *httpLinkScheme;

/**
 Scheme with which to open HTTPS links. e.g. if this is set to "googlechromes", any https:// links displayed in a room will be rewritten to use the googlechromes:// scheme.
 Defaults to "https".
 */
@property (nonatomic) NSString *httpsLinkScheme;

/**
 Whether a bubble component should detect the first link in its event's body, storing it in the `link` property.
 
 This boolean value is defined in shared settings object with the key: `enableBubbleComponentLinkDetection`.
 Return NO if no value is defined.
 */
@property (nonatomic) BOOL enableBubbleComponentLinkDetection;

/**
 Any hosts that should be ignored when calling `mxk_firstURLDetected` on an `NSString` without passing in any parameters.
 Customising this value modifies the behaviour of link detection in `MXKRoomBubbleComponent`.
 
 This boolean value is defined in shared settings object with the key: `firstURLDetectionIgnoredHosts`.
 The default value of this property only contains the matrix.to host.
 */
@property (nonatomic) NSArray<NSString *> *firstURLDetectionIgnoredHosts;

/**
 Indicate to hide un-decryptable events before joining the room. Default is `NO`.
 */
@property (nonatomic) BOOL hidePreJoinedUndecryptableEvents;

/**
 Indicate to hide un-decryptable events in the room. Default is `NO`.
 */
@property (nonatomic) BOOL hideUndecryptableEvents;

/**
 Indicates the strategy for sharing the outbound session key to other devices of the room
 */
@property (nonatomic) MXKKeyPreSharingStrategy outboundGroupSessionKeyPreSharingStrategy;

#pragma mark - Room members

/**
 Sort room members by considering their presence.
 Set NO to sort members in alphabetic order.
 
 This boolean value is defined in shared settings object with the key: `sortRoomMembersUsingLastSeenTime`.
 Return YES if no value is defined.
 */
@property (nonatomic) BOOL sortRoomMembersUsingLastSeenTime;

/**
 Show left members in room member list.
 
 This boolean value is defined in shared settings object with the key: `showLeftMembersInRoomMemberList`.
 Return NO if no value is defined.
 */
@property (nonatomic) BOOL showLeftMembersInRoomMemberList;

/// Flag to allow sharing a message or not. Default value is YES.
@property (nonatomic) BOOL messageDetailsAllowSharing;

/// Flag to allow saving a message or not. Default value is YES.
@property (nonatomic) BOOL messageDetailsAllowSaving;

/// Flag to allow copying a media/file or not. Default value is YES.
@property (nonatomic) BOOL messageDetailsAllowCopyingMedia;

/// Flag to allow pasting a media/file or not. Default value is YES.
@property (nonatomic) BOOL messageDetailsAllowPastingMedia;

#pragma mark - Contacts

/**
 Return YES if the user allows the local contacts sync.
 
 This boolean value is defined in shared settings object with the key: `syncLocalContacts`.
 Return NO if no value is defined.
 */
@property (nonatomic) BOOL syncLocalContacts;

/**
 Return YES if the user has been already asked for local contacts sync permission.

 This boolean value is defined in shared settings object with the key: `syncLocalContactsPermissionRequested`.
 Return NO if no value is defined.
 */
@property (nonatomic) BOOL syncLocalContactsPermissionRequested;

/**
 Return YES if after the user has been asked for local contacts sync permission and choose to open
 the system's Settings app to enable contacts access.

 This boolean value is defined in shared settings object with the key: `syncLocalContactsPermissionOpenedSystemSettings`.
 Return NO if no value is defined.
 */
@property (nonatomic) BOOL syncLocalContactsPermissionOpenedSystemSettings;

/**
 The current selected country code for the phonebook.
 
 This value is defined in shared settings object with the key: `phonebookCountryCode`.
 Return the SIM card information (if any) if no default value is defined.
 */
@property (nonatomic) NSString* phonebookCountryCode;


#pragma mark - Matrix users

/**
 Color associated to online matrix users.
 
 This color value is defined in shared settings object with the key: `presenceColorForOnlineUser`.
 The default color is `[UIColor greenColor]`.
 */
@property (nonatomic) UIColor *presenceColorForOnlineUser;

/**
 Color associated to unavailable matrix users.
 
 This color value is defined in shared settings object with the key: `presenceColorForUnavailableUser`.
 The default color is `[UIColor yellowColor]`.
 */
@property (nonatomic) UIColor *presenceColorForUnavailableUser;

/**
 Color associated to offline matrix users.
 
 This color value is defined in shared settings object with the key: `presenceColorForOfflineUser`.
 The default color is `[UIColor redColor]`.
 */
@property (nonatomic) UIColor *presenceColorForOfflineUser;

#pragma mark - Notifications

/// Flag to allow PushKit pushers or not. Default value is `NO`.
@property (nonatomic, assign) BOOL allowPushKitPushers;

/**
 A localization key used when registering the default notification payload.
 This key will be translated and displayed for APNS notifications as the body
 content, unless it is modified locally by a Notification Service Extension.
 
 The default value for this setting is "MESSAGE". Changes are *not* persisted.
 Updating the value after MXKAccount has called `enableAPNSPusher:success:failure:`
 will have no effect.
 */
@property (nonatomic) NSString *notificationBodyLocalizationKey;

#pragma mark - Calls

/**
 Return YES if the user enable CallKit support.
 
 This boolean value is defined in shared settings object with the key: `enableCallKit`.
 Return YES if no value is defined.
 */
@property (nonatomic, getter=isCallKitEnabled) BOOL enableCallKit;

#pragma mark - Shared userDefaults

/**
 A userDefaults object that is shared within the application group. The application group identifier
 is retrieved from MXSDKOptions sharedInstance (see `applicationGroupIdentifier` property).
 The default group is "group.org.matrix".
 */
@property (nonatomic, readonly) NSUserDefaults *sharedUserDefaults;

#pragma mark - Class methods

/**
 Return the shared application settings object. These settings are retrieved/stored in the shared defaults object (`[NSUserDefaults standardUserDefaults]`).
 */
+ (MXKAppSettings *)standardAppSettings;

/**
 Return the folder to use for caching MatrixKit data.
 */
+ (NSString*)cacheFolder;

/**
 Restore the default values.
 */
- (void)reset;

@end
