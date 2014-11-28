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

#import <MediaPlayer/MediaPlayer.h>

#import "RoomViewController.h"
#import "RoomMessage.h"
#import "RoomMessageTableCell.h"
#import "RoomMemberTableCell.h"

#import "MatrixHandler.h"
#import "AppDelegate.h"
#import "AppSettings.h"

#import "MediaManager.h"

#define UPLOAD_FILE_SIZE 5000000

#define ROOM_MESSAGE_CELL_DEFAULT_HEIGHT 50
#define ROOM_MESSAGE_CELL_DEFAULT_TEXTVIEW_TOP_CONST 10
#define ROOM_MESSAGE_CELL_DEFAULT_ATTACHMENTVIEW_TOP_CONST 18
#define ROOM_MESSAGE_CELL_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN -10

NSString *const kCmdChangeDisplayName = @"/nick";
NSString *const kCmdEmote = @"/me";
NSString *const kCmdJoinRoom = @"/join";
NSString *const kCmdKickUser = @"/kick";
NSString *const kCmdBanUser = @"/ban";
NSString *const kCmdUnbanUser = @"/unban";
NSString *const kCmdSetUserPowerLevel = @"/op";
NSString *const kCmdResetUserPowerLevel = @"/deop";


@interface RoomViewController () {
    BOOL forceScrollToBottomOnViewDidAppear;
    BOOL isJoinRequestInProgress;
    
    MXRoom *mxRoom;

    // Messages
    NSMutableArray *messages;
    id messagesListener;
    
    // Back pagination
    BOOL isBackPaginationInProgress;
    NSUInteger backPaginationAddedItemsNb;
    
    // Members list
    NSArray *members;
    id membersListener;
    
    // Attachment handling
    CustomImageView *highResImage;
    NSString *AVAudioSessionCategory;
    MPMoviePlayerController *videoPlayer;
    
    // Date formatter (nil if dateTime info is hidden)
    NSDateFormatter *dateFormatter;
    
    // Cache
    NSMutableArray *tmpCachedAttachments;
}

@property (weak, nonatomic) IBOutlet UINavigationItem *roomNavItem;
@property (weak, nonatomic) IBOutlet UITextField *roomNameTextField;
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
@end

@implementation RoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    forceScrollToBottomOnViewDidAppear = YES;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [button addTarget:self action:@selector(showHideRoomMembers:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    // Add tap detection on members view in order to hide members when the user taps outside members list
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideRoomMembers)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.membersView addGestureRecognizer:tap];
    
    _sendBtn.enabled = NO;
    _sendBtn.alpha = 0.5;
}

- (void)dealloc {
    // Clear temporary cached attachments (used for local echo)
    NSUInteger index = tmpCachedAttachments.count;
    NSError *error = nil;
    while (index--) {
        if (![[NSFileManager defaultManager] removeItemAtPath:[tmpCachedAttachments objectAtIndex:index] error:&error]) {
            NSLog(@"Fail to delete cached media: %@", error);
        }
    }
    tmpCachedAttachments = nil;
    
    [self hideAttachmentView];
    
    messages = nil;
    if (messagesListener) {
        [mxRoom removeListener:messagesListener];
        messagesListener = nil;
        [[AppSettings sharedSettings] removeObserver:self forKeyPath:@"hideUnsupportedMessages"];
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
    
    if (isBackPaginationInProgress || isJoinRequestInProgress) {
        // Busy - be sure that activity indicator is running
        [_activityIndicator startAnimating];
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
    
    // Reset visible room id
    [AppDelegate theDelegate].masterTabBarController.visibleRoomId = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (forceScrollToBottomOnViewDidAppear) {
        // Scroll to the bottom
        [self scrollToBottomAnimated:animated];
        forceScrollToBottomOnViewDidAppear = NO;
    }
}

#pragma mark - room ID

- (void)setRoomId:(NSString *)roomId {
    if ([self.roomId isEqualToString:roomId] == NO) {
        _roomId = roomId;
        // Reload room data here
        [self configureView];
    }
}

#pragma mark - UIGestureRecognizer delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.view == self.membersView) {
        // Compute actual frame of the displayed members list
        CGRect frame = self.membersTableView.frame;
        if (self.membersTableView.tableFooterView.frame.origin.y < frame.size.height) {
            frame.size.height = self.membersTableView.tableFooterView.frame.origin.y;
        }
        // gestureRecognizer should begin only if tap is outside members list
        return !CGRectContainsPoint(frame, [gestureRecognizer locationInView:self.membersView]);
    }
    return YES;
}

#pragma mark - Internal methods

