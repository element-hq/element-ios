/*
 Copyright 2014 OpenMarket Ltd
 
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
#import <MobileCoreServices/MobileCoreServices.h>

#import "RoomViewController.h"
#import "RoomMessageTableCell.h"
#import "RoomMemberTableCell.h"

#import "MatrixHandler.h"
#import "AppDelegate.h"
#import "AppSettings.h"

#import "MediaManager.h"

#define ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH 200

#define ROOM_MESSAGE_CELL_TEXTVIEW_TOP_CONST_DEFAULT 10
#define ROOM_MESSAGE_CELL_TEXTVIEW_TOP_CONST_IN_CHUNK (-5)
#define ROOM_MESSAGE_CELL_TEXTVIEW_EDGE_INSET_TOP_IN_CHUNK ROOM_MESSAGE_CELL_TEXTVIEW_TOP_CONST_IN_CHUNK
#define ROOM_MESSAGE_CELL_TEXTVIEW_BOTTOM_CONST_DEFAULT 0
#define ROOM_MESSAGE_CELL_TEXTVIEW_BOTTOM_CONST_GROUPED_CELL (-5)

#define ROOM_MESSAGE_CELL_IMAGE_MARGIN 5

NSString *const kCmdChangeDisplayName = @"/nick";
NSString *const kCmdEmote = @"/me";
NSString *const kCmdJoinRoom = @"/join";
NSString *const kCmdKickUser = @"/kick";
NSString *const kCmdBanUser = @"/ban";
NSString *const kCmdUnbanUser = @"/unban";
NSString *const kCmdSetUserPowerLevel = @"/op";
NSString *const kCmdResetUserPowerLevel = @"/deop";

NSString *const kLocalEchoEventIdPrefix = @"localEcho-";
NSString *const kFailedEventId = @"failedEventId";


@interface RoomViewController () {
    BOOL isFirstDisplay;
    BOOL isJoinRequestInProgress;
    
    MXRoom *mxRoom;
    
    NSMutableArray *messages;
    id messagesListener;
    
    // Members list
    NSArray *members;
    id membersListener;
    
    // Date formatter (nil if dateTimeLabel is hidden)
    NSDateFormatter *dateFormatter;
    
    // Cache
    NSMutableArray *tmpCachedAttachments;
}

@property (weak, nonatomic) IBOutlet UINavigationItem *roomNavItem;
@property (weak, nonatomic) IBOutlet UITableView *messagesTableView;
@property (weak, nonatomic) IBOutlet UIView *controlView;
@property (weak, nonatomic) IBOutlet UIButton *optionBtn;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *controlViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *membersView;
@property (weak, nonatomic) IBOutlet UITableView *membersTableView;

@property (strong, nonatomic) CustomAlert *actionMenu;
@property (nonatomic) BOOL isHiddenByMediaPicker;
@end

@implementation RoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    isFirstDisplay = YES;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [button addTarget:self action:@selector(showHideRoomMembers:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    _sendBtn.enabled = NO;
    _sendBtn.alpha = 0.5;
}

- (void)dealloc {
#ifdef TEMPORARY_PATCH_INITIAL_SYNC
    // FIXME: these lines should be removed when SDK will fix the initial sync issue
    if (isJoinRequestInProgress) {
        [[MatrixHandler sharedHandler] removeObserver:self forKeyPath:@"isInitialSyncDone"];
    }
#endif
    // Clear temporary cached attachments (used for local echo)
    NSUInteger index = tmpCachedAttachments.count;
    while (index--) {
        [MediaManager clearCacheForURL:[tmpCachedAttachments objectAtIndex:index]];
    }
    tmpCachedAttachments = nil;
    
    messages = nil;
    if (messagesListener) {
        [mxRoom unregisterListener:messagesListener];
        messagesListener = nil;
    }
    mxRoom = nil;
    
    members = nil;
    if (membersListener) {
        membersListener = nil;
    }
    
    if (self.actionMenu) {
        [self.actionMenu dismiss:NO];
        self.actionMenu = nil;
    }
    
    if (dateFormatter) {
        dateFormatter = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Check whether the view was hidden by the media picker
    if (_isHiddenByMediaPicker) {
        _isHiddenByMediaPicker = NO;
        // We don't reload room data in order to keep data related to local echo
    } else {
        // Load room data
        [self configureView];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextFieldChange:) name:UITextFieldTextDidChangeNotification object:nil];
    
    // Set visible room id
    [AppDelegate theDelegate].masterTabBarController.visibleRoomId = self.roomId;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // hide action
    if (self.actionMenu) {
        [self.actionMenu dismiss:NO];
        self.actionMenu = nil;
    }
    
    // Hide members by default
    [self hideRoomMembers];
    
    // Release message listener except if the view is hidden by the media picker
    if (messagesListener && (_isHiddenByMediaPicker == NO)) {
        [mxRoom unregisterListener:messagesListener];
        messagesListener = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
    
    // Reset visible room id
    [AppDelegate theDelegate].masterTabBarController.visibleRoomId = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (isFirstDisplay) {
        // Scroll to the bottom
        [self scrollToBottomAnimated:animated];
        isFirstDisplay = NO;
    }
}

#pragma mark -

- (void)setRoomId:(NSString *)roomId {
    if (self.roomId == nil) {
        // Room data will be loaded when view will appear
        _roomId = roomId;
    } else if ([self.roomId isEqualToString:roomId] == NO) {
        _roomId = roomId;
        // Reload room data here
        [self configureView];
    }
}

#ifdef TEMPORARY_PATCH_INITIAL_SYNC
// FIXME: this method should be removed when SDK will fix the initial sync issue
#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"isInitialSyncDone" isEqualToString:keyPath])
    {
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        if ([mxHandler isInitialSyncDone]) {
            [_activityIndicator stopAnimating];
            isJoinRequestInProgress = NO;
            [mxHandler removeObserver:self forKeyPath:@"isInitialSyncDone"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self configureView];
            });
        }
    }
}
#endif

#pragma mark - Internal methods

- (void)configureView {
    // Check whether a request is in progress to join the room
    if (isJoinRequestInProgress) {
        // Busy - be sure that activity indicator is running
        [_activityIndicator startAnimating];
        return;
    }
    
    // Flush messages
    messages = nil;
    
    // Remove potential roomData listener
    if (messagesListener && mxRoom) {
        [mxRoom unregisterListener:messagesListener];
        messagesListener = nil;
    }
    
    // Update room data
    if (self.roomId) {
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        mxRoom = [mxHandler.mxSession room:self.roomId];
        
        // Update room title
        self.roomNavItem.title = mxRoom.state.displayname;
        
        // Join the room if the user is not already listed in room's members
        if ([mxRoom.state memberWithUserId:mxHandler.userId] == nil) {
            isJoinRequestInProgress = YES;
            [_activityIndicator startAnimating];
            [mxHandler.mxRestClient joinRoom:self.roomId success:^{
#ifdef TEMPORARY_PATCH_INITIAL_SYNC
                // Presently the SDK is not able to handle correctly the context for the room recently joined
                // PATCH: we force new initial sync
                // FIXME: this new initial sync should be removed when SDK will fix the issue
                [mxHandler addObserver:self forKeyPath:@"isInitialSyncDone" options:0 context:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [mxHandler forceInitialSync];
                });
#else
                [_activityIndicator stopAnimating];
                isJoinRequestInProgress = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self configureView];
                });
#endif
            } failure:^(NSError *error) {
                [_activityIndicator stopAnimating];
                isJoinRequestInProgress = NO;
                NSLog(@"Failed to join room (%@): %@", mxRoom.state.displayname, error);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];
            return;
        }
        
        messages = [NSMutableArray arrayWithArray:mxRoom.messages];
        // Register a listener for events that modify the `messages` property
        messagesListener = [mxRoom registerEventListenerForTypes:mxHandler.mxSession.eventsFilterForMessages block:^(MXRoom *room, MXEvent *event, BOOL isLive) {
            // consider only live event
            if (isLive) {
                // For outgoing message, remove the temporary event
                if ([event.userId isEqualToString:[MatrixHandler sharedHandler].userId]) {
                    NSUInteger index = messages.count;
                    while (index--) {
                        MXEvent *mxEvent = [messages objectAtIndex:index];
                        if ([mxEvent.eventId isEqualToString:event.eventId]) {
                            [messages replaceObjectAtIndex:index withObject:event];
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                            [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                            return;
                        }
                    }
                }
                // Here a new event is added
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count inSection:0];
                [messages addObject:event];
                
                // Refresh table display (Disable animation during cells insertion to prevent flickering)
                [UIView setAnimationsEnabled:NO];
                [self.messagesTableView beginUpdates];
                if (indexPath.row > 0) {
                    NSIndexPath *prevIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0];
                    [self.messagesTableView reloadRowsAtIndexPaths:@[prevIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
                [self.messagesTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [self.messagesTableView endUpdates];
                [UIView setAnimationsEnabled:YES];
                
                [self scrollToBottomAnimated:NO];
            }
        }];
        
        // Trigger a back pagination if messages number is low
        if (messages && messages.count < 10) {
            [self triggerBackPagination];
        }
    } else {
        mxRoom = nil;
        // Update room title
        self.roomNavItem.title = nil;
    }
    
    [self.messagesTableView reloadData];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    // Scroll table view to the bottom
    NSInteger rowNb = messages.count;
    if (rowNb) {
        [self.messagesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(rowNb - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (void)triggerBackPagination {
    if (mxRoom.canPaginate)
    {
        [_activityIndicator startAnimating];
        
        [mxRoom paginateBackMessages:20 success:^(NSArray *oldMessages) {
            if (oldMessages.count)
            {
                // Update table sources
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, oldMessages.count)];
                [messages insertObjects:oldMessages atIndexes:indexSet];
                
                // Prepare insertion of new rows at the top of the table (compute cumulative height of added cells)
                NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:oldMessages.count];
                CGFloat verticalOffset = 0;
                for (NSUInteger index = 0; index < oldMessages.count; index++) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    [indexPaths addObject:indexPath];
                    verticalOffset += [self tableView:self.messagesTableView heightForRowAtIndexPath:indexPath];
                }
                
                // Disable animation during cells insertion to prevent flickering
                [UIView setAnimationsEnabled:NO];
                // Store the current content offset
                CGPoint contentOffset = self.messagesTableView.contentOffset;
                [self.messagesTableView beginUpdates];
                [self.messagesTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                [self.messagesTableView endUpdates];
                // Enable animation again
                [UIView setAnimationsEnabled:YES];
                // Fix vertical offset in order to prevent scrolling down
                contentOffset.y += verticalOffset;
                [self.messagesTableView setContentOffset:contentOffset animated:NO];
                
                [_activityIndicator stopAnimating];
                
                // Move the current message at the middle of the visible area (dispatch this action in order to let table end its refresh)
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.messagesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(oldMessages.count - 1) inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                });
            } else {
                // Here there was no event related to the `messages` property
                [_activityIndicator stopAnimating];
                // Trigger a new back pagination (if possible)
                [self triggerBackPagination];
            }
        } failure:^(NSError *error) {
            [_activityIndicator stopAnimating];
            NSLog(@"Failed to paginate back: %@", error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
}

- (void)showHideRoomMembers:(id)sender {
    // Check whether the members list is displayed
    if (members) {
        [self hideRoomMembers];
    } else {
        [self showRoomMembers];
    }
}

- (void)updateRoomMembers {
     members = [[mxRoom.state members] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
         MXRoomMember *member1 = (MXRoomMember*)obj1;
         MXRoomMember *member2 = (MXRoomMember*)obj2;
         
         // Move banned and left members at the end of the list
         if (member1.membership == MXMembershipLeave || member1.membership == MXMembershipBan) {
             if (member2.membership != MXMembershipLeave && member2.membership != MXMembershipBan) {
                 return NSOrderedDescending;
             }
         } else if (member2.membership == MXMembershipLeave || member2.membership == MXMembershipBan) {
             return NSOrderedAscending;
         }
         
         // Move invited members just before left and banned members
         if (member1.membership == MXMembershipInvite) {
             if (member2.membership != MXMembershipInvite) {
                 return NSOrderedDescending;
             }
         } else if (member2.membership == MXMembershipInvite) {
             return NSOrderedAscending;
         }
         
         if ([[AppSettings sharedSettings] sortMembersUsingLastSeenTime]) {
             
             // Get the users that correspond to these members
             MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
             MXUser *user1 = [mxHandler.mxSession user:member1.userId];
             MXUser *user2 = [mxHandler.mxSession user:member2.userId];
             
             if (user1.lastActiveAgo < user2.lastActiveAgo) {
                 return NSOrderedAscending;
             } else if (user1.lastActiveAgo == user2.lastActiveAgo) {
                 return [[mxRoom.state memberName:member1.userId] compare:[mxRoom.state memberName:member2.userId] options:NSCaseInsensitiveSearch];
             }
             return NSOrderedDescending;
         } else {
             // Move user without display name at the end (before invited users)
             if (member1.displayname) {
                 if (!member2.displayname) {
                     return NSOrderedAscending;
                 }
             } else if (member2.displayname) {
                 return NSOrderedDescending;
             }
             
             return [[mxRoom.state memberName:member1.userId] compare:[mxRoom.state memberName:member2.userId] options:NSCaseInsensitiveSearch];
         }
     }];
}

- (void)showRoomMembers {
    // Dismiss keyboard
    [self dismissKeyboard];
    
    [self updateRoomMembers];
    // Register a listener for events that concern room members
    NSArray *mxMembersEvents = @[
                                 kMXEventTypeStringRoomMember,
                                 kMXEventTypeStringRoomPowerLevels,
                                 kMXEventTypeStringPresence
                                 ];
    membersListener = [mxRoom registerEventListenerForTypes:mxMembersEvents block:^(MXRoom *room, MXEvent *event, BOOL isLive) {
        // consider only live event
        if (isLive) {
            // Refresh members list
            [self updateRoomMembers];
            [self.membersTableView reloadData];
        }
    }];
    
    self.membersView.hidden = NO;
    [self.membersTableView reloadData];
}

- (void)hideRoomMembers {
    if (membersListener) {
        [mxRoom unregisterListener:membersListener];
        membersListener = nil;
    }
    self.membersView.hidden = YES;
    members = nil;
}

#pragma mark - keyboard handling

- (void)onKeyboardWillShow:(NSNotification *)notif {
    NSValue *rectVal = notif.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect endRect = rectVal.CGRectValue;
    
    UIEdgeInsets insets = self.messagesTableView.contentInset;
    // Handle portrait/landscape mode
    insets.bottom = (endRect.origin.y == 0) ? endRect.size.width : endRect.size.height;
    self.messagesTableView.contentInset = insets;
    
    [self scrollToBottomAnimated:YES];
    
    // Move up control view
    // Don't forget the offset related to tabBar
    _controlViewBottomConstraint.constant = insets.bottom - [AppDelegate theDelegate].masterTabBarController.tabBar.frame.size.height;
}

- (void)onKeyboardWillHide:(NSNotification *)notif {
    UIEdgeInsets insets = self.messagesTableView.contentInset;
    insets.bottom = self.controlView.frame.size.height;
    self.messagesTableView.contentInset = insets;
    
    _controlViewBottomConstraint.constant = 0;
}

- (void)dismissKeyboard {
    // Hide the keyboard
    [_messageTextField resignFirstResponder];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Check table view members vs messages
    if (tableView == self.membersTableView)
    {
        return members.count;
    }
    
    return messages.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Check table view members vs messages
    if (tableView == self.membersTableView)
    {
        return 50;
    }
    
    // Compute here height of message cells
    CGFloat rowHeight;
    // Get event related to this row
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    MXEvent *mxEvent = [messages objectAtIndex:indexPath.row];
    CGSize contentSize;
    if ([mxHandler isAttachment:mxEvent]) {
        contentSize = [self attachmentContentSize:mxEvent];
    } else {
        // Use a TextView template to compute cell height
        UITextView *dummyTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH, MAXFLOAT)];
        dummyTextView.font = [UIFont systemFontOfSize:14];
        dummyTextView.text = [mxHandler displayTextFor:mxEvent inSubtitleMode:NO];
        contentSize = [dummyTextView sizeThatFits:dummyTextView.frame.size];
    }
    
    // Check whether the previous message has been sent by the same user.
    // We group together messages from the same user. The user's picture and name are displayed only for the first message.
    // We consider a new chunk when the user is different from the previous message's one.
    BOOL isNewChunk = YES;
    if (indexPath.row) {
        MXEvent *previousMxEvent = [messages objectAtIndex:indexPath.row - 1];
        if ([previousMxEvent.userId isEqualToString:mxEvent.userId]) {
            isNewChunk = NO;
        }
    }
    
    // Adjust cell height inside chunk
    rowHeight = contentSize.height;
    if (isNewChunk) {
        // The cell is the first cell of the chunk
        rowHeight += ROOM_MESSAGE_CELL_TEXTVIEW_TOP_CONST_DEFAULT;
    } else {
        // Inside chunk the height of the cell is reduced in order to reduce padding between messages
        rowHeight += ROOM_MESSAGE_CELL_TEXTVIEW_TOP_CONST_IN_CHUNK;
    }
    
    // Check whether the message is the last message of the current chunk
    BOOL isChunkEnd = YES;
    if (indexPath.row < messages.count - 1) {
        MXEvent *nextMxEvent = [messages objectAtIndex:indexPath.row + 1];
        if ([nextMxEvent.userId isEqualToString:mxEvent.userId]) {
            isChunkEnd = NO;
        }
    }
    
    if (!isNewChunk && !isChunkEnd) {
        // Reduce again cell height to reduce space with the next cell
        rowHeight += ROOM_MESSAGE_CELL_TEXTVIEW_BOTTOM_CONST_GROUPED_CELL;
    } else {
        // The cell is the first cell of the chunk or the last one
        rowHeight += ROOM_MESSAGE_CELL_TEXTVIEW_BOTTOM_CONST_DEFAULT;
    }
    
    if (isNewChunk && isChunkEnd) {
        // When the chunk is composed by only one message, we consider the minimun cell height (50) in order to display correctly user's picture
        if (rowHeight < 50) {
            rowHeight = 50;
        }
    }
    
    return rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    // Check table view members vs messages
    if (tableView == self.membersTableView) {
        RoomMemberTableCell *memberCell = [tableView dequeueReusableCellWithIdentifier:@"RoomMemberCell" forIndexPath:indexPath];
        if (indexPath.row < members.count) {
            [memberCell setRoomMember:[members objectAtIndex:indexPath.row] withRoom:mxRoom];
        }
        
        return memberCell;
    }
    
    // Handle here room message cells
    RoomMessageTableCell *cell;
    MXEvent *mxEvent = [messages objectAtIndex:indexPath.row];
    BOOL isIncomingMsg = NO;
    
    if ([mxEvent.userId isEqualToString:mxHandler.userId]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"OutgoingMessageCell" forIndexPath:indexPath];
        [((OutgoingMessageTableCell*)cell).activityIndicator stopAnimating];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"IncomingMessageCell" forIndexPath:indexPath];
        isIncomingMsg = YES;
    }
    
    // Check whether the previous message has been sent by the same user.
    // We group together messages from the same user. The user's picture and name are displayed only for the first message.
    // We consider a new chunk when the user is different from the previous message's one.
    BOOL isNewChunk = YES;
    if (indexPath.row) {
        MXEvent *previousMxEvent = [messages objectAtIndex:indexPath.row - 1];
        if ([previousMxEvent.userId isEqualToString:mxEvent.userId]) {
            isNewChunk = NO;
        }
    }
    
    if (isNewChunk) {
        // Adjust display of the first message of a chunk
        cell.pictureView.hidden = NO;
        cell.msgTextViewTopConstraint.constant = ROOM_MESSAGE_CELL_TEXTVIEW_TOP_CONST_DEFAULT;
        cell.msgTextViewBottomConstraint.constant = ROOM_MESSAGE_CELL_TEXTVIEW_BOTTOM_CONST_DEFAULT;
        cell.messageTextView.contentInset = UIEdgeInsetsZero;
        
        // Set user's picture
        cell.placeholder = @"default-profile";
        cell.pictureURL = [mxRoom.state memberWithUserId:mxEvent.userId].avatarUrl;
    } else {
        // Adjust display of other messages of the chunk
        cell.pictureView.hidden = YES;
        // The height of this cell has been reduced in order to reduce padding between messages of the same chunk
        // We define here a negative constant for the top space between textView and its superview to display correctly the message text.
        cell.msgTextViewTopConstraint.constant = ROOM_MESSAGE_CELL_TEXTVIEW_TOP_CONST_IN_CHUNK;
        // Shift to the top the displayed message to reduce space with the previous messages
        UIEdgeInsets edgeInsets = UIEdgeInsetsZero;
        edgeInsets.top = ROOM_MESSAGE_CELL_TEXTVIEW_EDGE_INSET_TOP_IN_CHUNK;
        cell.messageTextView.contentInset = edgeInsets;
        
        // Check whether the next message belongs to the same chunk in order to define bottom space between textView and its superview
        cell.msgTextViewBottomConstraint.constant = ROOM_MESSAGE_CELL_TEXTVIEW_BOTTOM_CONST_DEFAULT;
        if (indexPath.row < messages.count - 1) {
            MXEvent *nextMxEvent = [messages objectAtIndex:indexPath.row + 1];
            if ([nextMxEvent.userId isEqualToString:mxEvent.userId]) {
                cell.msgTextViewBottomConstraint.constant = ROOM_MESSAGE_CELL_TEXTVIEW_BOTTOM_CONST_GROUPED_CELL;
            }
        }
    }
    
    // Update incoming/outgoing message layout
    if (isIncomingMsg) {
        IncomingMessageTableCell* incomingMsgCell = (IncomingMessageTableCell*)cell;
        // Display user's display name for the first meesage of a chunk, except if the name appears in the displayed text (see emote and membership event)
        if (isNewChunk && [mxHandler isNotification:mxEvent] == NO) {
            incomingMsgCell.userNameLabel.hidden = NO;
            incomingMsgCell.userNameLabel.text = [mxRoom.state memberName:mxEvent.userId];
        } else {
            incomingMsgCell.userNameLabel.hidden = YES;
        }
        
        // Reset text color
        cell.messageTextView.textColor = [UIColor blackColor];
    } else {
        OutgoingMessageTableCell* outgoingMsgCell = (OutgoingMessageTableCell*)cell;
        // Hide unsent label by default
        outgoingMsgCell.unsentLabel.hidden = YES;
        
        // Set the right text color for outgoing messages
        if ([mxEvent.eventId hasPrefix:kLocalEchoEventIdPrefix]) {
            cell.messageTextView.textColor = [UIColor lightGrayColor];
        } else if ([mxEvent.eventId hasPrefix:kFailedEventId]) {
            cell.messageTextView.textColor = [UIColor redColor];
            outgoingMsgCell.unsentLabel.hidden = NO;
            // Align unsent label with the textView
            outgoingMsgCell.unsentLabelTopConstraint.constant = cell.msgTextViewTopConstraint.constant + cell.messageTextView.contentInset.top - ROOM_MESSAGE_CELL_TEXTVIEW_EDGE_INSET_TOP_IN_CHUNK;
        } else {
            cell.messageTextView.textColor = [UIColor blackColor];
        }
    }
    
    if ([mxHandler isAttachment:mxEvent]) {
        cell.attachmentView.hidden = NO;
        cell.messageTextView.text = nil; // Note: Text view is used as attachment background view
        CGSize contentSize = [self attachmentContentSize:mxEvent];
        cell.msgTextViewWidthConstraint.constant = contentSize.width;
        
        // Fade attachments during upload
        if (isIncomingMsg == NO && [mxEvent.eventId hasPrefix:kLocalEchoEventIdPrefix]) {
            cell.attachmentView.alpha = 0.5;
            [((OutgoingMessageTableCell*)cell).activityIndicator startAnimating];
        } else {
            cell.attachmentView.alpha = 1;
        }
        
        NSString *msgtype = mxEvent.content[@"msgtype"];
        if ([msgtype isEqualToString:kMXMessageTypeImage]) {
            NSString *url = mxEvent.content[@"thumbnail_url"];
            if (url == nil) {
                url = mxEvent.content[@"url"];
            }
            cell.attachedImageURL = url;
        } else {
            cell.attachedImageURL = nil;
        }
    } else {
        // Text message will be displayed in textView with max width
        cell.msgTextViewWidthConstraint.constant = ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH;
        // Cancel potential attachment loading
        cell.attachedImageURL = nil;
        cell.attachmentView.hidden = YES;
        
        NSString *displayText = [mxHandler displayTextFor:mxEvent inSubtitleMode:NO];
        // Update text color according to text content
        if ([displayText hasPrefix:kMatrixHandlerUnsupportedMessagePrefix]) {
            cell.messageTextView.textColor = [UIColor redColor];
        } else if (isIncomingMsg && ([displayText rangeOfString:mxHandler.userDisplayName options:NSCaseInsensitiveSearch].location != NSNotFound || [displayText rangeOfString:mxHandler.userId options:NSCaseInsensitiveSearch].location != NSNotFound)) {
            cell.messageTextView.textColor = [UIColor blueColor];
        }
        cell.messageTextView.text = displayText;
    }
    
    // Handle timestamp display
    if (dateFormatter && mxEvent.originServerTs) {
        cell.dateTimeLabel.hidden = NO;
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:mxEvent.originServerTs/1000];
        cell.dateTimeLabel.text = [dateFormatter stringFromDate:date];
        // Align dateTime label with the textView
        cell.dateTimeLabelTopConstraint.constant = cell.msgTextViewTopConstraint.constant + cell.messageTextView.contentInset.top - ROOM_MESSAGE_CELL_TEXTVIEW_EDGE_INSET_TOP_IN_CHUNK;
    } else {
        cell.dateTimeLabel.hidden = YES;
    }
    
    return cell;
}

- (CGSize)attachmentContentSize:(MXEvent*)mxEvent;
{
    CGSize contentSize;
    NSString *msgtype = mxEvent.content[@"msgtype"];
    if ([msgtype isEqualToString:kMXMessageTypeImage]) {
        CGFloat width, height;
        width = height = ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH;
        NSDictionary *thumbInfo = mxEvent.content[@"thumbnail_info"];
        if (thumbInfo) {
            width = [thumbInfo[@"w"] integerValue] + 2 * ROOM_MESSAGE_CELL_IMAGE_MARGIN;
            height = [thumbInfo[@"h"] integerValue] + 2 * ROOM_MESSAGE_CELL_IMAGE_MARGIN;
            if (width > ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH || height > ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH) {
                if (width > height) {
                    height = (height * ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH) / width;
                    height = floorf(height / 2) * 2;
                    width = ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH;
                } else {
                    width = (width * ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH) / height;
                    width = floorf(width / 2) * 2;
                    height = ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH;
                }
            }
        }
        contentSize = CGSizeMake(width, height);
    } else {
        contentSize = CGSizeMake(40, 40);
    }
    return contentSize;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Check table view members vs messages
    if (tableView == self.membersTableView) {
        // List action(s) available on this member
        // TODO: Check user's power level before allowing an action (kick, ban, ...)
        MXRoomMember *roomMember = [members objectAtIndex:indexPath.row];
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        __weak typeof(self) weakSelf = self;
        if (self.actionMenu) {
            [self.actionMenu dismiss:NO];
            self.actionMenu = nil;
        }
        
        // Consider the case of the user himself
        if ([roomMember.userId isEqualToString:mxHandler.userId]) {
            self.actionMenu = [[CustomAlert alloc] initWithTitle:@"Select an action:" message:nil style:CustomAlertStyleActionSheet];
            [self.actionMenu addActionWithTitle:@"Leave" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                if (weakSelf) {
                    weakSelf.actionMenu = nil;
                    [[MatrixHandler sharedHandler].mxRestClient leaveRoom:weakSelf.roomId
                                                                  success:^{
                                                                      // Back to recents
                                                                      [weakSelf.navigationController popViewControllerAnimated:YES];
                                                                  }
                                                                  failure:^(NSError *error) {
                                                                      NSLog(@"Leave room %@ failed: %@", weakSelf.roomId, error);
                                                                      //Alert user
                                                                      [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                  }];
                }
            }];
        } else {
            // Consider membership of the selected member
            switch (roomMember.membership) {
                case MXMembershipInvite:
                case MXMembershipJoin: {
                    self.actionMenu = [[CustomAlert alloc] initWithTitle:@"Select an action:" message:nil style:CustomAlertStyleActionSheet];
                    [self.actionMenu addActionWithTitle:@"Kick" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                        if (weakSelf) {
                            weakSelf.actionMenu = nil;
                            [[MatrixHandler sharedHandler].mxRestClient kickUser:roomMember.userId
                                                                        fromRoom:weakSelf.roomId
                                                                          reason:nil
                                                                         success:^{
                                                                         }
                                                                         failure:^(NSError *error) {
                                                                             NSLog(@"Kick %@ failed: %@", roomMember.userId, error);
                                                                             //Alert user
                                                                             [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                         }];
                        }
                    }];
                    [self.actionMenu addActionWithTitle:@"Ban" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                        if (weakSelf) {
                            weakSelf.actionMenu = nil;
                            [[MatrixHandler sharedHandler].mxRestClient banUser:roomMember.userId
                                                                         inRoom:weakSelf.roomId
                                                                         reason:nil
                                                                        success:^{
                                                                        }
                                                                        failure:^(NSError *error) {
                                                                            NSLog(@"Ban %@ failed: %@", roomMember.userId, error);
                                                                            //Alert user
                                                                            [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                        }];
                        }
                    }];
                    break;
                }
                case MXMembershipLeave: {
                    self.actionMenu = [[CustomAlert alloc] initWithTitle:@"Select an action:" message:nil style:CustomAlertStyleActionSheet];
                    [self.actionMenu addActionWithTitle:@"Invite" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                        if (weakSelf) {
                            weakSelf.actionMenu = nil;
                            [[MatrixHandler sharedHandler].mxRestClient inviteUser:roomMember.userId
                                                                            toRoom:weakSelf.roomId
                                                                           success:^{
                                                                           }
                                                                           failure:^(NSError *error) {
                                                                               NSLog(@"Invite %@ failed: %@", roomMember.userId, error);
                                                                               //Alert user
                                                                               [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                           }];
                        }
                    }];
                    [self.actionMenu addActionWithTitle:@"Ban" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                        if (weakSelf) {
                            weakSelf.actionMenu = nil;
                            [[MatrixHandler sharedHandler].mxRestClient banUser:roomMember.userId
                                                                         inRoom:weakSelf.roomId
                                                                         reason:nil
                                                                        success:^{
                                                                        }
                                                                        failure:^(NSError *error) {
                                                                            NSLog(@"Ban %@ failed: %@", roomMember.userId, error);
                                                                            //Alert user
                                                                            [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                        }];
                        }
                    }];
                    break;
                }
                case MXMembershipBan: {
                    self.actionMenu = [[CustomAlert alloc] initWithTitle:@"Select an action:" message:nil style:CustomAlertStyleActionSheet];
                    [self.actionMenu addActionWithTitle:@"Unban" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                        if (weakSelf) {
                            weakSelf.actionMenu = nil;
                            [[MatrixHandler sharedHandler].mxRestClient unbanUser:roomMember.userId
                                                                           inRoom:weakSelf.roomId
                                                                          success:^{
                                                                          }
                                                                          failure:^(NSError *error) {
                                                                              NSLog(@"Unban %@ failed: %@", roomMember.userId, error);
                                                                              //Alert user
                                                                              [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                          }];
                        }
                    }];
                    break;
                }
                default: {
                    break;
                }
            }
        }
        
        // Display the action sheet (if any)
        if (self.actionMenu) {
            self.actionMenu.cancelButtonIndex = [self.actionMenu addActionWithTitle:@"Cancel" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                weakSelf.actionMenu = nil;
            }];
            [self.actionMenu showInViewController:self];
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (tableView == self.messagesTableView) {
        // Dismiss keyboard when user taps on messages table view content
        [self dismissKeyboard];
    }
}

// Detect vertical bounce at the top of the tableview to trigger pagination
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView == self.messagesTableView) {
        // paginate ?
        if ((scrollView.contentOffset.y < -64) && (_activityIndicator.isAnimating == NO))
        {
            [self triggerBackPagination];
        }
    }
}

#pragma mark - UITextField delegate

- (void)onTextFieldChange:(NSNotification *)notif {
    NSString *msg = _messageTextField.text;
    
    if (msg.length) {
        _sendBtn.enabled = YES;
        _sendBtn.alpha = 1;
        // Reset potential placeholder (used in case of wrong command usage)
        _messageTextField.placeholder = nil;
    } else {
        _sendBtn.enabled = NO;
        _sendBtn.alpha = 0.5;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*) textField {
    // "Done" key has been pressed
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender {
    if (sender == _sendBtn) {
        NSString *msgTxt = self.messageTextField.text;
        
        // Handle potential commands in room chat
        if ([self isIRCStyleCommand:msgTxt] == NO) {
            [self postTextMessage:msgTxt];
        }
        
        self.messageTextField.text = nil;
        // disable send button
        [self onTextFieldChange:nil];
    } else if (sender == _optionBtn) {
        [self dismissKeyboard];
        
        // Display action menu: Add attachments, Invite user...
        __weak typeof(self) weakSelf = self;
        self.actionMenu = [[CustomAlert alloc] initWithTitle:@"Select an action:" message:nil style:CustomAlertStyleActionSheet];
        // Attachments
        [self.actionMenu addActionWithTitle:@"Attach" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
            if (weakSelf) {
                // Ask for attachment type
                weakSelf.actionMenu = [[CustomAlert alloc] initWithTitle:@"Select an attachment type:" message:nil style:CustomAlertStyleActionSheet];
                [weakSelf.actionMenu addActionWithTitle:@"Media" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                    if (weakSelf) {
                        // Open media gallery
                        UIImagePickerController *mediaPicker = [[UIImagePickerController alloc] init];
                        mediaPicker.delegate = weakSelf;
                        mediaPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                        mediaPicker.allowsEditing = NO;
                        mediaPicker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie, nil];
                        weakSelf.isHiddenByMediaPicker = YES;
                        [[AppDelegate theDelegate].masterTabBarController presentMediaPicker:mediaPicker];
                    }
                }];
                weakSelf.actionMenu.cancelButtonIndex = [weakSelf.actionMenu addActionWithTitle:@"Cancel" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                    weakSelf.actionMenu = nil;
                }];
                [weakSelf.actionMenu showInViewController:weakSelf];
            }
        }];
        // Invitation
        [self.actionMenu addActionWithTitle:@"Invite" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
            if (weakSelf) {
                // Ask for userId to invite
                weakSelf.actionMenu = [[CustomAlert alloc] initWithTitle:@"User ID:" message:nil style:CustomAlertStyleAlert];
                weakSelf.actionMenu.cancelButtonIndex = [weakSelf.actionMenu addActionWithTitle:@"Cancel" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                    weakSelf.actionMenu = nil;
                }];
                [weakSelf.actionMenu addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.secureTextEntry = NO;
                    textField.placeholder = @"ex: @bob:homeserver";
                }];
                [weakSelf.actionMenu addActionWithTitle:@"Invite" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                    UITextField *textField = [alert textFieldAtIndex:0];
                    NSString *userId = textField.text;
                    weakSelf.actionMenu = nil;
                    if (userId.length) {
                        [[MatrixHandler sharedHandler].mxRestClient inviteUser:userId toRoom:weakSelf.roomId success:^{
                            
                        } failure:^(NSError *error) {
                            NSLog(@"Invite %@ failed: %@", userId, error);
                            //Alert user
                            [[AppDelegate theDelegate] showErrorAsAlert:error];
                        }];
                    }
                }];
                [weakSelf.actionMenu showInViewController:weakSelf];
            }
        }];
        self.actionMenu.cancelButtonIndex = [self.actionMenu addActionWithTitle:@"Cancel" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
             weakSelf.actionMenu = nil;
        }];
        weakSelf.actionMenu.sourceView = weakSelf.optionBtn;
        [self.actionMenu showInViewController:self];
    }
}

- (IBAction)showHideDateTime:(id)sender {
    if (dateFormatter) {
        // dateTime will be hidden
        dateFormatter = nil;
    } else {
        // dateTime will be visible
        NSString *dateFormat =  @"MMM dd HH:mm";
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]]];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDateFormat:dateFormat];
    }
    
    [self.messagesTableView reloadData];
}

#pragma mark - Post messages

- (void)postMessage:(NSDictionary*)msgContent withLocalEventId:(NSString*)localEventId {
    MXMessageType msgType = msgContent[@"msgtype"];
    if (msgType) {
        // Check whether a temporary event has already been added for local echo (this happens on attachments)
        MXEvent *mxEvent = nil;
        if (localEventId) {
            // Update the temporary event with the actual msg content
            NSUInteger index = messages.count;
            while (index--) {
                mxEvent = [messages objectAtIndex:index];
                if ([mxEvent.eventId isEqualToString:localEventId]) {
                    mxEvent.content = msgContent;
                    // Refresh table display
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    break;
                }
            }
        } else {
            // Create a temporary event to displayed outgoing message (local echo)
            localEventId = [NSString stringWithFormat:@"%@%@", kLocalEchoEventIdPrefix, [[NSProcessInfo processInfo] globallyUniqueString]];
            mxEvent = [[MXEvent alloc] init];
            mxEvent.roomId = self.roomId;
            mxEvent.eventId = localEventId;
            mxEvent.eventType = MXEventTypeRoomMessage;
            mxEvent.type = kMXEventTypeStringRoomMessage;
            mxEvent.content = msgContent;
            mxEvent.userId = [MatrixHandler sharedHandler].userId;
            // Update table sources
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count inSection:0];
            [messages addObject:mxEvent];
            // Refresh table display (Disable animation during cells insertion to prevent flickering)
            [UIView setAnimationsEnabled:NO];
            [self.messagesTableView beginUpdates];
            if (indexPath.row > 0) {
                NSIndexPath *prevIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0];
                [self.messagesTableView reloadRowsAtIndexPaths:@[prevIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            [self.messagesTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self.messagesTableView endUpdates];
            [UIView setAnimationsEnabled:YES];
            
            [self scrollToBottomAnimated:NO];
        }
        
        // Send message to the room
        [[[MatrixHandler sharedHandler] mxRestClient] postMessage:self.roomId msgType:msgType content:mxEvent.content success:^(NSString *event_id) {
            // Update the temporary event with the actual event id
            NSUInteger index = messages.count;
            while (index--) {
                MXEvent *mxEvent = [messages objectAtIndex:index];
                if ([mxEvent.eventId isEqualToString:localEventId]) {
                    mxEvent.eventId = event_id;
                    // Refresh table display
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    break;
                }
            }
        } failure:^(NSError *error) {
            NSLog(@"Failed to send message (%@): %@", mxEvent.description, error);
            // Update the temporary event with the failed event id
            NSUInteger index = messages.count;
            while (index--) {
                MXEvent *mxEvent = [messages objectAtIndex:index];
                if ([mxEvent.eventId isEqualToString:localEventId]) {
                    mxEvent.eventId = kFailedEventId;
                    // Refresh table display
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [self scrollToBottomAnimated:YES];
                    break;
                }
            }
        }];
    }
}

- (void)postTextMessage:(NSString*)msgTxt {
    MXMessageType msgType = kMXMessageTypeText;
    // Check whether the message is an emote
    if ([msgTxt hasPrefix:@"/me "]) {
        msgType = kMXMessageTypeEmote;
        // Remove "/me " string
        msgTxt = [msgTxt substringFromIndex:4];
    }
    
    [self postMessage:@{@"msgtype":msgType, @"body":msgTxt} withLocalEventId:nil];
}

- (BOOL)isIRCStyleCommand:(NSString*)text{
    // Check whether the provided text may be an IRC-style command
    if ([text hasPrefix:@"/"] == NO || [text hasPrefix:@"//"] == YES) {
        return NO;
    }
    
    // Parse command line
    NSArray *components = [text componentsSeparatedByString:@" "];
    NSString *cmd = [components objectAtIndex:0];
    NSUInteger index = 1;
    
    if ([cmd isEqualToString:kCmdEmote]) {
        // post message as an emote
        [self postTextMessage:text];
    } else if ([text hasPrefix:kCmdChangeDisplayName]) {
        // Change display name
        NSString *displayName = [text substringFromIndex:kCmdChangeDisplayName.length + 1];
        // Remove white space from both ends
        displayName = [displayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (displayName.length) {
            MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
            [mxHandler.mxRestClient setDisplayName:displayName success:^{
            } failure:^(NSError *error) {
                NSLog(@"Set displayName failed: %@", error);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];
        } else {
            // Display cmd usage in text input as placeholder
            self.messageTextField.placeholder = @"Usage: /nick <display_name>";
        }
    } else if ([text hasPrefix:kCmdJoinRoom]) {
        // Join a room
        NSString *roomAlias = [text substringFromIndex:kCmdJoinRoom.length + 1];
        // Remove white space from both ends
        roomAlias = [roomAlias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // Check
        if (roomAlias.length) {
            // FIXME
            NSLog(@"Join Alias is not supported yet (%@)", text);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"/join is not supported yet" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        } else {
            // Display cmd usage in text input as placeholder
            self.messageTextField.placeholder = @"Usage: /join <room_alias>";
        }
    } else {
        // Retrieve userId
        NSString *userId = nil;
        while (index < components.count) {
            userId = [components objectAtIndex:index++];
            if (userId.length) {
                // done
                break;
            }
            // reset
            userId = nil;
        }
        
        if ([cmd isEqualToString:kCmdKickUser]) {
            if (userId) {
                // Retrieve potential reason
                NSString *reason = nil;
                while (index < components.count) {
                    if (reason) {
                        reason = [NSString stringWithFormat:@"%@ %@", reason, [components objectAtIndex:index++]];
                    } else {
                        reason = [components objectAtIndex:index++];
                    }
                }
                // Kick the user
                MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
                [mxHandler.mxRestClient kickUser:userId fromRoom:self.roomId reason:reason success:^{
                } failure:^(NSError *error) {
                    NSLog(@"Kick user (%@) failed: %@", userId, error);
                    //Alert user
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                }];
            } else {
                // Display cmd usage in text input as placeholder
                self.messageTextField.placeholder = @"Usage: /kick <userId> [<reason>]";
            }
        } else if ([cmd isEqualToString:kCmdBanUser]) {
            if (userId) {
                // Retrieve potential reason
                NSString *reason = nil;
                while (index < components.count) {
                    if (reason) {
                        reason = [NSString stringWithFormat:@"%@ %@", reason, [components objectAtIndex:index++]];
                    } else {
                        reason = [components objectAtIndex:index++];
                    }
                }
                // Ban the user
                MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
                [mxHandler.mxRestClient banUser:userId inRoom:self.roomId reason:reason success:^{
                } failure:^(NSError *error) {
                    NSLog(@"Ban user (%@) failed: %@", userId, error);
                    //Alert user
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                }];
            } else {
                // Display cmd usage in text input as placeholder
                self.messageTextField.placeholder = @"Usage: /ban <userId> [<reason>]";
            }
        } else if ([cmd isEqualToString:kCmdUnbanUser]) {
            if (userId) {
                // Unban the user
                MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
                [mxHandler.mxRestClient unbanUser:userId inRoom:self.roomId success:^{
                } failure:^(NSError *error) {
                    NSLog(@"Unban user (%@) failed: %@", userId, error);
                    //Alert user
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                }];
            } else {
                // Display cmd usage in text input as placeholder
                self.messageTextField.placeholder = @"Usage: /unban <userId>";
            }
        } else if ([cmd isEqualToString:kCmdSetUserPowerLevel]) {
            // Retrieve power level
            NSString *powerLevel = nil;
            while (index < components.count) {
                powerLevel = [components objectAtIndex:index++];
                if (powerLevel.length) {
                    // done
                    break;
                }
                // reset
                powerLevel = nil;
            }
            // Set power level
            if (userId && powerLevel) {
                // FIXME
                NSLog(@"Set user power level (/op) is not supported yet (%@)", userId);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"/op is not supported yet" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
            } else {
                // Display cmd usage in text input as placeholder
                self.messageTextField.placeholder = @"Usage: /op <userId> <power level>";
            }
        } else if ([cmd isEqualToString:kCmdResetUserPowerLevel]) {
            if (userId) {
                // Reset user power level
                // FIXME
                NSLog(@"Reset user power level (/deop) is not supported yet (%@)", userId);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"/deop is not supported yet" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
            } else {
                // Display cmd usage in text input as placeholder
                self.messageTextField.placeholder = @"Usage: /deop <userId>";
            }
        } else {
            NSLog(@"Unrecognised IRC-style command: %@", text);
            self.messageTextField.placeholder = [NSString stringWithFormat:@"Unrecognised IRC-style command: %@", cmd];
        }
    }
    return YES;
}

# pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (selectedImage) {
            // Create a temporary event to displayed outgoing message (local echo)
            NSString *localEventId = [NSString stringWithFormat:@"%@%@", kLocalEchoEventIdPrefix, [[NSProcessInfo processInfo] globallyUniqueString]];
            MXEvent *mxEvent = [[MXEvent alloc] init];
            mxEvent.roomId = self.roomId;
            mxEvent.eventId = localEventId;
            mxEvent.eventType = MXEventTypeRoomMessage;
            mxEvent.type = kMXEventTypeStringRoomMessage;
            // We store temporarily the selected image in cache, use the localId to build temporary url
            NSString *dummyURL = [NSString stringWithFormat:@"%@%@", kMediaManagerPrefixForDummyURL, localEventId];
            NSData *selectedImageData = UIImageJPEGRepresentation(selectedImage, 0.5);
            [MediaManager cachePictureWithData:selectedImageData forURL:dummyURL];
            if (tmpCachedAttachments == nil) {
                tmpCachedAttachments = [NSMutableArray array];
            }
            [tmpCachedAttachments addObject:dummyURL];
            NSMutableDictionary *thumbnailInfo = [[NSMutableDictionary alloc] init];
            [thumbnailInfo setValue:@"image/jpeg" forKey:@"mimetype"];
            [thumbnailInfo setValue:[NSNumber numberWithUnsignedInteger:(NSUInteger)selectedImage.size.width] forKey:@"w"];
            [thumbnailInfo setValue:[NSNumber numberWithUnsignedInteger:(NSUInteger)selectedImage.size.height] forKey:@"h"];
            [thumbnailInfo setValue:[NSNumber numberWithUnsignedInteger:selectedImageData.length] forKey:@"size"];
            mxEvent.content = @{@"msgtype":@"m.image", @"thumbnail_info":thumbnailInfo, @"thumbnail_url":dummyURL};
            mxEvent.userId = [MatrixHandler sharedHandler].userId;
            
            // Update table sources
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count inSection:0];
            [messages addObject:mxEvent];
            
            // Refresh table display (Disable animation during cells insertion to prevent flickering)
            [UIView setAnimationsEnabled:NO];
            [self.messagesTableView beginUpdates];
            if (indexPath.row > 0) {
                NSIndexPath *prevIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0];
                [self.messagesTableView reloadRowsAtIndexPaths:@[prevIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            [self.messagesTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self.messagesTableView endUpdates];
            [UIView setAnimationsEnabled:YES];
            
            [self scrollToBottomAnimated:NO];
            
            // Upload image and its thumbnail
            MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
            NSUInteger thumbnailSize = ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH - 5 * ROOM_MESSAGE_CELL_IMAGE_MARGIN;
            [mxHandler.mxRestClient uploadImage:selectedImage thumbnailSize:thumbnailSize timeout:30 success:^(NSDictionary *imageMessage) {
                // Send image
                [self postMessage:imageMessage withLocalEventId:localEventId];
            } failure:^(NSError *error) {
                NSLog(@"Failed to upload image: %@", error);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
                // Update the temporary event with the failed event id
                NSUInteger index = messages.count;
                while (index--) {
                    MXEvent *mxEvent = [messages objectAtIndex:index];
                    if ([mxEvent.eventId isEqualToString:localEventId]) {
                        mxEvent.eventId = kFailedEventId;
                        // Refresh table display
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                        [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        [self scrollToBottomAnimated:YES];
                        break;
                    }
                }
            }];
        }
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        //TODO
    }
    
    [self dismissMediaPicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissMediaPicker];
}

- (void)dismissMediaPicker {
    [[AppDelegate theDelegate].masterTabBarController dismissMediaPicker];
}
@end
