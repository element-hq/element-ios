/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "EventFormatter.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "WidgetManager.h"

#import "MXDecryptionResult.h"

#import <MatrixSDK/MatrixSDK.h>

#pragma mark - Constants definitions

NSString *const EventFormatterOnReRequestKeysLinkAction = @"EventFormatterOnReRequestKeysLinkAction";
NSString *const EventFormatterLinkActionSeparator = @"/";
NSString *const EventFormatterEditedEventLinkAction = @"EventFormatterEditedEventLinkAction";

NSString *const FunctionalMembersStateEventType = @"io.element.functional_members";
NSString *const FunctionalMembersServiceMembersKey = @"service_members";

static NSString *const kEventFormatterTimeFormat = @"HH:mm";

@interface EventFormatter ()
{
    /**
     The calendar used to retrieve the today date.
     */
    NSCalendar *calendar;
}
@end

@implementation EventFormatter

- (void)initDateTimeFormatters
{
    [super initDateTimeFormatters];
    
    timeFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [timeFormatter setDateFormat:kEventFormatterTimeFormat];
}

- (NSString *)stringFromEvent:(MXEvent *)event
                withRoomState:(MXRoomState *)roomState
           andLatestRoomState:(MXRoomState *)latestRoomState
                        error:(MXKEventFormatterError *)error
{
    NSString *stringFromEvent;
    NSAttributedString *attributedStringFromEvent = [self attributedStringFromEvent:event
                                                                      withRoomState:roomState
                                                                 andLatestRoomState:latestRoomState
                                                                       displayPills:NO
                                                                              error:error];
    if (*error == MXKEventFormatterErrorNone)
    {
        stringFromEvent = attributedStringFromEvent.string;
    }

    return stringFromEvent;
}

- (NSAttributedString *)attributedStringFromEvent:(MXEvent *)event
                                    withRoomState:(MXRoomState *)roomState
                               andLatestRoomState:(MXRoomState *)latestRoomState
                                     displayPills:(BOOL)displayPills
                                            error:(MXKEventFormatterError *)error
{
    NSAttributedString *string = [self unsafeAttributedStringFromEvent:event
                                                         withRoomState:roomState
                                                    andLatestRoomState:latestRoomState
                                                                 error:error];
    if (!string)
    {
        MXLogDebug(@"[EventFormatter]: No attributed string for event: %@, type: %@, msgtype: %@, has room state: %d, members: %lu, error: %lu",
                   event.eventId,
                   event.type,
                   event.content[@"msgtype"],
                   roomState != nil,
                   roomState.membersCount.members,
                   *error);

        // If we cannot create attributed string, but the message is nevertheless meant for display, show generic error
        // instead of a missing message on a timeline.
        if ([self shouldDisplayEvent:event]) {
            MXLogErrorDetails(@"[EventFormatter]: Missing attributed string for message event", @{
                @"event_id": event.eventId ?: @"unknown"
            });
            string = [[NSAttributedString alloc] initWithString:[VectorL10n noticeErrorUnformattableEvent] attributes:@{
                NSFontAttributeName: [self encryptedMessagesTextFont],
                NSForegroundColorAttributeName: [self encryptingTextColor]
            }];
        }
    }

    if (@available(iOS 15.0, *))
    {
        if (displayPills && roomState && [self shouldDisplayEvent:event])
        {
            string = [PillsFormatter insertPillsIn:string
                                       withSession:mxSession
                                    eventFormatter:self
                                             event:event
                                         roomState:roomState
                                andLatestRoomState:latestRoomState
                                        isEditMode:NO];
        }
    }

    return string;
}

- (NSAttributedString *)attributedStringFromEvent:(MXEvent *)event
                                    withRoomState:(MXRoomState *)roomState
                               andLatestRoomState:(MXRoomState *)latestRoomState
                                            error:(MXKEventFormatterError *)error
{
    return [self attributedStringFromEvent:event
                             withRoomState:roomState
                        andLatestRoomState:latestRoomState
                              displayPills:YES
                                     error:error];
}

- (BOOL)shouldDisplayEvent:(MXEvent *)event {
    return event.eventType == MXEventTypeRoomMessage
    && !event.isEditEvent
    && !event.isRedactedEvent;
}

