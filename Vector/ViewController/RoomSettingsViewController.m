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

#import "RoomSettingsViewController.h"

#import "TableViewCellWithLabelAndTextField.h"
#import "TableViewCellWithLabelAndLargeTextView.h"
#import "TableViewCellSeparator.h"

#import "RageShakeManager.h"

#import "VectorDesignValues.h"

#define ROOM_SECTION 0

#define ROOM_SECTION_NAME  0
#define ROOM_SECTION_TOPIC 1
#define ROOM_SECTION_COUNT 2

#define ROOM_TOPIC_CELL_HEIGHT 99

@interface RoomSettingsViewController ()
{
    // updated user data
    NSMutableDictionary<NSString*, id> *updatedItems;
    
    // active items
    UITextView* topicTextView;
    UITextField* nameTextField;
    
    // pending http operation
    MXHTTPOperation* pendingOperation;
}
@end

@implementation RoomSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TODO use a color panel
    // not an hard coded one.
    CGFloat item = (242.0f / 255.0);
    
    self.tableView.backgroundColor = [UIColor colorWithRed:item green:item blue:item alpha:item];
    self.tableView.separatorColor = [UIColor clearColor];
    
    // Setup `RoomSettingsViewController` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDone:)];
    doneButton.tintColor = VECTOR_GREEN_COLOR;
    
    // this viewController can be displayed
    // 1- with a "standard" push mode
    // 2- within a segmentedViewController i.e. inside another viewcontroller
    // so, we need to use the parent controller when it is required.
    UIViewController* topViewController = (self.parentViewController) ? self.parentViewController : self;
    topViewController.navigationItem.rightBarButtonItem = doneButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMXSessionStateChange:) name:kMXSessionStateDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self dismissFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionStateDidChangeNotification object:nil];
}

- (void)destroy
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (pendingOperation)
    {
        [pendingOperation cancel];
        pendingOperation = nil;
    }
    
    [super destroy];
}

#pragma mark - private

- (NSMutableDictionary*)getUpdatedItems
{
    if (!updatedItems)
    {
        updatedItems = [[NSMutableDictionary alloc] init];
    }
    
    return updatedItems;
}

- (void)dismissFirstResponder
{
    if ([topicTextView isFirstResponder])
    {
        [topicTextView resignFirstResponder];
    }
    
    if ([nameTextField isFirstResponder])
    {
        [nameTextField resignFirstResponder];
    }
}

- (void)showUpdatingSpinner
{
    // TODO : wait that we have the final behaviour
    self.view.alpha = 0.5f;
    self.view.userInteractionEnabled = NO;
}

- (void)hideUpdatingSpinner
{
    // TODO : wait that we have the final behaviour
    self.view.alpha = 1.0f;
    self.view.userInteractionEnabled = YES;
}

#pragma mark - actions

- (void)textViewDidChange:(UITextView *)textView
{
    // avoid nil pointer
    NSString* text = (textView.text) ? textView.text : @"";
    
    if (topicTextView == textView)
    {
        [[self getUpdatedItems] setObject:text forKey:@"ROOM_SECTION_TOPIC"];
    }
}

- (IBAction)onTextFieldUpdate:(UITextField*)textField
{
    // avoid nil pointer
    NSString* text = (textField.text) ? textField.text : @"";
    
    if (nameTextField == textField)
    {
        [[self getUpdatedItems] setObject:text forKey:@"ROOM_SECTION_NAME"];
    }
}

- (void)didMXSessionStateChange:(NSNotification *)notif
{
    // Check this is our Matrix session that has changed
    if (notif.object == self.session)
    {
        // refresh when the session sync is done.
        if (MXSessionStateRunning == self.session.state)
        {
            [self.tableView reloadData];
        }
    }
}

- (IBAction)onDone:(id)sender
{
    // check if there is some update
    if (mxRoomState && updatedItems && (updatedItems.count > 0))
    {
        // has a new room name
        if ([updatedItems objectForKey:@"ROOM_SECTION_NAME"])
        {
            NSString* newName = [updatedItems objectForKey:@"ROOM_SECTION_NAME"];
            
            if (![newName isEqualToString:mxRoomState.name])
            {
                [self showUpdatingSpinner];
                __weak typeof(self) weakSelf = self;
                
                pendingOperation = [mxRoom setName:newName success:^{
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    strongSelf->pendingOperation = nil;
                    [strongSelf->updatedItems removeObjectForKey:@"ROOM_SECTION_NAME"];
                    [strongSelf onDone:nil];
                    
                } failure:^(NSError *error) {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    // TODO should stop the saving ?
                    // continue the saving by now
                    strongSelf->pendingOperation = nil;
                    [strongSelf->updatedItems removeObjectForKey:@"ROOM_SECTION_NAME"];
                    [strongSelf onDone:nil];
                    
                    NSLog(@"[onDone] Rename room failed: %@", error);
                }];
                
                return;
            }
        }
        
        // has a new room topic
        if ([updatedItems objectForKey:@"ROOM_SECTION_TOPIC"])
        {
            NSString* newTopic = [updatedItems objectForKey:@"ROOM_SECTION_TOPIC"];
            
            if (![newTopic isEqualToString:mxRoomState.topic])
            {
                [self showUpdatingSpinner];
                __weak typeof(self) weakSelf = self;
                
                pendingOperation = [mxRoom setTopic:newTopic success:^{
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    strongSelf->pendingOperation = nil;
                    [strongSelf->updatedItems removeObjectForKey:@"ROOM_SECTION_TOPIC"];
                    [strongSelf onDone:nil];
                    
                } failure:^(NSError *error) {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    // TODO should stop the saving ?
                    // continue the saving by now
                    strongSelf->pendingOperation = nil;
                    [strongSelf->updatedItems removeObjectForKey:@"ROOM_SECTION_TOPIC"];
                    [strongSelf onDone:nil];
                    
                    NSLog(@"[onDone] Rename topic failed: %@", error);
                }];
                
                return;
            }
        }
    }
    
    [self hideUpdatingSpinner];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == ROOM_SECTION)
    {
        // add separators
        return ROOM_SECTION_COUNT * 2 + 1;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 33.0f;
}