- (void)configureView {
    // Check whether a request is in progress to join the room
    if (isJoinRequestInProgress) {
        // Busy - be sure that activity indicator is running
        [_activityIndicator startAnimating];
        return;
    }
    
    // Remove potential listener
    if (messagesListener && mxRoom) {
        [mxRoom removeListener:messagesListener];
        messagesListener = nil;
        [[AppSettings sharedSettings] removeObserver:self forKeyPath:@"hideUnsupportedMessages"];
    }
    // The whole room history is flushed here to rebuild it from the current instant (live)
    messages = nil;
    // Disable room title edition
    self.roomNameTextField.enabled = NO;
    
    // Update room data
    if (self.roomId) {
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        mxRoom = [mxHandler.mxSession room:self.roomId];
        
        // Update room title
        self.roomNameTextField.text = mxRoom.state.displayname;
        
        // Check first whether we have to join the room
        if (mxRoom.state.membership == MXMembershipInvite) {
            isJoinRequestInProgress = YES;
            [_activityIndicator startAnimating];
            [mxRoom join:^{
                [_activityIndicator stopAnimating];
                isJoinRequestInProgress = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self configureView];
                });
            } failure:^(NSError *error) {
                [_activityIndicator stopAnimating];
                isJoinRequestInProgress = NO;
                NSLog(@"Failed to join room (%@): %@", mxRoom.state.displayname, error);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];
            return;
        }
        
        // Enable room title edition
        self.roomNameTextField.enabled = YES;
        
        messages = [NSMutableArray array];
        [[AppSettings sharedSettings] addObserver:self forKeyPath:@"hideUnsupportedMessages" options:0 context:nil];
        // Register a listener to handle messages
        messagesListener = [mxRoom listenToEventsOfTypes:mxHandler.mxSession.eventsFilterForMessages onEvent:^(MXEvent *event, MXEventDirection direction, MXRoomState *roomState) {
            BOOL shouldScrollToBottom = NO;
            
            // Handle first live events
            if (direction == MXEventDirectionForwards) {
                shouldScrollToBottom = (self.messagesTableView.contentOffset.y + self.messagesTableView.frame.size.height >= self.messagesTableView.contentSize.height);
                
                NSIndexPath *indexPathForInsertedRow = nil;
                NSIndexPath *indexPathForDeletedRow = nil;
                NSMutableArray *indexPathsForUpdatedRows = [NSMutableArray array];
                BOOL isComplete = NO;
                // For outgoing message, remove the temporary event
                if ([event.userId isEqualToString:[MatrixHandler sharedHandler].userId] && messages.count) {
                    // Consider first the last message
                    RoomMessage *message = [messages lastObject];
                    NSUInteger index = messages.count - 1;
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    if ([message containsEventId:event.eventId]) {
                        if (message.messageType == RoomMessageTypeText) {
                            // Removing temporary event (local echo)
                            [message removeEvent:event.eventId];
                            // Update message with the received event
                            isComplete = [message addEvent:event withRoomState:roomState];
                            if (message.attributedTextMessage.length) {
                                [indexPathsForUpdatedRows addObject:indexPath];
                            } else {
                                [messages removeObjectAtIndex:index];
                                indexPathForDeletedRow = indexPath;
                            }
                        } else {
                            // Create a new message to handle attachment
                            message = [[RoomMessage alloc] initWithEvent:event andRoomState:roomState];
                            if (!message) {
                                // Ignore unsupported/unexpected events
                                [messages removeObjectAtIndex:index];
                                indexPathForDeletedRow = indexPath;
                            } else {
                                [messages replaceObjectAtIndex:index withObject:message];
                                [indexPathsForUpdatedRows addObject:indexPath];
                            }
                            isComplete = YES;
                        }
                    } else {
                        while (index--) {
                            message = [messages objectAtIndex:index];
                            indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                            if ([message containsEventId:event.eventId]) {
                                if (message.messageType == RoomMessageTypeText) {
                                    // Removing temporary event (local echo)
                                    [message removeEvent:event.eventId];
                                    if (message.attributedTextMessage.length) {
                                        [indexPathsForUpdatedRows addObject:indexPath];
                                    } else {
                                        [messages removeObjectAtIndex:index];
                                        indexPathForDeletedRow = indexPath;
                                    }
                                } else {
                                    // Remove the local event (a new one will be added to messages)
                                    [messages removeObjectAtIndex:index];
                                    indexPathForDeletedRow = indexPath;
                                }
                                break;
                            }
                        }
                    }
                }
                
                if (isComplete == NO) {
                    // Check whether the event may be grouped with last message
                    RoomMessage *lastMessage = [messages lastObject];
                    if (lastMessage && [lastMessage addEvent:event withRoomState:roomState]) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(messages.count - 1) inSection:0];
                        [indexPathsForUpdatedRows addObject:indexPath];
                    } else {
                        lastMessage = [[RoomMessage alloc] initWithEvent:event andRoomState:roomState];
                        if (lastMessage) {
                            indexPathForInsertedRow = [NSIndexPath indexPathForRow:messages.count inSection:0];
                            [messages addObject:lastMessage];
                        } // else ignore unsupported/unexpected events
                    }
                }
                
                // Refresh table display
                BOOL isModified = NO;
                [UIView setAnimationsEnabled:NO];
                [self.messagesTableView beginUpdates];
                if (indexPathForDeletedRow) {
                    if (indexPathForInsertedRow) {
                        [indexPathsForUpdatedRows removeAllObjects];
                        NSUInteger index = indexPathForDeletedRow.row;
                        for (; index < messages.count; index++) {
                            [indexPathsForUpdatedRows addObject:[NSIndexPath indexPathForRow:index inSection:0]];
                        }
                    } else {
                        [self.messagesTableView deleteRowsAtIndexPaths:@[indexPathForDeletedRow] withRowAnimation:UITableViewRowAnimationNone];
                        isModified = YES;
                    }
                } else if (indexPathForInsertedRow) {
                    [self.messagesTableView insertRowsAtIndexPaths:@[indexPathForInsertedRow] withRowAnimation:UITableViewRowAnimationNone];
                    isModified = YES;
                }
                if (indexPathsForUpdatedRows.count) {
                    [self.messagesTableView reloadRowsAtIndexPaths:indexPathsForUpdatedRows withRowAnimation:UITableViewRowAnimationNone];
                    isModified = YES;
                }
                [self.messagesTableView endUpdates];
                [UIView setAnimationsEnabled:YES];
                
                if (isModified) {
                    if ([[AppDelegate theDelegate].masterTabBarController.visibleRoomId isEqualToString:self.roomId] == NO) {
                        // Some new events are received for this room while it is not visible, scroll to bottom on viewDidAppear to focus on them
                        forceScrollToBottomOnViewDidAppear = YES;
                    }
                }
            } else if (isBackPaginationInProgress && direction == MXEventDirectionBackwards) {
                // Back pagination is in progress, we add an old event at the beginning of messages
                RoomMessage *firstMessage = [messages firstObject];
                if (!firstMessage || [firstMessage addEvent:event withRoomState:roomState] == NO) {
                    firstMessage = [[RoomMessage alloc] initWithEvent:event andRoomState:roomState];
                    if (firstMessage) {
                        [messages insertObject:firstMessage atIndex:0];
                        backPaginationAddedItemsNb++;
                    }
                    // Ignore unsupported/unexpected events
                }
                // Display is refreshed at the end of back pagination (see onComplete block)
            }
            
            if (shouldScrollToBottom) {
                [self scrollToBottomAnimated:YES];
            }
        }];
        
        // Trigger a back pagination by reseting first backState to get room history from live
        [mxRoom resetBackState];
        [self triggerBackPagination];
    } else {
        mxRoom = nil;
        // Update room title
        self.roomNameTextField.text = nil;
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
    // Check whether a back pagination is already in progress
    if (isBackPaginationInProgress) {
        return;
    }
    
    if (mxRoom.canPaginate) {
        [_activityIndicator startAnimating];
        isBackPaginationInProgress = YES;
        backPaginationAddedItemsNb = 0;
        
        [mxRoom paginateBackMessages:20 complete:^{
            if (backPaginationAddedItemsNb) {
                // Prepare insertion of new rows at the top of the table (compute cumulative height of added cells)
                NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:backPaginationAddedItemsNb];
                NSIndexPath *indexPath;
                CGFloat verticalOffset = 0;
                for (NSUInteger index = 0; index < backPaginationAddedItemsNb; index++) {
                    indexPath = [NSIndexPath indexPathForRow:index inSection:0];
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
                isBackPaginationInProgress = NO;
                
                // Move the current message at the middle of the visible area (dispatch this action in order to let table end its refresh)
                indexPath = [NSIndexPath indexPathForRow:(backPaginationAddedItemsNb - 1) inSection:0];
                backPaginationAddedItemsNb = 0;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.messagesTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                });
            } else {
                // Here there was no event related to the listened types
                [_activityIndicator stopAnimating];
                isBackPaginationInProgress = NO;
                // Trigger a new back pagination (if possible)
                [self triggerBackPagination];
            }
        } failure:^(NSError *error) {
            [_activityIndicator stopAnimating];
            isBackPaginationInProgress = NO;
            backPaginationAddedItemsNb = 0;
            NSLog(@"Failed to paginate back: %@", error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"hideUnsupportedMessages" isEqualToString:keyPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureView];
        });
    }
}

