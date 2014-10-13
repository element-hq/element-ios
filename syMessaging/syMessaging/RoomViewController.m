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

@interface RoomViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *tableFooter;
@property (weak, nonatomic) IBOutlet UIButton *optionBtn;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;

@property (strong, nonatomic) MXRoomData *mxRoomData;

@end

@implementation RoomViewController

#pragma mark - Managing the detail item

- (void)setRoomId:(NSString *)roomId {
    _roomId = roomId;
    
    // Update the view.
    [self configureView];
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.roomId) {
        self.mxRoomData = [[[MatrixHandler sharedHandler] mxData] getRoomData:self.roomId];
    } else {
        self.mxRoomData = nil;
    }
    
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
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
    
    // Scroll to the bottom
    [self.tableView scrollRectToVisible:_messageTextField.frame animated:NO];
    
    // Refresh
    // TODO
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextFieldChange:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
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
    if (self.mxRoomData){
        return self.mxRoomData.messages.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"RoomMessageCell" forIndexPath:indexPath];
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    MXEvent *mxEvent = [self.mxRoomData.messages objectAtIndex:indexPath.row];
    cell.textLabel.text = [mxHandler displayTextFor:mxEvent inDetailMode:NO];
    
    if ([mxEvent.user_id isEqualToString:mxHandler.userId]) {
        cell.textLabel.textAlignment = NSTextAlignmentRight;
    } else {
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
    }
    
    return cell;
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
    [self dismissKeyboard];
    
    if (sender == _sendBtn) {
        //TODO
    } else if (sender == _optionBtn) {
        //TODO
    }
}
@end
