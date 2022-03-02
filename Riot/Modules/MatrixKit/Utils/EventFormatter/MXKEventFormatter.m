/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd

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

#import "MXKEventFormatter.h"

@import MatrixSDK;
@import DTCoreText;

#import "MXEvent+MatrixKit.h"
#import "NSBundle+MatrixKit.h"
#import "MXKSwiftHeader.h"
#import "MXKTools.h"
#import "MXRoom+Sync.h"

#import "MXKRoomNameStringLocalizer.h"

static NSString *const kHTMLATagRegexPattern = @"<a href=\"(.*?)\">([^<]*)</a>";

@interface MXKEventFormatter ()
{
    /**
     The default CSS converted in DTCoreText object.
     */
    DTCSSStylesheet *dtCSS;

    /**
     Links detector in strings.
     */
    NSDataDetector *linkDetector;
}
@end

@implementation MXKEventFormatter

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [super init];
    if (self)
    {
        mxSession = matrixSession;

        [self initDateTimeFormatters];

        // Use the same list as matrix-react-sdk ( https://github.com/matrix-org/matrix-react-sdk/blob/24223ae2b69debb33fa22fcda5aeba6fa93c93eb/src/HtmlUtils.js#L25 )
        _allowedHTMLTags = @[
                             @"font", // custom to matrix for IRC-style font coloring
                             @"del", // for markdown
                             @"body", // added internally by DTCoreText
                             @"mx-reply",
                             @"h1", @"h2", @"h3", @"h4", @"h5", @"h6", @"blockquote", @"p", @"a", @"ul", @"ol",
                             @"nl", @"li", @"b", @"i", @"u", @"strong", @"em", @"strike", @"code", @"hr", @"br", @"div",
                             @"table", @"thead", @"caption", @"tbody", @"tr", @"th", @"td", @"pre"
                             ];

        self.defaultCSS = @" \
            pre,code { \
                background-color: #eeeeee; \
                display: inline; \
                font-family: monospace; \
                white-space: pre; \
                -coretext-fontname: Menlo-Regular; \
                font-size: small; \
            } \
            h1,h2 { \
                font-size: 1.2em; \
            }"; // match the size of h1/h2 to h3 to stop people shouting.

        // Set default colors
        _defaultTextColor = [UIColor blackColor];
        _subTitleTextColor = [UIColor blackColor];
        _prefixTextColor = [UIColor blackColor];
        _bingTextColor = [UIColor blueColor];
        _encryptingTextColor = [UIColor lightGrayColor];
        _sendingTextColor = [UIColor lightGrayColor];
        _errorTextColor = [UIColor redColor];
        _htmlBlockquoteBorderColor = [MXKTools colorWithRGBValue:0xDDDDDD];
        
        _defaultTextFont = [UIFont systemFontOfSize:14];
        _prefixTextFont = [UIFont systemFontOfSize:14];
        _bingTextFont = [UIFont systemFontOfSize:14];
        _stateEventTextFont = [UIFont italicSystemFontOfSize:14];
        _callNoticesTextFont = [UIFont italicSystemFontOfSize:14];
        _encryptedMessagesTextFont = [UIFont italicSystemFontOfSize:14];
        
        _eventTypesFilterForMessages = nil;

        // Consider the shared app settings by default
        _settings = [MXKAppSettings standardAppSettings];

        defaultRoomSummaryUpdater = [MXRoomSummaryUpdater roomSummaryUpdaterForSession:matrixSession];
        defaultRoomSummaryUpdater.lastMessageEventTypesAllowList = MXKAppSettings.standardAppSettings.lastMessageEventTypesAllowList;
        defaultRoomSummaryUpdater.ignoreRedactedEvent = !_settings.showRedactionsInRoomHistory;
        defaultRoomSummaryUpdater.roomNameStringLocalizer = [MXKRoomNameStringLocalizer new];

        linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        
        _markdownToHTMLRenderer = [MarkdownToHTMLRendererHardBreaks new];
    }
    return self;
}

- (void)initDateTimeFormatters
{
    // Prepare internal date formatter
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]]];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    // Set default date format
    [dateFormatter setDateFormat:@"MMM dd"];
    
    // Create a time formatter to get time string by considered the current system time formatting.
    timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
}

#pragma mark - Event formatter settings

// Checks whether the event is related to an attachment and if it is supported
- (BOOL)isSupportedAttachment:(MXEvent*)event
{
    BOOL isSupportedAttachment = NO;
    
    if (event.eventType == MXEventTypeRoomMessage)
    {
        NSString *msgtype;
        MXJSONModelSetString(msgtype, event.content[@"msgtype"]);
        
        NSString *urlField;
        NSDictionary *fileField;
        MXJSONModelSetString(urlField, event.content[@"url"]);
        MXJSONModelSetDictionary(fileField, event.content[@"file"]);
        
        BOOL hasUrl = urlField.length;
        BOOL hasFile = NO;
        
        if (fileField)
        {
            NSString *fileUrlField;
            MXJSONModelSetString(fileUrlField, fileField[@"url"]);
            NSString *fileIvField;
            MXJSONModelSetString(fileIvField, fileField[@"iv"]);
            NSDictionary *fileHashesField;
            MXJSONModelSetDictionary(fileHashesField, fileField[@"hashes"]);
            NSDictionary *fileKeyField;
            MXJSONModelSetDictionary(fileKeyField, fileField[@"key"]);
            
            hasFile = fileUrlField.length && fileIvField.length && fileHashesField && fileKeyField;
        }
        
        if ([msgtype isEqualToString:kMXMessageTypeImage])
        {
            isSupportedAttachment = hasUrl || hasFile;
        }
        else if ([msgtype isEqualToString:kMXMessageTypeAudio])
        {
            isSupportedAttachment = hasUrl || hasFile;
        }
        else if ([msgtype isEqualToString:kMXMessageTypeVideo])
        {
            isSupportedAttachment = hasUrl || hasFile;
        }
        else if ([msgtype isEqualToString:kMXMessageTypeFile])
        {
            isSupportedAttachment = hasUrl || hasFile;
        }
    }
    else if (event.eventType == MXEventTypeSticker)
    {
        NSString *urlField;
        NSDictionary *fileField;
        MXJSONModelSetString(urlField, event.content[@"url"]);
        MXJSONModelSetDictionary(fileField, event.content[@"file"]);
        
        BOOL hasUrl = urlField.length;
        BOOL hasFile = NO;
        
        // @TODO: Check whether the encrypted sticker uses the same `file dict than other media
        if (fileField)
        {
            NSString *fileUrlField;
            MXJSONModelSetString(fileUrlField, fileField[@"url"]);
            NSString *fileIvField;
            MXJSONModelSetString(fileIvField, fileField[@"iv"]);
            NSDictionary *fileHashesField;
            MXJSONModelSetDictionary(fileHashesField, fileField[@"hashes"]);
            NSDictionary *fileKeyField;
            MXJSONModelSetDictionary(fileKeyField, fileField[@"key"]);
            
            hasFile = fileUrlField.length && fileIvField.length && fileHashesField && fileKeyField;
        }
        
        isSupportedAttachment = hasUrl || hasFile;
    }
    return isSupportedAttachment;
}


#pragma mark event sender/target info

- (NSString*)senderDisplayNameForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState
{
    // Check whether the sender name is updated by the current event. This happens in case of a
    // newly joined member. Otherwise, fall back to the current display name defined in the provided
    // room state (note: this room state is supposed to not take the new event into account).
    return [self userDisplayNameFromContentInEvent:event withMembershipFilter:@"join"] ?: [roomState.members memberName:event.sender];
}

- (NSString*)targetDisplayNameForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState
{
    if (![event.type isEqualToString:kMXEventTypeStringRoomMember])
    {
        return nil; // Non-membership events don't have a target
    }
    return [self userDisplayNameFromContentInEvent:event withMembershipFilter:nil] ?: [roomState.members memberName:event.stateKey];
}

- (NSString*)userDisplayNameFromContentInEvent:(MXEvent*)event withMembershipFilter:(NSString *)filter
{
    NSString* membership;
    MXJSONModelSetString(membership, event.content[@"membership"]);
    NSString* displayname;
    MXJSONModelSetString(displayname, event.content[@"displayname"]);
    
    if (membership && (!filter || [membership isEqualToString:filter]) && [displayname length])
    {
        return displayname;
    }

    return nil;
}

- (NSString*)senderAvatarUrlForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState
{
    // Check whether the avatar URL is updated by the current event. This happens in case of a
    // newly joined member. Otherwise, fall back to the avatar URL defined in the provided room
    // state (note: this room state is supposed to not take the new event into account).
    NSString *avatarUrl = [self userAvatarUrlFromContentInEvent:event withMembershipFilter:@"join"] ?: [roomState.members memberWithUserId:event.sender].avatarUrl;
    
    // Handle here the case where no avatar is defined
    return avatarUrl ?: [self fallbackAvatarUrlForUserId:event.sender];
}

