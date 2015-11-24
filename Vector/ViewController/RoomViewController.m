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

#import "RoomActivitiesView.h"

#import "RoomParticipantsViewController.h"

#import "RoomDetailsViewController.h"

@interface RoomViewController ()
{
    // The constraint used to animate menu list display
    NSLayoutConstraint *menuListTopConstraint;
    
    // the user taps on a member thumbnail
    MXRoomMember *selectedRoomMember;

    // List of members who are typing in the room.
    NSArray *currentTypingUsers;
    
    // Typing notifications listener.
    id typingNotifListener;
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
    [self roomInputToolbarView:self.inputToolbarView heightDidChanged:((RoomInputToolbarView*)self.inputToolbarView).mainToolbarHeightConstraint.constant completion:nil];
    
    // set extra area
    [self setRoomActivitiesViewClass:RoomActivitiesView.class];
    
    // Set rageShake handler
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.navigationItem.rightBarButtonItem.target = self;
    self.navigationItem.rightBarButtonItem.action = @selector(onButtonPressed:);
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // Localize strings
    self.searchMenuLabel.text = NSLocalizedStringFromTable(@"room_menu_search", @"Vector", nil);
    self.participantsMenuLabel.text = NSLocalizedStringFromTable(@"room_menu_participants", @"Vector", nil);
    self.favouriteMenuLabel.text = NSLocalizedStringFromTable(@"room_menu_favourite", @"Vector", nil);
    self.settingsMenuLabel.text = NSLocalizedStringFromTable(@"room_menu_settings", @"Vector", nil);
    
   // Add the menu list view outside the main view
    CGRect frame = self.menuListView.frame;
    frame.origin.y = self.topLayoutGuide.length - frame.size.height;
    self.menuListView.frame = frame;
    [self.view addSubview:self.menuListView];
    
    // Define menu list view constraints
    self.menuListView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.menuListView
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:0
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.0
                                                                       constant:0];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.menuListView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:0
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0
                                                                        constant:0];
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.menuListView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:self.menuListView.frame.size.height];
    
    menuListTopConstraint = [NSLayoutConstraint constraintWithItem:self.menuListView
                                                                   attribute:NSLayoutAttributeBottom
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.topLayoutGuide
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1.0f
                                                                    constant:0.0f];
    
    if ([NSLayoutConstraint respondsToSelector:@selector(activateConstraints:)])
    {
        [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, heightConstraint, menuListTopConstraint]];
    }
    else
    {
        [self.view addConstraint:leftConstraint];
        [self.view addConstraint:rightConstraint];
        [self.view addConstraint:menuListTopConstraint];
        [self.menuListView addConstraint:heightConstraint];
    }
    [self.view setNeedsUpdateConstraints];
    
    if (self.roomDataSource)
    {
       // this room view controller has its own typing management.
       self.roomDataSource.showTypingNotifications = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self listenTypingNotifications];
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
    
    // Hide menu list view
    menuListTopConstraint.constant = 0;
    
    [self removeTypingNotificationsListener];
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
        [AppDelegate theDelegate].visibleRoomId = self.roomDataSource.roomId;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Reset visible room id
    [AppDelegate theDelegate].visibleRoomId = nil;
}

- (void)viewDidLayoutSubviews
{
    UIEdgeInsets contentInset = self.bubblesTableView.contentInset;
    contentInset.bottom = self.bottomLayoutGuide.length;
    self.bubblesTableView.contentInset = contentInset;
}

#pragma mark - Override MXKRoomViewController

- (void)displayRoom:(MXKRoomDataSource *)dataSource
{
    [super displayRoom:dataSource];
    
    self.navigationItem.rightBarButtonItem.enabled = (dataSource != nil);
}

- (void)updateViewControllerAppearanceOnRoomDataSourceState
{
    [super updateViewControllerAppearanceOnRoomDataSourceState];
    
    self.navigationItem.rightBarButtonItem.enabled = (self.roomDataSource != nil);
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
                 [[AppDelegate theDelegate] showRoom:room.state.roomId withMatrixSession:self.mainSession];
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
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (self.currentAlert)
    {
        [self.currentAlert dismiss:NO];
        self.currentAlert = nil;
    }
    
    [super destroy];
}

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    // Hide the menu list view when keyboard if displayed
    if (keyboardHeight && menuListTopConstraint.constant != 0)
    {
        [self onButtonPressed:self.navigationItem.rightBarButtonItem];
    }
    
    super.keyboardHeight = keyboardHeight;
}