// The attributed string can fail to be created for a number of reasons, and the size of the function (as well as super's implementation) makes
// it impossible to catch all the `return nil` and failure states.
// To make catching of missing strings reliable (and not place that burden on callers), we use private `unsafeAttributedStringFromEvent` method
// which is called by the public `attributedStringFromEvent`, and which also handles the catch-all missing message.
- (NSAttributedString *)unsafeAttributedStringFromEvent:(MXEvent *)event
                                          withRoomState:(MXRoomState *)roomState
                                     andLatestRoomState:(MXRoomState *)latestRoomState
                                                  error:(MXKEventFormatterError *)error
{
    if (event.isRedactedEvent)
    {
        if (event.eventType == MXEventTypeReaction)
        {
            //  do not show redacted reactions in the timeline
            return nil;
        }
        // Check whether the event is a thread root or redacted information is required
        if ((RiotSettings.shared.enableThreads && [mxSession.threadingService isEventThreadRoot:event])
            || self.settings.showRedactionsInRoomHistory)
        {
            NSAttributedString *result = [self redactedMessageReplacementAttributedString];
            
            if (error)
            {
                *error = MXKEventFormatterErrorNone;
            }
            
            return result;
        }
    }
    BOOL isEventSenderMyUser = [event.sender isEqualToString:mxSession.myUserId];
    
    if (event.eventType == MXEventTypeCustom) {
        
        // Build strings for widget events
        if ([event.type isEqualToString:kWidgetMatrixEventTypeString]
                || [event.type isEqualToString:kWidgetModularEventTypeString])
        {
            NSString *displayText;
            
            Widget *widget = [[Widget alloc] initWithWidgetEvent:event inMatrixSession:mxSession];
            if (widget)
            {
                // Prepare the display name of the sender
                NSString *senderDisplayName = roomState ? [self senderDisplayNameForEvent:event withRoomState:roomState] : event.sender;
                
                if (widget.isActive)
                {
                    if ([widget.type isEqualToString:kWidgetTypeJitsiV1]
                        || [widget.type isEqualToString:kWidgetTypeJitsiV2])
                    {
                        // This is an alive jitsi widget
                        if (isEventSenderMyUser)
                        {
                            displayText = [VectorL10n eventFormatterJitsiWidgetAddedByYou];
                        }
                        else
                        {
                            displayText = [VectorL10n eventFormatterJitsiWidgetAdded:senderDisplayName];
                        }
                    }
                    else
                    {
                        if (isEventSenderMyUser)
                        {
                            displayText = [VectorL10n eventFormatterWidgetAddedByYou:(widget.name ? widget.name : widget.type)];
                        }
                        else
                        {
                            displayText = [VectorL10n eventFormatterWidgetAdded:(widget.name ? widget.name : widget.type) :senderDisplayName];
                        }
                    }
                }
                else
                {
                    // This is a closed widget
                    // Check if it corresponds to a jitsi widget by looking at other state events for
                    // this jitsi widget (widget id = event.stateKey).
                    // Get all widgets state events in the room
                    NSMutableArray<MXEvent*> *widgetStateEvents = [NSMutableArray arrayWithArray:[roomState stateEventsWithType:kWidgetMatrixEventTypeString]];
                    [widgetStateEvents addObjectsFromArray:[roomState stateEventsWithType:kWidgetModularEventTypeString]];
                    
                    for (MXEvent *widgetStateEvent in widgetStateEvents)
                    {
                        if ([widgetStateEvent.stateKey isEqualToString:widget.widgetId])
                        {
                            Widget *activeWidget = [[Widget alloc] initWithWidgetEvent:widgetStateEvent inMatrixSession:mxSession];
                            if (activeWidget.isActive)
                            {
                                if ([activeWidget.type isEqualToString:kWidgetTypeJitsiV1]
                                    || [activeWidget.type isEqualToString:kWidgetTypeJitsiV2])
                                {
                                    // This was a jitsi widget
                                    return nil;
                                }
                                else
                                {
                                    if (isEventSenderMyUser)
                                    {
                                        displayText = [VectorL10n eventFormatterWidgetRemovedByYou:(activeWidget.name ? activeWidget.name : activeWidget.type)];
                                    }
                                    else
                                    {
                                        displayText = [VectorL10n eventFormatterWidgetRemoved:(activeWidget.name ? activeWidget.name : activeWidget.type) :senderDisplayName];
                                    }
                                }
                                break;
                            }
                        }
                    }
                }
            }
        
            if (displayText)
            {
                if (error)
                {
                    *error = MXKEventFormatterErrorNone;
                }

                // Build the attributed string with the right font and color for the events
                return [self renderString:displayText forEvent:event];
            }
        } else if ([event.type isEqualToString:VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType]) {
            //  do not show voice broadcast info in the timeline
            return nil;
        }
    }
    
    switch (event.eventType)
    {
        case MXEventTypeRoomCreate:
        {
            MXRoomCreateContent *createContent = [MXRoomCreateContent modelFromJSON:event.content];
            
            NSString *roomPredecessorId = createContent.roomPredecessorInfo.roomId;
            
            if (roomPredecessorId)
            {
                return [self roomCreatePredecessorAttributedStringWithPredecessorRoomId:roomPredecessorId];
            }
            else
            {
                NSAttributedString *string = [super attributedStringFromEvent:event
                                                                withRoomState:roomState
                                                           andLatestRoomState:latestRoomState
                                                                        error:error];
                NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@"· "];
                [result appendAttributedString:string];
                return result;
            }
        }
            break;
        case MXEventTypeCallCandidates:
        case MXEventTypeCallSelectAnswer:
        case MXEventTypeCallNegotiate:
        case MXEventTypeCallReplaces:
        case MXEventTypeCallRejectReplacement:
            //  Do not show call events except invite and reject in timeline
            return nil;
        case MXEventTypeCallInvite:
        {
            MXCallInviteEventContent *content = [MXCallInviteEventContent modelFromJSON:event.content];
            MXCall *call = [mxSession.callManager callWithCallId:content.callId];
            if (call && call.isIncoming && call.state == MXCallStateRinging)
            {
                //  incoming call UI will be handled by CallKit (or incoming call screen if CallKit disabled)
                //  do not show a bubble for this case
                return nil;
            }
        }
            break;
        case MXEventTypeKeyVerificationCancel:
        case MXEventTypeKeyVerificationDone:
            // Make event types MXEventTypeKeyVerificationCancel and MXEventTypeKeyVerificationDone visible in timeline.
            // TODO: Find another way to keep them visible and avoid instantiate empty NSMutableAttributedString.
            return [NSMutableAttributedString new];
        default:
            break;
    }
    
    NSAttributedString *attributedString = [super attributedStringFromEvent:event
                                                              withRoomState:roomState
                                                         andLatestRoomState:latestRoomState
                                                                      error:error];

    if (event.sentState == MXEventSentStateSent
        && [event.decryptionError.domain isEqualToString:MXDecryptingErrorDomain])
    {
        // Track e2e failures
        dispatch_async(dispatch_get_main_queue(), ^{
            [[DecryptionFailureTracker sharedInstance] reportUnableToDecryptErrorForEvent:event withRoomState:roomState mySession:self->mxSession];
        });

        if (event.decryptionError.code == MXDecryptingErrorUnknownInboundSessionIdCode)
        {
            // Append to the displayed error an attibuted string with a tappable link
            // so that the user can try to fix the UTD
            NSMutableAttributedString *attributedStringWithRerequestMessage = [attributedString mutableCopy];
            [attributedStringWithRerequestMessage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];

            NSString *linkActionString = [NSString stringWithFormat:@"%@%@%@", EventFormatterOnReRequestKeysLinkAction,
                                          EventFormatterLinkActionSeparator,
                                          event.eventId];

            [attributedStringWithRerequestMessage appendAttributedString:
             [[NSAttributedString alloc] initWithString:[VectorL10n eventFormatterRerequestKeysPart1Link]
                                             attributes:@{
                                                          NSLinkAttributeName: linkActionString,
                                                          NSForegroundColorAttributeName: self.sendingTextColor,
                                                          NSFontAttributeName: self.encryptedMessagesTextFont,
                                                          NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleSingle] 
                                                          }]];

            [attributedStringWithRerequestMessage appendAttributedString:
             [[NSAttributedString alloc] initWithString:[VectorL10n eventFormatterRerequestKeysPart2]
                                             attributes:@{
                                                          NSForegroundColorAttributeName: self.sendingTextColor,
                                                          NSFontAttributeName: self.encryptedMessagesTextFont
                                                          }]];

            attributedString = attributedStringWithRerequestMessage;
        }
    }
    else if (self.showEditionMention && event.contentHasBeenEdited)
    {
        NSMutableAttributedString *attributedStringWithEditMention = [attributedString mutableCopy];
        
        NSString *linkActionString = [NSString stringWithFormat:@"%@%@%@", EventFormatterEditedEventLinkAction,
                                      EventFormatterLinkActionSeparator,
                                      event.eventId];
        
        [attributedStringWithEditMention appendAttributedString:
         [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", [VectorL10n eventFormatterMessageEditedMention]]
                                         attributes:@{
                                                      NSLinkAttributeName: linkActionString,
                                                      NSForegroundColorAttributeName: self.editionMentionTextColor,
                                                      NSFontAttributeName: self.editionMentionTextFont
                                                      }]];
        
        attributedString = attributedStringWithEditMention;
    }

    return attributedString;
}