- (NSString*)targetAvatarUrlForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState
{
    if (![event.type isEqualToString:kMXEventTypeStringRoomMember])
    {
        return nil; // Non-membership events don't have a target
    }
    NSString *avatarUrl = [self userAvatarUrlFromContentInEvent:event withMembershipFilter:nil] ?: [roomState.members memberWithUserId:event.stateKey].avatarUrl;
    return avatarUrl ?: [self fallbackAvatarUrlForUserId:event.stateKey];
}

- (NSString*)userAvatarUrlFromContentInEvent:(MXEvent*)event withMembershipFilter:(NSString *)filter
{
    NSString* membership;
    MXJSONModelSetString(membership, event.content[@"membership"]);
    NSString* avatarUrl;
    MXJSONModelSetString(avatarUrl, event.content[@"avatar_url"]);
    
    if (membership && (!filter || [membership isEqualToString:filter]) && [avatarUrl length])
    {
        // We ignore non mxc avatar url
        if ([avatarUrl hasPrefix:kMXContentUriScheme])
        {
            return avatarUrl;
        }
    }
    
    return nil;
}

- (NSString*)fallbackAvatarUrlForUserId:(NSString*)userId {
    if ([MXSDKOptions sharedInstance].disableIdenticonUseForUserAvatar)
    {
        return nil;
    }
    return [mxSession.mediaManager urlOfIdenticon:userId];
}


#pragma mark - Events to strings conversion methods
- (NSString*)stringFromEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState error:(MXKEventFormatterError*)error
{
    NSString *stringFromEvent;
    NSAttributedString *attributedStringFromEvent = [self attributedStringFromEvent:event withRoomState:roomState error:error];
    if (*error == MXKEventFormatterErrorNone)
    {
        stringFromEvent = attributedStringFromEvent.string;
    }

    return stringFromEvent;
}

