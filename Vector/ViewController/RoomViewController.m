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

#import "RoomDataSource.h"

#import "AppDelegate.h"
#import "RageShakeManager.h"

#import "RoomInputToolbarView.h"

#import "RoomActivitiesView.h"

#import "RoomTitleViewWithTopic.h"

#import "RoomParticipantsViewController.h"

#import "SegmentedViewController.h"
#import "RoomSettingsViewController.h"

#import "RoomIncomingTextMsgBubbleCell.h"
#import "RoomIncomingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomIncomingAttachmentBubbleCell.h"
#import "RoomIncomingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingAttachmentWithPaginationTitleBubbleCell.h"

#import "RoomOutgoingTextMsgBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomOutgoingAttachmentBubbleCell.h"
#import "RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingAttachmentWithPaginationTitleBubbleCell.h"

#import "MXKRoomBubbleTableViewCell+Vector.h"

#import "AvatarGenerator.h"

@interface RoomViewController ()
{
    // The customized room data source for Vector
    RoomDataSource *customizedRoomDataSource;
    
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
    
    // Register first customized cell view classes used to render bubbles
    [self.bubblesTableView registerClass:RoomIncomingTextMsgBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    // Set room title view
    [self setRoomTitleViewClass:RoomTitleViewWithTopic.class];
    
    // Replace the default input toolbar view.
    // Note: this operation will force the layout of subviews. That is why cell view classes must be registered before.
    [self setRoomInputToolbarViewClass:RoomInputToolbarView.class];
    [self roomInputToolbarView:self.inputToolbarView heightDidChanged:((RoomInputToolbarView*)self.inputToolbarView).mainToolbarMinHeightConstraint.constant completion:nil];
    
    // Set user picture in input toolbar
    MXKImageView *userPictureView = ((RoomInputToolbarView*)self.inputToolbarView).pictureView;
    if (userPictureView)
    {
        UIImage *preview = [AvatarGenerator generateRoomMemberAvatar:self.mainSession.myUser.userId displayName:self.mainSession.myUser.displayname];
        NSString *avatarThumbURL = nil;
        if (self.mainSession.myUser.avatarUrl)
        {
            // Suppose this url is a matrix content uri, we use SDK to get the well adapted thumbnail from server
            avatarThumbURL = [self.mainSession.matrixRestClient urlOfContentThumbnail:self.mainSession.myUser.avatarUrl toFitViewSize:userPictureView.frame.size withMethod:MXThumbnailingMethodCrop];
        }
        userPictureView.enableInMemoryCache = YES;
        [userPictureView setImageURL:avatarThumbURL withType:nil andImageOrientation:UIImageOrientationUp previewImage:preview];
        [userPictureView.layer setCornerRadius:userPictureView.frame.size.width / 2];
        userPictureView.clipsToBounds = YES;
    }
    
    // set extra area
    [self setRoomActivitiesViewClass:RoomActivitiesView.class];
    
    // Set rageShake handler
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.navigationItem.rightBarButtonItem.target = self;
    self.navigationItem.rightBarButtonItem.action = @selector(onButtonPressed:);
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // Localize strings here
    
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
    
    [self removeTypingNotificationsListener];
    
    if (customizedRoomDataSource)
    {
        // Remove select event id
        customizedRoomDataSource.selectedEventId = nil;
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
    
    // Store ref on customized room data source
    if ([dataSource isKindOfClass:RoomDataSource.class])
    {
        customizedRoomDataSource = (RoomDataSource*)dataSource;
    }
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
    
    if (customizedRoomDataSource)
    {
        customizedRoomDataSource.selectedEventId = nil;
        customizedRoomDataSource = nil;
    }
    
    [super destroy];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    Class cellViewClass = nil;
    
    // Sanity check
    if ([cellData conformsToProtocol:@protocol(MXKRoomBubbleCellDataStoring)])
    {
        id<MXKRoomBubbleCellDataStoring> bubbleData = (id<MXKRoomBubbleCellDataStoring>)cellData;
        
        // Select the suitable table view cell class
        if (bubbleData.isIncoming)
        {
            if (bubbleData.isAttachmentWithThumbnail)
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    cellViewClass = RoomIncomingAttachmentWithPaginationTitleBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomIncomingAttachmentBubbleCell.class;
                }
            }
            else
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    cellViewClass = RoomIncomingTextMsgWithPaginationTitleBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomIncomingTextMsgBubbleCell.class;
                }
            }
        }
        else
        {
            // Handle here outgoing bubbles
            if (bubbleData.isAttachmentWithThumbnail)
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    cellViewClass = RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomOutgoingAttachmentBubbleCell.class;
                }
            }
            else
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    cellViewClass = RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomOutgoingTextMsgBubbleCell.class;
                }
            }
        }
    }
    
    return cellViewClass;
}