- (NSAttributedString*)attributedStringFromEvents:(NSArray<MXEvent*>*)events
                                    withRoomState:(MXRoomState*)roomState
                               andLatestRoomState:(MXRoomState*)latestRoomState
                                            error:(MXKEventFormatterError*)error
{
    NSString *displayText;

    if (events.count)
    {
        MXEvent *roomCreateEvent = [events filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", kMXEventTypeStringRoomCreate]].firstObject;
        
        MXEvent *callInviteEvent = [events filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", kMXEventTypeStringCallInvite]].firstObject;
        
        if (roomCreateEvent)
        {
            MXKEventFormatterError tmpError;
            displayText = [super attributedStringFromEvent:roomCreateEvent
                                             withRoomState:roomState
                                        andLatestRoomState:latestRoomState
                                                     error:&tmpError].string;

            NSAttributedString *rendered = [self renderString:displayText forEvent:roomCreateEvent];
            NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@"· "];
            [result appendAttributedString:rendered];
            [result setAttributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:13],
                NSForegroundColorAttributeName: ThemeService.shared.theme.textSecondaryColor
            } range:NSMakeRange(0, result.length)];
            //  add one-char space
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            //  add more link
            NSAttributedString *linkMore = [[NSAttributedString alloc] initWithString:[VectorL10n more] attributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:13],
                NSForegroundColorAttributeName: ThemeService.shared.theme.tintColor
            }];
            [result appendAttributedString:linkMore];
            return result;
        }
        else if (callInviteEvent)
        {
            //  return a non-nil value
            return [NSMutableAttributedString new];
        }
        else if (events[0].eventType == MXEventTypeRoomMember)
        {
            // This is a series for cells tagged with RoomBubbleCellDataTagMembership
            // TODO: Build a complete summary like Riot-web
            displayText = [VectorL10n eventFormatterMemberUpdates:events.count];
        }
    }

    if (displayText)
    {
        // Build the attributed string with the right font and color for the events
        return [self renderString:displayText forEvent:events[0]];
    }

    return [super attributedStringFromEvents:events
                               withRoomState:roomState
                          andLatestRoomState:latestRoomState
                                       error:error];
}

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [super initWithMatrixSession:matrixSession];
    if (self)
    {
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        
        // Use the selected bg color to set the code block background color in the default CSS.
        NSUInteger bgColor = [MXKTools rgbValueWithColor:ThemeService.shared.theme.selectedBackgroundColor];
        self.defaultCSS = [NSString stringWithFormat:@" \
                           pre,code { \
                           background-color: #%06lX; \
                           display: inline; \
                           font-family: monospace; \
                           white-space: pre; \
                           -coretext-fontname: Menlo-Regular; \
                           font-size: small; \
                           } \
                           h1,h2 { \
                           font-size: 1.2em; \
                           }", (unsigned long)bgColor];
        
        self.defaultTextColor = ThemeService.shared.theme.textPrimaryColor;
        self.subTitleTextColor = ThemeService.shared.theme.textSecondaryColor;
        self.prefixTextColor = ThemeService.shared.theme.textSecondaryColor;
        self.bingTextColor = ThemeService.shared.theme.noticeColor;
        self.encryptingTextColor = ThemeService.shared.theme.textPrimaryColor;
        self.sendingTextColor = ThemeService.shared.theme.textPrimaryColor;
        self.linksColor = ThemeService.shared.theme.colors.links;
        self.errorTextColor = ThemeService.shared.theme.textPrimaryColor;
        self.showEditionMention = YES;
        self.editionMentionTextColor = ThemeService.shared.theme.textSecondaryColor;
        
        self.defaultTextFont = [UIFont systemFontOfSize:15];
        self.prefixTextFont = [UIFont boldSystemFontOfSize:15];
        self.bingTextFont = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        self.stateEventTextFont = [UIFont italicSystemFontOfSize:15];
        self.callNoticesTextFont = [UIFont italicSystemFontOfSize:15];
        self.encryptedMessagesTextFont = [UIFont italicSystemFontOfSize:15];
        self.emojiOnlyTextFont = [UIFont systemFontOfSize:48];
        self.editionMentionTextFont = [UIFont systemFontOfSize:12];
        
        // Handle space and video room types, enables their display in the room list
        defaultRoomSummaryUpdater.showRoomTypeStrings = @[
            MXRoomTypeStringSpace,
            MXRoomTypeStringVideo
        ];
    }
    return self;
}

