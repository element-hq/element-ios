/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import <MatrixSDK/MatrixSDK.h>

#import "MXKAppSettings.h"

@protocol MarkdownToHTMLRendererProtocol;
/**
 Formatting result codes.
 */
typedef enum : NSUInteger {

    /**
     The formatting was successful.
     */
    MXKEventFormatterErrorNone = 0,

    /**
     The formatter knows the event type but it encountered data that it does not support.
     */
    MXKEventFormatterErrorUnsupported,

    /**
     The formatter encountered unexpected data in the event.
     */
    MXKEventFormatterErrorUnexpected,

    /**
     The formatter does not support the type of the passed event.
     */
    MXKEventFormatterErrorUnknownEventType

} MXKEventFormatterError;

/**
 `MXKEventFormatter` is an utility class for formating Matrix events into strings which
 will be displayed to the end user.
 */
@interface MXKEventFormatter : NSObject <MXRoomSummaryUpdating>
{
@protected
    /**
     The matrix session. Used to get contextual data.
     */
    MXSession *mxSession;
    
    /**
     The date formatter used to build date string without time information.
     */
    NSDateFormatter *dateFormatter;
    
    /**
     The time formatter used to build time string without date information.
     */
    NSDateFormatter *timeFormatter;
    
    /**
     The default room summary updater from the MXSession.
     */
    MXRoomSummaryUpdater *defaultRoomSummaryUpdater;
}

/**
 The settings used to handle room events.
 
 By default the shared application settings are considered.
 */
@property (nonatomic) MXKAppSettings *settings;

/**
 Flag indicating if the formatter must build strings that will be displayed as subtitle.
 Default is NO.
 */
@property (nonatomic) BOOL isForSubtitle;

/**
 Flags indicating if the formatter must create clickable links for Matrix user ids,
 room ids, room aliases or event ids.
 Default is NO.
 */
@property (nonatomic) BOOL treatMatrixUserIdAsLink;
@property (nonatomic) BOOL treatMatrixRoomIdAsLink;
@property (nonatomic) BOOL treatMatrixRoomAliasAsLink;
@property (nonatomic) BOOL treatMatrixEventIdAsLink;

/**
 Initialise the event formatter.

 @param mxSession the Matrix to retrieve contextual data.
 @return the newly created instance.
 */
- (instancetype)initWithMatrixSession:(MXSession*)mxSession;

/**
 Initialise the date and time formatters.
 This formatter could require to be updated after updating the device settings.
 e.g the time format switches from 24H format to AM/PM.
 */
- (void)initDateTimeFormatters;

/**
 The types of events allowed to be displayed in the room history.
 No string will be returned by the formatter for the events whose the type doesn't belong to this array.
 
 Default is nil. All messages types are displayed.
 */
@property (nonatomic) NSArray<NSString*> *eventTypesFilterForMessages;

@property (nonatomic, strong) id<MarkdownToHTMLRendererProtocol> markdownToHTMLRenderer;

/**
 Checks whether the event is related to an attachment and if it is supported.

 @param event an event.
 @return YES if the provided event is related to a supported attachment type.
 */
- (BOOL)isSupportedAttachment:(MXEvent*)event;

#pragma mark - Events to strings conversion methods
/**
 Compose the event sender display name according to the current room state.
 
 @param event the event to format.
 @param roomState the room state right before the event.
 @return the sender display name
 */
- (NSString*)senderDisplayNameForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState;

/**
 Compose the event target display name according to the current room state.

 @discussion "target" refers to the room member who is the target of this event (if any), e.g.
 the invitee, the person being banned, etc.

 @param event the event to format.
 @param roomState the room state right before the event.
 @return the target display name (if any)
 */
- (NSString*)targetDisplayNameForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState;

/**
 Retrieve the avatar url of the event sender from the current room state.
 
 @param event the event to format.
 @param roomState the room state right before the event.
 @return the sender avatar url
 */
- (NSString*)senderAvatarUrlForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState;

/**
 Retrieve the avatar url of the event target from the current room state.

 @discussion "target" refers to the room member who is the target of this event (if any), e.g.
 the invitee, the person being banned, etc.

 @param event the event to format.
 @param roomState the room state right before the event.
 @return the target avatar url (if any)
 */