# pragma mark - Room members

- (void)showHideRoomMembers:(id)sender {
    // Check whether the members list is displayed
    if (members) {
        [self hideRoomMembers];
    } else {
        [self hideAttachmentView];
        [self showRoomMembers];
    }
}

- (void)updateRoomMembers {
     members = [[mxRoom.state members] sortedArrayUsingComparator:^NSComparisonResult(MXRoomMember *member1, MXRoomMember *member2) {
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
             
             // Move users who are not online or unavailable at the end (before invited users)
             if ((user1.presence == MXPresenceOnline) || (user1.presence == MXPresenceUnavailable)) {
                 if ((user2.presence != MXPresenceOnline) && (user2.presence != MXPresenceUnavailable)) {
                     return NSOrderedAscending;
                 }
             } else if ((user2.presence == MXPresenceOnline) || (user2.presence == MXPresenceUnavailable)) {
                 return NSOrderedDescending;
             } else {
                 // Here both users are neither online nor unavailable (the lastActive ago is useless)
                 // We will sort them according to their display, by keeping in front the offline users
                 if (user1.presence == MXPresenceOffline) {
                     if (user2.presence != MXPresenceOffline) {
                         return NSOrderedAscending;
                     }
                 } else if (user2.presence == MXPresenceOffline) {
                     return NSOrderedDescending;
                 }
                 return [[mxRoom.state memberName:member1.userId] compare:[mxRoom.state memberName:member2.userId] options:NSCaseInsensitiveSearch];
             }
             
             // Consider user's lastActive ago value
             if (user1.lastActiveAgo < user2.lastActiveAgo) {
                 return NSOrderedAscending;
             } else if (user1.lastActiveAgo == user2.lastActiveAgo) {
                 return [[mxRoom.state memberName:member1.userId] compare:[mxRoom.state memberName:member2.userId] options:NSCaseInsensitiveSearch];
             }
             return NSOrderedDescending;
         } else {
             // Move user without display name at the end (before invited users)
             if (member1.displayname.length) {
                 if (!member2.displayname.length) {
                     return NSOrderedAscending;
                 }
             } else if (member2.displayname.length) {
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
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    NSArray *mxMembersEvents = @[
                                 kMXEventTypeStringRoomMember,
                                 kMXEventTypeStringRoomPowerLevels,
                                 kMXEventTypeStringPresence
                                 ];
    membersListener = [mxHandler.mxSession listenToEventsOfTypes:mxMembersEvents onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
        // consider only live event
        if (direction == MXEventDirectionForwards) {
            // Check the room Id (if any)
            if (event.roomId && [event.roomId isEqualToString:self.roomId] == NO) {
                // This event does not concern the current room members
                return;
            }
            
            // Hide potential action sheet
            if (self.actionMenu) {
                [self.actionMenu dismiss:NO];
                self.actionMenu = nil;
            }
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
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        [mxHandler.mxSession removeListener:membersListener];
        membersListener = nil;
    }
    self.membersView.hidden = YES;
    members = nil;
}

# pragma mark - Attachment handling

- (void)showAttachmentView:(UIGestureRecognizer *)gestureRecognizer {
    CustomImageView *attachment = (CustomImageView*)gestureRecognizer.view;
    [self dismissKeyboard];
    
    // Retrieve attachment information
    NSDictionary *content = attachment.mediaInfo;
    NSUInteger msgtype = ((NSNumber*)content[@"msgtype"]).unsignedIntValue;
    if (msgtype == RoomMessageTypeImage) {
        NSString *url = content[@"url"];
        if (url.length) {
            highResImage = [[CustomImageView alloc] initWithFrame:self.membersView.frame];
            highResImage.contentMode = UIViewContentModeScaleAspectFit;
            highResImage.backgroundColor = [UIColor blackColor];
            highResImage.imageURL = url;
            [self.view addSubview:highResImage];
            
            // Add tap recognizer to hide attachment
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideAttachmentView)];
            [tap setNumberOfTouchesRequired:1];
            [tap setNumberOfTapsRequired:1];
            [highResImage addGestureRecognizer:tap];
            highResImage.userInteractionEnabled = YES;
        }
    } else if (msgtype == RoomMessageTypeVideo) {
        NSString *url =content[@"url"];
        if (url.length) {
            NSString *mimetype = nil;
            if (content[@"info"]) {
                mimetype = content[@"info"][@"mimetype"];
            }
            AVAudioSessionCategory = [[AVAudioSession sharedInstance] category];
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            videoPlayer = [[MPMoviePlayerController alloc] init];
            if (videoPlayer != nil) {
                videoPlayer.scalingMode = MPMovieScalingModeAspectFit;
                [self.view addSubview:videoPlayer.view];
                [videoPlayer setFullscreen:YES animated:NO];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(moviePlayerPlaybackDidFinishNotification:)
                                                             name:MPMoviePlayerPlaybackDidFinishNotification
                                                           object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(moviePlayerWillExitFullscreen:)
                                                             name:MPMoviePlayerWillExitFullscreenNotification
                                                           object:videoPlayer];
                [MediaManager prepareMedia:url mimeType:mimetype success:^(NSString *cacheFilePath) {
                    if (cacheFilePath) {
                        if (tmpCachedAttachments == nil) {
                            tmpCachedAttachments = [NSMutableArray array];
                        }
                        if ([tmpCachedAttachments indexOfObject:cacheFilePath]) {
                            [tmpCachedAttachments addObject:cacheFilePath];
                        }
                    }
                    videoPlayer.contentURL = [NSURL fileURLWithPath:cacheFilePath];
                    [videoPlayer play];
                } failure:^(NSError *error) {
                    [self hideAttachmentView];
                    //Alert user
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                }];
            }
        }
    } else if (msgtype == RoomMessageTypeAudio) {
    } else if (msgtype == RoomMessageTypeLocation) {
    }
}

- (void)hideAttachmentView {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerWillExitFullscreenNotification object:nil];
    
    if (highResImage) {
        [highResImage removeFromSuperview];
        highResImage = nil;
    }
    // Restore audio category
    if (AVAudioSessionCategory) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategory error:nil];
    }
    if (videoPlayer) {
        [videoPlayer stop];
        [videoPlayer setFullscreen:NO];
        [videoPlayer.view removeFromSuperview];
        videoPlayer = nil;
    }
}