- (NSDictionary*)stringAttributesForEventTimestamp
{
    return @{
             NSForegroundColorAttributeName : [UIColor lightGrayColor],
             NSFontAttributeName: [UIFont systemFontOfSize:10]
             };
}

#pragma mark event sender info

- (NSString*)senderAvatarUrlForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState
{
    // Override this method to ignore the identicons defined by default in matrix kit.
    
    // Consider first the avatar url defined in provided room state (Note: this room state is supposed to not take the new event into account)
    NSString *senderAvatarUrl = [roomState.members memberWithUserId:event.sender].avatarUrl;
    
    // Check whether this avatar url is updated by the current event (This happens in case of new joined member)
    NSString* membership = event.content[@"membership"];
    NSString* eventAvatarUrl = event.content[@"avatar_url"];
    NSString* prevEventAvatarUrl = event.prevContent[@"avatar_url"];
    if (membership && [membership isEqualToString:@"join"] && [eventAvatarUrl length] && ![eventAvatarUrl isEqualToString:prevEventAvatarUrl])
    {
        // Use the actual avatar
        senderAvatarUrl = eventAvatarUrl;
    }
    
    // We ignore non mxc avatar url (The identicons are removed here).
    if (senderAvatarUrl && [senderAvatarUrl hasPrefix:kMXContentUriScheme] == NO)
    {
        senderAvatarUrl = nil;
    }
    
    return senderAvatarUrl;
}

