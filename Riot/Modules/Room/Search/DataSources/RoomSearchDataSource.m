/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomSearchDataSource.h"

#import "RoomBubbleCellData.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "MXKRoomBubbleTableViewCell+Riot.h"

@interface RoomSearchDataSource ()
{
    MXKRoomDataSource *roomDataSource;
}

@end

@implementation RoomSearchDataSource

- (instancetype)initWithRoomDataSource:(MXKRoomDataSource *)roomDataSource
{
    self = [super initWithMatrixSession:roomDataSource.mxSession];
    if (self)
    {
        self->roomDataSource = roomDataSource;
        
        // The messages search is limited to the room data.
        self.roomEventFilter.rooms = @[roomDataSource.roomId];
    }
    return self;
}

- (void)destroy
{
    roomDataSource = nil;
    
    [super destroy];
}

- (void)convertHomeserverResultsIntoCells:(MXSearchRoomEventResults *)roomEventResults onComplete:(dispatch_block_t)onComplete
{
    // Prepare text font used to highlight the search pattern.
    UIFont *patternFont = [roomDataSource.eventFormatter bingTextFont];

    dispatch_group_t group = dispatch_group_create();
    
    // Convert the HS results into `RoomViewController` cells
    for (MXSearchResult *result in roomEventResults.results)
    {
        dispatch_group_enter(group);

        void(^continueBlock)(void) = ^{
            // Let the `RoomViewController` ecosystem do the job
            // The search result contains only room message events, no state events.
            // Thus, passing the current room state is not a huge problem. Only
            // the user display name and his avatar may be wrong.
            RoomBubbleCellData *cellData = [[RoomBubbleCellData alloc] initWithEvent:result.result andRoomState:self->roomDataSource.roomState andRoomDataSource:self->roomDataSource];
            if (cellData)
            {
                // Highlight the search pattern
                [cellData highlightPatternInTextMessage:self.searchText
                                    withBackgroundColor:ThemeService.shared.theme.searchResultHighlightColor
                                        foregroundColor:ThemeService.shared.theme.textPrimaryColor
                                                andFont:patternFont];

                // Use profile information as data to display
                MXSearchUserProfile *userProfile = result.context.profileInfo[result.result.sender];
                cellData.senderDisplayName = userProfile.displayName;
                cellData.senderAvatarUrl = userProfile.avatarUrl;

                [self->cellDataArray insertObject:cellData atIndex:0];
            }

            dispatch_group_leave(group);
        };

        if (RiotSettings.shared.enableThreads)
        {
            if (result.result.isInThread)
            {
                continueBlock();
            }
            else if (result.result.unsignedData.relations.thread)
            {
                continueBlock();
            }
            else
            {
                [roomDataSource.room liveTimeline:^(id<MXEventTimeline> liveTimeline) {
                    [liveTimeline paginate:NSUIntegerMax
                                 direction:MXTimelineDirectionBackwards
                             onlyFromStore:YES
                                  complete:^{
                        [liveTimeline resetPagination];
                        continueBlock();
                    } failure:^(NSError * _Nonnull error) {
                        continueBlock();
                    }];
                }];
            }
        }
        else
        {
            continueBlock();
        }
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        onComplete();
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Finalize cell view customization here
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class] && ![cell isKindOfClass:MXKRoomEmptyBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *bubbleCell = (MXKRoomBubbleTableViewCell*)cell;

        // Display date for each message
        [bubbleCell addDateLabel];

        if (RiotSettings.shared.enableThreads)
        {
            RoomBubbleCellData *cellData = (RoomBubbleCellData*)[self cellDataAtIndex:indexPath.row];
            MXEvent *event = cellData.events.firstObject;

            if (event)
            {
                if (cellData.hasThreadRoot)
                {
                    id<MXThreadProtocol> thread = cellData.bubbleComponents.firstObject.thread;
                    ThreadSummaryView *threadSummaryView = [[ThreadSummaryView alloc] initWithThread:thread
                                                                                             session:self.mxSession];
                    [bubbleCell.tmpSubviews addObject:threadSummaryView];

                    threadSummaryView.translatesAutoresizingMaskIntoConstraints = NO;
                    [bubbleCell.contentView addSubview:threadSummaryView];

                    CGFloat leftMargin = PlainRoomCellLayoutConstants.reactionsViewLeftMargin;
                    CGFloat height = [ThreadSummaryView contentViewHeightForThread:thread fitting:cellData.maxTextViewWidth];

                    CGRect bubbleComponentFrame = [bubbleCell componentFrameInContentViewForIndex:0];
                    CGFloat bottomPositionY = bubbleComponentFrame.origin.y + bubbleComponentFrame.size.height;

                    // Set constraints for the summary view
                    [NSLayoutConstraint activateConstraints: @[
                        [threadSummaryView.leadingAnchor constraintEqualToAnchor:threadSummaryView.superview.leadingAnchor
                                                                        constant:leftMargin],
                        [threadSummaryView.topAnchor constraintEqualToAnchor:threadSummaryView.superview.topAnchor
                                                                    constant:bottomPositionY + PlainRoomCellLayoutConstants.threadSummaryViewTopMargin],
                        [threadSummaryView.heightAnchor constraintEqualToConstant:height],
                        [threadSummaryView.trailingAnchor constraintLessThanOrEqualToAnchor:threadSummaryView.superview.trailingAnchor constant:-PlainRoomCellLayoutConstants.reactionsViewRightMargin]
                    ]];
                }
                else if (event.isInThread)
                {
                    FromAThreadView *fromAThreadView = [FromAThreadView instantiate];
                    [bubbleCell.tmpSubviews addObject:fromAThreadView];
                    
                    fromAThreadView.translatesAutoresizingMaskIntoConstraints = NO;
                    [bubbleCell.contentView addSubview:fromAThreadView];

                    CGFloat leftMargin = PlainRoomCellLayoutConstants.reactionsViewLeftMargin;
                    CGFloat height = [FromAThreadView contentViewHeightForEvent:event fitting:cellData.maxTextViewWidth];

                    CGRect bubbleComponentFrame = [bubbleCell componentFrameInContentViewForIndex:0];
                    CGFloat bottomPositionY = bubbleComponentFrame.origin.y + bubbleComponentFrame.size.height;

                    // Set constraints for the summary view
                    [NSLayoutConstraint activateConstraints: @[
                        [fromAThreadView.leadingAnchor constraintEqualToAnchor:fromAThreadView.superview.leadingAnchor
                                                                      constant:leftMargin],
                        [fromAThreadView.topAnchor constraintEqualToAnchor:fromAThreadView.superview.topAnchor
                                                                  constant:bottomPositionY + PlainRoomCellLayoutConstants.fromAThreadViewTopMargin],
                        [fromAThreadView.heightAnchor constraintEqualToConstant:height],
                        [fromAThreadView.trailingAnchor constraintLessThanOrEqualToAnchor:fromAThreadView.superview.trailingAnchor constant:-PlainRoomCellLayoutConstants.reactionsViewRightMargin]
                    ]];
                }
            }
        }
    }

    return cell;
}

@end