#pragma mark - MXKDataSource delegate

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    // Handle here user actions on bubbles for Vector app
    if (customizedRoomDataSource)
    {
        if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnMessageTextView] || [actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnContentView])
        {
            // Retrieve the tapped event
            MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            
            // Update display of the visible table cell view
            NSArray* cellArray = self.bubblesTableView.visibleCells;
            
            // Check whether a selection already exist or not
            if (customizedRoomDataSource.selectedEventId)
            {
                // Cancel the current selection
                for (MXKRoomBubbleTableViewCell *tableViewCell in cellArray)
                {
                    if (tableViewCell.blurred)
                    {
                        tableViewCell.blurred = NO;
                    }
                    else
                    {
                        [tableViewCell unselectComponent];
                    }
                }
                
                customizedRoomDataSource.selectedEventId = nil;
            }
            else if (tappedEvent)
            {
                // Highlight this event in displayed message
                
                // Blur all table cells, except the tapped one
                for (MXKRoomBubbleTableViewCell *tableViewCell in cellArray)
                {
                    tableViewCell.blurred = YES;
                }
                MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
                roomBubbleTableViewCell.blurred = NO;
                
                // Compute the component index if tapped event is provided
                for (NSUInteger componentIndex = 0; componentIndex < roomBubbleTableViewCell.bubbleData.bubbleComponents.count; componentIndex++)
                {
                    MXKRoomBubbleComponent *component = roomBubbleTableViewCell.bubbleData.bubbleComponents[componentIndex];
                    if ([component.event.eventId isEqualToString:tappedEvent.eventId])
                    {
                        // Report the selected event id in data source to keep this event selected in case of table reload.
                        if (customizedRoomDataSource)
                        {
                            customizedRoomDataSource.selectedEventId = tappedEvent.eventId;
                        }
                        
                        [roomBubbleTableViewCell selectComponent:componentIndex];
                        
                        break;
                    }
                }
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnOverlayContainer])
        {
            // Cancel the current event selection
            NSArray* cellArray = self.bubblesTableView.visibleCells;
            
            for (MXKRoomBubbleTableViewCell *tableViewCell in cellArray)
            {
                if (tableViewCell.blurred)
                {
                    tableViewCell.blurred = NO;
                }
                else
                {
                    [tableViewCell unselectComponent];
                }
            }
            
            customizedRoomDataSource.selectedEventId = nil;
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnEvent])
        {
            // Disable default behavior
        }
        else
        {
            // Keep default implementation for other actions
            [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
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
    
    if ([[segue identifier] isEqualToString:@"showRoomDetails"])
    {
        if ([pushedViewController isKindOfClass:[SegmentedViewController class]])
        {
            // Dismiss keyboard
            [self dismissKeyboard];
            
            SegmentedViewController* segmentedViewController = (SegmentedViewController*)pushedViewController;
            
            MXSession* session = self.roomDataSource.mxSession;
            NSString* roomid = self.roomDataSource.roomId;
            NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
            NSMutableArray* titles = [[NSMutableArray alloc] init];
            
            // members screens
            [titles addObject: NSLocalizedStringFromTable(@"room_details_people", @"Vector", nil)];
            
            RoomParticipantsViewController* participantsViewController = [[RoomParticipantsViewController alloc] init];
            participantsViewController.mxRoom = [session roomWithRoomId:roomid];
            [viewControllers addObject:participantsViewController];
            
            [titles addObject: NSLocalizedStringFromTable(@"room_details_settings", @"Vector", nil)];
            RoomSettingsViewController *settingsViewController = [RoomSettingsViewController roomSettingsViewController];
            [settingsViewController initWithSession:session andRoomId:roomid];
            [viewControllers addObject:settingsViewController];
            
            
            segmentedViewController.title = NSLocalizedStringFromTable(@"room_details_title", @"Vector", nil);
            [segmentedViewController initWithTitles:titles viewControllers:viewControllers defaultSelected:0];
            
            // to display a red navbar when the home server cannot be reached.
            [segmentedViewController addMatrixSession:session];
        }
    }
    
    // Hide back button title
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

#pragma mark - MXKRoomInputToolbarViewDelegate

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView placeCallWithVideo:(BOOL)video
{
    [self.mainSession.callManager placeCallInRoom:self.roomDataSource.roomId withVideo:video];
}

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.navigationItem.rightBarButtonItem)
    {
        // FIXME Launch messages search session
    }
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - RoomDetailsViewController management

- (BOOL)roomTitleViewShouldBeginEditing:(MXKRoomTitleView*)titleView
{
    // Instead of editing room title, we open room details view here
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self performSegueWithIdentifier:@"showRoomDetails" sender:self];
        
    });
    
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
        typingNotifListener = [self.roomDataSource.room listenToEventsOfTypes:@[kMXEventTypeStringTypingNotification] onEvent:^(MXEvent *event, MXEventDirection direction, MXRoomState *roomState) {
            
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
    for(int i = 0; i < MIN(count, 2); i++)
    {
        NSString* name = [currentTypingUsers objectAtIndex:i];
        
        MXRoomMember* member = [self.roomDataSource.room.state memberWithUserId:name];
        
        if (nil != member)
        {
            name = member.displayname;
        }
        
        // sanity check
        if (name)
        {
            [names addObject:name];
        }
    }
    
    if (0 == names.count)
    {
        // something to do ?
    }
    else if (1 == names.count)
    {
        text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_one_user_is_typing", @"Vector", nil), [names objectAtIndex:0]];
    }
    else if (2 == names.count)
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