- (NSAttributedString *)attributedStringFromEvent:(MXEvent *)event withRoomState:(MXRoomState *)roomState error:(MXKEventFormatterError *)error
{
    // Check we can output the error
    NSParameterAssert(error);
    
    *error = MXKEventFormatterErrorNone;
    
    // Filter the events according to their type.
    if (_eventTypesFilterForMessages && ([_eventTypesFilterForMessages indexOfObject:event.type] == NSNotFound))
    {
        // Ignore this event
        return nil;
    }
    
    BOOL isEventSenderMyUser = [event.sender isEqualToString:mxSession.myUserId];
    
    // Check first whether the event has been redacted
    NSString *redactedInfo = nil;
    BOOL isRedacted = event.isRedactedEvent;
    if (isRedacted)
    {
        // Check whether the event is a thread root or redacted information is required
        if ((RiotSettings.shared.enableThreads && [mxSession.threadingService isEventThreadRoot:event])
            || _settings.showRedactionsInRoomHistory)
        {
            MXLogDebug(@"[MXKEventFormatter] Redacted event %@ (%@)", event.description, event.redactedBecause);
            
            NSString *redactorId = event.redactedBecause[@"sender"];
            NSString *redactedBy = @"";
            // Consider live room state to resolve redactor name if no roomState is provided
            MXRoomState *aRoomState = roomState ? roomState : [mxSession roomWithRoomId:event.roomId].dangerousSyncState;
            redactedBy = [aRoomState.members memberName:redactorId];
            
            NSString *redactedReason = (event.redactedBecause[@"content"])[@"reason"];
            if (redactedReason.length)
            {
                if ([redactorId isEqualToString:mxSession.myUserId])
                {
                    redactedBy = [NSString stringWithFormat:@"%@%@", [MatrixKitL10n noticeEventRedactedByYou], [MatrixKitL10n noticeEventRedactedReason:redactedReason]];
                }
                else if (redactedBy.length)
                {
                    redactedBy = [NSString stringWithFormat:@"%@%@", [MatrixKitL10n noticeEventRedactedBy:redactedBy], [MatrixKitL10n noticeEventRedactedReason:redactedReason]];
                }
                else
                {
                    redactedBy = [MatrixKitL10n noticeEventRedactedReason:redactedReason];
                }
            }
            else if ([redactorId isEqualToString:mxSession.myUserId])
            {
                redactedBy = [MatrixKitL10n noticeEventRedactedByYou];
            }
            else if (redactedBy.length)
            {
                redactedBy = [MatrixKitL10n noticeEventRedactedBy:redactedBy];
            }
            
            redactedInfo = [MatrixKitL10n noticeEventRedacted:redactedBy];
        }
    }
    
    // Prepare returned description
    NSString *displayText = nil;
    NSAttributedString *attributedDisplayText = nil;
    BOOL isRoomDirect = [mxSession roomWithRoomId:event.roomId].isDirect;

    // Prepare the display name of the sender
    NSString *senderDisplayName;
    senderDisplayName = roomState ? [self senderDisplayNameForEvent:event withRoomState:roomState] : event.sender;
    
    switch (event.eventType)
    {
        case MXEventTypeRoomName:
        {
            NSString *roomName;
            MXJSONModelSetString(roomName, event.content[@"name"]);
            
            if (isRedacted)
            {
                if (!redactedInfo)
                {
                    // Here the event is ignored (no display)
                    return nil;
                }
                roomName = redactedInfo;
            }
            
            if (roomName.length)
            {
                if (isEventSenderMyUser)
                {
                    if (isRoomDirect)
                    {
                        displayText = [MatrixKitL10n noticeRoomNameChangedByYouForDm:roomName];
                    }
                    else
                    {
                        displayText = [MatrixKitL10n noticeRoomNameChangedByYou:roomName];
                    }
                }
                else
                {
                    if (isRoomDirect)
                    {
                        displayText = [MatrixKitL10n noticeRoomNameChangedForDm:senderDisplayName :roomName];
                    }
                    else
                    {
                        displayText = [MatrixKitL10n noticeRoomNameChanged:senderDisplayName :roomName];
                    }
                }
            }
            else
            {
                if (isEventSenderMyUser)
                {
                    if (isRoomDirect)
                    {
                        displayText = [MatrixKitL10n noticeRoomNameRemovedByYouForDm];
                    }
                    else
                    {
                        displayText = [MatrixKitL10n noticeRoomNameRemovedByYou];
                    }
                }
                else
                {
                    if (isRoomDirect)
                    {
                        displayText = [MatrixKitL10n noticeRoomNameRemovedForDm:senderDisplayName];
                    }
                    else
                    {
                        displayText = [MatrixKitL10n noticeRoomNameRemoved:senderDisplayName];
                    }
                }
            }
            break;
        }
        case MXEventTypeRoomTopic:
        {
            NSString *roomTopic;
            MXJSONModelSetString(roomTopic, event.content[@"topic"]);
            
            if (isRedacted)
            {
                if (!redactedInfo)
                {
                    // Here the event is ignored (no display)
                    return nil;
                }
                roomTopic = redactedInfo;
            }
            
            if (roomTopic.length)
            {
                if (isEventSenderMyUser)
                {
                    displayText = [MatrixKitL10n noticeTopicChangedByYou:roomTopic];
                }
                else
                {
                    displayText = [MatrixKitL10n noticeTopicChanged:senderDisplayName :roomTopic];
                }
            }
            else
            {
                if (isEventSenderMyUser)
                {
                    displayText = [MatrixKitL10n noticeRoomTopicRemovedByYou];
                }
                else
                {
                    displayText = [MatrixKitL10n noticeRoomTopicRemoved:senderDisplayName];
                }
            }
            
            break;
        }
        case MXEventTypeRoomMember:
        {
            // Presently only change on membership, display name and avatar are supported
            
            // Check whether the sender has updated his profile
            if (event.isUserProfileChange)
            {
                // Is redacted event?
                if (isRedacted)
                {
                    if (!redactedInfo)
                    {
                        // Here the event is ignored (no display)
                        return nil;
                    }
                    if (isEventSenderMyUser)
                    {
                        displayText = [MatrixKitL10n noticeProfileChangeRedactedByYou:redactedInfo];
                    }
                    else
                    {
                        displayText = [MatrixKitL10n noticeProfileChangeRedacted:senderDisplayName :redactedInfo];
                    }
                }
                else
                {
                    // Check whether the display name has been changed
                    NSString *displayname;
                    MXJSONModelSetString(displayname, event.content[@"displayname"]);
                    NSString *prevDisplayname;
                    MXJSONModelSetString(prevDisplayname, event.prevContent[@"displayname"]);
                    
                    if (!displayname.length)
                    {
                        displayname = nil;
                    }
                    if (!prevDisplayname.length)
                    {
                        prevDisplayname = nil;
                    }
                    if ((displayname || prevDisplayname) && ([displayname isEqualToString:prevDisplayname] == NO))
                    {
                        if (!prevDisplayname)
                        {
                            if (isEventSenderMyUser)
                            {
                                displayText = [MatrixKitL10n noticeDisplayNameSetByYou:displayname];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeDisplayNameSet:event.sender :displayname];
                            }
                        }
                        else if (!displayname)
                        {
                            if (isEventSenderMyUser)
                            {
                                displayText = [MatrixKitL10n noticeDisplayNameRemovedByYou];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeDisplayNameRemoved:event.sender];
                            }
                        }
                        else
                        {
                            if (isEventSenderMyUser)
                            {
                                displayText = [MatrixKitL10n noticeDisplayNameChangedFromByYou:prevDisplayname :displayname];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeDisplayNameChangedFrom:event.sender :prevDisplayname :displayname];
                            }
                        }
                    }
                    
                    // Check whether the avatar has been changed
                    NSString *avatar;
                    MXJSONModelSetString(avatar, event.content[@"avatar_url"]);
                    NSString *prevAvatar;
                    MXJSONModelSetString(prevAvatar, event.prevContent[@"avatar_url"]);
                    
                    if (!avatar.length)
                    {
                        avatar = nil;
                    }
                    if (!prevAvatar.length)
                    {
                        prevAvatar = nil;
                    }
                    if ((prevAvatar || avatar) && ([avatar isEqualToString:prevAvatar] == NO))
                    {
                        if (displayText)
                        {
                            displayText = [NSString stringWithFormat:@"%@ %@", displayText, [MatrixKitL10n noticeAvatarChangedToo]];
                        }
                        else
                        {
                            if (isEventSenderMyUser)
                            {
                                displayText = [MatrixKitL10n noticeAvatarUrlChangedByYou];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeAvatarUrlChanged:senderDisplayName];
                            }
                        }
                    }
                }
            }
            else
            {
                // Retrieve membership
                NSString* membership;
                MXJSONModelSetString(membership, event.content[@"membership"]);
                
                // Prepare targeted member display name
                NSString *targetDisplayName = event.stateKey;
                
                // Retrieve content displayname
                NSString *contentDisplayname;
                MXJSONModelSetString(contentDisplayname, event.content[@"displayname"]);
                NSString *prevContentDisplayname;
                MXJSONModelSetString(prevContentDisplayname, event.prevContent[@"displayname"]);
                
                // Consider here a membership change
                if ([membership isEqualToString:@"invite"])
                {
                    if (event.content[@"third_party_invite"])
                    {
                        if ([event.stateKey isEqualToString:mxSession.myUserId])
                        {
                            displayText = [MatrixKitL10n noticeRoomThirdPartyRegisteredInviteByYou:event.content[@"third_party_invite"][@"display_name"]];
                        }
                        else
                        {
                            displayText = [MatrixKitL10n noticeRoomThirdPartyRegisteredInvite:targetDisplayName :event.content[@"third_party_invite"][@"display_name"]];
                        }
                    }
                    else
                    {
                        if ([MXCallManager isConferenceUser:event.stateKey])
                        {
                            if (isEventSenderMyUser)
                            {
                                displayText = [MatrixKitL10n noticeConferenceCallRequestByYou];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeConferenceCallRequest:senderDisplayName];
                            }
                        }
                        else
                        {
                            // The targeted member display name (if any) is available in content
                            if (isEventSenderMyUser)
                            {
                                displayText = [MatrixKitL10n noticeRoomInviteByYou:targetDisplayName];
                            }
                            else if ([targetDisplayName isEqualToString:mxSession.myUserId])
                            {
                                displayText = [MatrixKitL10n noticeRoomInviteYou:senderDisplayName];
                            }
                            else
                            {
                                if (contentDisplayname.length)
                                {
                                    targetDisplayName = contentDisplayname;
                                }
                                
                                displayText = [MatrixKitL10n noticeRoomInvite:senderDisplayName :targetDisplayName];
                            }
                        }
                    }
                }
                else if ([membership isEqualToString:@"join"])
                {
                    if ([MXCallManager isConferenceUser:event.stateKey])
                    {
                        displayText = [MatrixKitL10n noticeConferenceCallStarted];
                    }
                    else
                    {
                        // The targeted member display name (if any) is available in content
                        if (isEventSenderMyUser)
                        {
                            displayText = [MatrixKitL10n noticeRoomJoinByYou];
                        }
                        else
                        {
                            if (contentDisplayname.length)
                            {
                                targetDisplayName = contentDisplayname;
                            }
                            
                            displayText = [MatrixKitL10n noticeRoomJoin:targetDisplayName];
                        }
                    }
                }
                else if ([membership isEqualToString:@"leave"])
                {
                    NSString *prevMembership = nil;
                    if (event.prevContent)
                    {
                        MXJSONModelSetString(prevMembership, event.prevContent[@"membership"]);
                    }
                    
                    // The targeted member display name (if any) is available in prevContent
                    if (prevContentDisplayname.length)
                    {
                        targetDisplayName = prevContentDisplayname;
                    }
                    
                    if ([event.sender isEqualToString:event.stateKey])
                    {
                        if ([MXCallManager isConferenceUser:event.stateKey])
                        {
                            displayText = [MatrixKitL10n noticeConferenceCallFinished];
                        }
                        else
                        {
                            if (prevMembership && [prevMembership isEqualToString:@"invite"])
                            {
                                if (isEventSenderMyUser)
                                {
                                    displayText = [MatrixKitL10n noticeRoomRejectByYou];
                                }
                                else
                                {
                                    displayText = [MatrixKitL10n noticeRoomReject:targetDisplayName];
                                }
                            }
                            else
                            {
                                if (isEventSenderMyUser)
                                {
                                    displayText = [MatrixKitL10n noticeRoomLeaveByYou];
                                }
                                else
                                {
                                    displayText = [MatrixKitL10n noticeRoomLeave:targetDisplayName];
                                }
                            }
                        }
                    }
                    else if (prevMembership)
                    {
                        if ([prevMembership isEqualToString:@"invite"])
                        {
                            if (isEventSenderMyUser)
                            {
                                displayText = [MatrixKitL10n noticeRoomWithdrawByYou:targetDisplayName];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeRoomWithdraw:senderDisplayName :targetDisplayName];
                            }
                            if (event.content[@"reason"])
                            {
                                displayText = [displayText stringByAppendingString:[MatrixKitL10n noticeRoomReason:event.content[@"reason"]]];
                            }

                        }
                        else if ([prevMembership isEqualToString:@"join"])
                        {
                            if (isEventSenderMyUser)
                            {
                                displayText = [MatrixKitL10n noticeRoomKickByYou:targetDisplayName];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeRoomKick:senderDisplayName :targetDisplayName];
                            }
                            
                            //  add reason if exists
                            if (event.content[@"reason"])
                            {
                                displayText = [displayText stringByAppendingString:[MatrixKitL10n noticeRoomReason:event.content[@"reason"]]];
                            }
                        }
                        else if ([prevMembership isEqualToString:@"ban"])
                        {
                            if (isEventSenderMyUser)
                            {
                                displayText = [MatrixKitL10n noticeRoomUnbanByYou:targetDisplayName];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeRoomUnban:senderDisplayName :targetDisplayName];
                            }
                        }
                    }
                }
                else if ([membership isEqualToString:@"ban"])
                {
                    // The targeted member display name (if any) is available in prevContent
                    if (prevContentDisplayname.length)
                    {
                        targetDisplayName = prevContentDisplayname;
                    }
                    
                    if (isEventSenderMyUser)
                    {
                        displayText = [MatrixKitL10n noticeRoomBanByYou:targetDisplayName];
                    }
                    else
                    {
                        displayText = [MatrixKitL10n noticeRoomBan:senderDisplayName :targetDisplayName];
                    }
                    if (event.content[@"reason"])
                    {
                        displayText = [displayText stringByAppendingString:[MatrixKitL10n noticeRoomReason:event.content[@"reason"]]];
                    }
                }
                
                // Append redacted info if any
                if (redactedInfo)
                {
                    displayText = [NSString stringWithFormat:@"%@ %@", displayText, redactedInfo];
                }
            }
            
            if (!displayText)
            {
                *error = MXKEventFormatterErrorUnexpected;
            }
            break;
        }
        case MXEventTypeRoomCreate:
        {
            NSString *creatorId;
            MXJSONModelSetString(creatorId, event.content[@"creator"]);
            
            if (creatorId)
            {
                if ([creatorId isEqualToString:mxSession.myUserId])
                {
                    if (isRoomDirect)
                    {
                        displayText = [MatrixKitL10n noticeRoomCreatedByYouForDm];
                    }
                    else
                    {
                        displayText = [MatrixKitL10n noticeRoomCreatedByYou];
                    }
                }
                else
                {
                    if (isRoomDirect)
                    {
                        displayText = [MatrixKitL10n noticeRoomCreatedForDm:(roomState ? [roomState.members memberName:creatorId] : creatorId)];
                    }
                    else
                    {
                        displayText = [MatrixKitL10n noticeRoomCreated:(roomState ? [roomState.members memberName:creatorId] : creatorId)];
                    }
                }
                // Append redacted info if any
                if (redactedInfo)
                {
                    displayText = [NSString stringWithFormat:@"%@ %@", displayText, redactedInfo];
                }
            }
            break;
        }
        case MXEventTypeRoomJoinRules:
        {
            NSString *joinRule;
            MXJSONModelSetString(joinRule, event.content[@"join_rule"]);
            
            if (joinRule)
            {
                if ([event.sender isEqualToString:mxSession.myUserId])
                {
                    if ([joinRule isEqualToString:kMXRoomJoinRulePublic])
                    {
                        if (isRoomDirect)
                        {
                            displayText = [MatrixKitL10n noticeRoomJoinRulePublicByYouForDm];
                        }
                        else
                        {
                            displayText = [MatrixKitL10n noticeRoomJoinRulePublicByYou];
                        }
                    }
                    else if ([joinRule isEqualToString:kMXRoomJoinRuleInvite])
                    {
                        if (isRoomDirect)
                        {
                            displayText = [MatrixKitL10n noticeRoomJoinRuleInviteByYouForDm];
                        }
                        else
                        {
                            displayText = [MatrixKitL10n noticeRoomJoinRuleInviteByYou];
                        }
                    }
                }
                else
                {
                    NSString *displayName = roomState ? [roomState.members memberName:event.sender] : event.sender;
                    if ([joinRule isEqualToString:kMXRoomJoinRulePublic])
                    {
                        if (isRoomDirect)
                        {
                            displayText = [MatrixKitL10n noticeRoomJoinRulePublicForDm:displayName];
                        }
                        else
                        {
                            displayText = [MatrixKitL10n noticeRoomJoinRulePublic:displayName];
                        }
                    }
                    else if ([joinRule isEqualToString:kMXRoomJoinRuleInvite])
                    {
                        if (isRoomDirect)
                        {
                            displayText = [MatrixKitL10n noticeRoomJoinRuleInviteForDm:displayName];
                        }
                        else
                        {
                            displayText = [MatrixKitL10n noticeRoomJoinRuleInvite:displayName];
                        }
                    }
                }
                
                if (!displayText)
                {
                    //  use old string for non-handled cases: "knock" and "private"
                    displayText = [MatrixKitL10n noticeRoomJoinRule:joinRule];
                }
                
                // Append redacted info if any
                if (redactedInfo)
                {
                    displayText = [NSString stringWithFormat:@"%@ %@", displayText, redactedInfo];
                }
            }
            break;
        }
        case MXEventTypeRoomPowerLevels:
        {
            if (isRoomDirect)
            {
                displayText = [MatrixKitL10n noticeRoomPowerLevelIntroForDm];
            }
            else
            {
                displayText = [MatrixKitL10n noticeRoomPowerLevelIntro];
            }
            NSDictionary *users;
            MXJSONModelSetDictionary(users, event.content[@"users"]);
            
            for (NSString *key in users.allKeys)
            {
                displayText = [NSString stringWithFormat:@"%@\n\u2022 %@: %@", displayText, key, [users objectForKey:key]];
            }
            if (event.content[@"users_default"])
            {
                displayText = [NSString stringWithFormat:@"%@\n\u2022 %@: %@", displayText, [MatrixKitL10n default], event.content[@"users_default"]];
            }
            
            displayText = [NSString stringWithFormat:@"%@\n%@", displayText, [MatrixKitL10n noticeRoomPowerLevelActingRequirement]];
            if (event.content[@"ban"])
            {
                displayText = [NSString stringWithFormat:@"%@\n\u2022 ban: %@", displayText, event.content[@"ban"]];
            }
            if (event.content[@"kick"])
            {
                displayText = [NSString stringWithFormat:@"%@\n\u2022 remove: %@", displayText, event.content[@"kick"]];
            }
            if (event.content[@"redact"])
            {
                displayText = [NSString stringWithFormat:@"%@\n\u2022 redact: %@", displayText, event.content[@"redact"]];
            }
            if (event.content[@"invite"])
            {
                displayText = [NSString stringWithFormat:@"%@\n\u2022 invite: %@", displayText, event.content[@"invite"]];
            }
            
            displayText = [NSString stringWithFormat:@"%@\n%@", displayText, [MatrixKitL10n noticeRoomPowerLevelEventRequirement]];
            
            NSDictionary *events;
            MXJSONModelSetDictionary(events, event.content[@"events"]);
            for (NSString *key in events.allKeys)
            {
                displayText = [NSString stringWithFormat:@"%@\n\u2022 %@: %@", displayText, key, [events objectForKey:key]];
            }
            if (event.content[@"events_default"])
            {
                displayText = [NSString stringWithFormat:@"%@\n\u2022 %@: %@", displayText, @"events_default", event.content[@"events_default"]];
            }
            if (event.content[@"state_default"])
            {
                displayText = [NSString stringWithFormat:@"%@\n\u2022 %@: %@", displayText, @"state_default", event.content[@"state_default"]];
            }
            
            // Append redacted info if any
            if (redactedInfo)
            {
                displayText = [NSString stringWithFormat:@"%@\n %@", displayText, redactedInfo];
            }
            break;
        }
        case MXEventTypeRoomAliases:
        {
            NSArray *aliases;
            MXJSONModelSetArray(aliases, event.content[@"aliases"]);
            if (aliases)
            {
                if (isRoomDirect)
                {
                    displayText = [MatrixKitL10n noticeRoomAliasesForDm:[aliases componentsJoinedByString:@", "]];
                }
                else
                {
                    displayText = [MatrixKitL10n noticeRoomAliases:[aliases componentsJoinedByString:@", "]];
                }
                // Append redacted info if any
                if (redactedInfo)
                {
                    displayText = [NSString stringWithFormat:@"%@\n %@", displayText, redactedInfo];
                }
            }
            break;
        }
        case MXEventTypeRoomRelatedGroups:
        {
            NSArray *groups;
            MXJSONModelSetArray(groups, event.content[@"groups"]);
            if (groups)
            {
                displayText = [MatrixKitL10n noticeRoomRelatedGroups:[groups componentsJoinedByString:@", "]];
                // Append redacted info if any
                if (redactedInfo)
                {
                    displayText = [NSString stringWithFormat:@"%@\n %@", displayText, redactedInfo];
                }
            }
            break;
        }
        case MXEventTypeRoomEncrypted:
        {
            // Is redacted?
            if (isRedacted)
            {
                if (!redactedInfo)
                {
                    // Here the event is ignored (no display)
                    return nil;
                }
                displayText = redactedInfo;
            }
            else
            {
                // If the message still appears as encrypted, there was propably an error for decryption
                // Show this error
                if (event.decryptionError)
                {
                    NSString *errorDescription;

                    if ([event.decryptionError.domain isEqualToString:MXDecryptingErrorDomain]
                        && [MXKAppSettings standardAppSettings].hideUndecryptableEvents)
                    {
                        //  Hide this event, it cannot be decrypted
                        displayText = nil;
                    }
                    else if ([event.decryptionError.domain isEqualToString:MXDecryptingErrorDomain]
                        && event.decryptionError.code == MXDecryptingErrorUnknownInboundSessionIdCode)
                    {
                        // Make the unknown inbound session id error description more user friendly
                        errorDescription = [MatrixKitL10n noticeCryptoErrorUnknownInboundSessionId];
                    }
                    else if ([event.decryptionError.domain isEqualToString:MXDecryptingErrorDomain]
                           && event.decryptionError.code == MXDecryptingErrorDuplicateMessageIndexCode)
                    {
                        // Hide duplicate message warnings
                        MXLogDebug(@"[MXKEventFormatter] Warning: Duplicate message with error description %@", event.decryptionError);
                        displayText = nil;
                    }
                    else
                    {
                        errorDescription = event.decryptionError.localizedDescription;
                    }

                    if (errorDescription)
                    {
                        displayText = [MatrixKitL10n noticeCryptoUnableToDecrypt:errorDescription];
                    }
                }
                else
                {
                    displayText = [MatrixKitL10n noticeEncryptedMessage];
                }
            }
            
            break;
        }
        case MXEventTypeRoomEncryption:
        {
            NSString *algorithm;
            MXJSONModelSetString(algorithm, event.content[@"algorithm"]);
            
            if (isRedacted)
            {
                if (!redactedInfo)
                {
                    // Here the event is ignored (no display)
                    return nil;
                }
                algorithm = redactedInfo;
            }
            
            if ([algorithm isEqualToString:kMXCryptoMegolmAlgorithm])
            {
                if (isEventSenderMyUser)
                {
                    displayText = [MatrixKitL10n noticeEncryptionEnabledOkByYou];
                }
                else
                {
                    displayText = [MatrixKitL10n noticeEncryptionEnabledOk:senderDisplayName];
                }
            }
            else
            {
                if (isEventSenderMyUser)
                {
                    displayText = [MatrixKitL10n noticeEncryptionEnabledUnknownAlgorithmByYou:algorithm];
                }
                else
                {
                    displayText = [MatrixKitL10n noticeEncryptionEnabledUnknownAlgorithm:senderDisplayName :algorithm];
                }
            }
            
            break;
        }
        case MXEventTypeRoomHistoryVisibility:
        {
            if (isRedacted)
            {
                displayText = redactedInfo;
            }
            else
            {
                MXRoomHistoryVisibility historyVisibility;
                MXJSONModelSetString(historyVisibility, event.content[@"history_visibility"]);
                
                if (historyVisibility)
                {
                    if ([historyVisibility isEqualToString:kMXRoomHistoryVisibilityWorldReadable])
                    {
                        if (!isRoomDirect)
                        {
                            if (isEventSenderMyUser)
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToAnyoneByYou];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToAnyone:senderDisplayName];
                            }
                        }
                    }
                    else if ([historyVisibility isEqualToString:kMXRoomHistoryVisibilityShared])
                    {
                        if (isEventSenderMyUser)
                        {
                            if (isRoomDirect)
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToMembersByYouForDm];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToMembersByYou];
                            }
                        }
                        else
                        {
                            if (isRoomDirect)
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToMembersForDm:senderDisplayName];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToMembers:senderDisplayName];
                            }
                        }
                    }
                    else if ([historyVisibility isEqualToString:kMXRoomHistoryVisibilityInvited])
                    {
                        if (isEventSenderMyUser)
                        {
                            if (isRoomDirect)
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToMembersFromInvitedPointByYouForDm];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToMembersFromInvitedPointByYou];
                            }
                        }
                        else
                        {
                            if (isRoomDirect)
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToMembersFromInvitedPointForDm:senderDisplayName];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToMembersFromInvitedPoint:senderDisplayName];
                            }
                        }
                    }
                    else if ([historyVisibility isEqualToString:kMXRoomHistoryVisibilityJoined])
                    {
                        if (isEventSenderMyUser)
                        {
                            if (isRoomDirect)
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToMembersFromJoinedPointByYouForDm];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToMembersFromJoinedPointByYou];
                            }
                        }
                        else
                        {
                            if (isRoomDirect)
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToMembersFromJoinedPointForDm:senderDisplayName];
                            }
                            else
                            {
                                displayText = [MatrixKitL10n noticeRoomHistoryVisibleToMembersFromJoinedPoint:senderDisplayName];
                            }
                        }
                    }
                }
            }
            break;
        }
        case MXEventTypeRoomMessage:
        {
            // Is redacted?
            if (isRedacted)
            {
                if (!redactedInfo)
                {
                    // Here the event is ignored (no display)
                    return nil;
                }
                displayText = redactedInfo;
            }
            else if (event.isEditEvent)
            {
                return nil;
            }
            else
            {
                NSString *msgtype;
                MXJSONModelSetString(msgtype, event.content[kMXMessageTypeKey]);

                NSString *body;
                BOOL isHTML = NO;
                NSString *eventThreadId = event.threadId;

                // Use the HTML formatted string if provided
                if ([event.content[@"format"] isEqualToString:kMXRoomMessageFormatHTML])
                {
                    isHTML =YES;
                    MXJSONModelSetString(body, event.content[@"formatted_body"]);
                }
                else if (eventThreadId && !RiotSettings.shared.enableThreads)
                {
                    NSString *repliedEventId = event.relatesTo.inReplyTo.eventId ?: eventThreadId;
                    isHTML = YES;
                    MXJSONModelSetString(body, event.content[kMXMessageBodyKey]);
                    MXEvent *repliedEvent = [mxSession.store eventWithEventId:repliedEventId
                                                                       inRoom:event.roomId];
                    
                    NSString *repliedEventContent;
                    MXJSONModelSetString(repliedEventContent, repliedEvent.content[kMXMessageBodyKey]);
                    body = [NSString stringWithFormat:@"<mx-reply><blockquote><a href=\"%@\">In reply to</a> <a href=\"%@\">%@</a><br>%@</blockquote></mx-reply>%@",
                            [MXTools permalinkToEvent:repliedEventId inRoom:event.roomId],
                            [MXTools permalinkToUserWithUserId:repliedEvent.sender],
                            repliedEvent.sender,
                            repliedEventContent,
                            body];
                    
                }
                else
                {
                    MXJSONModelSetString(body, event.content[kMXMessageBodyKey]);
                }

                if (body)
                {
                    if ([msgtype isEqualToString:kMXMessageTypeImage])
                    {
                        body = body? body : [MatrixKitL10n noticeImageAttachment];
                        // Check attachment validity
                        if (![self isSupportedAttachment:event])
                        {
                            MXLogDebug(@"[MXKEventFormatter] Warning: Unsupported attachment %@", event.description);
                            body = [MatrixKitL10n noticeInvalidAttachment];
                            *error = MXKEventFormatterErrorUnsupported;
                        }
                    }
                    else if ([msgtype isEqualToString:kMXMessageTypeAudio])
                    {
                        body = body? body : [MatrixKitL10n noticeAudioAttachment];
                        if (![self isSupportedAttachment:event])
                        {
                            MXLogDebug(@"[MXKEventFormatter] Warning: Unsupported attachment %@", event.description);
                            if (_isForSubtitle || !_settings.showUnsupportedEventsInRoomHistory)
                            {
                                body = [MatrixKitL10n noticeInvalidAttachment];
                            }
                            else
                            {
                                body = [MatrixKitL10n noticeUnsupportedAttachment:event.description];
                            }
                            *error = MXKEventFormatterErrorUnsupported;
                        }
                    }
                    else if ([msgtype isEqualToString:kMXMessageTypeVideo])
                    {
                        body = body? body : [MatrixKitL10n noticeVideoAttachment];
                        if (![self isSupportedAttachment:event])
                        {
                            MXLogDebug(@"[MXKEventFormatter] Warning: Unsupported attachment %@", event.description);
                            if (_isForSubtitle || !_settings.showUnsupportedEventsInRoomHistory)
                            {
                                body = [MatrixKitL10n noticeInvalidAttachment];
                            }
                            else
                            {
                                body = [MatrixKitL10n noticeUnsupportedAttachment:event.description];
                            }
                            *error = MXKEventFormatterErrorUnsupported;
                        }
                    }
                    else if ([msgtype isEqualToString:kMXMessageTypeFile])
                    {
                        body = body? body : [MatrixKitL10n noticeFileAttachment];
                        // Check attachment validity
                        if (![self isSupportedAttachment:event])
                        {
                            MXLogDebug(@"[MXKEventFormatter] Warning: Unsupported attachment %@", event.description);
                            body = [MatrixKitL10n noticeInvalidAttachment];
                            *error = MXKEventFormatterErrorUnsupported;
                        }
                    }

                    if (isHTML)
                    {
                        // Build the attributed string from the HTML string
                        attributedDisplayText = [self renderHTMLString:body forEvent:event withRoomState:roomState];
                    }
                    else
                    {
                        // Build the attributed string with the right font and color for the event
                        attributedDisplayText = [self renderString:body forEvent:event];
                    }

                    // Build the full emote string after the body message formatting
                    if ([msgtype isEqualToString:kMXMessageTypeEmote])
                    {
                        __block NSUInteger insertAt = 0;

                        // For replies, look for the end of the parent message
                        // This helps us insert the emote prefix in the right place
                        if (event.relatesTo.inReplyTo || (event.isInThread && !RiotSettings.shared.enableThreads))
                        {
                            [attributedDisplayText enumerateAttribute:kMXKToolsBlockquoteMarkAttribute
                                                              inRange:NSMakeRange(0, attributedDisplayText.length)
                                                              options:(NSAttributedStringEnumerationReverse)
                                                           usingBlock:^(id value, NSRange range, BOOL *stop) {
                                insertAt = range.location;
                                *stop = YES;
                            }];
                        }

                        // Always use default font and color for the emote prefix
                        NSString *emotePrefix = [NSString stringWithFormat:@"* %@ ", senderDisplayName];
                        NSAttributedString *attributedEmotePrefix =
                        [[NSAttributedString alloc] initWithString:emotePrefix
                                                        attributes:@{
                                                                    NSForegroundColorAttributeName: _defaultTextColor,
                                                                    NSFontAttributeName: _defaultTextFont
                                                                    }];

                        // Then, insert the emote prefix at the start of the message
                        // (location varies depending on whether it was a reply)
                        NSMutableAttributedString *newAttributedDisplayText =
                        [[NSMutableAttributedString alloc] initWithAttributedString:attributedDisplayText];
                        [newAttributedDisplayText insertAttributedString:attributedEmotePrefix
                                                                 atIndex:insertAt];
                        attributedDisplayText = newAttributedDisplayText;
                    }
                }
            }
            break;
        }
        case MXEventTypeRoomMessageFeedback:
        {
            NSString *type;
            MXJSONModelSetString(type, event.content[@"type"]);
            NSString *eventId;
            MXJSONModelSetString(eventId, event.content[@"target_event_id"]);
            
            if (type && eventId)
            {
                displayText = [MatrixKitL10n noticeFeedback:eventId :type];
                // Append redacted info if any
                if (redactedInfo)
                {
                    displayText = [NSString stringWithFormat:@"%@ %@", displayText, redactedInfo];
                }
            }
            break;
        }
        case MXEventTypeRoomRedaction:
        {
            NSString *eventId = event.redacts;
            if (isEventSenderMyUser)
            {
                displayText = [MatrixKitL10n noticeRedactionByYou:eventId];
            }
            else
            {
                displayText = [MatrixKitL10n noticeRedaction:senderDisplayName :eventId];
            }
            break;
        }
        case MXEventTypeRoomThirdPartyInvite:
        {
            NSString *displayname;
            MXJSONModelSetString(displayname, event.content[@"display_name"]);
            if (displayname)
            {
                if (isEventSenderMyUser)
                {
                    if (isRoomDirect)
                    {
                        displayText = [MatrixKitL10n noticeRoomThirdPartyInviteByYouForDm:displayname];
                    }
                    else
                    {
                        displayText = [MatrixKitL10n noticeRoomThirdPartyInviteByYou:displayname];
                    }
                }
                else
                {
                    if (isRoomDirect)
                    {
                        displayText = [MatrixKitL10n noticeRoomThirdPartyInviteForDm:senderDisplayName :displayname];
                    }
                    else
                    {
                        displayText = [MatrixKitL10n noticeRoomThirdPartyInvite:senderDisplayName :displayname];
                    }
                }
            }
            else
            {
                // Consider the invite has been revoked
                MXJSONModelSetString(displayname, event.prevContent[@"display_name"]);
                if (isEventSenderMyUser)
                {
                    if (isRoomDirect)
                    {
                        displayText = [MatrixKitL10n noticeRoomThirdPartyRevokedInviteByYouForDm:displayname];
                    }
                    else
                    {
                        displayText = [MatrixKitL10n noticeRoomThirdPartyRevokedInviteByYou:displayname];
                    }
                }
                else
                {
                    if (isRoomDirect)
                    {
                        displayText = [MatrixKitL10n noticeRoomThirdPartyRevokedInviteForDm:senderDisplayName :displayname];
                    }
                    else
                    {
                        displayText = [MatrixKitL10n noticeRoomThirdPartyRevokedInvite:senderDisplayName :displayname];
                    }
                }
            }
            break;
        }
        case MXEventTypeCallInvite:
        {
            MXCallInviteEventContent *callInviteEventContent = [MXCallInviteEventContent modelFromJSON:event.content];

            if (callInviteEventContent.isVideoCall)
            {
                if (isEventSenderMyUser)
                {
                    displayText = [MatrixKitL10n noticePlacedVideoCallByYou];
                }
                else
                {
                    displayText = [MatrixKitL10n noticePlacedVideoCall:senderDisplayName];
                }
            }
            else
            {
                if (isEventSenderMyUser)
                {
                    displayText = [MatrixKitL10n noticePlacedVoiceCallByYou];
                }
                else
                {
                    displayText = [MatrixKitL10n noticePlacedVoiceCall:senderDisplayName];
                }
            }
            break;
        }
        case MXEventTypeCallAnswer:
        {
            if (isEventSenderMyUser)
            {
                displayText = [MatrixKitL10n noticeAnsweredVideoCallByYou];
            }
            else
            {
                displayText = [MatrixKitL10n noticeAnsweredVideoCall:senderDisplayName];
            }
            break;
        }
        case MXEventTypeCallHangup:
        {
            if (isEventSenderMyUser)
            {
                displayText = [MatrixKitL10n noticeEndedVideoCallByYou];
            }
            else
            {
                displayText = [MatrixKitL10n noticeEndedVideoCall:senderDisplayName];
            }
            break;
        }
        case MXEventTypeCallReject:
        {
            if (isEventSenderMyUser)
            {
                displayText = [MatrixKitL10n noticeDeclinedVideoCallByYou];
            }
            else
            {
                displayText = [MatrixKitL10n noticeDeclinedVideoCall:senderDisplayName];
            }
            break;
        }
        case MXEventTypeSticker:
        {
            // Is redacted?
            if (isRedacted)
            {
                if (!redactedInfo)
                {
                    // Here the event is ignored (no display)
                    return nil;
                }
                displayText = redactedInfo;
            }
            else
            {
                NSString *body;
                MXJSONModelSetString(body, event.content[kMXMessageBodyKey]);
                
                // Check sticker validity
                if (![self isSupportedAttachment:event])
                {
                    MXLogDebug(@"[MXKEventFormatter] Warning: Unsupported sticker %@", event.description);
                    body = [MatrixKitL10n noticeInvalidAttachment];
                    *error = MXKEventFormatterErrorUnsupported;
                }
                
                displayText = body? body : [MatrixKitL10n noticeSticker];
            }
            break;
        }
        case MXEventTypePollStart:
        {
            if (event.isEditEvent)
            {
                return nil;
            }
            
            displayText = [MXEventContentPollStart modelFromJSON:event.content].question;
            break;
        }
        default:
            *error = MXKEventFormatterErrorUnknownEventType;
            break;
    }

    if (!attributedDisplayText && displayText)
    {
        // Build the attributed string with the right font and color for the event
        attributedDisplayText = [self renderString:displayText forEvent:event];
    }
    
    if (!attributedDisplayText)
    {
        MXLogDebug(@"[MXKEventFormatter] Warning: Unsupported event %@)", event.description);
        if (_settings.showUnsupportedEventsInRoomHistory)
        {
            if (MXKEventFormatterErrorNone == *error)
            {
                *error = MXKEventFormatterErrorUnsupported;
            }
            
            NSString *shortDescription = nil;
            
            switch (*error)
            {
                case MXKEventFormatterErrorUnsupported:
                    shortDescription = [MatrixKitL10n noticeErrorUnsupportedEvent];
                    break;
                case MXKEventFormatterErrorUnexpected:
                    shortDescription = [MatrixKitL10n noticeErrorUnexpectedEvent];
                    break;
                case MXKEventFormatterErrorUnknownEventType:
                    shortDescription = [MatrixKitL10n noticeErrorUnknownEventType];
                    break;
                    
                default:
                    break;
            }
            
            if (!_isForSubtitle)
            {
                // Return event content as unsupported event
                displayText = [NSString stringWithFormat:@"%@: %@", shortDescription, event.description];
            }
            else
            {
                // Return a short error description
                displayText = shortDescription;
            }

            // Build the attributed string with the right font for the event
            attributedDisplayText = [self renderString:displayText forEvent:event];
        }
    }
    
    return attributedDisplayText;
}