- (NSString*)targetAvatarUrlForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState;

/**
 Generate a displayable string representating the event.
 
 @param event the event to format.
 @param roomState the room state right before the event.
 @param latestRoomState the latest room state of the room containing this event.
 @param error the error code. In case of formatting error, the formatter may return non nil string as a proposal.
 @return the display text for the event.
 */
- (NSString*)stringFromEvent:(MXEvent*)event
               withRoomState:(MXRoomState*)roomState
          andLatestRoomState:(MXRoomState*)latestRoomState
                       error:(MXKEventFormatterError*)error;

/**
 Generate a displayable attributed string representating the event.

 @param event the event to format.
 @param roomState the room state right before the event.
 @param latestRoomState the latest room state of the room containing this event.
 @param error the error code. In case of formatting error, the formatter may return non nil string as a proposal.
 @return the attributed string for the event.
 */
- (NSAttributedString*)attributedStringFromEvent:(MXEvent*)event
                                   withRoomState:(MXRoomState*)roomState
                              andLatestRoomState:(MXRoomState*)latestRoomState
                                           error:(MXKEventFormatterError*)error;

/**
 Generate a displayable attributed string representating a summary for the provided events.

 @param events the series of events to format.
 @param roomState the room state right before the first event in the series.
 @param latestRoomState the latest room state of the room containing this event.
 @param error the error code. In case of formatting error, the formatter may return non nil string as a proposal.
 @return the attributed string.
 */
- (NSAttributedString*)attributedStringFromEvents:(NSArray<MXEvent*>*)events
                                    withRoomState:(MXRoomState*)roomState
                               andLatestRoomState:(MXRoomState*)latestRoomState
                                            error:(MXKEventFormatterError*)error;

/**
 Render a random string into an attributed string with the font and the text color
 that correspond to the passed event.

 @param string the string to render.
 @param event the event associated to the string.
 @return an attributed string.
 */
- (NSAttributedString*)renderString:(NSString*)string forEvent:(MXEvent*)event;

/**
 Render a random html string into an attributed string with the font and the text color
 that correspond to the passed event.

 @param htmlString the HTLM string to render.
 @param event the event associated to the string.
 @param roomState the room state right before the event. If nil, replies will not get constructed or formatted.
 @return an attributed string.
 */
- (NSAttributedString*)renderHTMLString:(NSString*)htmlString
                               forEvent:(MXEvent*)event
                          withRoomState:(MXRoomState*)roomState
                     andLatestRoomState:(MXRoomState*)latestRoomState;

/**
 Defines the replacement attributed string for a redacted message.

 @return attributed string describing redacted message.
 */
- (NSAttributedString*)redactedMessageReplacementAttributedString;

/**
 Same as [self renderString:forEvent:] but add a prefix.
 The prefix will be rendered with 'prefixTextFont' and 'prefixTextColor'.
 
 @param string the string to render.
 @param prefix the prefix to add.
 @param event the event associated to the string.
 @return an attributed string.
 */
- (NSAttributedString*)renderString:(NSString*)string withPrefix:(NSString*)prefix forEvent:(MXEvent*)event;

#pragma mark - Conversion tools

/**
 Convert a Markdown string to HTML.
 
 @param markdownString the string to convert.
 @return an HTML formatted string.
 */
- (NSString*)htmlStringFromMarkdownString:(NSString*)markdownString;

#pragma mark - Timestamp formatting

/**
 Generate the date in string format corresponding to the date.
 
 @param date The date.
 @param time The flag used to know if the returned string must include time information or not.
 @return the string representation of the date.
 */
- (NSString*)dateStringFromDate:(NSDate *)date withTime:(BOOL)time;

/**
 Generate the date in string format corresponding to the timestamp.
 The returned string is localised according to the current device settings.

 @param timestamp The timestamp in milliseconds since Epoch.
 @param time The flag used to know if the returned string must include time information or not.
 @return the string representation of the date.
 */
- (NSString*)dateStringFromTimestamp:(uint64_t)timestamp withTime:(BOOL)time;

