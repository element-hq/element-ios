/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRecentCellData.h"

@import MatrixSDK;

#import "MXKDataSource.h"
#import "MXEvent+MatrixKit.h"

#import "MXKSwiftHeader.h"

@implementation MXKRecentCellData
@synthesize roomSummary, dataSource, lastEventDate;

- (instancetype)initWithRoomSummary:(id<MXRoomSummaryProtocol>)theRoomSummary
                         dataSource:(MXKDataSource*)theDataSource;
{
    self = [self init];
    if (self)
    {
        roomSummary = theRoomSummary;
        dataSource = theDataSource;
    }
    return self;
}

- (void)dealloc
{
    roomSummary = nil;
}

- (MXSession *)mxSession
{
    MXSession *session = dataSource.mxSession;
    
    if (session == nil)
    {
        session = roomSummary.mxSession;
    }
    
    return session;
}

- (NSString*)lastEventDate
{
    return (NSString*)roomSummary.lastMessage.others[@"lastEventDate"];
}

- (BOOL)hasUnread
{
    return (roomSummary.localUnreadEventCount != 0);
}

- (BOOL)isRoomMarkedAsUnread
{
    return [[self mxSession] isRoomMarkedAsUnread:roomSummary.roomId];;
}

- (NSString *)roomIdentifier
{
    if (self.isSuggestedRoom)
    {
        return self.roomSummary.spaceChildInfo.childRoomId;
    }
    return roomSummary.roomId;
}

- (NSString *)roomDisplayname
{
    if (self.isSuggestedRoom)
    {
        return self.roomSummary.spaceChildInfo.displayName;
    }
    return roomSummary.displayName;
}

- (NSString *)avatarUrl
{
    if (self.isSuggestedRoom)
    {
        return self.roomSummary.spaceChildInfo.avatarUrl;
    }
    return roomSummary.avatar;
}

- (NSString *)directUserId
{
    return self.roomSummary.directUserId;
}

- (MXPresence)presence
{
    if (self.roomSummary.isDirect)
    {
        MXUser *contact = [self.mxSession userWithUserId:self.roomSummary.directUserId];
        return contact.presence;
    }
    else
    {
        return MXPresenceUnknown;
    }
}

- (NSString *)lastEventTextMessage
{
    if (self.isSuggestedRoom)
    {
        return roomSummary.spaceChildInfo.topic;
    }
    return roomSummary.lastMessage.text;
}

- (NSAttributedString *)lastEventAttributedTextMessage
{
    if (self.isSuggestedRoom)
    {
        return nil;
    }
    return roomSummary.lastMessage.attributedText;
}

- (NSUInteger)notificationCount
{
    return roomSummary.notificationCount;
}

- (NSUInteger)highlightCount
{
    return roomSummary.highlightCount;
}

- (NSString*)notificationCountStringValue
{
    return [NSString stringWithFormat:@"%tu", self.notificationCount];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ %@: %@ - %@", super.description, self.roomSummary.roomId, self.roomDisplayname, self.lastEventTextMessage];
}

- (BOOL)isSuggestedRoom
{
    // As off now, we only store MXSpaceChildInfo in case of suggested rooms
    return self.roomSummary.spaceChildInfo != nil;
}

@end