- (NSAttributedString*)attributedStringFromEvents:(NSArray<MXEvent*>*)events withRoomState:(MXRoomState*)roomState error:(MXKEventFormatterError*)error
{
    // TODO: Do a full summary
    return nil;
}

- (NSAttributedString*)renderString:(NSString*)string forEvent:(MXEvent*)event
{
    // Sanity check
    if (!string)
    {
        return nil;
    }
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:string];

    NSRange wholeString = NSMakeRange(0, str.length);

    // Apply color and font corresponding to the event state
    [str addAttribute:NSForegroundColorAttributeName value:[self textColorForEvent:event] range:wholeString];
    [str addAttribute:NSFontAttributeName value:[self fontForEvent:event] range:wholeString];

    // If enabled, make links clickable
    if (!([[_settings httpLinkScheme] isEqualToString: @"http"] &&
          [[_settings httpsLinkScheme] isEqualToString: @"https"]))
    {
        NSArray *matches = [linkDetector matchesInString:[str string] options:0 range:wholeString];
        for (NSTextCheckingResult *match in matches)
        {
            NSRange matchRange = [match range];
            NSURL *matchUrl = [match URL];
            NSURLComponents *url = [[NSURLComponents new] initWithURL:matchUrl resolvingAgainstBaseURL:NO];

            if (url)
            {
                if ([url.scheme isEqualToString: @"http"])
                {
                    url.scheme = [_settings httpLinkScheme];
                }
                else if ([url.scheme isEqualToString: @"https"])
                {
                    url.scheme = [_settings httpsLinkScheme];
                }

                if (url.URL)
                {
                    [str addAttribute:NSLinkAttributeName value:url.URL range:matchRange];
                }
            }
        }
    }

    // Apply additional treatments
    return [self postRenderAttributedString:str];
}

