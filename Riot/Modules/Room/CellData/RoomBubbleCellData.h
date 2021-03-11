/*
 Copyright 2015 OpenMarket Ltd

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

#import <MatrixKit/MatrixKit.h>

// Custom tags for MXKRoomBubbleCellDataStoring.tag
typedef NS_ENUM(NSInteger, RoomBubbleCellDataTag)
{
    RoomBubbleCellDataTagMessage = 0, // Default value used for messages
    RoomBubbleCellDataTagMembership,
    RoomBubbleCellDataTagRoomCreateConfiguration,
    RoomBubbleCellDataTagRoomCreateWithPredecessor,
    RoomBubbleCellDataTagKeyVerificationNoDisplay,
    RoomBubbleCellDataTagKeyVerificationRequestIncomingApproval,
    RoomBubbleCellDataTagKeyVerificationRequest,
    RoomBubbleCellDataTagKeyVerificationConclusion,
    RoomBubbleCellDataTagCall,
    RoomBubbleCellDataTagRoomCreationIntro
};

/**
 `RoomBubbleCellData` defines Vector bubble cell data model.
 */
@interface RoomBubbleCellData : MXKRoomBubbleCellDataWithAppendingMode

/**
 A Boolean value that determines whether this bubble contains the current last message.
 Used to keep displaying the timestamp of the last message.
 */
@property(nonatomic) BOOL containsLastMessage;

/**
 Indicate true to display the timestamp of the selected component.
 */
@property(nonatomic) BOOL showTimestampForSelectedComponent;

/**
 Indicate true to display the timestamp of the selected component on the left if possible (YES by default).
 */
@property(nonatomic) BOOL displayTimestampForSelectedComponentOnLeftWhenPossible;

/**
 The event id of the current selected event inside the bubble. Default is nil.
 */
@property(nonatomic) NSString *selectedEventId;

/**
 The index of the oldest component (component with a timestamp, and an actual display). NSNotFound by default.
 */
@property(nonatomic, readonly) NSInteger oldestComponentIndex;

/**
 The index of the most recent component (component with a timestamp, and an actual display). NSNotFound by default.
 */
@property(nonatomic, readonly) NSInteger mostRecentComponentIndex;

/**
 The index of the current selected component. NSNotFound by default.
 */
@property(nonatomic, readonly) NSInteger selectedComponentIndex;

/**
 Return additional content height (read receipts, reactions).
 */
@property(nonatomic, readonly) CGFloat additionalContentHeight;

/**
 MXKeyVerification object associated to key verifcation event when using key verification by direct message.
 */
@property(nonatomic, strong) MXKeyVerification *keyVerification;

/**
 Indicate if there is a pending operation that updates `keyVerification` property.
 */
@property(nonatomic) BOOL isKeyVerificationOperationPending;

/**
 Index of the component which needs a sent tick displayed. -1 if none.
 */
@property(nonatomic) NSInteger componentIndexOfSentMessageTick;

/**
 Indicate to update additional content height.
 */
- (void)setNeedsUpdateAdditionalContentHeight;

/**
 Update additional content height if needed.
 */
- (void)updateAdditionalContentHeightIfNeeded;

/**
 The index of the first visible component. NSNotFound by default.
 */
- (NSInteger)firstVisibleComponentIndex;

#pragma mark - Show all reactions

- (BOOL)showAllReactionsForEvent:(NSString*)eventId;
- (void)setShowAllReactions:(BOOL)showAllReactions forEvent:(NSString*)eventId;


#pragma mark - Accessibility

- (NSString*)accessibilityLabel;

@end
