/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKCellData.h"
#import "MXKRoomBubbleCellDataStoring.h"

#import "MXKRoomBubbleComponent.h"

#define MXKROOMBUBBLECELLDATA_TEXTVIEW_DEFAULT_VERTICAL_INSET 8

/**
 `MXKRoomBubbleCellData` instances compose data for `MXKRoomBubbleTableViewCell` cells.
 
 This is the basic implementation which considers only one component (event) by bubble.
 `MXKRoomBubbleCellDataWithAppendingMode` extends this class to merge consecutive messages from the same sender into one bubble.
 */
@interface MXKRoomBubbleCellData : MXKCellData <MXKRoomBubbleCellDataStoring>
{
@protected
    /**
     The data source owner of this instance.
     */
    __weak MXKRoomDataSource *roomDataSource;
    
    /**
     Array of bubble components. Each bubble is supposed to have at least one component.
     */
    NSMutableArray *bubbleComponents;
    
    /**
     The body of the message with sets of attributes, or kind of content description in case of attachment (e.g. "image attachment")
     */
    NSAttributedString *attributedTextMessage;
    
    /**
     Same as attributedTextMessage but without vertical positioning vertical blank space.
     */
    NSAttributedString *attributedTextMessageWithoutPositioningSpace;
    
    /**
     The optional text pattern to be highlighted in the body of the message.
     */
    NSString *highlightedPattern;
    UIColor  *highlightedPatternForegroundColor;
    UIColor  *highlightedPatternBackgroundColor;
    UIFont   *highlightedPatternFont;
}

/**
 The matrix session.
 */
@property (nonatomic, readonly) MXSession *mxSession;

/**
 Returns bubble components list (`MXKRoomBubbleComponent` instances).
 */
@property (nonatomic, readonly) NSArray<MXKRoomBubbleComponent*> *bubbleComponents;

/**
 Read receipts per event.
 */
@property(nonatomic) NSMutableDictionary<NSString* /* eventId */,
                                         NSArray<MXReceiptData *> *> *readReceipts;

/**
 Aggregated reactions per event.
 */
@property(nonatomic) NSMutableDictionary<NSString* /* eventId */, MXAggregatedReactions*> *reactions;

/**
 Whether there is a link to preview in the components.
 */
@property (nonatomic, readonly) BOOL hasLink;

/**
 Event formatter
 */
@property (nonatomic) MXKEventFormatter *eventFormatter;

/**
 The max width of the text view used to display the text message (relevant only for text message or attached file).
 */
@property (nonatomic) CGFloat maxTextViewWidth;

/**
 The bubble content size depends on its type:
 - Text: returns suitable content size of a text view to display the whole text message (respecting maxTextViewWidth).
 - Attached image or video: returns suitable content size for an image view in order to display
 attachment thumbnail or icon.
 - Attached file: returns suitable content size of a text view to display the file name (no icon is used presently).
 */
@property (nonatomic) CGSize contentSize;

/**
 Set of flags indicating fixes that need to be applied at display time.
 */
@property (nonatomic, readonly) MXKRoomBubbleComponentDisplayFix displayFix;

/**
 Attachment upload
 */
@property (nonatomic) NSString *uploadId;
@property (nonatomic) CGFloat uploadProgress;

/**
 Indicate a bubble component needs to show encryption badge.
 */
@property (nonatomic, readonly) BOOL containsBubbleComponentWithEncryptionBadge;

/**
 Indicate that the current text message layout is no longer valid and should be recomputed
 before presentation in a bubble cell. This could be due to the content changing, or the
 available space for the cell has been updated.
 
 This will clear the current `attributedTextMessage` allowing it to be
 rebuilt on demand when requested.
 */
- (void)invalidateTextLayout;

/**
 Check and refresh the position of each component.
 */
- (void)prepareBubbleComponentsPosition;

/**
 Return the raw height of the provided text by removing any vertical margin/inset.
 
 @param attributedText the attributed text to measure
 @return the computed height
 */
- (CGFloat)rawTextHeight:(NSAttributedString*)attributedText;

/**
 Return the raw height of the provided text by removing any vertical margin/inset and constraining the width.
 
 @param attributedText the attributed text to measure
 @param maxTextViewWidth the maximum text width
 @return the computed height
 */
- (CGFloat)rawTextHeight:(NSAttributedString*)attributedText withMaxWidth:(CGFloat)maxTextViewWidth;

/**
 Return the content size of a text view initialized with the provided attributed text.
 CAUTION: This method runs only on main thread.
 
 @param attributedText the attributed text to measure
 @param removeVerticalInset tell whether the computation should remove vertical inset in text container.
 @return the computed size content
 */
- (CGSize)textContentSize:(NSAttributedString*)attributedText removeVerticalInset:(BOOL)removeVerticalInset;

/**
 Get bubble component index from event id.

 @param eventId Event id of bubble component.
 @return Index of bubble component associated to event id or NSNotFound
 */
- (NSInteger)bubbleComponentIndexForEventId:(NSString *)eventId;

/**
 Get the first visible component.
 
 @return First visible component or nil.
 */
- (MXKRoomBubbleComponent*)getFirstBubbleComponentWithDisplay;

/**
 Get the last visible component.
 
 @return Last visible component or nil.
 */
- (MXKRoomBubbleComponent*)getLastBubbleComponentWithDisplay;

@end