- (NSAttributedString*)renderHTMLString:(NSString*)htmlString forEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState
{
    NSString *html = htmlString;

    // Special treatment for "In reply to" message
    if (event.isReplyEvent || (event.isInThread && !RiotSettings.shared.enableThreads))
    {
        html = [self renderReplyTo:html withRoomState:roomState];
    }

    // Apply the css style that corresponds to the event state
    UIFont *font = [self fontForEvent:event];
    
    // Do some sanitisation before finalizing the string
    MXWeakify(self);
    DTHTMLAttributedStringBuilderWillFlushCallback sanitizeCallback = ^(DTHTMLElement *element) {
        MXStrongifyAndReturnIfNil(self);
        [element sanitizeWith:self.allowedHTMLTags bodyFont:font imageHandler:self.htmlImageHandler];
    };

    NSDictionary *options = @{
                              DTUseiOS6Attributes: @(YES),              // Enable it to be able to display the attributed string in a UITextView
                              DTDefaultFontFamily: font.familyName,
                              DTDefaultFontName: font.fontName,
                              DTDefaultFontSize: @(font.pointSize),
                              DTDefaultTextColor: [self textColorForEvent:event],
                              DTDefaultLinkDecoration: @(NO),
                              DTDefaultStyleSheet: dtCSS,
                              DTWillFlushBlockCallBack: sanitizeCallback
                              };

    // Do not use the default HTML renderer of NSAttributedString because this method
    // runs on the UI thread which we want to avoid because renderHTMLString is called
    // most of the time from a background thread.
    // Use DTCoreText HTML renderer instead.
    // Using DTCoreText, which renders static string, helps to avoid code injection attacks
    // that could happen with the default HTML renderer of NSAttributedString which is a
    // webview.
    NSAttributedString *str = [[NSAttributedString alloc] initWithHTMLData:[html dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:NULL];
        
    // Apply additional treatments
    str = [self postRenderAttributedString:str];

    // Finalize the attributed string by removing DTCoreText artifacts (Trim trailing newlines).
    str = [MXKTools removeDTCoreTextArtifacts:str];

    // Finalize HTML blockquote blocks marking
    str = [MXKTools removeMarkedBlockquotesArtifacts:str];

    return str;
}

/**
 Special treatment for "In reply to" message.

 According to https://docs.google.com/document/d/1BPd4lBrooZrWe_3s_lHw_e-Dydvc7bXbm02_sV2k6Sc/edit.

 @param htmlString an html string containing a reply-to message.
 @param roomState the room state right before the event.
 @return a displayable internationalised html string.
 */
- (NSString*)renderReplyTo:(NSString*)htmlString withRoomState:(MXRoomState*)roomState
{
    NSString *html = htmlString;
    
    static NSRegularExpression *htmlATagRegex;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        htmlATagRegex = [NSRegularExpression regularExpressionWithPattern:kHTMLATagRegexPattern options:NSRegularExpressionCaseInsensitive error:nil];
    });
    
    __block NSUInteger hrefCount = 0;
    
    __block NSRange inReplyToLinkRange = NSMakeRange(NSNotFound, 0);
    __block NSRange inReplyToTextRange = NSMakeRange(NSNotFound, 0);
    __block NSRange userIdRange = NSMakeRange(NSNotFound, 0);
    
    [htmlATagRegex enumerateMatchesInString:html
                                    options:0
                                      range:NSMakeRange(0, html.length)
                                 usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                                     
                                     if (hrefCount > 1)
                                     {
                                         *stop = YES;
                                     }
                                     else if (hrefCount == 0 && match.numberOfRanges >= 2)
                                     {
                                        inReplyToLinkRange = [match rangeAtIndex:1];
                                        inReplyToTextRange = [match rangeAtIndex:2];
                                     }
                                     else if (hrefCount == 1 && match.numberOfRanges >= 2)
                                     {
                                         userIdRange = [match rangeAtIndex:2];
                                     }
                                     
                                     hrefCount++;
                                 }];
    
    // Note: Take care to replace text starting with the end
    
    // Replace <a href=\"https://matrix.to/#/mxid\">mxid</a>
    // By <a href=\"https://matrix.to/#/mxid\">Display name</a>
    // To replace the user Matrix ID by his display name when available.
    // This link is the second <a> HTML node of the html string
    
    if (userIdRange.location != NSNotFound)
    {
        NSString *userId = [html substringWithRange:userIdRange];
        
        NSString *senderDisplayName = [roomState.members memberName:userId];
        
        if (senderDisplayName)
        {
            html = [html stringByReplacingCharactersInRange:userIdRange withString:senderDisplayName];
        }
    }
    
    // Replace <mx-reply><blockquote><a href=\"__permalink__\">In reply to</a>
    // By <mx-reply><blockquote><a href=\"#\">['In reply to' from resources]</a>
    // To disable the link and to localize the "In reply to" string
    // This link is the first <a> HTML node of the html string
    
    if (inReplyToTextRange.location != NSNotFound)
    {
        html = [html stringByReplacingCharactersInRange:inReplyToTextRange withString:[MatrixKitL10n noticeInReplyTo]];
    }
    
    if (inReplyToLinkRange.location != NSNotFound)
    {
        html = [html stringByReplacingCharactersInRange:inReplyToLinkRange withString:@"#"];
    }
    
    return html;
}