#pragma mark - MXRoomSummaryUpdating
- (BOOL)session:(MXSession *)session updateRoomSummary:(MXRoomSummary *)summary withLastEvent:(MXEvent *)event eventState:(MXRoomState *)eventState roomState:(MXRoomState *)roomState
{
    // Do not display voice broadcast chunk in last message.
    if (event.eventType == MXEventTypeRoomMessage && event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType])
    {
        return NO;
    }
    
    // Update last message if we have a voice broadcast in the room.
    MXEvent *lastVoiceBroadcastInfoEvent = [self lastVoiceBroadcastInfoEventWithEvent:event roomState:roomState];
    if (lastVoiceBroadcastInfoEvent != nil)
    {
        MXEvent *voiceBroadcastInfoStartedEvent = [self voiceBroadcastInfoStartedEventWithEvent:lastVoiceBroadcastInfoEvent
                                                                                         roomId:summary.roomId
                                                                                        session:session];
        if (voiceBroadcastInfoStartedEvent != nil
            && !(voiceBroadcastInfoStartedEvent.isRedactedEvent || [voiceBroadcastInfoStartedEvent.eventId isEqualToString:event.redacts]))
        {
            return [self session:session
               updateRoomSummary:summary
withVoiceBroadcastInfoStateEvent:lastVoiceBroadcastInfoEvent
  voiceBroadcastInfoStartedEvent:voiceBroadcastInfoStartedEvent
                       roomState:roomState];
        }
    }
    
    BOOL updated = [super session:session updateRoomSummary:summary withLastEvent:event eventState:eventState roomState:roomState];
    
    if (updated)
    {
        // Force the default text color for the last message (cancel highlighted message color)
        NSMutableAttributedString *lastEventDescription = [[NSMutableAttributedString alloc] initWithAttributedString:summary.lastMessage.attributedText];
        NSRange range = NSMakeRange(0, lastEventDescription.length);
        [lastEventDescription addAttribute:NSForegroundColorAttributeName
                                     value:ThemeService.shared.theme.colors.secondaryContent
                                     range:range];
        [lastEventDescription addThemeColorNameAttribute:@"secondaryContent" range:range];
        [lastEventDescription addThemeIdentifierAttribute];
        
        summary.lastMessage.attributedText = lastEventDescription;
    }
    
    return updated;
}


