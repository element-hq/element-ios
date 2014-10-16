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

#import "MatrixHandler.h"
#import "AppDelegate.h"

#define TEXT_VIEW_VERTICAL_MARGIN 5

// Table view cell
@interface RoomMessageCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *userPicture;
@property (weak, nonatomic) IBOutlet UITextView  *messageTextView;
@end
@implementation RoomMessageCell
@end

@interface IncomingMessageCell : RoomMessageCell
@end
@implementation IncomingMessageCell
@end

@interface OutgoingMessageCell : RoomMessageCell
@end
@implementation OutgoingMessageCell
@end


@interface RoomViewController ()
{
    BOOL isFirstDisplay;
    
    MXRoomData *mxRoomData;
    
    NSMutableArray *messages;
    id registeredListener;
}

@property (weak, nonatomic) IBOutlet UINavigationItem *roomNavItem;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
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
                            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                            return;
                        }
                    }
                }
                // Here a new event is added
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count inSection:0];
                [messages addObject:event];
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
                [self scrollToBottomAnimated:YES];
            }
        }];
    } else {
        mxRoomData = nil;
    }
    
    [self.tableView reloadData];
    
    // Update room title
    self.roomNavItem.title = mxRoomData.displayname;
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    // Scroll table view to the bottom
    NSInteger rowNb = messages.count;
    if (rowNb) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(rowNb - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
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
                    verticalOffset += [self tableView:self.tableView heightForRowAtIndexPath:indexPath];
                }
                
                // Disable animation during cells insertion to prevent flickering
                [UIView setAnimationsEnabled:NO];
                // Store the current content offset
                CGPoint contentOffset = self.tableView.contentOffset;
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
                // Enable animation again
                [UIView setAnimationsEnabled:YES];
                // Fix vertical offset in order to prevent scrolling down
                contentOffset.y += verticalOffset;
                [self.tableView setContentOffset:contentOffset animated:NO];
                
                [_activityIndicator stopAnimating];
                
                // Move the current message at the middle of the visible area (dispatch this action in order to let table end its refresh)
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(oldMessages.count - 1) inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
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

#pragma mark - keyboard handling

- (void)onKeyboardWillShow:(NSNotification *)notif {
    NSValue *rectVal = notif.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect endRect = rectVal.CGRectValue;
    
    UIEdgeInsets insets = self.tableView.contentInset;
    // Handle portrait/landscape mode
    insets.bottom = (endRect.origin.y == 0) ? endRect.size.width : endRect.size.height;
    self.tableView.contentInset = insets;
    
    [self scrollToBottomAnimated:YES];
    
    // Move up control view
    // Don't forget the offset related to tabBar
    _controlViewBottomConstraint.constant = insets.bottom - [AppDelegate theDelegate].masterTabBarController.tabBar.frame.size.height;
}

- (void)onKeyboardWillHide:(NSNotification *)notif {
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.bottom = self.controlView.frame.size.height;
    self.tableView.contentInset = insets;
    
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
    return messages.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat rowHeight;
    // Get event related to this row
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    MXEvent *mxEvent = [messages objectAtIndex:indexPath.row];
    
    // Use a TextView template to compute cell height
    UITextView *dummyTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, MAXFLOAT)];
    dummyTextView.font = [UIFont systemFontOfSize:14];
    dummyTextView.text = [mxHandler displayTextFor:mxEvent inDetailMode:NO];
    CGSize contentSize = [dummyTextView sizeThatFits:dummyTextView.frame.size];
    rowHeight = contentSize.height + (TEXT_VIEW_VERTICAL_MARGIN * 2);
    
    // Force minimum height: 50
    if (rowHeight < 50) {
        rowHeight = 50;
    }    
    return rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RoomMessageCell *cell;
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    MXEvent *mxEvent = [messages objectAtIndex:indexPath.row];
    
    if ([mxEvent.user_id isEqualToString:mxHandler.userId]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"OutgoingMessageCell" forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"IncomingMessageCell" forIndexPath:indexPath];
    }
    
    cell.messageTextView.text = [mxHandler displayTextFor:mxEvent inDetailMode:NO];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Dismiss keyboard when user taps on table view content
    [self dismissKeyboard];
}

// Detect vertical bounce at the top of the tableview to trigger pagination
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView == self.tableView) {
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

#pragma mark -

- (IBAction)onButtonPressed:(id)sender {
    if (sender == _sendBtn) {
        NSString *msgTxt = self.messageTextField.text;
        
        // Send message to the room
        [[[MatrixHandler sharedHandler] mxSession] postTextMessage:self.roomId text:msgTxt success:^(NSString *event_id) {
            // Create a temporary event to displayed outgoing message
            MXEvent *mxEvent = [[MXEvent alloc] init];
            mxEvent.room_id = self.roomId;
            mxEvent.event_id = event_id;
            mxEvent.eventType = MXEventTypeRoomMessage;
            mxEvent.type = kMXEventTypeStringRoomMessage;
            mxEvent.content = @{@"msgtype":@"m.text", @"body":msgTxt};
            mxEvent.user_id = [MatrixHandler sharedHandler].userId;
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count inSection:0];
            [messages addObject:mxEvent];
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
            [self scrollToBottomAnimated:YES];
        } failure:^(NSError *error) {
            NSLog(@"Failed to send message (%@): %@", self.messageTextField.text, error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
        
        self.messageTextField.text = nil;
        // disable send button
        [self onTextFieldChange:nil];
    } else if (sender == _optionBtn) {
        [self dismissKeyboard];
        //TODO: display option menu (Attachments...)
    }
}
@end