- (NSAttributedString*)postRenderAttributedString:(NSAttributedString*)attributedString
{
    if (!attributedString)
    {
        return nil;
    }
    
    NSInteger enabledMatrixIdsBitMask= 0;

    // If enabled, make user id clickable
    if (_treatMatrixUserIdAsLink)
    {
        enabledMatrixIdsBitMask |= MXKTOOLS_USER_IDENTIFIER_BITWISE;
    }

    // If enabled, make room id clickable
    if (_treatMatrixRoomIdAsLink)
    {
        enabledMatrixIdsBitMask |= MXKTOOLS_ROOM_IDENTIFIER_BITWISE;
    }

    // If enabled, make room alias clickable
    if (_treatMatrixRoomAliasAsLink)
    {
        enabledMatrixIdsBitMask |= MXKTOOLS_ROOM_ALIAS_BITWISE;
    }

    // If enabled, make event id clickable
    if (_treatMatrixEventIdAsLink)
    {
        enabledMatrixIdsBitMask |= MXKTOOLS_EVENT_IDENTIFIER_BITWISE;
    }
    
    // If enabled, make group id clickable
    if (_treatMatrixGroupIdAsLink)
    {
        enabledMatrixIdsBitMask |= MXKTOOLS_GROUP_IDENTIFIER_BITWISE;
    }

    return [MXKTools createLinksInAttributedString:attributedString forEnabledMatrixIds:enabledMatrixIdsBitMask];
}

