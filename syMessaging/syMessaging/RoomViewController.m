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

// Table view cells
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
}

@property (weak, nonatomic) IBOutlet UINavigationItem *roomNavItem;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *controlView;
@property (weak, nonatomic) IBOutlet UIButton *optionBtn;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *controlViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) MXRoomData *mxRoomData;

@end

@implementation RoomViewController

#pragma mark - Managing the detail item

- (void)setRoomId:(NSString *)roomId {
    _roomId = roomId;
    
    // Update the view
    [self configureView];
}

- (void)configureView {
    // Update room data
    if (self.roomId) {
        self.mxRoomData = [[MatrixHandler sharedHandler].mxData getRoomData:self.roomId];
    } else {
        self.mxRoomData = nil;
    }
    
    [self.tableView reloadData];
    
    // Update room title
    self.roomNavItem.title = self.mxRoomData.displayname;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    isFirstDisplay = YES;
    
    _sendBtn.enabled = NO;
    _sendBtn.alpha = 0.5;
}

- (void)dealloc {
    _mxRoomData = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Update the view
    [self configureView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextFieldChange:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
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

- (void)scrollToBottomAnimated:(BOOL)animated {
    // Scroll table view to the bottom
    NSInteger rowNb = [self tableView:self.tableView numberOfRowsInSection:0];
    if (rowNb) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(rowNb - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowNb = 0;
    if (self.mxRoomData){
        rowNb = self.mxRoomData.messages.count;
    }
    return rowNb;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Default message cell height
    CGFloat rowHeight = 50;
    
    return rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RoomMessageCell *cell;
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    MXEvent *mxEvent = [self.mxRoomData.messages objectAtIndex:indexPath.row];
    
    if ([mxEvent.user_id isEqualToString:mxHandler.userId]) {
        cell = [aTableView dequeueReusableCellWithIdentifier:@"OutgoingMessageCell" forIndexPath:indexPath];
    } else {
        cell = [aTableView dequeueReusableCellWithIdentifier:@"IncomingMessageCell" forIndexPath:indexPath];
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
            if (self.mxRoomData.canPaginate)
            {
                [_activityIndicator startAnimating];
                
                [self.mxRoomData paginateBackMessages:20 success:^(NSArray *messages) {
                    // Update room data
                    self.mxRoomData = [[[MatrixHandler sharedHandler] mxData] getRoomData:self.roomId];
                    
                    // Refresh display
                    [self.tableView beginUpdates];
                    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:messages.count];
                    for (NSUInteger index = 0; index < messages.count; index++) {
                        [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
                    }
                    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView endUpdates];
                    
                    // Maintain the current message in visible area
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(messages.count - 1) inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                    [_activityIndicator stopAnimating];
                } failure:^(NSError *error) {
                    [_activityIndicator stopAnimating];
                    NSLog(@"Failed to paginate back: %@", error);
                    //Alert user
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                }];
            }
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
        // Send message to the room
        [[[MatrixHandler sharedHandler] mxSession] postTextMessage:self.roomId text:self.messageTextField.text success:^(NSString *event_id) {
            self.messageTextField.text = nil;
            // disable send button
            [self onTextFieldChange:nil];
            [self configureView];
        } failure:^(NSError *error) {
            NSLog(@"Failed to send message (%@): %@", self.messageTextField.text, error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    } else if (sender == _optionBtn) {
        [self dismissKeyboard];
        //TODO: display option menu (Attachments...)
    }
}
@end