- (MXEvent *)lastVoiceBroadcastInfoEventWithEvent:(MXEvent *)event roomState:(MXRoomState *)roomState
{
    MXEvent *voiceBroadcastInfoEvent = nil;
    VoiceBroadcastInfo *info = nil;
    if ([event.type isEqualToString:VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType])
    {
        info = [VoiceBroadcastInfo modelFromJSON: event.content];
        
        if (info != nil)
        {
            voiceBroadcastInfoEvent = event;
        }
    }
    else
    {
        MXEvent *stateEvent = [roomState stateEventsWithType:VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType].lastObject;
        if (stateEvent != nil)
        {
            info = [VoiceBroadcastInfo modelFromJSON: stateEvent.content];
            if (info != nil && ![VoiceBroadcastInfo isStoppedFor:info.state])
            {
                voiceBroadcastInfoEvent = stateEvent;
            }
        }
    }
    
    return voiceBroadcastInfoEvent;
}

- (MXEvent *)voiceBroadcastInfoStartedEventWithEvent:(MXEvent *)voiceBroadcastInfoEvent roomId:(NSString *)roomId session:(MXSession *)session
{
    VoiceBroadcastInfo *voiceBroadcastInfo = [VoiceBroadcastInfo modelFromJSON: voiceBroadcastInfoEvent.content];
    if ([VoiceBroadcastInfo isStartedFor:voiceBroadcastInfo.state])
    {
        return voiceBroadcastInfoEvent;
    }
    else
    {
        // Search for the event only in the store to avoid network calls while updating the room summary (this a synchronous process and we cannot delay it).
        return [mxSession.store eventWithEventId:voiceBroadcastInfo.voiceBroadcastId inRoom:roomId];
    }
}

- (BOOL)session:(MXSession *)session updateRoomSummary:(MXRoomSummary *)summary withStateEvents:(NSArray<MXEvent *> *)stateEvents roomState:(MXRoomState *)roomState
{
    BOOL updated = [super session:session updateRoomSummary:summary withStateEvents:stateEvents roomState:roomState];

    MXEvent* lastRoomRetentionEvent = [self roomRetentionEventFromStateEvents:stateEvents];
    if (lastRoomRetentionEvent)
    {
        summary.others[MXRoomSummary.roomRetentionMaxLifetime] = lastRoomRetentionEvent.content[MXRoomSummary.roomRetentionEventMaxLifetimeKey];
        updated = YES;
    }
        
    // Customisation for EMS Functional Members in direct rooms
    if (BuildSettings.supportFunctionalMembers && summary.room.isDirect)
    {
        if ([self functionalMembersEventFromStateEvents:stateEvents])
        {
            MXLogDebug(@"[EventFormatter] The functional members event has been updated.")
            
            // The stateEvents parameter contains state events that may change the room summary. If service members are found,
            // it's likely that something changed. As they aren't stored, the only reliable check would be to compute the
            // room name which we'll do twice more in updateRoomSummary:withServerRoomSummary:roomState: anyway.
            //
            // So return YES and let that happen there.
            updated = YES;
        }
    }
    
    return updated;
}