- (UITableViewHeaderFooterView *)headerViewForSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = [[UITableViewHeaderFooterView alloc] initWithFrame:CGRectMake(0, 0, 10, 33)];
    
    header.backgroundColor = [UIColor redColor];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ROOM_SECTION)
    {
        NSInteger row = indexPath.row;
        
        // is a separator ?
        if ((row % 2) == 0)
        {
            return 1.0f;
        }
        
        // retrieve row as a ROOM_SECTION_XX index
        row = (row - 1) / 2;
        
        if (row == ROOM_SECTION_TOPIC)
        {
            return ROOM_TOPIC_CELL_HEIGHT;
        }
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    UITableViewCell* cell = nil;
    
    // general settings
    if (indexPath.section == ROOM_SECTION)
    {
        if ((row % 2) == 0)
        {
            UITableViewCell* sepCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellSeparator defaultReuseIdentifier]];
            
            if (!sepCell)
            {
                sepCell = [[TableViewCellSeparator alloc] init];
            }
            
            // the borders are drawn in dark grey
            sepCell.contentView.backgroundColor = ((row == 0) || (row == ROOM_SECTION_COUNT * 2)) ? [UIColor darkGrayColor] : [UIColor lightGrayColor];
            
            return sepCell;
        }
        
        // retrieve row as a ROOM_SECTION_XX index
        row = (row - 1) / 2;
        
        if (row == ROOM_SECTION_TOPIC)
        {
            TableViewCellWithLabelAndLargeTextView *roomTopicCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithLabelAndLargeTextView defaultReuseIdentifier]];
            
            if (!roomTopicCell)
            {
                roomTopicCell = [[TableViewCellWithLabelAndLargeTextView alloc] init];
                
                // define the cell height
                CGRect frame = roomTopicCell.frame;
                frame.size.height = ROOM_TOPIC_CELL_HEIGHT;
                roomTopicCell.frame = frame;
            }
            
            roomTopicCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_topic", @"Vector", nil);
            topicTextView = roomTopicCell.mxkTextView;
            
            if (updatedItems && [updatedItems objectForKey:@"ROOM_SECTION_TOPIC"])
            {
                roomTopicCell.mxkTextView.text = (NSString*)[updatedItems objectForKey:@"ROOM_SECTION_TOPIC"];
            }
            else
            {
                roomTopicCell.mxkTextView.text = mxRoomState.topic;
            }
            
            roomTopicCell.mxkTextView.delegate = self;
            
            // disable the edition if the user cannoy update it
            roomTopicCell.mxkTextView.editable = isSuperUser;
            roomTopicCell.mxkTextView.textColor = isSuperUser ? [UIColor blackColor] : [UIColor lightGrayColor];
            
            cell = roomTopicCell;
        }
        else if (row == ROOM_SECTION_NAME)
        {
            TableViewCellWithLabelAndTextField *roomNameCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithLabelAndTextField defaultReuseIdentifier]];
            
            if (!roomNameCell)
            {
                roomNameCell = [[TableViewCellWithLabelAndTextField alloc] init];
            }
            
            roomNameCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_room_name", @"Vector", nil);
            roomNameCell.mxkTextField.userInteractionEnabled = YES;
            
            if (updatedItems && [updatedItems objectForKey:@"ROOM_SECTION_NAME"])
            {
                roomNameCell.mxkTextField.text = (NSString*)[updatedItems objectForKey:@"ROOM_SECTION_NAME"];
            }
            else
            {
                roomNameCell.mxkTextField.text = mxRoomState.name;
            }
            roomNameCell.accessoryType = UITableViewCellAccessoryNone;
            
            cell = roomNameCell;
            nameTextField = roomNameCell.mxkTextField;
            
            // disable the edition if the user cannoy update it
            roomNameCell.editable = isSuperUser;
            roomNameCell.mxkTextField.textColor = isSuperUser ? [UIColor blackColor] : [UIColor lightGrayColor];
            
            
            // Add a "textFieldDidChange" notification method to the text field control.
            [roomNameCell.mxkTextField addTarget:self action:@selector(onTextFieldUpdate:) forControlEvents:UIControlEventEditingChanged];
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == aTableView)
    {
        [self dismissFirstResponder];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView)
    {
        [self dismissFirstResponder];
    }
}

@end