- (NSAttributedString *)renderString:(NSString *)string withPrefix:(NSString *)prefix forEvent:(MXEvent *)event
{
    NSMutableAttributedString *str;

    if (prefix)
    {
        str = [[NSMutableAttributedString alloc] initWithString:prefix];

        // Apply the prefix font and color on the prefix
        NSRange prefixRange = NSMakeRange(0, prefix.length);
        [str addAttribute:NSForegroundColorAttributeName value:_prefixTextColor range:prefixRange];
        [str addAttribute:NSFontAttributeName value:_prefixTextFont range:prefixRange];

        // And append the string rendered according to event state
        [str appendAttributedString:[self renderString:string forEvent:event]];

        return str;
    }
    else
    {
        // Use the legacy method
        return [self renderString:string forEvent:event];
    }
}

- (void)setDefaultCSS:(NSString*)defaultCSS
{
    // Make sure we mark HTML blockquote blocks for later computation
    _defaultCSS = [NSString stringWithFormat:@"%@%@", [MXKTools cssToMarkBlockquotes], defaultCSS];

    dtCSS = [[DTCSSStylesheet alloc] initWithStyleBlock:_defaultCSS];
}

#pragma mark - MXRoomSummaryUpdating
- (BOOL)session:(MXSession *)session updateRoomSummary:(MXRoomSummary *)summary withStateEvents:(NSArray<MXEvent *> *)stateEvents roomState:(MXRoomState *)roomState
{
    // We build strings containing the sender displayname (ex: "Bob: Hello!")
    // If a sender changes his displayname, we need to update the lastMessage.
    MXRoomLastMessage *lastMessage;
    for (MXEvent *event in stateEvents)
    {
        if (event.isUserProfileChange)
        {
            if (!lastMessage)
            {
                // Load lastMessageEvent on demand to save I/O
                lastMessage = summary.lastMessage;
            }

            if ([event.sender isEqualToString:lastMessage.sender])
            {
                // The last message must be recomputed
                [summary resetLastMessage:nil failure:nil commit:YES];
                break;
            }
        }
        else if (event.eventType == MXEventTypeRoomJoinRules)
        {
            summary.joinRule = roomState.joinRule;
        }
    }

    return [defaultRoomSummaryUpdater session:session updateRoomSummary:summary withStateEvents:stateEvents roomState:roomState];
}