#pragma mark - MXKDataSource delegate

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    // Remove sub menu if user tap on table view
    if (menuListTopConstraint.constant != 0)
    {
        [self onButtonPressed:self.navigationItem.rightBarButtonItem];
    }
    
    if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnMessageTextView])
    {
        self.roomDataSource.showBubblesDateTime = !self.roomDataSource.showBubblesDateTime;
        NSLog(@"    -> Turn %@ cells date", self.roomDataSource.showBubblesDateTime ? @"ON" : @"OFF");
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
    
    if ([[segue identifier] isEqualToString:@"showRoomParticipants"])
    {
        if ([pushedViewController isKindOfClass:[RoomParticipantsViewController class]])
        {
            // Dismiss keyboard
            [self dismissKeyboard];
            
            RoomParticipantsViewController* participantsViewController = (RoomParticipantsViewController*)pushedViewController;
            participantsViewController.mxRoom = self.roomDataSource.room;
        }
    }
    else if ([[segue identifier] isEqualToString:@"showRoomDetails"])
    {
        if ([pushedViewController isKindOfClass:[RoomDetailsViewController class]])
        {
            // Dismiss keyboard
            [self dismissKeyboard];
            
            RoomDetailsViewController* detailsViewController = (RoomDetailsViewController*)pushedViewController;
            [detailsViewController initWithSession:self.roomDataSource.mxSession andRoomId:self.roomDataSource.roomId];
        }
    }
    
    // Hide back button title
    self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

#pragma mark - MXKRoomInputToolbarViewDelegate

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView isTyping:(BOOL)typing
{
    // Remove sub menu if user starts typing
    if (typing && menuListTopConstraint.constant != 0)
    {
        [self onButtonPressed:self.navigationItem.rightBarButtonItem];
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
        // Hide/show the menu list by updating its top constraint
        if (menuListTopConstraint.constant)
        {
            // Hide the menu
            menuListTopConstraint.constant = 0;
        }
        else
        {
            [self dismissKeyboard];
            
            // Show the menu
            menuListTopConstraint.constant = self.menuListView.frame.size.height;
        }
        
        // Refresh layout with animation
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished){
                         }];
    }
    else
    {
        // Hide menu without animation
        menuListTopConstraint.constant = 0;
        
        if (sender == self.searchMenuButton)
        {
            // TODO
        }
        else if (sender == self.participantsMenuButton)
        {
            [self performSegueWithIdentifier:@"showRoomParticipants" sender:self];
        }
        else if (sender == self.favouriteMenuButton)
        {
            // TODO
        }
        else if (sender == self.settingsMenuButton)
        {
            // TODO
        }
    }
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove sub menu if user tap on table view
    if (menuListTopConstraint.constant != 0)
    {
        [self onButtonPressed:self.navigationItem.rightBarButtonItem];
    }
    
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - RoomDetailsViewController management

- (BOOL)roomTitleViewShouldBeginEditing:(MXKRoomTitleView*)titleView
{
    // instead of opening a text edition
    // launch a dedicated viewcontroller.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"showRoomDetails" sender:self];
    });
    
    // cancel any requested edition
    return NO;
}

#pragma mark - typing management

- (void)removeTypingNotificationsListener
{
    if (self.roomDataSource)
    {
        // Remove the previous live listener
        if (typingNotifListener)
        {
            [self.roomDataSource.room removeListener:typingNotifListener];
            currentTypingUsers = nil;
        }
    }
}

- (void)listenTypingNotifications
{
    if (self.roomDataSource)
    {
        // Add typing notification listener
        typingNotifListener = [self.roomDataSource.room listenToEventsOfTypes:@[kMXEventTypeStringTypingNotification] onEvent:^(MXEvent *event, MXEventDirection direction, MXRoomState *roomState)
                               {
                                   
                                   // Handle only live events
                                   if (direction == MXEventDirectionForwards)
                                   {
                                       // Retrieve typing users list
                                       NSMutableArray *typingUsers = [NSMutableArray arrayWithArray:self.roomDataSource.room.typingUsers];
                                       // Remove typing info for the current user
                                       NSUInteger index = [typingUsers indexOfObject:self.mainSession.myUser.userId];
                                       if (index != NSNotFound)
                                       {
                                           [typingUsers removeObjectAtIndex:index];
                                       }
                                       // Ignore this notification if both arrays are empty
                                       if (currentTypingUsers.count || typingUsers.count)
                                       {
                                           currentTypingUsers = typingUsers;
                                           [self refreshTypingView];
                                       }
                                   }
                               }];
        
        currentTypingUsers = self.roomDataSource.room.typingUsers;
        [self refreshTypingView];
    }
}


- (void)refreshTypingView
{
    NSString* text = nil;
    NSUInteger count = currentTypingUsers.count;
    
    // get the room member names
    NSMutableArray *names = [[NSMutableArray alloc] init];
    
    // keeps the only the first two users
    // 
    for(int i = 0; i < MIN(count, 2); i++) {
        NSString* name = [currentTypingUsers objectAtIndex:i];
        
        MXRoomMember* member = [self.roomDataSource.room.state memberWithUserId:name];
        
        if (nil != member)
        {
            name = member.displayname;
        }
        
        [names addObject:name];
    }
    
    
    if (0 == count)
    {
        // something to do ?
    }
    else if (1 == count)
    {
        text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_one_user_is_typing", @"Vector", nil), [names objectAtIndex:0]];
    }
    else if (2 == count)
    {
        text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_two_users_are_typing", @"Vector", nil), [names objectAtIndex:0], [names objectAtIndex:1]];
    }
    else
    {
        text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_many_users_are_typing", @"Vector", nil), [names objectAtIndex:0], [names objectAtIndex:1]];
    }
    
    if (self.activitiesView)
    {
        [((RoomActivitiesView*) self.activitiesView) updateTypingMessage:text];
    }
}

@end