- (void)moviePlayerWillExitFullscreen:(NSNotification*)notification {
    if (notification.object == videoPlayer) {
        [self hideAttachmentView];
    }
}

- (void)moviePlayerPlaybackDidFinishNotification:(NSNotification *)notification {
    NSDictionary *notificationUserInfo = [notification userInfo];
    NSNumber *resultValue = [notificationUserInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    MPMovieFinishReason reason = [resultValue intValue];
    
    // error cases
    if (reason == MPMovieFinishReasonPlaybackError) {
        NSError *mediaPlayerError = [notificationUserInfo objectForKey:@"error"];
        if (mediaPlayerError) {
            NSLog(@"Playback failed with error description: %@", [mediaPlayerError localizedDescription]);
            [self hideAttachmentView];
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:mediaPlayerError];
        }
    }
}

#pragma mark - Keyboard handling

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
    [_roomNameTextField resignFirstResponder];
}

#pragma mark - UITableView data source

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
    if (tableView == self.membersTableView) {
        // Use the same default height than message cell
        return ROOM_MESSAGE_CELL_DEFAULT_HEIGHT;
    }
    
    // Compute here height of message cells
    CGFloat rowHeight;
    // Get message related to this row
    RoomMessage* message = [messages objectAtIndex:indexPath.row];
    // Consider message content height
    rowHeight = message.contentSize.height;
    // Add top margin
    if (message.messageType == RoomMessageTypeText) {
        rowHeight += ROOM_MESSAGE_CELL_DEFAULT_TEXTVIEW_TOP_CONST;
    } else {
        rowHeight += ROOM_MESSAGE_CELL_DEFAULT_ATTACHMENTVIEW_TOP_CONST;
    }
    
    // Check whether the previous message has been sent by the same user.
    // The user's picture and name are displayed only for the first message.
    BOOL shouldHideSenderInfo = NO;
    if (indexPath.row) {
        RoomMessage *previousMessage = [messages objectAtIndex:indexPath.row - 1];
        if ([previousMessage.senderId isEqualToString:message.senderId]
            && [previousMessage.senderName isEqualToString:message.senderName]
            && [previousMessage.senderAvatarUrl isEqualToString:message.senderAvatarUrl]) {
            shouldHideSenderInfo = YES;
        }
    }
    
    if (shouldHideSenderInfo) {
        // Reduce top margin -> row height reduction
        rowHeight += ROOM_MESSAGE_CELL_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN;
    } else {
        // We consider a minimun cell height in order to display correctly user's picture
        if (rowHeight < ROOM_MESSAGE_CELL_DEFAULT_HEIGHT) {
            rowHeight = ROOM_MESSAGE_CELL_DEFAULT_HEIGHT;
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
    RoomMessage *message = [messages objectAtIndex:indexPath.row];
    BOOL isIncomingMsg = NO;
    
    if ([message.senderId isEqualToString:mxHandler.userId]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"OutgoingMessageCell" forIndexPath:indexPath];
        OutgoingMessageTableCell* outgoingMsgCell = (OutgoingMessageTableCell*)cell;
        // Hide potential loading wheel
        [outgoingMsgCell.activityIndicator stopAnimating];
        // Hide unsent view by default, and remove potential unsent label(s)
        outgoingMsgCell.unsentView.hidden = YES;
        for (UIView *view in outgoingMsgCell.unsentView.subviews) {
            [view removeFromSuperview];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"IncomingMessageCell" forIndexPath:indexPath];
        isIncomingMsg = YES;
    }
    
    // Restore initial settings
    cell.attachmentView.imageURL = nil; // Cancel potential attachment loading
    cell.attachmentView.hidden = YES;
    cell.playIconView.hidden = YES;
    // Remove all gesture recognizer
    while (cell.attachmentView.gestureRecognizers.count) {
        [cell.attachmentView removeGestureRecognizer:cell.attachmentView.gestureRecognizers[0]];
    }
    // Remove potential dateTime label(s)
    if (cell.dateTimeView.constraints.count) {
        if ([NSLayoutConstraint respondsToSelector:@selector(deactivateConstraints:)]) {
            [NSLayoutConstraint deactivateConstraints:cell.dateTimeView.constraints];
        } else {
            [cell.dateTimeView removeConstraints:cell.dateTimeView.constraints];
        }
        for (UIView *view in cell.dateTimeView.subviews) {
            [view removeFromSuperview];
        }
    }
    
    // Check whether the previous message has been sent by the same user.
    // The user's picture and name are displayed only for the first message.
    BOOL shouldHideSenderInfo = NO;
    if (indexPath.row) {
        RoomMessage *previousMessage = [messages objectAtIndex:indexPath.row - 1];
        if ([previousMessage.senderId isEqualToString:message.senderId]
            && [previousMessage.senderName isEqualToString:message.senderName]
            && [previousMessage.senderAvatarUrl isEqualToString:message.senderAvatarUrl]) {
            shouldHideSenderInfo = YES;
        }
    }
    
    if (shouldHideSenderInfo) {
        cell.pictureView.hidden = YES;
        cell.msgTextViewTopConstraint.constant = ROOM_MESSAGE_CELL_DEFAULT_TEXTVIEW_TOP_CONST + ROOM_MESSAGE_CELL_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN;
        cell.attachViewTopConstraint.constant = ROOM_MESSAGE_CELL_DEFAULT_ATTACHMENTVIEW_TOP_CONST + ROOM_MESSAGE_CELL_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN;
        
    } else {
        cell.pictureView.hidden = NO;
        cell.msgTextViewTopConstraint.constant = ROOM_MESSAGE_CELL_DEFAULT_TEXTVIEW_TOP_CONST;
        cell.attachViewTopConstraint.constant = ROOM_MESSAGE_CELL_DEFAULT_ATTACHMENTVIEW_TOP_CONST;
        // Handle user's picture
        cell.pictureView.placeholder = @"default-profile";
        cell.pictureView.imageURL = message.senderAvatarUrl;
        [cell.pictureView.layer setCornerRadius:cell.pictureView.frame.size.width / 2];
        cell.pictureView.clipsToBounds = YES;
    }
    
    // Update incoming/outgoing message layout
    if (isIncomingMsg) {
        IncomingMessageTableCell* incomingMsgCell = (IncomingMessageTableCell*)cell;
        // Display user's display name except if the name appears in the displayed text (see emote and membership event)
        incomingMsgCell.userNameLabel.hidden = (shouldHideSenderInfo || message.startsWithSenderName);
        incomingMsgCell.userNameLabel.text = message.senderName;
    } else {
        OutgoingMessageTableCell* outgoingMsgCell = (OutgoingMessageTableCell*)cell;
        // Adjust top constraint constant for unsent labels container
        CGFloat yPosition;
        if (message.messageType == RoomMessageTypeText) {
            outgoingMsgCell.unsentViewTopConstraint.constant = cell.msgTextViewTopConstraint.constant;
            yPosition = ROOM_MESSAGE_TEXTVIEW_MARGIN;
        } else {
            outgoingMsgCell.unsentViewTopConstraint.constant = cell.attachViewTopConstraint.constant;
            yPosition = -ROOM_MESSAGE_TEXTVIEW_MARGIN;
        }
        // Add unsent label for failed components
        for (RoomMessageComponent *component in message.components) {
            if (component.status == RoomMessageComponentStatusFailed) {
                UILabel *unsentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yPosition, outgoingMsgCell.unsentView.frame.size.width , 20)];
                unsentLabel.text = @"Unsent";
                unsentLabel.textAlignment = NSTextAlignmentCenter;
                unsentLabel.textColor = [UIColor redColor];
                unsentLabel.font = [UIFont systemFontOfSize:14];
                [outgoingMsgCell.unsentView addSubview:unsentLabel];
                outgoingMsgCell.unsentView.hidden = NO;
            }
            yPosition += component.height;
        }
    }
    CGSize contentSize = message.contentSize;
    if (message.messageType != RoomMessageTypeText) {
        cell.messageTextView.hidden = YES;
        cell.attachmentView.hidden = NO;
        // Update image view frame in order to center loading wheel (if any)
        CGRect frame = cell.attachmentView.frame;
        frame.size.width = contentSize.width;
        frame.size.height = contentSize.height;
        cell.attachmentView.frame = frame;
        // Fade attachments during upload
        if (message.isUploadInProgress) {
            cell.attachmentView.alpha = 0.5;
            [((OutgoingMessageTableCell*)cell).activityIndicator startAnimating];
            cell.attachmentView.hideActivityIndicator = YES;
        } else {
            cell.attachmentView.alpha = 1;
            cell.attachmentView.hideActivityIndicator = NO;
        }
        NSString *url = message.thumbnailURL;
        if (!url && message.messageType == RoomMessageTypeImage) {
            url = message.attachmentURL;
        }
        if (message.messageType == RoomMessageTypeVideo) {
            cell.playIconView.hidden = NO;
        }
        
        cell.attachmentView.imageURL = url;
        if (url && message.attachmentURL && message.attachmentInfo) {
            // Add tap recognizer to open attachment
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAttachmentView:)];
            [tap setNumberOfTouchesRequired:1];
            [tap setNumberOfTapsRequired:1];
            [tap setDelegate:self];
            [cell.attachmentView addGestureRecognizer:tap];
            // Store attachment content description used in showAttachmentView:
            cell.attachmentView.mediaInfo = @{@"msgtype" : [NSNumber numberWithUnsignedInt:message.messageType],
                                              @"url" : message.attachmentURL,
                                              @"info" : message.attachmentInfo};
        }
        
        // Adjust Attachment width constant
        cell.attachViewWidthConstraint.constant = contentSize.width;
    } else {
        cell.messageTextView.hidden = NO;
        cell.messageTextView.attributedText = message.attributedTextMessage;
        // Adjust textView width constraint
        cell.msgTextViewWidthConstraint.constant = contentSize.width;
    }
    
    // Handle timestamp display
    if (dateFormatter) {
        cell.dateTimeView.hidden = NO;
        CGFloat yPosition;
        // Adjust top constraint constant
        if (message.messageType == RoomMessageTypeText) {
            cell.dateTimeViewTopConstraint.constant = cell.msgTextViewTopConstraint.constant;
            yPosition = ROOM_MESSAGE_TEXTVIEW_MARGIN;
        } else {
            cell.dateTimeViewTopConstraint.constant = cell.attachViewTopConstraint.constant;
            yPosition = -ROOM_MESSAGE_TEXTVIEW_MARGIN;
        }
        // Add datetime label for each component
        for (RoomMessageComponent *component in message.components) {
            if (component.date) {
                UILabel *dateTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yPosition, cell.dateTimeView.frame.size.width , 20)];
                dateTimeLabel.text = [dateFormatter stringFromDate:component.date];
                if (isIncomingMsg) {
                    dateTimeLabel.textAlignment = NSTextAlignmentRight;
                } else {
                    dateTimeLabel.textAlignment = NSTextAlignmentLeft;
                }
                dateTimeLabel.textColor = [UIColor lightGrayColor];
                dateTimeLabel.font = [UIFont systemFontOfSize:12];
                dateTimeLabel.adjustsFontSizeToFitWidth = YES;
                dateTimeLabel.minimumScaleFactor = 0.6;
                [dateTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
                [cell.dateTimeView addSubview:dateTimeLabel];
                // Force dateTimeLabel in full width (to handle auto-layout in case of screen rotation)
                NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:dateTimeLabel
                                                                                  attribute:NSLayoutAttributeLeading
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:cell.dateTimeView
                                                                                  attribute:NSLayoutAttributeLeading
                                                                                 multiplier:1.0
                                                                                   constant:0];
                NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:dateTimeLabel
                                                                                   attribute:NSLayoutAttributeTrailing
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:cell.dateTimeView
                                                                                   attribute:NSLayoutAttributeTrailing
                                                                                  multiplier:1.0
                                                                                    constant:0];
                // Vertical constraints are required for iOS > 8
                NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:dateTimeLabel
                                                                                 attribute:NSLayoutAttributeTop
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:cell.dateTimeView
                                                                                 attribute:NSLayoutAttributeTop
                                                                                multiplier:1.0
                                                                                  constant:yPosition];
                NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:dateTimeLabel
                                                                                    attribute:NSLayoutAttributeHeight
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:nil
                                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                                   multiplier:1.0
                                                                                     constant:20];
                if ([NSLayoutConstraint respondsToSelector:@selector(activateConstraints:)]) {
                    [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, heightConstraint]];
                } else {
                    [cell.dateTimeView addConstraint:leftConstraint];
                    [cell.dateTimeView addConstraint:rightConstraint];
                    [cell.dateTimeView addConstraint:topConstraint];
                    [dateTimeLabel addConstraint:heightConstraint];
                }
            }
            yPosition += component.height;
        }
    } else {
        cell.dateTimeView.hidden = YES;
    }
    return cell;
}