- (BOOL)session:(MXSession *)session updateRoomSummary:(MXRoomSummary *)summary withVoiceBroadcastInfoStateEvent:(MXEvent *)stateEvent voiceBroadcastInfoStartedEvent:(MXEvent *)voiceBroadcastInfoStartedEvent roomState:(MXRoomState *)roomState
{
    BOOL isStoppedVoiceBroadcast = [VoiceBroadcastInfo isStoppedFor:[VoiceBroadcastInfo modelFromJSON: stateEvent.content].state];
    
    if ([summary.lastMessage.eventId isEqualToString:voiceBroadcastInfoStartedEvent.eventId])
    {
        if (!isStoppedVoiceBroadcast)
        {
            return NO;
        }
    }
    else
    {
        [summary updateLastMessage:[[MXRoomLastMessage alloc] initWithEvent:voiceBroadcastInfoStartedEvent]];
        if (summary.lastMessage.others == nil)
        {
            summary.lastMessage.others = [NSMutableDictionary dictionary];
        }
    }
    
    NSAttributedString *attachmentString = nil;
    UIColor *textColor;
    NSString *colorIdentifier;
    if (isStoppedVoiceBroadcast)
    {
        textColor = ThemeService.shared.theme.colors.secondaryContent;
        colorIdentifier = @"secondaryContent";
        NSString *senderDisplayName;
        if ([stateEvent.stateKey isEqualToString:session.myUser.userId])
        {
            summary.lastMessage.text = VectorL10n.noticeVoiceBroadcastEndedByYou;
        }
        else
        {
            senderDisplayName = [self senderDisplayNameForEvent:stateEvent withRoomState:roomState];
            summary.lastMessage.text = [VectorL10n noticeVoiceBroadcastEnded:senderDisplayName];
        }
        summary.lastMessage.others[@"lastEventDate"] = [self dateStringFromEvent:stateEvent withTime:YES];
    }
    else
    {
        textColor = ThemeService.shared.theme.colors.alert;
        colorIdentifier = @"alert";
        UIImage *liveImage = AssetImages.voiceBroadcastLive.image;
        
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [liveImage imageWithTintColor:textColor renderingMode:UIImageRenderingModeAlwaysTemplate];
        attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        
        summary.lastMessage.text = VectorL10n.noticeVoiceBroadcastLive;
        summary.lastMessage.others[@"lastEventDate"] = [self dateStringFromEvent:voiceBroadcastInfoStartedEvent withTime:YES];
    }
    
    // Compute the attribute text message
    NSMutableAttributedString *lastMessage;
    if (attachmentString)
    {
        lastMessage = [[NSMutableAttributedString alloc] initWithAttributedString:attachmentString];
        // Change base line
        [lastMessage addAttribute:NSBaselineOffsetAttributeName value:@(-3.0f) range:NSMakeRange(0, attachmentString.length)];
        
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", summary.lastMessage.text]];
        [lastMessage appendAttributedString:attributedText];
        [lastMessage addAttribute:NSFontAttributeName value:self.defaultTextFont range:NSMakeRange(0, lastMessage.length)];
    }
    else
    {
        NSAttributedString *attributedText = [self renderString:summary.lastMessage.text forEvent:stateEvent];
        lastMessage = [[NSMutableAttributedString alloc] initWithAttributedString:attributedText];
    }
    
    [lastMessage addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, lastMessage.length)];
    if (colorIdentifier)
    {
        [lastMessage addThemeColorNameAttribute:colorIdentifier range:NSMakeRange(0, lastMessage.length)];
        [lastMessage addThemeIdentifierAttribute];
    }

    summary.lastMessage.attributedText = lastMessage;
    
    return YES;
}

- (NSAttributedString *)redactedMessageReplacementAttributedString
{
    UIFont *font = self.defaultTextFont;
    UIColor *color = ThemeService.shared.theme.colors.secondaryContent;
    NSString *string = [NSString stringWithFormat:@" %@", VectorL10n.eventFormatterMessageDeleted];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string
                                                                     attributes:@{
                                                                         NSFontAttributeName: font,
                                                                         NSForegroundColorAttributeName: color
                                                                     }];

    CGSize imageSize = CGSizeMake(20, 20);
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [[AssetImages.roomContextMenuDelete.image vc_resizedWith:imageSize] vc_tintedImageUsingColor:color];
    attachment.bounds = CGRectMake(0, font.descender, imageSize.width, imageSize.height);
    NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:attachment];

    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithAttributedString:imageString];
    [result appendAttributedString:attrString];

    return result;
}

- (BOOL)session:(MXSession *)session updateRoomSummary:(MXRoomSummary *)summary withServerRoomSummary:(MXRoomSyncSummary *)serverRoomSummary roomState:(MXRoomState *)roomState
{
    BOOL updated = [super session:session updateRoomSummary:summary withServerRoomSummary:serverRoomSummary roomState:roomState];
    
    // Customisation for EMS Functional Members in direct rooms
    if (BuildSettings.supportFunctionalMembers && summary.room.isDirect)
    {
        MXEvent *functionalMembersEvent = [self functionalMembersEventFromStateEvents:roomState.stateEvents];
        
        if (functionalMembersEvent)
        {
            MXLogDebug(@"[EventFormatter] Computing the room name and avatar excluding functional members.")
            
            NSArray<NSString*> *serviceMemberIDs = functionalMembersEvent.content[FunctionalMembersServiceMembersKey] ?: @[];
            
            updated |= [defaultRoomSummaryUpdater updateSummaryDisplayname:summary
                                                                   session:session
                                                     withServerRoomSummary:serverRoomSummary
                                                                 roomState:roomState
                                                          excludingUserIDs:serviceMemberIDs];
            
            updated |= [defaultRoomSummaryUpdater updateSummaryAvatar:summary
                                                              session:session
                                                withServerRoomSummary:serverRoomSummary
                                                            roomState:roomState
                                                     excludingUserIDs:serviceMemberIDs];
        }
    }

    return updated;
}

