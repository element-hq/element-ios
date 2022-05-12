/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
    return roomSummary.displayname;
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