#pragma mark - UITableView delegate

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
                    MXRoom *currentRoom = [[MatrixHandler sharedHandler].mxSession room:weakSelf.roomId];
                    [currentRoom leave:^{
                        // Back to recents
                        [weakSelf.navigationController popViewControllerAnimated:YES];
                    } failure:^(NSError *error) {
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
        if (scrollView.contentOffset.y < -64)
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

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == self.roomNameTextField) {
        self.roomNameTextField.borderStyle = UITextBorderStyleRoundedRect;
        self.roomNameTextField.backgroundColor = [UIColor whiteColor];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.roomNameTextField) {
        self.roomNameTextField.borderStyle = UITextBorderStyleNone;
        self.roomNameTextField.backgroundColor = [UIColor clearColor];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*) textField {
    // "Done" key has been pressed
    [textField resignFirstResponder];
    
    if (textField == self.roomNameTextField) {
        NSString *roomName = self.roomNameTextField.text;
        if ([roomName isEqualToString:mxRoom.state.name] == NO) {
            [self.activityIndicator startAnimating];
            MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
            [mxHandler.mxRestClient setRoomName:self.roomId name:roomName success:^{
                if (isBackPaginationInProgress == NO) {
                    [self.activityIndicator stopAnimating];
                }
            } failure:^(NSError *error) {
                if (isBackPaginationInProgress == NO) {
                    [self.activityIndicator stopAnimating];
                }
                // Revert change
                self.roomNameTextField.text = mxRoom.state.displayname;
                NSLog(@"Rename room failed: %@", error);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];
        }
    }
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
                        weakSelf.actionMenu = nil;
                        // Open media gallery
                        UIImagePickerController *mediaPicker = [[UIImagePickerController alloc] init];
                        mediaPicker.delegate = weakSelf;
                        mediaPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                        mediaPicker.allowsEditing = NO;
                        mediaPicker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie, nil];
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
        NSString *dateFormat = @"MMM dd HH:mm";
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]]];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDateFormat:dateFormat];
    }
    
    [self.messagesTableView reloadData];
}