- (BOOL)session:(MXSession *)session updateRoomSummary:(MXRoomSummary *)summary withLastEvent:(MXEvent *)event eventState:(MXRoomState *)eventState roomState:(MXRoomState *)roomState
{
    // Use the default updater as first pass
    MXRoomLastMessage *currentlastMessage = summary.lastMessage;
    BOOL updated = [defaultRoomSummaryUpdater session:session updateRoomSummary:summary withLastEvent:event eventState:eventState roomState:roomState];
    if (updated)
    {
        // Then customise

        // Compute the text message
        // Note that we use the current room state (roomState) because when we display
        // users displaynames, we want current displaynames
        MXKEventFormatterError error;
        NSString *lastMessageString = [self stringFromEvent:event withRoomState:roomState error:&error];
        
        if (0 == lastMessageString.length)
        {
            // @TODO: there is a conflict with what [defaultRoomSummaryUpdater updateRoomSummary] did :/
            updated = NO;
            // Restore the previous lastMessageEvent
            [summary updateLastMessage:currentlastMessage];
        }
        else
        {
            summary.lastMessage.text = lastMessageString;
            
            if (summary.lastMessage.others == nil)
            {
                summary.lastMessage.others = [NSMutableDictionary dictionary];
            }
            
            // Store the potential error
            summary.lastMessage.others[@"mxkEventFormatterError"] = @(error);
            
            summary.lastMessage.others[@"lastEventDate"] = [self dateStringFromEvent:event withTime:YES];

            // Check whether the sender name has to be added
            NSString *prefix = nil;

            if (event.eventType == MXEventTypeRoomMessage)
            {
                NSString *msgtype = event.content[kMXMessageTypeKey];
                if ([msgtype isEqualToString:kMXMessageTypeEmote] == NO)
                {
                    NSString *senderDisplayName = [self senderDisplayNameForEvent:event withRoomState:roomState];
                    prefix = [NSString stringWithFormat:@"%@: ", senderDisplayName];
                }
            }
            else if (event.eventType == MXEventTypeSticker)
            {
                NSString *senderDisplayName = [self senderDisplayNameForEvent:event withRoomState:roomState];
                prefix = [NSString stringWithFormat:@"%@: ", senderDisplayName];
            }

            // Compute the attribute text message
            summary.lastMessage.attributedText = [self renderString:summary.lastMessage.text withPrefix:prefix forEvent:event];
        }
    }
    
    return updated;
}

- (BOOL)session:(MXSession *)session updateRoomSummary:(MXRoomSummary *)summary withServerRoomSummary:(MXRoomSyncSummary *)serverRoomSummary roomState:(MXRoomState *)roomState
{
    return [defaultRoomSummaryUpdater session:session updateRoomSummary:summary withServerRoomSummary:serverRoomSummary roomState:roomState];
}


#pragma mark - Conversion private methods

/**
 Get the text color to use according to the event state.
 
 @param event the event.
 @return the text color.
 */
- (UIColor*)textColorForEvent:(MXEvent*)event
{
    // Select the text color
    UIColor *textColor;
    
    // Check whether an error occurred during event formatting.
    if (event.mxkEventFormatterError != MXKEventFormatterErrorNone)
    {
        textColor = _errorTextColor;
    }
    // Check whether the message is highlighted.
    else if (event.mxkIsHighlighted || (event.isInThread && !RiotSettings.shared.enableThreads && ![event.sender isEqualToString:mxSession.myUserId]))
    {
        textColor = _bingTextColor;
    }
    else
    {
        // Consider here the sending state of the event, and the property `isForSubtitle`.
        switch (event.sentState)
        {
            case MXEventSentStateSent:
                if (_isForSubtitle)
                {
                    textColor = _subTitleTextColor;
                }
                else
                {
                    textColor = _defaultTextColor;
                }
                break;
            case MXEventSentStateEncrypting:
                textColor = _encryptingTextColor;
                break;
            case MXEventSentStatePreparing:
            case MXEventSentStateUploading:
            case MXEventSentStateSending:
                textColor = _sendingTextColor;
                break;
            case MXEventSentStateFailed:
                textColor = _errorTextColor;
                break;
            default:
                if (_isForSubtitle)
                {
                    textColor = _subTitleTextColor;
                }
                else
                {
                    textColor = _defaultTextColor;
                }
                break;
        }
    }
    
    return textColor;
}

/**
 Get the text font to use according to the event state.

 @param event the event.
 @return the text font.
 */
- (UIFont*)fontForEvent:(MXEvent*)event
{
    // Select text font
    UIFont *font = _defaultTextFont;
    if (event.isState)
    {
        font = _stateEventTextFont;
    }
    else if (event.eventType == MXEventTypeCallInvite || event.eventType == MXEventTypeCallAnswer || event.eventType == MXEventTypeCallHangup)
    {
        font = _callNoticesTextFont;
    }
    else if (event.mxkIsHighlighted || (event.isInThread && !RiotSettings.shared.enableThreads && ![event.sender isEqualToString:mxSession.myUserId]))
    {
        font = _bingTextFont;
    }
    else if (event.eventType == MXEventTypeRoomEncrypted)
    {
        font = _encryptedMessagesTextFont;
    }
    else if (!_isForSubtitle && event.eventType == MXEventTypeRoomMessage && (_emojiOnlyTextFont || _singleEmojiTextFont))
    {
        NSString *message;
        MXJSONModelSetString(message, event.content[kMXMessageBodyKey]);

        if (_emojiOnlyTextFont && [MXKTools isEmojiOnlyString:message])
        {
            font = _emojiOnlyTextFont;
        }
        else if (_singleEmojiTextFont && [MXKTools isSingleEmojiString:message])
        {
            font = _singleEmojiTextFont;
        }
    }
    return font;
}

#pragma mark - Conversion tools

- (NSString *)htmlStringFromMarkdownString:(NSString *)markdownString
{
    NSString *htmlString = [_markdownToHTMLRenderer renderToHTMLWithMarkdown:markdownString];

    // Strip off the trailing newline, if it exists.
    if ([htmlString hasSuffix:@"\n"])
    {
        htmlString = [htmlString substringToIndex:htmlString.length - 1];
    }

    // Strip start and end <p> tags else you get 'orrible spacing.
    // But only do this if it's a single paragraph we're dealing with,
    // otherwise we'll produce some garbage (`something</p><p>another`).
    if ([htmlString hasPrefix:@"<p>"] && [htmlString hasSuffix:@"</p>"])
    {
        NSArray *components = [htmlString componentsSeparatedByString:@"<p>"];
        NSUInteger paragrapsCount = components.count - 1;

        if (paragrapsCount == 1) {
            htmlString = [htmlString substringFromIndex:3];
            htmlString = [htmlString substringToIndex:htmlString.length - 4];
        }
    }

    return htmlString;
}

#pragma mark - Timestamp formatting

- (NSString*)dateStringFromDate:(NSDate *)date withTime:(BOOL)time
{
    // Get first date string without time (if a date format is defined, else only time string is returned)
    NSString *dateString = nil;
    if (dateFormatter.dateFormat)
    {
        dateString = [dateFormatter stringFromDate:date];
    }
    
    if (time)
    {
        NSString *timeString = [self timeStringFromDate:date];
        if (dateString.length)
        {
            // Add time string
            dateString = [NSString stringWithFormat:@"%@ %@", dateString, timeString];
        }
        else
        {
            dateString = timeString;
        }
    }
    
    return dateString;
}

- (NSString*)dateStringFromTimestamp:(uint64_t)timestamp withTime:(BOOL)time
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp / 1000];
    
    return [self dateStringFromDate:date withTime:time];
}

- (NSString*)dateStringFromEvent:(MXEvent *)event withTime:(BOOL)time
{
    if (event.originServerTs != kMXUndefinedTimestamp)
    {
        return [self dateStringFromTimestamp:event.originServerTs withTime:time];
    }
    
    return nil;
}

- (NSString*)timeStringFromDate:(NSDate *)date
{
    NSString *timeString = [timeFormatter stringFromDate:date];
    
    return timeString.lowercaseString;
}

@end