/**
 Generate the date in string format corresponding to the event.
 The returned string is localised according to the current device settings.
 
 @param event The event to format.
 @param time The flag used to know if the returned string must include time information or not.
 @return the string representation of the event date.
 */
- (NSString*)dateStringFromEvent:(MXEvent*)event withTime:(BOOL)time;

/**
 Generate the time string of the provided date by considered the current system time formatting.
 
 @param date The date.
 @return the string representation of the time component of the date.
 */
- (NSString*)timeStringFromDate:(NSDate *)date;


# pragma mark - Customisation
/**
 The list of allowed HTML tags in rendered attributed strings.
 */
@property (nonatomic) NSArray<NSString*> *allowedHTMLTags;

/**
 A block to run on HTML `img` tags when calling `renderHTMLString:forEvent:withRoomState:`.
 
 This block provides the original URL for the image and can be used to download the image locally
 and return a local file URL for the image to attach to the rendered attributed string.
 */
@property (nonatomic, copy) NSURL* (^htmlImageHandler)(NSString *sourceURL, CGFloat width, CGFloat height);

/**
 The style sheet used by the 'renderHTMLString' method.
*/
@property (nonatomic) NSString *defaultCSS;

/**
 Default color used to display text content of event.
 Default is [UIColor blackColor].
 */
@property (nonatomic) UIColor *defaultTextColor;

/**
 Default color used to display text content of event when it is displayed as subtitle (related to 'isForSubtitle' property).
 Default is [UIColor blackColor].
 */
@property (nonatomic) UIColor *subTitleTextColor;

/**
 Color applied on the event description prefix used to display for example the message sender name.
 Default is [UIColor blackColor].
 */
@property (nonatomic) UIColor *prefixTextColor;

/**
 Color used when the event must be bing to the end user. This happens when the event
 matches the user's push rules.
 Default is [UIColor blueColor].
 */
@property (nonatomic) UIColor *bingTextColor;

/**
 Color used to display text content of an event being encrypted.
 Default is [UIColor lightGrayColor].
 */
@property (nonatomic) UIColor *encryptingTextColor;

/**
 Color used to display text content of an event being sent.
 Default is [UIColor lightGrayColor].
 */
@property (nonatomic) UIColor *sendingTextColor;

/**
 Color used to display links and hyperlinks contentt.
 Default is [UIColor linkColor].
 */
@property (nonatomic) UIColor *linksColor;

/**
 Color used to display error text.
 Default is red.
 */
@property (nonatomic) UIColor *errorTextColor;

/**
 Color used to display the side border of HTML blockquotes.
 Default is a grey.
 */
@property (nonatomic) UIColor *htmlBlockquoteBorderColor;

/**
 Default text font used to display text content of event.
 Default is SFUIText-Regular 14.
 */
@property (nonatomic) UIFont *defaultTextFont;

/**
 Font applied on the event description prefix used to display for example the message sender name.
 Default is SFUIText-Regular 14.
 */
@property (nonatomic) UIFont *prefixTextFont;

/**
 Text font used when the event must be bing to the end user. This happens when the event
 matches the user's push rules.
 Default is SFUIText-Regular 14.
 */
@property (nonatomic) UIFont *bingTextFont;

/**
 Text font used when the event is a state event.
 Default is italic SFUIText-Regular 14.
 */
@property (nonatomic) UIFont *stateEventTextFont;

/**
 Text font used to display call notices (invite, answer, hangup).
 Default is SFUIText-Regular 14.
 */
@property (nonatomic) UIFont *callNoticesTextFont;

/**
 Text font used to display encrypted messages.
 Default is SFUIText-Regular 14.
 */
@property (nonatomic) UIFont *encryptedMessagesTextFont;

/**
 Text font used to display message containing a single emoji.
 Default is nil (same font as self.emojiOnlyTextFont).
 */
@property (nonatomic) UIFont *singleEmojiTextFont;

/**
 Text font used to display message containing only emojis.
 Default is nil (same font as self.defaultTextFont).
 */
@property (nonatomic) UIFont *emojiOnlyTextFont;

@end