#pragma mark - Post messages

- (void)postMessage:(NSDictionary*)msgContent withLocalEvent:(MXEvent*)localEvent {
    MXMessageType msgType = msgContent[@"msgtype"];
    if (msgType) {
        // Check whether a temporary event has already been added for local echo (this happens on attachments)
        RoomMessage *message = nil;
        if (localEvent) {
            // Update the temporary event with the actual msg content
            NSUInteger index = messages.count;
            while (index--) {
                message = [messages objectAtIndex:index];
                if ([message containsEventId:localEvent.eventId]) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    localEvent.content = msgContent;
                    if (message.messageType == RoomMessageTypeText) {
                        [message removeEvent:localEvent.eventId];
                        [message addEvent:localEvent withRoomState:mxRoom.state];
                        if (message.attributedTextMessage.length) {
                            // Refresh table display
                            [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        } else {
                            [messages removeObjectAtIndex:index];
                            [self.messagesTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        }
                    } else {
                        // Create a new message
                        message = [[RoomMessage alloc] initWithEvent:localEvent andRoomState:mxRoom.state];
                        if (message) {
                            // Refresh table display
                            [messages replaceObjectAtIndex:index withObject:message];
                            [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        } else {
                            [messages removeObjectAtIndex:index];
                            [self.messagesTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        }
                    }
                    break;
                }
            }
        } else {
            // Create a temporary event to displayed outgoing message (local echo)
            NSString* localEventId = [NSString stringWithFormat:@"%@%@", kLocalEchoEventIdPrefix, [[NSProcessInfo processInfo] globallyUniqueString]];
            localEvent = [[MXEvent alloc] init];
            localEvent.roomId = self.roomId;
            localEvent.eventId = localEventId;
            localEvent.eventType = MXEventTypeRoomMessage;
            localEvent.type = kMXEventTypeStringRoomMessage;
            localEvent.content = msgContent;
            localEvent.userId = [MatrixHandler sharedHandler].userId;
            localEvent.originServerTs = kMXUndefinedTimestamp;
            // Check whether this new event may be grouped with last message
            RoomMessage *lastMessage = [messages lastObject];
            if (lastMessage && [lastMessage addEvent:localEvent withRoomState:mxRoom.state]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(messages.count - 1) inSection:0];
                [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            } else {
                lastMessage = [[RoomMessage alloc] initWithEvent:localEvent andRoomState:mxRoom.state];
                if (lastMessage) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count inSection:0];
                    [messages addObject:lastMessage];
                    [self.messagesTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                } else {
                    NSLog(@"ERROR: Unable to add local event: %@", localEvent.description);
                }
            }
            [self scrollToBottomAnimated:NO];
        }
        
        // Send message to the room
        [[[MatrixHandler sharedHandler] mxRestClient] postMessageToRoom:self.roomId msgType:msgType content:localEvent.content success:^(NSString *event_id) {
            // Check whether this event has already been received from events listener
            BOOL isEventAlreadyAddedToRoom = NO;
            NSUInteger index = messages.count;
            while (index--) {
                RoomMessage *message = [messages objectAtIndex:index];
                if ([message containsEventId:event_id]) {
                    isEventAlreadyAddedToRoom = YES;
                    break;
                }
            }
            // Remove or update the temporary event
            index = messages.count;
            while (index--) {
                RoomMessage *message = [messages objectAtIndex:index];
                if ([message containsEventId:localEvent.eventId]) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    if (message.messageType == RoomMessageTypeText) {
                        [message removeEvent:localEvent.eventId];
                        if (isEventAlreadyAddedToRoom == NO) {
                            // Update the temporary event with the actual event id
                            localEvent.eventId = event_id;
                            [message addEvent:localEvent withRoomState:mxRoom.state];
                        }
                        if (message.attributedTextMessage.length) {
                            // Refresh table display
                            [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        } else {
                            [messages removeObjectAtIndex:index];
                            [self.messagesTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        }
                    } else {
                        message = nil;
                        if (isEventAlreadyAddedToRoom == NO) {
                            // Create a new message
                            localEvent.eventId = event_id;
                            message = [[RoomMessage alloc] initWithEvent:localEvent andRoomState:mxRoom.state];
                        }
                        if (message) {
                            // Refresh table display
                            [messages replaceObjectAtIndex:index withObject:message];
                            [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        } else {
                            [messages removeObjectAtIndex:index];
                            [self.messagesTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        }
                    }
                    break;
                }
            }
        } failure:^(NSError *error) {
            [self handleError:error forLocalEvent:localEvent];
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
    
    [self postMessage:@{@"msgtype":msgType, @"body":msgTxt} withLocalEvent:nil];
}

- (MXEvent*)addLocalEventForAttachedImage:(UIImage*)image {
    // Create a temporary event to displayed outgoing message (local echo)
    NSString *localEventId = [NSString stringWithFormat:@"%@%@", kLocalEchoEventIdPrefix, [[NSProcessInfo processInfo] globallyUniqueString]];
    MXEvent *mxEvent = [[MXEvent alloc] init];
    mxEvent.roomId = self.roomId;
    mxEvent.eventId = localEventId;
    mxEvent.eventType = MXEventTypeRoomMessage;
    mxEvent.type = kMXEventTypeStringRoomMessage;
    mxEvent.originServerTs = kMXUndefinedTimestamp;
    // We store temporarily the image in cache, use the localId to build temporary url
    NSString *dummyURL = [NSString stringWithFormat:@"%@%@", kMediaManagerPrefixForDummyURL, localEventId];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    NSString *cacheFilePath = [MediaManager cacheMediaData:imageData forURL:dummyURL mimeType:@"image/jpeg"];
    if (cacheFilePath) {
        if (tmpCachedAttachments == nil) {
            tmpCachedAttachments = [NSMutableArray array];
        }
        [tmpCachedAttachments addObject:cacheFilePath];
    }
    NSMutableDictionary *thumbnailInfo = [[NSMutableDictionary alloc] init];
    [thumbnailInfo setValue:@"image/jpeg" forKey:@"mimetype"];
    [thumbnailInfo setValue:[NSNumber numberWithUnsignedInteger:(NSUInteger)image.size.width] forKey:@"w"];
    [thumbnailInfo setValue:[NSNumber numberWithUnsignedInteger:(NSUInteger)image.size.height] forKey:@"h"];
    [thumbnailInfo setValue:[NSNumber numberWithUnsignedInteger:imageData.length] forKey:@"size"];
    mxEvent.content = @{@"msgtype":@"m.image", @"thumbnail_info":thumbnailInfo, @"thumbnail_url":dummyURL, @"url":dummyURL, @"info":thumbnailInfo};
    mxEvent.userId = [MatrixHandler sharedHandler].userId;
    
    // Update table sources
    RoomMessage *message = [[RoomMessage alloc] initWithEvent:mxEvent andRoomState:mxRoom.state];
    if (message) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count inSection:0];
        [messages addObject:message];
        [self.messagesTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        NSLog(@"ERROR: Unable to add local event for attachment: %@", mxEvent.description);
    }
    
    [self scrollToBottomAnimated:NO];
    return mxEvent;
}

- (void)handleError:(NSError *)error forLocalEvent:(MXEvent *)localEvent {
    NSLog(@"Post message failed: %@", error);
    if (error) {
        // Alert user
        [[AppDelegate theDelegate] showErrorAsAlert:error];
    }
    
    // Update the temporary event with this local event id
    NSUInteger index = messages.count;
    while (index--) {
        RoomMessage *message = [messages objectAtIndex:index];
        if ([message containsEventId:localEvent.eventId]) {
            NSLog(@"Posted event: %@", localEvent.description);
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            if (message.messageType == RoomMessageTypeText) {
                [message removeEvent:localEvent.eventId];
                localEvent.eventId = kFailedEventId;
                [message addEvent:localEvent withRoomState:mxRoom.state];
                if (message.attributedTextMessage.length) {
                    // Refresh table display
                    [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                } else {
                    [messages removeObjectAtIndex:index];
                    [self.messagesTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
            } else {
                // Create a new message
                localEvent.eventId = kFailedEventId;
                message = [[RoomMessage alloc] initWithEvent:localEvent andRoomState:mxRoom.state];
                if (message) {
                    // Refresh table display
                    [messages replaceObjectAtIndex:index withObject:message];
                    [self.messagesTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                } else {
                    [messages removeObjectAtIndex:index];
                    [self.messagesTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
            }
            break;
        }
    }
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
            MXEvent *localEvent = [self addLocalEventForAttachedImage:selectedImage];
            // Upload image and its thumbnail
            MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
            NSUInteger thumbnailSize = ROOM_MESSAGE_MAX_ATTACHMENTVIEW_WIDTH;
            [mxHandler.mxRestClient uploadImage:selectedImage thumbnailSize:thumbnailSize timeout:30 success:^(NSDictionary *imageMessage) {
                // Send image
                [self postMessage:imageMessage withLocalEvent:localEvent];
            } failure:^(NSError *error) {
                [self handleError:error forLocalEvent:localEvent];
            }];
        }
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL* selectedVideo = [info objectForKey:UIImagePickerControllerMediaURL];
        if (selectedVideo) {
            // Create video thumbnail
            MPMoviePlayerController* moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:selectedVideo];
            if (moviePlayerController) {
                [moviePlayerController setShouldAutoplay:NO];
                UIImage* videoThumbnail = [moviePlayerController thumbnailImageAtTime:(NSTimeInterval)1 timeOption:MPMovieTimeOptionNearestKeyFrame];
                [moviePlayerController stop];
                moviePlayerController = nil;
                
                if (videoThumbnail) {
                    // Prepare video thumbnail description
                    NSUInteger thumbnailSize = ROOM_MESSAGE_MAX_ATTACHMENTVIEW_WIDTH;
                    UIImage *thumbnail = [MediaManager resize:videoThumbnail toFitInSize:CGSizeMake(thumbnailSize, thumbnailSize)];
                    NSMutableDictionary *thumbnailInfo = [[NSMutableDictionary alloc] init];
                    [thumbnailInfo setValue:@"image/jpeg" forKey:@"mimetype"];
                    [thumbnailInfo setValue:[NSNumber numberWithUnsignedInteger:(NSUInteger)thumbnail.size.width] forKey:@"w"];
                    [thumbnailInfo setValue:[NSNumber numberWithUnsignedInteger:(NSUInteger)thumbnail.size.height] forKey:@"h"];
                    NSData *thumbnailData = UIImageJPEGRepresentation(thumbnail, 0.9);
                    [thumbnailInfo setValue:[NSNumber numberWithUnsignedInteger:thumbnailData.length] forKey:@"size"];
                    
                    // Create the local event displayed during uploading
                    MXEvent *localEvent = [self addLocalEventForAttachedImage:thumbnail];
                    
                    // Upload thumbnail
                    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
                    [mxHandler.mxRestClient uploadContent:thumbnailData mimeType:@"image/jpeg" timeout:30 success:^(NSString *url) {
                        // Prepare content of attached video
                        NSMutableDictionary *videoContent = [[NSMutableDictionary alloc] init];
                        NSMutableDictionary *videoInfo = [[NSMutableDictionary alloc] init];
                        [videoContent setValue:@"m.video" forKey:@"msgtype"];
                        [videoInfo setValue:url forKey:@"thumbnail_url"];
                        [videoInfo setValue:thumbnailInfo forKey:@"thumbnail_info"];
                        
                        // Convert video container to mp4
                        AVURLAsset* videoAsset = [AVURLAsset URLAssetWithURL:selectedVideo options:nil];
                        AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:videoAsset presetName:AVAssetExportPresetMediumQuality];
                        // Set output URL
                        NSString * outputFileName = [NSString stringWithFormat:@"%.0f.mp4",[[NSDate date] timeIntervalSince1970]];
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                        NSString *cacheRoot = [paths objectAtIndex:0];
                        NSURL *tmpVideoLocation = [NSURL fileURLWithPath:[cacheRoot stringByAppendingPathComponent:outputFileName]];
                        exportSession.outputURL = tmpVideoLocation;
                        // Check supported output file type
                        NSArray *supportedFileTypes = exportSession.supportedFileTypes;
                        if ([supportedFileTypes containsObject:AVFileTypeMPEG4]) {
                            exportSession.outputFileType = AVFileTypeMPEG4;
                            [videoInfo setValue:@"video/mp4" forKey:@"mimetype"];
                        } else {
                            NSLog(@"Unexpected case: MPEG-4 file format is not supported");
                            // we send QuickTime movie file by default
                            exportSession.outputFileType = AVFileTypeQuickTimeMovie;
                            [videoInfo setValue:@"video/quicktime" forKey:@"mimetype"];
                        }
                        // Export video file and send it
                        [exportSession exportAsynchronouslyWithCompletionHandler:^{
                            // Check status
                            if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                                AVURLAsset* asset = [AVURLAsset URLAssetWithURL:tmpVideoLocation
                                                                        options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                 [NSNumber numberWithBool:YES],
                                                                                 AVURLAssetPreferPreciseDurationAndTimingKey,
                                                                                 nil]
                                                     ];
                                
                                [videoInfo setValue:[NSNumber numberWithDouble:(1000 * CMTimeGetSeconds(asset.duration))] forKey:@"duration"];
                                NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
                                if (videoTracks.count > 0) {
                                    AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
                                    CGSize videoSize = videoTrack.naturalSize;
                                    [videoInfo setValue:[NSNumber numberWithUnsignedInteger:(NSUInteger)videoSize.width] forKey:@"w"];
                                    [videoInfo setValue:[NSNumber numberWithUnsignedInteger:(NSUInteger)videoSize.height] forKey:@"h"];
                                }
                                
                                // Upload the video
                                NSData *videoData = [NSData dataWithContentsOfURL:tmpVideoLocation];
                                [[NSFileManager defaultManager] removeItemAtPath:[tmpVideoLocation path] error:nil];
                                if (videoData) {
                                    if (videoData.length < UPLOAD_FILE_SIZE) {
                                        [videoInfo setValue:[NSNumber numberWithUnsignedInteger:videoData.length] forKey:@"size"];
                                        [mxHandler.mxRestClient uploadContent:videoData mimeType:videoInfo[@"mimetype"] timeout:30 success:^(NSString *url) {
                                            [videoContent setValue:url forKey:@"url"];
                                            [videoContent setValue:videoInfo forKey:@"info"];
                                            [videoContent setValue:@"Video" forKey:@"body"];
                                            [self postMessage:videoContent withLocalEvent:localEvent];
                                        } failure:^(NSError *error) {
                                            [self handleError:error forLocalEvent:localEvent];
                                        }];
                                    } else {
                                        NSLog(@"Video is too large");
                                        [self handleError:nil forLocalEvent:localEvent];
                                    }
                                } else {
                                    NSLog(@"Attach video failed: no data");
                                    [self handleError:nil forLocalEvent:localEvent];
                                }
                            }
                            else {
                                NSLog(@"Video export failed: %d", (int)[exportSession status]);
                                // remove tmp file (if any)
                                [[NSFileManager defaultManager] removeItemAtPath:[tmpVideoLocation path] error:nil];
                                [self handleError:nil forLocalEvent:localEvent];
                            }
                        }];
                    } failure:^(NSError *error) {
                        NSLog(@"Video thumbnail upload failed");
                        [self handleError:error forLocalEvent:localEvent];
                    }];
                }
            }
        }
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