/**
 Gets the latest state event of type `io.element.functional_members` from the supplied array of state events.
 Note: This function will be expensive on big rooms, recommended for use only on DMs.
 @return An event of type `io.element.functional_members`, or nil if the event wasn't found.
 */
- (MXEvent *)functionalMembersEventFromStateEvents:(NSArray<MXEvent *> *)stateEvents
{
    NSPredicate *functionalMembersPredicate = [NSPredicate predicateWithFormat:@"type == %@", FunctionalMembersStateEventType];
    return [stateEvents filteredArrayUsingPredicate:functionalMembersPredicate].lastObject;
}

- (MXEvent *)roomRetentionEventFromStateEvents:(NSArray<MXEvent *> *)stateEvents
{
    NSPredicate *functionalMembersPredicate = [NSPredicate predicateWithFormat:@"type == %@", kMXEventTypeStringRoomRetention];
    return [stateEvents filteredArrayUsingPredicate:functionalMembersPredicate].lastObject;
}

#pragma mark - Timestamp formatting

- (NSString*)dateStringFromDate:(NSDate *)date withTime:(BOOL)time
{
    // Check the provided date
    if (!date)
    {
        return nil;
    }
    
    // Retrieve today date at midnight
    NSDate *today = [calendar startOfDayForDate:[NSDate date]];
    
    NSTimeInterval interval = -[date timeIntervalSinceDate:today];
    
    if (interval > 60*60*24*364)
    {
        [dateFormatter setDateFormat:@"MMM dd yyyy"];
        
        // Ignore time information here
        return [super dateStringFromDate:date withTime:NO];
    }
    else if (interval > 60*60*24*6)
    {
        [dateFormatter setDateFormat:@"MMM dd"];
        
        // Ignore time information here
        return [super dateStringFromDate:date withTime:NO];
    }
    else if (interval > 60*60*24)
    {
        if (time)
        {
            [dateFormatter setDateFormat:@"EEE"];
        }
        else
        {
            [dateFormatter setDateFormat:@"EEEE"];
        }
        
        return [super dateStringFromDate:date withTime:time];
    }
    else if (interval > 0)
    {
        if (time)
        {
            [dateFormatter setDateFormat:nil];
            return [NSString stringWithFormat:@"%@ %@", [VectorL10n yesterday], [super dateStringFromDate:date withTime:YES]];
        }
        return [VectorL10n yesterday];
    }
    else if (interval > - 60*60*24)
    {
        if (time)
        {
            [dateFormatter setDateFormat:nil];
            return [NSString stringWithFormat:@"%@", [super dateStringFromDate:date withTime:YES]];
        }
        return [VectorL10n today];
    }
    else
    {
        // Date in future
        [dateFormatter setDateFormat:@"EEE MMM dd yyyy"];
        return [super dateStringFromDate:date withTime:time];
    }
}

#pragma mark - Room create predecessor

- (NSAttributedString*)roomCreatePredecessorAttributedStringWithPredecessorRoomId:(NSString*)predecessorRoomId
{
    NSDictionary *roomPredecessorReasonAttributes = @{
                                                      NSFontAttributeName : self.defaultTextFont
                                                      };
    
    NSDictionary *roomLinkAttributes = @{
                                         NSFontAttributeName : self.defaultTextFont,
                                         NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)
                                         };
    
    NSMutableAttributedString *roomPredecessorAttributedString = [NSMutableAttributedString new];
    
    NSString *roomPredecessorReasonString = [NSString stringWithFormat:@"%@\n", [VectorL10n roomPredecessorInformation]];
    NSAttributedString *roomPredecessorReasonAttributedString = [[NSAttributedString alloc] initWithString:roomPredecessorReasonString attributes:roomPredecessorReasonAttributes];
    
    NSString *predecessorRoomLinkString = [VectorL10n roomPredecessorLink];
    NSAttributedString *predecessorRoomLinkAttributedString = [[NSAttributedString alloc] initWithString:predecessorRoomLinkString attributes:roomLinkAttributes];
    
    [roomPredecessorAttributedString appendAttributedString:roomPredecessorReasonAttributedString];
    [roomPredecessorAttributedString appendAttributedString:predecessorRoomLinkAttributedString];
    
    NSRange wholeStringRange = NSMakeRange(0, roomPredecessorAttributedString.length);
    [roomPredecessorAttributedString addAttribute:NSForegroundColorAttributeName value:self.defaultTextColor range:wholeStringRange];
    
    return roomPredecessorAttributedString;
}

@end
