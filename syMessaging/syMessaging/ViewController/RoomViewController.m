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

#import "RoomViewController.h"
#import "RoomMessageTableCell.h"

#import "MatrixHandler.h"
#import "AppDelegate.h"

#define ROOM_MESSAGE_CELL_TOP_MARGIN 5
#define ROOM_MESSAGE_CELL_BOTTOM_MARGIN 5
#define INCOMING_MESSAGE_CELL_USER_LABEL_HEIGHT 20

NSString *const kLocalEchoEventIdPrefix = @"localEcho-";
NSString *const kFailedEventId = @"failedEventId";


@interface RoomViewController ()
{
    BOOL isFirstDisplay;
    
    MXRoomData *mxRoomData;
    
    NSMutableArray *messages;
    id registeredListener;
    
    // Members list
    NSArray       *members;
    UIView        *membersTableViewBackground;
    UITableView   *membersTableView;
}

@property (weak, nonatomic) IBOutlet UINavigationItem *roomNavItem;
@property (weak, nonatomic) IBOutlet UITableView *messagesTableView;
@property (weak, nonatomic) IBOutlet UIView *controlView;
@property (weak, nonatomic) IBOutlet UIButton *optionBtn;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *controlViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

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
    messages = nil;
    if (registeredListener) {
        [mxRoomData unregisterListener:registeredListener];
        registeredListener = nil;
    }
    mxRoomData = nil;
    
    membersTableViewBackground = nil;
    membersTableView = nil;
    members = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Reload room data
    [self configureView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextFieldChange:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Hide members by default
    [self hideRoomMembers];
    
    if (registeredListener) {
        [mxRoomData unregisterListener:registeredListener];
        registeredListener = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
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
    _roomId = roomId;
    
    // Load room data
    [self configureView];
    
    // Trigger a back pagination if messages number is low
    if (messages.count < 10) {
        [self triggerBackPagination];
    }
}

#pragma mark - Internal methods

- (void)configureView {
    // Flush messages
    messages = nil;
    
    // Remove potential roomData listener
    if (registeredListener && mxRoomData) {
        [mxRoomData unregisterListener:registeredListener];
        registeredListener = nil;
    }
    
    // Update room data
    if (self.roomId) {
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        mxRoomData = [mxHandler.mxData getRoomData:self.roomId];
        messages = [NSMutableArray arrayWithArray:mxRoomData.messages];
        // Register a listener for events that modify the `messages` property 
        registeredListener = [mxRoomData registerEventListenerForTypes:mxHandler.mxData.eventsFilterForMessages block:^(MXRoomData *roomData, MXEvent *event, BOOL isLive) {
            // consider only live event
            if (isLive) {
                // For outgoing message, remove the temporary event
                if ([event.user_id isEqualToString:[MatrixHandler sharedHandler].userId]) {
                    NSUInteger index = messages.count;
                    while (index--) {
                        MXEvent *mxEvent = [messages objectAtIndex:index];
                        if ([mxEvent.event_id isEqualToString:event.event_id]) {
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
                [self.messagesTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
                [self scrollToBottomAnimated:YES];
            }
        }];
    } else {
        mxRoomData = nil;
    }
    
    [self.messagesTableView reloadData];
    
    // Update room title
    self.roomNavItem.title = mxRoomData.displayname;
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    // Scroll table view to the bottom
    NSInteger rowNb = messages.count;
    if (rowNb) {
        [self.messagesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(rowNb - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (void)triggerBackPagination {
    if (mxRoomData.canPaginate)
    {
        [_activityIndicator startAnimating];
        
        [mxRoomData paginateBackMessages:20 success:^(NSArray *oldMessages) {
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
                // Trigger a new back pagination (if any)
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

- (void)showRoomMembers {
    members = [mxRoomData members];
    
    // define members table background
    CGRect frame = self.messagesTableView.frame;
    UIEdgeInsets roomTableInset = self.messagesTableView.contentInset;
    frame.origin.x += roomTableInset.left;
    frame.origin.y += roomTableInset.top;
    frame.size.width -= roomTableInset.left + roomTableInset.right;
    frame.size.height -= roomTableInset.top + roomTableInset.bottom;
    // overlap the control view
    frame.size.height += self.controlView.frame.size.height;
    membersTableViewBackground = [[UIView alloc] initWithFrame:frame];
    membersTableViewBackground.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    
    membersTableViewBackground.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideRoomMembers)];
    [membersTableViewBackground addGestureRecognizer:tap];
    
    // compute table height (the table should not cover all the screen to let the user be able to dismiss the table)
    CGFloat tableHeight = members.count * 44;
    CGFloat tableHeightMax = membersTableViewBackground.frame.size.height - 50;
    if (tableHeightMax < tableHeight)
    {
        tableHeight = tableHeightMax;
    }
    frame.size.height = tableHeight;
    membersTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    membersTableView.delegate = self;
    membersTableView.dataSource = self;
    
    [self.view addSubview:membersTableViewBackground];
    [self.view addSubview:membersTableView];
}

- (void)hideRoomMembers {
    [membersTableView removeFromSuperview];
    membersTableView = nil;
    [membersTableViewBackground removeFromSuperview];
    membersTableViewBackground = nil;
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
    // Check whether members list is displayed
    if (tableView == membersTableView)
    {
        return members.count;
    }
    
    return messages.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Check whether members list is displayed
    if (tableView == membersTableView)
    {
        return 44;
    }
    
    // Handle here room thread cells
    CGFloat rowHeight;
    // Get event related to this row
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    MXEvent *mxEvent = [messages objectAtIndex:indexPath.row];
    BOOL isIncomingMsg = ([mxEvent.user_id isEqualToString:mxHandler.userId] == NO);
    
    // Use a TextView template to compute cell height
    UITextView *dummyTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, MAXFLOAT)];
    dummyTextView.font = [UIFont systemFontOfSize:14];
    dummyTextView.text = [mxHandler displayTextFor:mxEvent inSubtitleMode:NO];
    CGSize contentSize = [dummyTextView sizeThatFits:dummyTextView.frame.size];
    
    // Handle incoming / outgoing layout
    if (isIncomingMsg) {
        // By default the user name is displayed above the message
        rowHeight = contentSize.height + ROOM_MESSAGE_CELL_TOP_MARGIN + INCOMING_MESSAGE_CELL_USER_LABEL_HEIGHT + ROOM_MESSAGE_CELL_BOTTOM_MARGIN;
        
        if (indexPath.row) {
            // This user name is hide if the previous message is from the same user
            MXEvent *previousMxEvent = [messages objectAtIndex:indexPath.row - 1];
            if ([previousMxEvent.user_id isEqualToString:mxEvent.user_id]) {
                rowHeight -= INCOMING_MESSAGE_CELL_USER_LABEL_HEIGHT;
            }
        }
    } else {
        rowHeight = contentSize.height + ROOM_MESSAGE_CELL_TOP_MARGIN + ROOM_MESSAGE_CELL_BOTTOM_MARGIN;
    }
    
    // Force minimum height: 50
    if (rowHeight < 50) {
        rowHeight = 50;
    }    
    return rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    // Check whether members list is displayed
    if (tableView == membersTableView)
    {
        UITableViewCell *cell;
        cell = [membersTableView dequeueReusableCellWithIdentifier:@"RoomMemberCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RoomMemberCell"];
            cell.imageView.image = [UIImage imageNamed:@"default-profile"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        if (indexPath.row < members.count) {
            MXRoomMember *roomMember = [members objectAtIndex:indexPath.row];
            cell.textLabel.text = [mxHandler displayNameFor:roomMember];
        }
        
        return cell;
    }
    
    // Handle here room thread cells
    RoomMessageTableCell *cell;
    MXEvent *mxEvent = [messages objectAtIndex:indexPath.row];
    BOOL isIncomingMsg = NO;
    
    if ([mxEvent.user_id isEqualToString:mxHandler.userId]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"OutgoingMessageCell" forIndexPath:indexPath];
        cell.messageTextView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"IncomingMessageCell" forIndexPath:indexPath];
        cell.messageTextView.backgroundColor = [UIColor lightGrayColor];
        isIncomingMsg = YES;
    }
    
    // Clear background for notifications (We consider as notification mxEvent which is not a text message or an attachment)
    if ([mxHandler isNotification:mxEvent]) {
        cell.messageTextView.backgroundColor = [UIColor clearColor];
    }
    
    // Hide user picture if the previous message is from the same user
    cell.pictureView.hidden = NO;
    if (indexPath.row) {
        MXEvent *previousMxEvent = [messages objectAtIndex:indexPath.row - 1];
        if ([previousMxEvent.user_id isEqualToString:mxEvent.user_id]) {
            cell.pictureView.hidden = YES;
        }
    }
    // Set url for visible picture
    if (!cell.pictureView.hidden) {
        cell.placeholder = @"default-profile";
        cell.pictureURL = [mxRoomData getMember:mxEvent.user_id].avatar_url;
    }
    
    // Update incoming/outgoing message layout
    if (isIncomingMsg) {
        // Hide userName in incoming message if the previous message is from the same user
        IncomingMessageTableCell* incomingMsgCell = (IncomingMessageTableCell*)cell;
        CGRect frame = incomingMsgCell.userNameLabel.frame;
        if (cell.pictureView.hidden) {
            incomingMsgCell.userNameLabel.text = nil;
            frame.size.height = 0;
            incomingMsgCell.userNameLabel.hidden = YES;
        } else {
            frame.size.height = INCOMING_MESSAGE_CELL_USER_LABEL_HEIGHT;
            incomingMsgCell.userNameLabel.hidden = NO;
            NSString *userName = [mxHandler displayNameFor:[mxRoomData getMember:mxEvent.user_id]];
            incomingMsgCell.userNameLabel.text = [NSString stringWithFormat:@"- %@", userName];
        }
        incomingMsgCell.userNameLabel.frame = frame;
    } else {
        // Hide unsent label by default
        UILabel *unsentLabel = ((OutgoingMessageTableCell*)cell).unsentLabel;
        unsentLabel.hidden = YES;
        
        // Set the right text color for outgoing messages
        if ([mxEvent.event_id hasPrefix:kLocalEchoEventIdPrefix]) {
            cell.messageTextView.textColor = [UIColor lightGrayColor];
        } else if ([mxEvent.event_id hasPrefix:kFailedEventId]) {
            cell.messageTextView.textColor = [UIColor redColor];
            unsentLabel.hidden = NO;
        } else {
            cell.messageTextView.textColor = [UIColor blackColor];
        }
    }
    
    cell.messageTextView.text = [mxHandler displayTextFor:mxEvent inSubtitleMode:NO];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Dismiss keyboard when user taps on table view content
    [self dismissKeyboard];
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
        
        // Create a temporary event to displayed outgoing message (local echo)
        NSString *localEventId = [NSString stringWithFormat:@"%@%@", kLocalEchoEventIdPrefix, [[NSProcessInfo processInfo] globallyUniqueString]];
        MXEvent *mxEvent = [[MXEvent alloc] init];
        mxEvent.room_id = self.roomId;
        mxEvent.event_id = localEventId;
        mxEvent.eventType = MXEventTypeRoomMessage;
        mxEvent.type = kMXEventTypeStringRoomMessage;
        mxEvent.content = @{@"msgtype":@"m.text", @"body":msgTxt};
        mxEvent.user_id = [MatrixHandler sharedHandler].userId;
        // Update table sources
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count inSection:0];
        [messages addObject:mxEvent];
        // Refresh table display
        [self.messagesTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
        [self scrollToBottomAnimated:YES];
        
        // Send message to the room
        [[[MatrixHandler sharedHandler] mxSession] postTextMessage:self.roomId text:msgTxt success:^(NSString *event_id) {
            // Update the temporary event with the actual event id
            NSUInteger index = messages.count;
            while (index--) {
                MXEvent *mxEvent = [messages objectAtIndex:index];
                if ([mxEvent.event_id isEqualToString:localEventId]) {
                    mxEvent.event_id = event_id;
                    // Refresh table display
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    break;
                }
            }
        } failure:^(NSError *error) {
            NSLog(@"Failed to send message (%@): %@", self.messageTextField.text, error);
            // Update the temporary event with the failed event id
            NSUInteger index = messages.count;
            while (index--) {
                MXEvent *mxEvent = [messages objectAtIndex:index];
                if ([mxEvent.event_id isEqualToString:localEventId]) {
                    mxEvent.event_id = kFailedEventId;
                    // Refresh table display
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [self scrollToBottomAnimated:YES];
                    break;
                }
            }
        }];
        
        self.messageTextField.text = nil;
        // disable send button
        [self onTextFieldChange:nil];
    } else if (sender == _optionBtn) {
        [self dismissKeyboard];
        
        //TODO: display action menu: Add attachments, Invite user...
        

//        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Invite a user" message:nil preferredStyle:UIAlertControllerStyleAlert];
//        or
//        UIAlertView *plainTextInputAlert = [[UIAlertView alloc]initWithTitle:@"Invite a user" message:nil delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"ok", nil];
//        // apply style
//        plainTextInputAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        
    }
}
@end
