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

#import "AppDelegate.h"
#import "RageShakeManager.h"

#import "RoomInputToolbarView.h"

@interface RoomViewController ()
{
    // Voip call options
    UIButton *voipVoiceCallButton;
    UIButton *voipVideoCallButton;
    UIBarButtonItem *voipVoiceCallBarButtonItem;
    UIBarButtonItem *voipVideoCallBarButtonItem;
    
    // the user taps on a member thumbnail
    MXRoomMember *selectedRoomMember;
}

@property (strong, nonatomic) MXKAlert *currentAlert;

@end

@implementation RoomViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set room title view
    [self setRoomTitleViewClass:MXKRoomTitleViewWithTopic.class];
    
    // Replace the default input toolbar view.
    [self setRoomInputToolbarViewClass:RoomInputToolbarView.class];
    
    // Set rageShake handler
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.navigationItem.rightBarButtonItem.target = self;
    self.navigationItem.rightBarButtonItem.action = @selector(onButtonPressed:);
    
    self.menuListView.layer.borderColor = [UIColor blackColor].CGColor;
    self.menuListView.layer.borderWidth = 2;
    self.menuListView.layer.cornerRadius = 20;
    // Set autoresizing flag to support device rotation
    self.menuListView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // hide action
    if (self.currentAlert)
    {
        [self.currentAlert dismiss:NO];
        self.currentAlert = nil;
    }
    
    if (self.menuListView.superview)
    {
        [self.menuListView removeFromSuperview];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.childViewControllers)
    {
        // Dispose data source defined for room member list view controller (if any)
        for (id childViewController in self.childViewControllers)
        {
            if ([childViewController isKindOfClass:[MXKRoomMemberListViewController class]])
            {
                MXKRoomMemberListViewController *viewController = (MXKRoomMemberListViewController*)childViewController;
                MXKDataSource *dataSource = [viewController dataSource];
                [viewController destroy];
                [dataSource destroy];
            }
        }
    }
    
    [super viewDidAppear:animated];
    
    if (self.roomDataSource)
    {
        // Set visible room id
        [AppDelegate theDelegate].masterTabBarController.visibleRoomId = self.roomDataSource.roomId;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Reset visible room id
    [AppDelegate theDelegate].masterTabBarController.visibleRoomId = nil;
}

#pragma mark - Override MXKRoomViewController

- (void)displayRoom:(MXKRoomDataSource *)dataSource
{
    [super displayRoom:dataSource];
}

- (void)updateViewControllerAppearanceOnRoomDataSourceState
{
    [super updateViewControllerAppearanceOnRoomDataSourceState];
}

- (BOOL)isIRCStyleCommand:(NSString*)string
{
    // Override the default behavior for `/join` command in order to open automatically the joined room
    
    if ([string hasPrefix:kCmdJoinRoom])
    {
        // Join a room
        NSString *roomAlias = [string substringFromIndex:kCmdJoinRoom.length + 1];
        // Remove white space from both ends
        roomAlias = [roomAlias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // Check
        if (roomAlias.length)
        {
            [self.mainSession joinRoom:roomAlias success:^(MXRoom *room)
             {
                 // Show the room
                 [[AppDelegate theDelegate].masterTabBarController showRoom:room.state.roomId withMatrixSession:self.mainSession];
             } failure:^(NSError *error)
             {
                 NSLog(@"[Console RoomVC] Join roomAlias (%@) failed: %@", roomAlias, error);
                 //Alert user
                 [[AppDelegate theDelegate] showErrorAsAlert:error];
             }];
        }
        else
        {
            // Display cmd usage in text input as placeholder
            self.inputToolbarView.placeholder = @"Usage: /join <room_alias>";
        }
        return YES;
    }
    return [super isIRCStyleCommand:string];
}

- (void)destroy
{
    if (self.currentAlert)
    {
        [self.currentAlert dismiss:NO];
        self.currentAlert = nil;
    }
    
    [super destroy];
}

#pragma mark - MXKDataSource delegate

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnMessageTextView])
    {
        self.roomDataSource.showBubblesDateTime = !self.roomDataSource.showBubblesDateTime;
        NSLog(@"    -> Turn %@ cells date", self.roomDataSource.showBubblesDateTime ? @"ON" : @"OFF");
    }
    else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAvatarView])
    {
        // Override default implementation in case of tap on avatar
        selectedRoomMember = [self.roomDataSource.room.state memberWithUserId:userInfo[kMXKRoomBubbleCellUserIdKey]];
        if (selectedRoomMember)
        {
            [self performSegueWithIdentifier:@"showMemberDetails" sender:self];
        }
    }
    else
    {
        // Keep default implementation for other actions
        [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [super prepareForSegue:segue sender:sender];
    
    id pushedViewController = [segue destinationViewController];
    
    if ([[segue identifier] isEqualToString:@"showMemberList"])
    {
        if ([pushedViewController isKindOfClass:[MXKRoomMemberListViewController class]])
        {
            MXKRoomMemberListViewController* membersController = (MXKRoomMemberListViewController*)pushedViewController;
            
            // Dismiss keyboard
            [self dismissKeyboard];
            
            MXKRoomMemberListDataSource *membersDataSource = [[MXKRoomMemberListDataSource alloc] initWithRoomId:self.roomDataSource.roomId andMatrixSession:self.mainSession];
            [membersDataSource finalizeInitialization];
            
            [membersController displayList:membersDataSource];
        }
    }
    else if ([[segue identifier] isEqualToString:@"showMemberDetails"])
    {
        if (selectedRoomMember)
        {
            MXKRoomMemberDetailsViewController *memberViewController = pushedViewController;
            // Set rageShake handler
            memberViewController.rageShakeManager = [RageShakeManager sharedManager];
            // Set delegate to handle start chat option
            memberViewController.delegate = [AppDelegate theDelegate];
            
            [memberViewController displayRoomMember:selectedRoomMember withMatrixRoom:self.roomDataSource.room];
            
            selectedRoomMember = nil;
        }
    }
}

#pragma mark - MXKRoomInputToolbarViewDelegate

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView isTyping:(BOOL)typing
{
    // Remove sub menu if user starts typing
    if (typing && self.menuListView.superview)
    {
        [self.menuListView removeFromSuperview];
    }
    
    [super roomInputToolbarView:toolbarView isTyping:typing];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView placeCallWithVideo:(BOOL)video
{
    [self.mainSession.callManager placeCallInRoom:self.roomDataSource.roomId withVideo:video];
}

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.navigationItem.rightBarButtonItem)
    {
        if (self.menuListView.superview)
        {
            [self.menuListView removeFromSuperview];
        }
        else
        {
            UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
            [currentWindow addSubview:self.menuListView];
            
            CGRect frame = self.menuListView.frame;
            // Align on top right corner
            CGFloat xPosition = CGRectGetWidth(currentWindow.frame) - CGRectGetWidth(frame) - 10;
            frame.origin = CGPointMake(ceil(xPosition), self.bubblesTableView.contentInset.top - 15);
            self.menuListView.frame = frame;
        }
    }
    else
    {
        if (self.menuListView.superview)
        {
            [self.menuListView removeFromSuperview];
        }
        
        if (sender == self.searchInChatButton)
        {
            // TODO
        }
        else if (sender == self.participantsButton)
        {
            [self performSegueWithIdentifier:@"showMemberList" sender:self];
        }
        else if (sender == self.settingsButton)
        {
            // TODO
        }
    }
}

@end


