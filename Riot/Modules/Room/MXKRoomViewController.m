/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 Copyright 2019 The Matrix.org Foundation C.I.C

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

#define MXKROOMVIEWCONTROLLER_DEFAULT_TYPING_TIMEOUT_SEC 10
#define MXKROOMVIEWCONTROLLER_MESSAGES_TABLE_MINIMUM_HEIGHT 50

#import "MXKRoomViewController.h"

#import <MediaPlayer/MediaPlayer.h>

#import "MXKRoomBubbleTableViewCell.h"
#import "MXKSearchTableViewCell.h"
#import "MXKImageView.h"

#import "MXKRoomDataSourceManager.h"

#import "MXKRoomInputToolbarViewWithSimpleTextView.h"

#import "MXKConstants.h"

#import "MXKRoomBubbleCellData.h"

#import "MXKEncryptionKeysImportView.h"

#import "NSBundle+MatrixKit.h"
#import "MXKSlashCommands.h"
#import "MXKSwiftHeader.h"

#import "MXKPreviewViewController.h"

@interface MXKRoomViewController () <MXKPreviewViewControllerDelegate>
{
    /**
     YES once the view has appeared
     */
    BOOL hasAppearedOnce;
    
    /**
     YES if scrolling to bottom is in progress
     */
    BOOL isScrollingToBottom;
    
    /**
     Date of the last observed typing
     */
    NSDate *lastTypingDate;
    
    /**
     Local typing timout
     */
    NSTimer *typingTimer;
    
    /**
     YES when pagination is in progress.
     */
    BOOL isPaginationInProgress;
    
    /**
     The back pagination spinner view.
     */
    UIView* backPaginationActivityView;
    
    /**
     Store the height of the first bubble before back pagination.
     */
    CGFloat backPaginationSavedFirstBubbleHeight;
    
    /**
     Potential request in progress to join the selected room
     */
    MXHTTPOperation *joinRoomRequest;
    
    /**
     Text selection
     */
    NSString *selectedText;
    
    /**
     The class used to instantiate attachments viewer for image and video..
     */
    Class attachmentsViewerClass;
    
    /**
     The class used to display event details.
     */
    Class customEventDetailsViewClass;
    
    /**
     The reconnection animated view.
     */
    UIView* reconnectingView;
    
    /**
     The view to import e2e keys.
     */
    MXKEncryptionKeysImportView *importView;

    /**
     The latest server sync date
     */
    NSDate* latestServerSync;
    
    /**
     The restart the event connnection
     */
    BOOL restartConnection;
}

/**
 The eventId of the Attachment that was used to open the Attachments ViewController
 */
@property (nonatomic) NSString *openedAttachmentEventId;

/**
 The eventId of the Attachment from which the Attachments ViewController was closed
 */
@property (nonatomic) NSString *closedAttachmentEventId;

@property (nonatomic) UIImageView *openedAttachmentImageView;

/**
 Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
 */
@property (nonatomic, weak) id mxSessionWillLeaveRoomNotificationObserver;

/**
 Observe UIApplicationDidBecomeActiveNotification to refresh bubbles when app leaves the background state.
 */
@property (nonatomic, weak) id uiApplicationDidBecomeActiveNotificationObserver;

/**
 Observe UIMenuControllerDidHideMenuNotification to cancel text selection
 */
@property (nonatomic, weak) id uiMenuControllerDidHideMenuNotificationObserver;

/**
 The attachments viewer for image and video.
 */
@property (nonatomic, weak) MXKAttachmentsViewController *attachmentsViewer;

@end

@implementation MXKRoomViewController
@synthesize roomDataSource, titleView, inputToolbarView, activitiesView;

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKRoomViewController class])
                          bundle:[NSBundle bundleForClass:[MXKRoomViewController class]]];
}

+ (instancetype)roomViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKRoomViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKRoomViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Scroll to bottom the bubble history at first display
    shouldScrollToBottomOnTableRefresh = YES;
    
    // Default pagination settings
    _paginationThreshold = 300;
    _paginationLimit = 30;
    
    // Save progress text input by default
    _saveProgressTextInput = YES;
    
    // Enable auto join option by default
    _autoJoinInvitedRoom = YES;
    
    // Do not take ownership of room data source by default
    _hasRoomDataSourceOwnership = NO;
    
    // Turn on the automatic events acknowledgement.
    _eventsAcknowledgementEnabled = YES;
    
    // Do not update the read marker by default.
    _updateRoomReadMarker = NO;
    
    // Center the table content on the initial event top by default.
    _centerBubblesTableViewContentOnTheInitialEventBottom = NO;
    
    // Scroll to the bottom when a keyboard is presented
    _scrollHistoryToTheBottomOnKeyboardPresentation = YES;
    
    // Keep visible the status bar by default.
    isStatusBarHidden = NO;
    
    // By default actions button is shown in document preview
    _allowActionsInDocumentPreview = YES;
    
    // By default the duration of the composer resizing is 0.3s
    _resizeComposerAnimationDuration = 0.3;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (BuildSettings.newAppLayoutEnabled)
    {
        [self vc_setLargeTitleDisplayMode: UINavigationItemLargeTitleDisplayModeNever];
    }
    
    // Check whether the view controller has been pushed via storyboard
    if (!_bubblesTableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    // Adjust bottom constraint of the input toolbar container in order to take into account potential tabBar
    _roomInputToolbarContainerBottomConstraint.active = NO;
    _roomInputToolbarContainerBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                                              attribute:NSLayoutAttributeTop
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.roomInputToolbarContainer
                                                                              attribute:NSLayoutAttributeBottom
                                                                             multiplier:1.0f
                                                                               constant:0.0f];
    #pragma clang diagnostic pop
    
    _roomInputToolbarContainerBottomConstraint.active = YES;
    [self.view setNeedsUpdateConstraints];
    
    // Hide bubbles table by default in order to hide initial scrolling to the bottom
    _bubblesTableView.hidden = YES;
    
    // Ensure that the titleView will be scaled when it will be required
    // during a screen rotation for example.
    _roomTitleViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // Set default input toolbar view
    [self setRoomInputToolbarViewClass:MXKRoomInputToolbarViewWithSimpleTextView.class];
    
    // set the default extra
    [self setRoomActivitiesViewClass:MXKRoomActivitiesView.class];
    
    // Finalize table view configuration
    [self configureBubblesTableView];
    
    // Observe UIApplicationDidBecomeActiveNotification to refresh bubbles when app leaves the background state.
    MXWeakify(self);
    _uiApplicationDidBecomeActiveNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        if (self->roomDataSource.state == MXKDataSourceStateReady && [self->roomDataSource tableView:self->_bubblesTableView numberOfRowsInSection:0])
        {
            // Reload the full table
            self.bubbleTableViewDisplayInTransition = YES;
            [self reloadBubblesTable:YES];
            self.bubbleTableViewDisplayInTransition = NO;
        }
    }];
    
    if ([MXKAppSettings standardAppSettings].outboundGroupSessionKeyPreSharingStrategy == MXKKeyPreSharingWhenEnteringRoom)
    {
        [self shareEncryptionKeys];
    }
}

- (BOOL)prefersStatusBarHidden
{
    // Return the current status bar visibility.
    // Caution: Enable [UIViewController prefersStatusBarHidden] use at application level
    // by turning on UIViewControllerBasedStatusBarAppearance in Info.plist.
    return isStatusBarHidden;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setToolbarHidden:YES animated:NO];
    
    // Observe server sync process at room data source level too
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatrixSessionChange) name:kMXKRoomDataSourceSyncStatusChanged object:nil];

    // Observe timeline failure
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTimelineError:) name:kMXKRoomDataSourceTimelineError object:nil];

    // Observe the server sync
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncNotification) name:kMXSessionDidSyncNotification object:nil];
    
    // Be sure to display the activity indicator during back pagination
    if (isPaginationInProgress)
    {
        [self startActivityIndicator];
    }
    
    // Finalize view controller appearance
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateViewControllerAppearanceOnRoomDataSourceState];
    });
    
    // no need to reload the tableview at this stage
    // IOS is going to load it after calling this method
    // so give a breath to scroll to the bottom if required
    if (shouldScrollToBottomOnTableRefresh)
    {
        self.bubbleTableViewDisplayInTransition = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self scrollBubblesTableViewToBottomAnimated:NO];
            
            // Show bubbles table after initial scrolling to the bottom
            // Patch: We need to delay this operation to wait for the end of scrolling.
            dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                
                self->_bubblesTableView.hidden = NO;
                self.bubbleTableViewDisplayInTransition = NO;
                
            });
            
        });
    }
    else
    {
        _bubblesTableView.hidden = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Remove the rounded bottom unsafe area of the iPhone X
    _bubblesTableViewBottomConstraint.constant += self.view.safeAreaInsets.bottom;

    if (_saveProgressTextInput && roomDataSource)
    {
        // Retrieve the potential message partially typed during last room display.
        // Note: We have to wait for viewDidAppear before updating growingTextView (viewWillAppear is too early)
        inputToolbarView.attributedTextMessage = roomDataSource.partialAttributedTextMessage;
    }
    
    if (!hasAppearedOnce)
    {
        hasAppearedOnce = YES;
    }
    
    //  Mark all messages as read when the room is displayed
    [self.roomDataSource.room.summary markAllAsReadLocally];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKRoomDataSourceSyncStatusChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKRoomDataSourceTimelineError object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidSyncNotification object:nil];
    
    [self removeReconnectingView];
}

- (void)dealloc
{
    if (_mxSessionWillLeaveRoomNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_mxSessionWillLeaveRoomNotificationObserver];
    }
    
    if (_uiApplicationDidBecomeActiveNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_uiApplicationDidBecomeActiveNotificationObserver];
    }
    
    if (_uiMenuControllerDidHideMenuNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_uiMenuControllerDidHideMenuNotificationObserver];
    }
    
    [self destroy];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    isSizeTransitionInProgress = YES;
    shouldScrollToBottomOnTableRefresh = [self isBubblesTableScrollViewAtTheBottom];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(coordinator.transitionDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (!self.keyboardView)
        {
            [self updateMessageTextViewFrame];
        }
        
        // Force full table refresh to take into account cell width change.
        self.bubbleTableViewDisplayInTransition = YES;
        [self reloadBubblesTable:YES invalidateBubblesCellDataCache:YES];
        self.bubbleTableViewDisplayInTransition = NO;
        
        self->shouldScrollToBottomOnTableRefresh = NO;
        self->isSizeTransitionInProgress = NO;
    });
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
// The 2 following methods are deprecated since iOS 8
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    isSizeTransitionInProgress = YES;
    shouldScrollToBottomOnTableRefresh = [self isBubblesTableScrollViewAtTheBottom];
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    if (!self.keyboardView)
    {
        [self updateMessageTextViewFrame];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Force full table refresh to take into account cell width change.
        self.bubbleTableViewDisplayInTransition = YES;
        [self reloadBubblesTable:YES];
        self.bubbleTableViewDisplayInTransition = NO;
        
        self->shouldScrollToBottomOnTableRefresh = NO;
        self->isSizeTransitionInProgress = NO;
    });
}
#pragma clang diagnostic pop

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat bubblesTableViewBottomConst = self.roomInputToolbarContainerBottomConstraint.constant + self.roomInputToolbarContainerHeightConstraint.constant + self.roomActivitiesContainerHeightConstraint.constant;

    if (self.bubblesTableViewBottomConstraint.constant != bubblesTableViewBottomConst)
    {
        self.bubblesTableViewBottomConstraint.constant = bubblesTableViewBottomConst;
    }

}

#pragma mark - Override MXKViewController

- (void)onMatrixSessionChange
{
    [super onMatrixSessionChange];
    
    // Check dataSource state
    if (self.roomDataSource && (self.roomDataSource.state == MXKDataSourceStatePreparing || self.roomDataSource.serverSyncEventCount))
    {
        // dataSource is not ready, keep running the loading wheel
        [self startActivityIndicator];
    }
}

- (void)onKeyboardShowAnimationComplete
{
    // Check first if the first responder belongs to title view
    UIView *keyboardView = titleView.inputAccessoryView.superview;
    if (!keyboardView)
    {
        // Check whether the first responder is the input tool bar text composer
        keyboardView = inputToolbarView.inputAccessoryViewForKeyboard.superview;
    }
    
    // Report the keyboard view in order to track keyboard frame changes
    self.keyboardView = keyboardView;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    // Deduce the bottom constraint for the input toolbar view (Don't forget the potential tabBar)
    CGFloat inputToolbarViewBottomConst = keyboardHeight - self.bottomLayoutGuide.length;
    // Check whether the keyboard is over the tabBar
    if (inputToolbarViewBottomConst < 0)
    {
        inputToolbarViewBottomConst = 0;
    }
    
    // Update constraints
    _roomInputToolbarContainerBottomConstraint.constant = inputToolbarViewBottomConst;
    _bubblesTableViewBottomConstraint.constant = inputToolbarViewBottomConst + _roomInputToolbarContainerHeightConstraint.constant + _roomActivitiesContainerHeightConstraint.constant;
    
    // Remove the rounded bottom unsafe area of the iPhone X
    _bubblesTableViewBottomConstraint.constant += self.view.safeAreaInsets.bottom;

    // Invalidate the current layout to take into account the new constraints in the next update cycle.
    [self.view setNeedsLayout];
    
    // Compute the visible area (tableview + toolbar) at the end of animation
    CGFloat visibleArea = self.view.frame.size.height - _bubblesTableView.adjustedContentInset.top - keyboardHeight;
    // Deduce max height of the message text input by considering the minimum height of the table view.
    inputToolbarView.maxHeight = visibleArea - MXKROOMVIEWCONTROLLER_MESSAGES_TABLE_MINIMUM_HEIGHT;
    
    // Check conditions before scrolling the tableview content when a new keyboard is presented.
    if ((_scrollHistoryToTheBottomOnKeyboardPresentation || [self isBubblesTableScrollViewAtTheBottom]) && !super.keyboardHeight && keyboardHeight && !currentAlert)
    {
        self.bubbleTableViewDisplayInTransition = YES;
        
        // Force here the layout update to scroll correctly the table content.
        [self.view layoutIfNeeded];
        [self scrollBubblesTableViewToBottomAnimated:NO];
        
        self.bubbleTableViewDisplayInTransition = NO;
    }
    else
    {
        [self updateCurrentEventIdAtTableBottom:NO];
    }
    
    super.keyboardHeight = keyboardHeight;
}
#pragma clang diagnostic pop

- (void)destroy
{
    if (documentInteractionController)
    {
        [documentInteractionController dismissPreviewAnimated:NO];
        [documentInteractionController dismissMenuAnimated:NO];
        documentInteractionController = nil;
    }
    
    if (currentSharedAttachment)
    {
        [currentSharedAttachment onShareEnded];
        currentSharedAttachment = nil;
    }
    
    [self dismissTemporarySubViews];
    
    _bubblesTableView.dataSource = nil;
    _bubblesTableView.delegate = nil;
    _bubblesTableView = nil;
    
    if (roomDataSource.delegate == self)
    {
        roomDataSource.delegate = nil;
    }
    
    if (_hasRoomDataSourceOwnership)
    {
        // Release the room data source
        [roomDataSource destroy];
    }
    roomDataSource = nil;
    
    if (titleView)
    {
        [titleView removeFromSuperview];
        [titleView destroy];
        titleView = nil;
    }
    
    if (inputToolbarView)
    {
        [inputToolbarView removeFromSuperview];
        [inputToolbarView destroy];
        inputToolbarView = nil;
    }
    
    if (activitiesView)
    {
        [activitiesView removeFromSuperview];
        [activitiesView destroy];
        activitiesView = nil;
    }
    
    [typingTimer invalidate];
    typingTimer = nil;
    
    if (joinRoomRequest)
    {
        [joinRoomRequest cancel];
        joinRoomRequest = nil;
    }

    [super destroy];
}

#pragma mark -

- (void)configureBubblesTableView
{
    // Set up table delegates
    _bubblesTableView.delegate = self;
    _bubblesTableView.dataSource = roomDataSource; // Note: data source may be nil here, it will be set during [displayRoom:] call.
    
    // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
    MXWeakify(self);
    _mxSessionWillLeaveRoomNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionWillLeaveRoomNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        // Check whether the user will leave the current room
        if (notif.object == self.mainSession)
        {
            NSString *roomId = notif.userInfo[kMXSessionNotificationRoomIdKey];
            if (roomId && [roomId isEqualToString:self->roomDataSource.roomId])
            {
                // Update view controller appearance
                [self leaveRoomOnEvent:notif.userInfo[kMXSessionNotificationEventKey]];
            }
        }
    }];
}

- (void)updateMessageTextViewFrame
{
    if (!self.keyboardView)
    {
        // Compute the visible area (tableview + toolbar)
        CGFloat visibleArea = self.view.frame.size.height - _bubblesTableView.adjustedContentInset.top;
        // Deduce max height of the message text input by considering the minimum height of the table view.
        inputToolbarView.maxHeight = visibleArea - MXKROOMVIEWCONTROLLER_MESSAGES_TABLE_MINIMUM_HEIGHT;
    }
}

- (CGFloat)tableViewSafeAreaWidth
{
    CGFloat safeAreaInsetsWidth;
    
    // Take safe area into account
    safeAreaInsetsWidth = self.bubblesTableView.safeAreaInsets.left + self.bubblesTableView.safeAreaInsets.right;
    
    return self.bubblesTableView.frame.size.width - safeAreaInsetsWidth;
}

#pragma mark - Public API

- (void)displayRoom:(MXKRoomDataSource *)dataSource
{
    if (roomDataSource)
    {
        if (self.hasRoomDataSourceOwnership)
        {
            // Release the room data source
            [roomDataSource destroy];
        }
        else if (roomDataSource.delegate == self)
        {
            roomDataSource.delegate = nil;
        }
        roomDataSource = nil;
        
        [self removeMatrixSession:self.mainSession];
    }
    
    // Reset the current event id
    currentEventIdAtTableBottom = nil;
    
    if (dataSource)
    {
        if (dataSource.isPeeking)
        {
            // Remove the input toolbar in case of peeking.
            // We do not let the user type message in this case.
            [self setRoomInputToolbarViewClass:nil];
        }
        
        roomDataSource = dataSource;
        roomDataSource.delegate = self;
        roomDataSource.paginationLimitAroundInitialEvent = _paginationLimit;
        
        // Report the matrix session at view controller level to update UI according to session state
        [self addMatrixSession:roomDataSource.mxSession];
        
        if (_bubblesTableView)
        {
            [self dismissTemporarySubViews];
            
            // Set up table data source
            _bubblesTableView.dataSource = roomDataSource;
        }
        
        // When ready, do the initial back pagination
        if (roomDataSource.state == MXKDataSourceStateReady)
        {
            [self onRoomDataSourceReady];
        }
    }
    
    [self updateViewControllerAppearanceOnRoomDataSourceState];
}

- (void)onRoomDataSourceReady
{
    // If the user is only invited, auto-join the room if this option is enabled
    if (roomDataSource.room.summary.membership == MXMembershipInvite)
    {
        if (_autoJoinInvitedRoom)
        {
            [self joinRoom:nil];
        }
    }
    else
    {
        [self triggerInitialBackPagination];
    }
}

- (void)updateViewControllerAppearanceOnRoomDataSourceState
{
    // Update UI by considering dataSource state
    if (roomDataSource && roomDataSource.state == MXKDataSourceStateReady)
    {
        [self stopActivityIndicator];
        
        if (titleView)
        {
            titleView.mxRoom = roomDataSource.room;
            titleView.editable = YES;
            titleView.hidden = NO;
        }
        else
        {
            // set default title
            self.navigationItem.title = roomDataSource.room.summary.displayname;
        }
        
        // Show input tool bar
        inputToolbarView.hidden = NO;
    }
    else
    {
        // Update the title except if the room has just been left
        if (!_leftRoomReasonLabel)
        {
            if (roomDataSource && roomDataSource.state == MXKDataSourceStatePreparing)
            {
                if (titleView)
                {
                    titleView.mxRoom = roomDataSource.room;
                    titleView.hidden = (!titleView.mxRoom);
                }
                else
                {
                    self.navigationItem.title = roomDataSource.room.summary.displayname;
                }
            }
            else
            {
                if (titleView)
                {
                    titleView.mxRoom = nil;
                    titleView.hidden = NO;
                }
                else
                {
                    self.navigationItem.title = nil;
                }
            }
        }
        titleView.editable = NO;
        
        // Hide input tool bar
        inputToolbarView.hidden = YES;
    }
    
    // Finalize room title refresh
    [titleView refreshDisplay];
    
    if (activitiesView)
    {
        // Hide by default the activity view when no room is displayed
        activitiesView.hidden = (roomDataSource == nil);
    }
}

- (void)onTimelineError:(NSNotification *)notif
{
    if (notif.object == roomDataSource)
    {
        [self stopActivityIndicator];

        // Compute the message to display to the end user
        NSString *errorTitle;
        NSString *errorMessage;

        NSError *error = notif.userInfo[kMXKRoomDataSourceTimelineErrorErrorKey];
        if ([MXError isMXError:error])
        {
            MXError *mxError = [[MXError alloc] initWithNSError:error];
            if ([mxError.errcode isEqualToString:kMXErrCodeStringNotFound])
            {
                errorTitle = [VectorL10n roomErrorTimelineEventNotFoundTitle];
                errorMessage = [VectorL10n roomErrorTimelineEventNotFound];
            }
            else
            {
                errorTitle = [VectorL10n roomErrorCannotLoadTimeline];
                errorMessage = mxError.error;
            }
        }
        else
        {
            errorTitle = [VectorL10n roomErrorCannotLoadTimeline];
        }

        // And show it
        [currentAlert dismissViewControllerAnimated:NO completion:nil];

        __weak typeof(self) weakSelf = self;
        UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:errorTitle
                                                                            message:errorMessage
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        
        [errorAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                    
                                                    typeof(self) self = weakSelf;
                                                    self->currentAlert = nil;
                                                    
                                                }]];

        [self presentViewController:errorAlert animated:YES completion:nil];
        currentAlert = errorAlert;
    }
}

- (void)joinRoom:(void(^)(MXKRoomViewControllerJoinRoomResult result))completion
{
    if (joinRoomRequest != nil)
    {
        if (completion)
        {
            completion(MXKRoomViewControllerJoinRoomResultFailureJoinInProgress);
        }
        return;
    }
    
    UserIndicatorCancel cancelIndicator = [self.userIndicatorStore presentLoadingWithLabel:[VectorL10n joining] isInteractionBlocking:YES];
    joinRoomRequest = [roomDataSource.room join:^{
        
        self->joinRoomRequest = nil;
        cancelIndicator();
        
        [self triggerInitialBackPagination];
        
        if (completion)
        {
            completion(MXKRoomViewControllerJoinRoomResultSuccess);
        }
        
    } failure:^(NSError *error) {
        cancelIndicator();
        MXLogDebug(@"[MXKRoomVC] Failed to join room (%@)", self->roomDataSource.room.summary.displayname);
        [self processRoomJoinFailureWithError:error completion:completion];
    }];
}

- (void)joinRoomWithRoomIdOrAlias:(NSString*)roomIdOrAlias
                       viaServers:(NSArray<NSString*>*)viaServers
                       andSignUrl:(NSString*)signUrl
                       completion:(void(^)(MXKRoomViewControllerJoinRoomResult result))completion
{
    if (joinRoomRequest != nil)
    {
        if (completion)
        {
            completion(MXKRoomViewControllerJoinRoomResultFailureJoinInProgress);
        }
        
        return;
    }
    
    UserIndicatorCancel cancelIndicator = [self.userIndicatorStore presentLoadingWithLabel:[VectorL10n joining] isInteractionBlocking:YES];
    void (^success)(MXRoom *room) = ^(MXRoom *room) {
        
        self->joinRoomRequest = nil;
        cancelIndicator();
        
        MXWeakify(self);
        
        // The room is now part of the user's room
        MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mainSession];
        
        [roomDataSourceManager roomDataSourceForRoom:room.roomId create:YES onComplete:^(MXKRoomDataSource *newRoomDataSource) {
            
            MXStrongifyAndReturnIfNil(self);
            
            // And can be displayed
            [self displayRoom:newRoomDataSource];
            
            if (completion)
            {
                completion(MXKRoomViewControllerJoinRoomResultSuccess);
            }
        }];
    };
    
    void (^failure)(NSError *error) = ^(NSError *error) {
        cancelIndicator();
        MXLogDebug(@"[MXKRoomVC] Failed to join room (%@)", roomIdOrAlias);
        [self processRoomJoinFailureWithError:error completion:completion];
    };
    
    // Does the join need to be validated before?
    if (signUrl)
    {
        joinRoomRequest = [self.mainSession joinRoom:roomIdOrAlias viaServers:viaServers withSignUrl:signUrl success:success failure:failure];
    }
    else
    {
        joinRoomRequest = [self.mainSession joinRoom:roomIdOrAlias viaServers:viaServers success:success failure:failure];
    }
}

- (void)processRoomJoinFailureWithError:(NSError *)error completion:(void(^)(MXKRoomViewControllerJoinRoomResult result))completion
{
    self->joinRoomRequest = nil;
    [self stopActivityIndicator];
    
    // Show the error to the end user
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    
    // FIXME: We should hide this inside the SDK and expose it as a domain specific error
    BOOL isRoomEmpty = [msg isEqualToString:@"No known servers"];
    if (isRoomEmpty)
    {
        // minging kludge until https://matrix.org/jira/browse/SYN-678 is fixed
        // 'Error when trying to join an empty room should be more explicit'
        msg = [VectorL10n roomErrorJoinFailedEmptyRoom];
    }
    
    MXWeakify(self);
    [self->currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomErrorJoinFailedTitle]
                                                                        message:msg
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [errorAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action) {
        
        MXStrongifyAndReturnIfNil(self);
        self->currentAlert = nil;
        
        if (completion)
        {
            completion((isRoomEmpty ? MXKRoomViewControllerJoinRoomResultFailureRoomEmpty : MXKRoomViewControllerJoinRoomResultFailureGeneric));
        }
    }]];
    
    [self presentViewController:errorAlert animated:YES completion:nil];
    currentAlert = errorAlert;
}

- (void)leaveRoomOnEvent:(MXEvent*)event
{
    [self dismissTemporarySubViews];
    
    NSString *reason = nil;
    if (event)
    {
        MXKEventFormatterError error;
        reason = [roomDataSource.eventFormatter
                  stringFromEvent:event
                  withRoomState:roomDataSource.roomState
                  andLatestRoomState:nil
                  error:&error];
        if (error != MXKEventFormatterErrorNone)
        {
            reason = nil;
        }
    }
    
    if (!reason.length)
    {
        if (self.roomDataSource.room.isDirect)
        {
            reason = [VectorL10n roomLeftForDm];
        }
        else
        {
            reason = [VectorL10n roomLeft];
        }
    }
    
    
    _bubblesTableView.dataSource = nil;
    _bubblesTableView.delegate = nil;
    
    if (self.hasRoomDataSourceOwnership)
    {
        // Release the room data source
        [roomDataSource destroy];
    }
    else if (roomDataSource.delegate == self)
    {
        roomDataSource.delegate = nil;
    }
    roomDataSource = nil;
    
    // Add reason label
    UILabel *leftRoomReasonLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, self.view.frame.size.width - 20, 70)];
    leftRoomReasonLabel.numberOfLines = 0;
    leftRoomReasonLabel.text = reason;
    leftRoomReasonLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _bubblesTableView.tableHeaderView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
    [_bubblesTableView.tableHeaderView addSubview:leftRoomReasonLabel];
    [_bubblesTableView reloadData];
    
    _leftRoomReasonLabel = leftRoomReasonLabel;
    
    [self updateViewControllerAppearanceOnRoomDataSourceState];
}

- (void)setPaginationLimit:(NSUInteger)paginationLimit
{
    _paginationLimit = paginationLimit;

    // Use the same value when loading messages around the initial event
    roomDataSource.paginationLimitAroundInitialEvent = _paginationLimit;
}

- (void)setRoomTitleViewClass:(Class)roomTitleViewClass
{
    if ([self.titleView.class isEqual:roomTitleViewClass]) {
        return;
    }
    
    // Sanity check: accept only MXKRoomTitleView classes or sub-classes
    NSParameterAssert([roomTitleViewClass isSubclassOfClass:MXKRoomTitleView.class]);
    
    // Remove potential title view
    if (titleView)
    {
        [NSLayoutConstraint deactivateConstraints:titleView.constraints];
        
        [titleView dismissKeyboard];
        [titleView removeFromSuperview];
        [titleView destroy];
    }
    
    self.navigationItem.titleView = titleView = [roomTitleViewClass roomTitleView];
    titleView.delegate = self;
    
    // Define directly the navigation titleView with the custom title view instance. Do not use anymore a container.
    self.navigationItem.titleView = titleView;
    
    [self updateViewControllerAppearanceOnRoomDataSourceState];
}

- (void)setRoomInputToolbarViewClass:(Class)roomInputToolbarViewClass
{
    if (!_roomInputToolbarContainer)
    {
        MXLogDebug(@"[MXKRoomVC] Set roomInputToolbarViewClass failed: container is missing");
        return;
    }

    // Remove potential toolbar
    if (inputToolbarView)
    {
        MXLogDebug(@"[MXKRoomVC] setRoomInputToolbarViewClass: Set inputToolbarView with class %@ to nil", [self.inputToolbarView class]);
        
        [NSLayoutConstraint deactivateConstraints:inputToolbarView.constraints];
        [inputToolbarView dismissKeyboard];
        [inputToolbarView removeFromSuperview];
        [inputToolbarView destroy];
        inputToolbarView = nil;
    }
    
    if (roomDataSource && roomDataSource.isPeeking)
    {
        // Do not show the input toolbar if the displayed timeline in case of peeking.
        // We do not let the user type message in this case.
        roomInputToolbarViewClass = nil;
    }
    
    if (roomInputToolbarViewClass)
    {
        // Sanity check: accept only MXKRoomInputToolbarView classes or sub-classes
        NSParameterAssert([roomInputToolbarViewClass isSubclassOfClass:MXKRoomInputToolbarView.class]);
        
        MXLogDebug(@"[MXKRoomVC] setRoomInputToolbarViewClass: Set inputToolbarView to class %@", roomInputToolbarViewClass);
        
        id inputToolbarView = [roomInputToolbarViewClass roomInputToolbarView];
        self->inputToolbarView = inputToolbarView;
        self->inputToolbarView.delegate = self;
        
        // Add the input toolbar view and define edge constraints
        [_roomInputToolbarContainer addSubview:inputToolbarView];
        [_roomInputToolbarContainer addConstraint:[NSLayoutConstraint constraintWithItem:_roomInputToolbarContainer
                                                                               attribute:NSLayoutAttributeBottom
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:inputToolbarView
                                                                               attribute:NSLayoutAttributeBottom
                                                                              multiplier:1.0f
                                                                                constant:0.0f]];
        [_roomInputToolbarContainer addConstraint:[NSLayoutConstraint constraintWithItem:_roomInputToolbarContainer
                                                                               attribute:NSLayoutAttributeTop
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:inputToolbarView
                                                                               attribute:NSLayoutAttributeTop
                                                                              multiplier:1.0f
                                                                                constant:0.0f]];
        [_roomInputToolbarContainer addConstraint:[NSLayoutConstraint constraintWithItem:_roomInputToolbarContainer
                                                                               attribute:NSLayoutAttributeLeading
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:inputToolbarView
                                                                               attribute:NSLayoutAttributeLeading
                                                                              multiplier:1.0f
                                                                                constant:0.0f]];
        [_roomInputToolbarContainer addConstraint:[NSLayoutConstraint constraintWithItem:_roomInputToolbarContainer
                                                                               attribute:NSLayoutAttributeTrailing
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:inputToolbarView
                                                                               attribute:NSLayoutAttributeTrailing
                                                                              multiplier:1.0f
                                                                                constant:0.0f]];
    }
    
    [_roomInputToolbarContainer setNeedsUpdateConstraints];
}


- (void)setRoomActivitiesViewClass:(Class)roomActivitiesViewClass
{
    if (!_roomActivitiesContainer)
    {
        MXLogDebug(@"[MXKRoomVC] Set RoomActivitiesViewClass failed: container is missing");
        return;
    }

    // Remove potential toolbar
    if (activitiesView)
    {
        [NSLayoutConstraint deactivateConstraints:activitiesView.constraints];
        [activitiesView removeFromSuperview];
        [activitiesView destroy];
        activitiesView = nil;
    }
    
    if (roomActivitiesViewClass)
    {
        // Sanity check: accept only MXKRoomExtraInfoView classes or sub-classes
        NSParameterAssert([roomActivitiesViewClass isSubclassOfClass:MXKRoomActivitiesView.class]);
        
        activitiesView = [roomActivitiesViewClass roomActivitiesView];
        
        // Add the view and define edge constraints
        activitiesView.translatesAutoresizingMaskIntoConstraints = NO;
        [_roomActivitiesContainer addSubview:activitiesView];
        
        NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:_roomActivitiesContainer
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:activitiesView
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0f
                                                                          constant:0.0f];
        
        
        NSLayoutConstraint* leadingConstraint = [NSLayoutConstraint constraintWithItem:_roomActivitiesContainer
                                                                             attribute:NSLayoutAttributeLeading
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:activitiesView
                                                                             attribute:NSLayoutAttributeLeading
                                                                            multiplier:1.0f
                                                                              constant:0.0f];
        
        NSLayoutConstraint* widthConstraint = [NSLayoutConstraint constraintWithItem:_roomActivitiesContainer
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:activitiesView
                                                                           attribute:NSLayoutAttributeWidth
                                                                          multiplier:1.0f
                                                                            constant:0.0f];
        
        NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:_roomActivitiesContainer
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:activitiesView
                                                                            attribute:NSLayoutAttributeHeight
                                                                           multiplier:1.0f
                                                                             constant:0.0f];
        

        [NSLayoutConstraint activateConstraints:@[topConstraint, leadingConstraint, widthConstraint, heightConstraint]];
        
        // let the provide view to define a height.
        // it could have no constrainst if there is no defined xib
        _roomActivitiesContainerHeightConstraint.constant = activitiesView.height;

        // Listen to activities view change
        activitiesView.delegate = self;
    }
    else
    {
        _roomActivitiesContainerHeightConstraint.constant = 0;
    }
    
    _bubblesTableViewBottomConstraint.constant = _roomInputToolbarContainerBottomConstraint.constant + _roomInputToolbarContainerHeightConstraint.constant +_roomActivitiesContainerHeightConstraint.constant;

    [_roomActivitiesContainer setNeedsUpdateConstraints];
}

- (void)setAttachmentsViewerClass:(Class)theAttachmentsViewerClass
{
    if (theAttachmentsViewerClass)
    {
        // Sanity check: accept only MXKAttachmentsViewController classes or sub-classes
        NSParameterAssert([theAttachmentsViewerClass isSubclassOfClass:MXKAttachmentsViewController.class]);
    }
    
    attachmentsViewerClass = theAttachmentsViewerClass;
}

- (void)setEventDetailsViewClass:(Class)eventDetailsViewClass
{
    if (eventDetailsViewClass)
    {
        // Sanity check: accept only MXKEventDetailsView classes or sub-classes
        NSParameterAssert([eventDetailsViewClass isSubclassOfClass:MXKEventDetailsView.class]);
    }
    
    customEventDetailsViewClass = eventDetailsViewClass;
}

- (BOOL)sendAsIRCStyleCommandIfPossible:(NSString*)string
{
    // Check whether the provided text may be an IRC-style command
    if ([string hasPrefix:@"/"] == NO || [string hasPrefix:@"//"] == YES)
    {
        return NO;
    }
    
    // Parse command line
    NSArray *components = [string componentsSeparatedByString:@" "];
    NSString *cmd = [components objectAtIndex:0];
    NSUInteger index = 1;
    
    // TODO: display an alert with the cmd usage in case of error or unrecognized cmd.
    NSString *cmdUsage;
    
    if ([cmd isEqualToString:kMXKSlashCmdEmote])
    {
        // send message as an emote
        [self sendTextMessage:string];
    }
    else if ([string hasPrefix:kMXKSlashCmdChangeDisplayName])
    {
        // Change display name
        NSString *displayName;
        
        // Sanity check
        if (string.length > kMXKSlashCmdChangeDisplayName.length)
        {
            displayName = [string substringFromIndex:kMXKSlashCmdChangeDisplayName.length + 1];
            
            // Remove white space from both ends
            displayName = [displayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        
        if (displayName.length)
        {
            [roomDataSource.mxSession.matrixRestClient setDisplayName:displayName success:^{
                
            } failure:^(NSError *error) {
                
                MXLogDebug(@"[MXKRoomVC] Set displayName failed");
                // Notify MatrixKit user
                NSString *myUserId = self->roomDataSource.mxSession.myUser.userId;
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                
            }];
        }
        else
        {
            // Display cmd usage in text input as placeholder
            cmdUsage = @"Usage: /nick <display_name>";
        }
    }
    else if ([string hasPrefix:kMXKSlashCmdJoinRoom])
    {
        // Join a room
        NSString *roomAlias;
        
        // Sanity check
        if (string.length > kMXKSlashCmdJoinRoom.length)
        {
            roomAlias = [string substringFromIndex:kMXKSlashCmdJoinRoom.length + 1];
            
            // Remove white space from both ends
            roomAlias = [roomAlias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        
        // Check
        if (roomAlias.length)
        {
            // TODO: /join command does not support via parameters yet
            [roomDataSource.mxSession joinRoom:roomAlias viaServers:nil success:^(MXRoom *room) {
                // Do nothing by default when we succeed to join the room
            } failure:^(NSError *error) {
                
                MXLogDebug(@"[MXKRoomVC] Join roomAlias (%@) failed", roomAlias);
                // Notify MatrixKit user
                NSString *myUserId = self->roomDataSource.mxSession.myUser.userId;
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                
            }];
        }
        else
        {
            // Display cmd usage in text input as placeholder
            cmdUsage = @"Usage: /join <room_alias>";
        }
    }
    else if ([string hasPrefix:kMXKSlashCmdPartRoom])
    {
        // Leave this room or another one
        NSString *roomId;
        NSString *roomIdOrAlias;
        
        // Sanity check
        if (string.length > kMXKSlashCmdPartRoom.length)
        {
            roomIdOrAlias = [string substringFromIndex:kMXKSlashCmdPartRoom.length + 1];
            
            // Remove white space from both ends
            roomIdOrAlias = [roomIdOrAlias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }

        // Check
        if (roomIdOrAlias.length)
        {
            // Leave another room
            if ([MXTools isMatrixRoomAlias:roomIdOrAlias])
            {
                // Convert the alias to a room ID
                MXRoom *room = [roomDataSource.mxSession roomWithAlias:roomIdOrAlias];
                if (room)
                {
                    roomId = room.roomId;
                }
            }
            else if ([MXTools isMatrixRoomIdentifier:roomIdOrAlias])
            {
                roomId = roomIdOrAlias;
            }
        }
        else
        {
            // Leave the current room
            roomId = roomDataSource.roomId;
        }

        if (roomId.length)
        {
            [roomDataSource.mxSession leaveRoom:roomId success:^{

            } failure:^(NSError *error) {

                MXLogDebug(@"[MXKRoomVC] Part room_alias (%@ / %@) failed", roomIdOrAlias, roomId);
                // Notify MatrixKit user
                NSString *myUserId = self->roomDataSource.mxSession.myUser.userId;
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                
            }];
        }
        else
        {
            // Display cmd usage in text input as placeholder
            cmdUsage = @"Usage: /part [<room_alias>]";
        }
    }
    else if ([string hasPrefix:kMXKSlashCmdChangeRoomTopic])
    {
        // Change topic
        NSString *topic;
        
        // Sanity check
        if (string.length > kMXKSlashCmdChangeRoomTopic.length)
        {
            topic = [string substringFromIndex:kMXKSlashCmdChangeRoomTopic.length + 1];
            // Remove white space from both ends
            topic = [topic stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }

        if (topic.length)
        {
            [roomDataSource.room setTopic:topic success:^{
                
            } failure:^(NSError *error) {

                MXLogDebug(@"[MXKRoomVC] Set topic failed");
                // Notify MatrixKit user
                NSString *myUserId = self->roomDataSource.mxSession.myUser.userId;
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];

            }];
        }
        else
        {
            // Display cmd usage in text input as placeholder
            cmdUsage = @"Usage: /topic <topic>";
        }
    }
    else if ([string hasPrefix:kMXKSlashCmdDiscardSession])
    {
        [roomDataSource.mxSession.crypto discardOutboundGroupSessionForRoomWithRoomId:roomDataSource.roomId onComplete:^{
            MXLogDebug(@"[MXKRoomVC] Manually discarded outbound group session");
        }];
    }
    else
    {
        // Retrieve userId
        NSString *userId = nil;
        while (index < components.count)
        {
            userId = [components objectAtIndex:index++];
            if (userId.length)
            {
                // done
                break;
            }
            // reset
            userId = nil;
        }
        
        if ([cmd isEqualToString:kMXKSlashCmdInviteUser])
        {
            if (userId)
            {
                // Invite the user
                [roomDataSource.room inviteUser:userId success:^{

                } failure:^(NSError *error) {

                    MXLogDebug(@"[MXKRoomVC] Invite user (%@) failed", userId);
                    // Notify MatrixKit user
                    NSString *myUserId = self->roomDataSource.mxSession.myUser.userId;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];

                }];
            }
            else
            {
                // Display cmd usage in text input as placeholder
                cmdUsage = @"Usage: /invite <userId>";
            }
        }
        else if ([cmd isEqualToString:kMXKSlashCmdKickUser])
        {
            if (userId)
            {
                // Retrieve potential reason
                NSString *reason = nil;
                while (index < components.count)
                {
                    if (reason)
                    {
                        reason = [NSString stringWithFormat:@"%@ %@", reason, [components objectAtIndex:index++]];
                    }
                    else
                    {
                        reason = [components objectAtIndex:index++];
                    }
                }
                // Kick the user
                [roomDataSource.room kickUser:userId reason:reason success:^{
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[MXKRoomVC] Kick user (%@) failed", userId);
                    // Notify MatrixKit user
                    NSString *myUserId = self->roomDataSource.mxSession.myUser.userId;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                    
                }];
            }
            else
            {
                // Display cmd usage in text input as placeholder
                cmdUsage = @"Usage: /kick <userId> [<reason>]";
            }
        }
        else if ([cmd isEqualToString:kMXKSlashCmdBanUser])
        {
            if (userId)
            {
                // Retrieve potential reason
                NSString *reason = nil;
                while (index < components.count)
                {
                    if (reason)
                    {
                        reason = [NSString stringWithFormat:@"%@ %@", reason, [components objectAtIndex:index++]];
                    }
                    else
                    {
                        reason = [components objectAtIndex:index++];
                    }
                }
                // Ban the user
                [roomDataSource.room banUser:userId reason:reason success:^{
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[MXKRoomVC] Ban user (%@) failed", userId);
                    // Notify MatrixKit user
                    NSString *myUserId = self->roomDataSource.mxSession.myUser.userId;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                    
                }];
            }
            else
            {
                // Display cmd usage in text input as placeholder
                cmdUsage = @"Usage: /ban <userId> [<reason>]";
            }
        }
        else if ([cmd isEqualToString:kMXKSlashCmdUnbanUser])
        {
            if (userId)
            {
                // Unban the user
                [roomDataSource.room unbanUser:userId success:^{
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[MXKRoomVC] Unban user (%@) failed", userId);
                    // Notify MatrixKit user
                    NSString *myUserId = self->roomDataSource.mxSession.myUser.userId;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                    
                }];
            }
            else
            {
                // Display cmd usage in text input as placeholder
                cmdUsage = @"Usage: /unban <userId>";
            }
        }
        else if ([cmd isEqualToString:kMXKSlashCmdSetUserPowerLevel])
        {
            // Retrieve power level
            NSString *powerLevel = nil;
            while (index < components.count)
            {
                powerLevel = [components objectAtIndex:index++];
                if (powerLevel.length)
                {
                    // done
                    break;
                }
                // reset
                powerLevel = nil;
            }
            // Set power level
            if (userId && powerLevel)
            {
                // Set user power level
                [roomDataSource.room setPowerLevelOfUserWithUserID:userId powerLevel:[powerLevel integerValue] success:^{
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[MXKRoomVC] Set user power (%@) failed", userId);
                    // Notify MatrixKit user
                    NSString *myUserId = self->roomDataSource.mxSession.myUser.userId;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                    
                }];
            }
            else
            {
                // Display cmd usage in text input as placeholder
                cmdUsage = @"Usage: /op <userId> <power level>";
            }
        }
        else if ([cmd isEqualToString:kMXKSlashCmdResetUserPowerLevel])
        {
            if (userId)
            {
                // Reset user power level
                [roomDataSource.room setPowerLevelOfUserWithUserID:userId powerLevel:0 success:^{

                } failure:^(NSError *error) {

                    MXLogDebug(@"[MXKRoomVC] Reset user power (%@) failed", userId);
                    // Notify MatrixKit user
                    NSString *myUserId = self->roomDataSource.mxSession.myUser.userId;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];

                }];
            }
            else
            {
                // Display cmd usage in text input as placeholder
                cmdUsage = @"Usage: /deop <userId>";
            }
        }
        else
        {
            MXLogDebug(@"[MXKRoomVC] Unrecognised IRC-style command: %@", string);
//            cmdUsage = [NSString stringWithFormat:@"Unrecognised IRC-style command: %@", cmd];
            return NO;
        }
    }
    return YES;
}

- (void)mention:(MXRoomMember*)roomMember
{
    NSString *memberName = roomMember.displayname.length ? roomMember.displayname : roomMember.userId;

    if (inputToolbarView.textMessage.length)
    {
        [inputToolbarView pasteText:memberName];
    }
    else if ([roomMember.userId isEqualToString:self.mainSession.myUser.userId])
    {
        // Prepare emote
        inputToolbarView.textMessage = @"/me ";
    }
    else
    {
        // Bing the member
        inputToolbarView.textMessage = [NSString stringWithFormat:@"%@: ", memberName];
    }
    
    [inputToolbarView becomeFirstResponder];
}

- (void)dismissKeyboard
{
    [titleView dismissKeyboard];
    [inputToolbarView dismissKeyboard];
}

- (BOOL)isBubblesTableScrollViewAtTheBottom
{
    if (_bubblesTableView.contentSize.height)
    {
        // Check whether the most recent message is visible.
        // Compute the max vertical position visible according to contentOffset
        CGFloat maxPositionY = _bubblesTableView.contentOffset.y + (_bubblesTableView.frame.size.height - _bubblesTableView.adjustedContentInset.bottom);
        // Be a bit less retrictive, consider the table view at the bottom even if the most recent message is partially hidden
        maxPositionY += 44;
        BOOL isScrolledToBottom = (maxPositionY >= _bubblesTableView.contentSize.height);

        // Consider the table view at the bottom if a scrolling to bottom is in progress too
        return (isScrolledToBottom || isScrollingToBottom);
    }
    
    // Consider empty table view as at the bottom. Only do this after it has appeared.
    // Returning YES here before the view has appeared allows calls to scrollBubblesTableViewToBottomAnimated
    // before the view knows its final size, resulting in a position offset the second time a room is shown (#4524).
    return hasAppearedOnce;
}

- (void)scrollBubblesTableViewToBottomAnimated:(BOOL)animated
{
    if (_bubblesTableView.contentSize.height)
    {
        CGFloat visibleHeight = _bubblesTableView.frame.size.height - _bubblesTableView.adjustedContentInset.top - _bubblesTableView.adjustedContentInset.bottom;
        if (visibleHeight < _bubblesTableView.contentSize.height)
        {
            CGFloat wantedOffsetY = _bubblesTableView.contentSize.height - visibleHeight - _bubblesTableView.adjustedContentInset.top;
            CGFloat currentOffsetY = _bubblesTableView.contentOffset.y;
            if (wantedOffsetY != currentOffsetY)
            {
                isScrollingToBottom = YES;
                BOOL savedBubbleTableViewDisplayInTransition = self.isBubbleTableViewDisplayInTransition;
                self.bubbleTableViewDisplayInTransition = YES;
                [self setBubbleTableViewContentOffset:CGPointMake(0, wantedOffsetY) animated:animated];
                self.bubbleTableViewDisplayInTransition = savedBubbleTableViewDisplayInTransition;
            }
            else
            {
                // upateCurrentEventIdAtTableBottom must be called here (it is usually called by the scrollview delegate at the end of scrolling).
                [self updateCurrentEventIdAtTableBottom:YES];
            }
        }
        else
        {
            [self setBubbleTableViewContentOffset:CGPointMake(0, -_bubblesTableView.adjustedContentInset.top) animated:animated];            
        }
        
        shouldScrollToBottomOnTableRefresh = NO;
    }
}

- (void)dismissTemporarySubViews
{
    [self dismissKeyboard];
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    if (eventDetailsView)
    {
        [eventDetailsView removeFromSuperview];
        eventDetailsView = nil;
    }
    
    if (_leftRoomReasonLabel)
    {
        [_leftRoomReasonLabel removeFromSuperview];
        _leftRoomReasonLabel = nil;
        _bubblesTableView.tableHeaderView = nil;
    }
    
    // Dispose potential keyboard view
    self.keyboardView = nil;
}

- (void)setBubbleTableViewContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
    if (preventBubblesTableViewScroll)
    {
        return;
    }
    
    [self.bubblesTableView setContentOffset:contentOffset animated:animated];
}

#pragma mark - properties

- (void)setBubbleTableViewDisplayInTransition:(BOOL)bubbleTableViewDisplayInTransition
{
    if (_bubbleTableViewDisplayInTransition != bubbleTableViewDisplayInTransition)
    {
        _bubbleTableViewDisplayInTransition = bubbleTableViewDisplayInTransition;
        
        [self updateCurrentEventIdAtTableBottom:YES];
    }
}

- (void)setUpdateRoomReadMarker:(BOOL)updateRoomReadMarker
{
    if (_updateRoomReadMarker != updateRoomReadMarker)
    {
        _updateRoomReadMarker = updateRoomReadMarker;
        
        if (updateRoomReadMarker == YES)
        {
            if (currentEventIdAtTableBottom)
            {
                [self.roomDataSource.room moveReadMarkerToEventId:currentEventIdAtTableBottom];
            }
            else
            {
                // Look for the last displayed event.
                [self updateCurrentEventIdAtTableBottom:YES];
            }
        }
    }
}

#pragma mark - activity indicator

- (BOOL)canStopActivityIndicator {
    // Keep the loading wheel displayed while we are joining the room
    if (joinRoomRequest)
    {
        return NO;
    }
    
    // Check internal processes before stopping the loading wheel
    if (isPaginationInProgress || isInputToolbarProcessing)
    {
        // Keep activity indicator running
        return NO;
    }
    
    return [super canStopActivityIndicator];
}

#pragma mark - Pagination

- (void)triggerInitialBackPagination
{
    // Trigger back pagination to fill all the screen
    CGRect frame = [[UIScreen mainScreen] bounds];
    
    MXWeakify(self);
    
    isPaginationInProgress = YES;
    [self startActivityIndicator];
    [roomDataSource paginateToFillRect:frame
                             direction:MXTimelineDirectionBackwards
           withMinRequestMessagesCount:_paginationLimit
                               success:^{
        
                                   MXStrongifyAndReturnIfNil(self);

                                   // Stop spinner
                                   self->isPaginationInProgress = NO;
                                   [self stopActivityIndicator];
                                   
                                   self.bubbleTableViewDisplayInTransition = YES;

                                   // Reload table
                                   [self reloadBubblesTable:YES];

                                   if (self->roomDataSource.timeline.initialEventId)
                                   {
                                       // Center the table view to the cell that contains this event
                                       NSInteger index = [self->roomDataSource indexOfCellDataWithEventId:self->roomDataSource.timeline.initialEventId];
                                       if (index != NSNotFound)
                                       {
                                           // Let iOS put the cell at the top of the table view
                                           [self.bubblesTableView scrollToRowAtIndexPath: [NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                                           
                                           // Apply an offset to move the targeted component at the center of the screen.
                                           UITableViewCell *cell = [self->_bubblesTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
                                           
                                           CGPoint contentOffset = self->_bubblesTableView.contentOffset;
                                           CGFloat firstVisibleContentRowOffset = self->_bubblesTableView.contentOffset.y + self->_bubblesTableView.adjustedContentInset.top;
                                           CGFloat lastVisibleContentRowOffset = self->_bubblesTableView.frame.size.height - self->_bubblesTableView.adjustedContentInset.bottom;
                                           
                                           CGFloat localPositionOfEvent = 0.0;
                                           
                                           if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
                                           {
                                               MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
                                               
                                               if (self->_centerBubblesTableViewContentOnTheInitialEventBottom)
                                               {
                                                   localPositionOfEvent = [roomBubbleTableViewCell bottomPositionOfEvent:self->roomDataSource.timeline.initialEventId];
                                               }
                                               else
                                               {
                                                   localPositionOfEvent = [roomBubbleTableViewCell topPositionOfEvent:self->roomDataSource.timeline.initialEventId];
                                               }
                                           }
                                           
                                           contentOffset.y += localPositionOfEvent - (lastVisibleContentRowOffset / 2 - (cell.frame.origin.y - firstVisibleContentRowOffset));
                                           
                                           // Sanity check
                                           if (contentOffset.y + lastVisibleContentRowOffset > self->_bubblesTableView.contentSize.height)
                                           {
                                               contentOffset.y = self->_bubblesTableView.contentSize.height - lastVisibleContentRowOffset;
                                           }
                                           
                                           [self setBubbleTableViewContentOffset:contentOffset animated:NO];
                                           
                                           
                                           // Update the read receipt and potentially the read marker.
                                           [self updateCurrentEventIdAtTableBottom:YES];
                                       }
                                   }
                                   
                                   self.bubbleTableViewDisplayInTransition = NO;
                               }
                               failure:^(NSError *error) {
        
                                   MXStrongifyAndReturnIfNil(self);

                                   // Stop spinner
                                   self->isPaginationInProgress = NO;
                                   [self stopActivityIndicator];
                                   
                                   self.bubbleTableViewDisplayInTransition = YES;

                                   // Reload table
                                   [self reloadBubblesTable:YES];
                                   
                                   self.bubbleTableViewDisplayInTransition = NO;

                               }];
}

/**
 Trigger an inconspicuous pagination.
 The retrieved history is added discretely to the top or the bottom of bubbles table without change the current display.

 @param limit the maximum number of messages to retrieve.
 @param direction backwards or forwards.
 */
- (void)triggerPagination:(NSUInteger)limit direction:(MXTimelineDirection)direction
{
    // Paginate only if possible
    if (isPaginationInProgress || roomDataSource.state != MXKDataSourceStateReady || NO == [roomDataSource.timeline canPaginate:direction])
    {
        return;
    }
    
    UserIndicatorCancel cancelIndicator = [self.userIndicatorStore presentLoadingWithLabel:[VectorL10n loading] isInteractionBlocking:NO];
    
    // Store the current height of the first bubble (if any)
    backPaginationSavedFirstBubbleHeight = 0;
    if (direction == MXTimelineDirectionBackwards && [roomDataSource tableView:_bubblesTableView numberOfRowsInSection:0])
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        backPaginationSavedFirstBubbleHeight = [self tableView:_bubblesTableView heightForRowAtIndexPath:indexPath];
    }
    
    isPaginationInProgress = YES;
    
    MXWeakify(self);
    
    // Trigger pagination
    [roomDataSource paginate:limit direction:direction onlyFromStore:NO success:^(NSUInteger addedCellNumber) {
        
        MXStrongifyAndReturnIfNil(self);
        
        // We will adjust the vertical offset in order to unchange the current display (pagination should be inconspicuous)
        CGFloat verticalOffset = 0;

        if (direction == MXTimelineDirectionBackwards)
        {
            // Compute the cumulative height of the added messages
            for (NSUInteger index = 0; index < addedCellNumber; index++)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                verticalOffset += [self tableView:self->_bubblesTableView heightForRowAtIndexPath:indexPath];
            }

            // Add delta of the height of the previous first cell (if any)
            if (addedCellNumber < [self->roomDataSource tableView:self->_bubblesTableView numberOfRowsInSection:0])
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:addedCellNumber inSection:0];
                verticalOffset += ([self tableView:self->_bubblesTableView heightForRowAtIndexPath:indexPath] - self->backPaginationSavedFirstBubbleHeight);
            }

            self->_bubblesTableView.tableHeaderView = self->backPaginationActivityView = nil;
        }
        else
        {
            self->_bubblesTableView.tableFooterView = self->reconnectingView = nil;
        }

        // Trigger a full table reload. We could not only insert new cells related to pagination,
        // because some other changes may have been ignored during pagination (see[dataSource:didCellChange:]).
        self.bubbleTableViewDisplayInTransition = YES;

        // Disable temporarily scrolling and hide the scroll indicator during refresh to prevent flickering
        [self.bubblesTableView setShowsVerticalScrollIndicator:NO];
        [self.bubblesTableView setScrollEnabled:NO];

        CGPoint contentOffset = self.bubblesTableView.contentOffset;

        BOOL hasBeenScrolledToBottom = [self reloadBubblesTable:NO];

        if (direction == MXTimelineDirectionBackwards)
        {
            // Backwards pagination adds cells at the top of the tableview content.
            // Vertical content offset needs to be updated (except if the table has been scrolled to bottom)
            if ((!hasBeenScrolledToBottom && verticalOffset > 0) || direction == MXTimelineDirectionForwards)
            {
                // Adjust vertical offset in order to compensate scrolling
                contentOffset.y += verticalOffset;
                [self setBubbleTableViewContentOffset:contentOffset animated:NO];
            }
        }
        else
        {
            [self setBubbleTableViewContentOffset:contentOffset animated:NO];
        }

        // Restore scrolling and the scroll indicator
        [self.bubblesTableView setShowsVerticalScrollIndicator:YES];
        [self.bubblesTableView setScrollEnabled:YES];

        self.bubbleTableViewDisplayInTransition = NO;
        self->isPaginationInProgress = NO;

        // Force the update of the current visual position
        // Else there is a scroll jump on incoming message (see https://github.com/vector-im/vector-ios/issues/79)
        if (direction == MXTimelineDirectionBackwards)
        {
            [self updateCurrentEventIdAtTableBottom:NO];
        }
        
        if (cancelIndicator) {
            cancelIndicator();
        }

    } failure:^(NSError *error) {
        
        MXStrongifyAndReturnIfNil(self);
        
        self.bubbleTableViewDisplayInTransition = YES;
        
        // Reload table on failure because some changes may have been ignored during pagination (see[dataSource:didCellChange:])
        self->isPaginationInProgress = NO;
        self->_bubblesTableView.tableHeaderView = self->backPaginationActivityView = nil;
        
        [self reloadBubblesTable:NO];
        
        self.bubbleTableViewDisplayInTransition = NO;

        if (cancelIndicator) {
            cancelIndicator();
        }
    }];
}

- (void)triggerAttachmentBackPagination:(NSString*)eventId
{
    // Paginate only if possible
    if (NO == [roomDataSource.timeline canPaginate:MXTimelineDirectionBackwards] && self.attachmentsViewer)
    {
        return;
    }
    
    isPaginationInProgress = YES;
    
    MXWeakify(self);
    
    // Trigger back pagination to find previous attachments
    [roomDataSource paginate:_paginationLimit direction:MXTimelineDirectionBackwards onlyFromStore:NO success:^(NSUInteger addedCellNumber) {
        
        MXStrongifyAndReturnIfNil(self);
        
        // Check whether attachments viewer is still visible
        if (self.attachmentsViewer)
        {
            // Check whether some older attachments have been added.
            // Note: the stickers are excluded from the attachments list returned by the room datasource.
            BOOL isDone = NO;
            NSArray *attachmentsWithThumbnail = self.roomDataSource.attachmentsWithThumbnail;
            if (attachmentsWithThumbnail.count)
            {
                MXKAttachment *attachment = attachmentsWithThumbnail.firstObject;
                isDone = ![attachment.eventId isEqualToString:eventId];
            }
            
            // Check whether pagination is still available
            self.attachmentsViewer.complete = ([self->roomDataSource.timeline canPaginate:MXTimelineDirectionBackwards] == NO);
            
            if (isDone || self.attachmentsViewer.complete)
            {
                // Refresh the current attachments list.
                [self.attachmentsViewer displayAttachments:attachmentsWithThumbnail focusOn:nil];
                
                // Trigger a full table reload without scrolling. We could not only insert new cells related to back pagination,
                // because some other changes may have been ignored during back pagination (see[dataSource:didCellChange:]).
                self.bubbleTableViewDisplayInTransition = YES;
                self->isPaginationInProgress = NO;
                [self reloadBubblesTable:YES];
                self.bubbleTableViewDisplayInTransition = NO;
                
                // Done
                return;
            }
            
            // Here a new back pagination is required
            [self triggerAttachmentBackPagination:eventId];
        }
        else
        {
            // Trigger a full table reload without scrolling. We could not only insert new cells related to back pagination,
            // because some other changes may have been ignored during back pagination (see[dataSource:didCellChange:]).
            self.bubbleTableViewDisplayInTransition = YES;
            self->isPaginationInProgress = NO;
            [self reloadBubblesTable:YES];
            self.bubbleTableViewDisplayInTransition = NO;
        }
        
    } failure:^(NSError *error) {
        
        MXStrongifyAndReturnIfNil(self);
        
        // Reload table on failure because some changes may have been ignored during back pagination (see[dataSource:didCellChange:])
        self.bubbleTableViewDisplayInTransition = YES;
        self->isPaginationInProgress = NO;
        [self reloadBubblesTable:YES];
        self.bubbleTableViewDisplayInTransition = NO;
        
        if (self.attachmentsViewer)
        {
            // Force attachments update to cancel potential loading wheel
            [self.attachmentsViewer displayAttachments:self.attachmentsViewer.attachments focusOn:nil];
        }
        
    }];
}

#pragma mark - Post messages

- (void)sendTextMessage:(NSString*)msgTxt
{
    // Let the datasource send it and manage the local echo
    [roomDataSource sendTextMessage:msgTxt success:nil failure:^(NSError *error)
    {
        // Just log the error. The message will be displayed in red in the room history
        MXLogDebug(@"[MXKRoomViewController] sendTextMessage failed.");
    }];
}

# pragma mark - Event handling

- (void)showEventDetails:(MXEvent *)event
{
    [self dismissKeyboard];
    
    // Remove potential existing subviews
    [self dismissTemporarySubViews];
    
    MXKEventDetailsView *eventDetailsView;
    
    if (customEventDetailsViewClass)
    {
        eventDetailsView = [[customEventDetailsViewClass alloc] initWithEvent:event andMatrixSession:roomDataSource.mxSession];
    }
    else
    {
        eventDetailsView = [[MXKEventDetailsView alloc] initWithEvent:event andMatrixSession:roomDataSource.mxSession];
    }    
    
    // Add shadow on event details view
    eventDetailsView.layer.cornerRadius = 5;
    eventDetailsView.layer.shadowOffset = CGSizeMake(0, 1);
    eventDetailsView.layer.shadowOpacity = 0.5f;
    
    // Add the view and define edge constraints
    [self.view addSubview:eventDetailsView];
    
    self->eventDetailsView = eventDetailsView;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:eventDetailsView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.topLayoutGuide
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0f
                                                           constant:10.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:eventDetailsView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.bottomLayoutGuide
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0f
                                                           constant:-10.0f]];
    #pragma clang diagnostic pop
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:eventDetailsView
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0f
                                                           constant:-10.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:eventDetailsView
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0f
                                                           constant:10.0f]];
    [self.view setNeedsUpdateConstraints];
}

- (void)promptUserToResendEvent:(NSString *)eventId
{
    MXEvent *event = [roomDataSource eventWithEventId:eventId];
    
    MXLogDebug(@"[MXKRoomViewController] promptUserToResendEvent: %@", event);
    
    if (event && event.eventType == MXEventTypeRoomMessage)
    {
        NSString *msgtype = event.content[kMXMessageTypeKey];
        
        NSString* textMessage;
        if ([msgtype isEqualToString:kMXMessageTypeText])
        {
            textMessage = event.content[kMXMessageBodyKey];
        }
        
        // Show a confirmation popup to the end user
        if (currentAlert)
        {
            [currentAlert dismissViewControllerAnimated:NO completion:nil];
        }
        
        __weak typeof(self) weakSelf = self;
        
        UIAlertController *resendAlert = [UIAlertController alertControllerWithTitle:[VectorL10n resendMessage]
                                                                             message:textMessage
                                                                      preferredStyle:UIAlertControllerStyleAlert];
        
        [resendAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                           
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                       }]];
        
        [resendAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                           
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           // Let the datasource resend. It will manage local echo, etc.
                                                           [self->roomDataSource resendEventWithEventId:eventId success:nil failure:nil];
                                                           
                                                       }]];
        
        [self presentViewController:resendAlert animated:YES completion:nil];
        currentAlert = resendAlert;
    }
}

#pragma mark - bubbles table

- (BOOL)reloadBubblesTable:(BOOL)useBottomAnchor
{
    return [self reloadBubblesTable:useBottomAnchor invalidateBubblesCellDataCache:NO];
}

- (BOOL)reloadBubblesTable:(BOOL)useBottomAnchor invalidateBubblesCellDataCache:(BOOL)invalidateBubblesCellDataCache
{
    BOOL shouldScrollToBottom = shouldScrollToBottomOnTableRefresh;
    
    // When no size transition is in progress, check if the bottom of the content is currently visible.
    // If this is the case, we will scroll automatically to the bottom after table refresh.
    if (!isSizeTransitionInProgress && !shouldScrollToBottom)
    {
        shouldScrollToBottom = [self isBubblesTableScrollViewAtTheBottom];
    }
    
    // Force bubblesCellData message recalculation if requested
    if (invalidateBubblesCellDataCache)
    {
        [self.roomDataSource invalidateBubblesCellDataCache];
    }
    
    // When scroll to bottom is not active, check whether we should keep the current event displayed at the bottom of the table
    if (!shouldScrollToBottom && useBottomAnchor && currentEventIdAtTableBottom)
    {
        // Update content offset after refresh in order to keep visible the current event displayed at the bottom
        
        [_bubblesTableView reloadData];
        
        // Retrieve the new cell index of the event displayed previously at the bottom of table
        NSInteger rowIndex = [roomDataSource indexOfCellDataWithEventId:currentEventIdAtTableBottom];
        if (rowIndex != NSNotFound)
        {
            // Retrieve the corresponding cell
            UITableViewCell *cell = [_bubblesTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:rowIndex inSection:0]];
            UITableViewCell *cellTmp;
            if (!cell)
            {
                NSString *reuseIdentifier = [self cellReuseIdentifierForCellData:[roomDataSource cellDataAtIndex:rowIndex]];
                // Create temporarily the cell (this cell will released at the end, to be reusable)
                // Do not pass in the indexPath when creating this cell, as there is a possible crash by dequeuing
                // multiple cells for the same index path if rotating the device coincides with reloading the data.
                cellTmp = [_bubblesTableView dequeueReusableCellWithIdentifier:reuseIdentifier];
                cell = cellTmp;
            }
            
            if (cell)
            {
                CGFloat eventTopPosition = cell.frame.origin.y;
                CGFloat eventBottomPosition = eventTopPosition + cell.frame.size.height;
                
                // Compute accurate event positions in case of bubble with multiple components
                if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
                {
                    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
                    NSArray *bubbleComponents = roomBubbleTableViewCell.bubbleData.bubbleComponents;
                    
                    if (bubbleComponents.count > 1)
                    {
                        // Check and update each component position
                        [roomBubbleTableViewCell.bubbleData prepareBubbleComponentsPosition];
                        
                        NSInteger index = bubbleComponents.count - 1;
                        MXKRoomBubbleComponent *component = bubbleComponents[index];
                        
                        if ([component.event.eventId isEqualToString:currentEventIdAtTableBottom])
                        {
                            eventTopPosition += roomBubbleTableViewCell.msgTextViewTopConstraint.constant + component.position.y;
                        }
                        else
                        {
                            while (index--)
                            {
                                MXKRoomBubbleComponent *previousComponent = bubbleComponents[index];
                                if ([previousComponent.event.eventId isEqualToString:currentEventIdAtTableBottom])
                                {
                                    // Update top position if this is not the first component
                                    if (index)
                                    {
                                        eventTopPosition += roomBubbleTableViewCell.msgTextViewTopConstraint.constant + previousComponent.position.y;
                                    }
                                    
                                    eventBottomPosition = cell.frame.origin.y + roomBubbleTableViewCell.msgTextViewTopConstraint.constant + component.position.y;
                                    break;
                                }
                                
                                component = previousComponent;
                            }
                        }
                    }
                }
                
                // Compute the offset of the content displayed at the bottom.
                CGFloat contentBottomOffsetY = _bubblesTableView.contentOffset.y + (_bubblesTableView.frame.size.height - _bubblesTableView.adjustedContentInset.bottom);
                if (contentBottomOffsetY > _bubblesTableView.contentSize.height)
                {
                    contentBottomOffsetY = _bubblesTableView.contentSize.height;
                }
                
                // Check whether this event is no more displayed at the bottom
                if ((contentBottomOffsetY <= eventTopPosition ) || (eventBottomPosition < contentBottomOffsetY))
                {
                    // Compute the top content offset to display again this event at the table bottom
                    CGFloat contentOffsetY = eventBottomPosition - (_bubblesTableView.frame.size.height - _bubblesTableView.adjustedContentInset.bottom);
                    
                    // Check if there are enought data to fill the top
                    if (contentOffsetY < -_bubblesTableView.adjustedContentInset.top)
                    {
                        // Scroll to the top
                        contentOffsetY = -_bubblesTableView.adjustedContentInset.top;
                    }
                    
                    CGPoint contentOffset = _bubblesTableView.contentOffset;
                    contentOffset.y = contentOffsetY;
                    [self setBubbleTableViewContentOffset:contentOffset animated:NO];
                }
                
                if (cellTmp && [cellTmp conformsToProtocol:@protocol(MXKCellRendering)] && [cellTmp respondsToSelector:@selector(didEndDisplay)])
                {
                    // Release here resources, and restore reusable cells
                    [(id<MXKCellRendering>)cellTmp didEndDisplay];
                }
            }
        }
    }
    else
    {
        // Do a full reload
        [_bubblesTableView reloadData];
        if (shouldScrollToBottom) {
            // If we need to scroll to the bottom after the reload, layout refresh needs to be triggered,
            // otherwise contentSize of the table view will not be up-to-date
            // e.g. https://stackoverflow.com/a/31324129
            [_bubblesTableView layoutIfNeeded];
        }
    }
    
    if (shouldScrollToBottom)
    {
        [self scrollBubblesTableViewToBottomAnimated:NO];
    }
    
    return shouldScrollToBottom;
}

- (void)updateCurrentEventIdAtTableBottom:(BOOL)acknowledge
{
    // Do not update events if the controller is used as context menu preview.
    if (self.isContextPreview)
    {
        return;
    }
    
    // Update the identifier of the event displayed at the bottom of the table, except if a rotation or other size transition is in progress.
    if (!isSizeTransitionInProgress && !self.isBubbleTableViewDisplayInTransition)
    {
        // Compute the content offset corresponding to the line displayed at the table bottom (just above the toolbar).
        CGFloat contentBottomOffsetY = _bubblesTableView.contentOffset.y + (_bubblesTableView.frame.size.height - _bubblesTableView.adjustedContentInset.bottom);
        if (contentBottomOffsetY > _bubblesTableView.contentSize.height)
        {
            contentBottomOffsetY = _bubblesTableView.contentSize.height;
        }
        // Be a bit less retrictive, consider visible an event at the bottom even if is partially hidden.
        contentBottomOffsetY += 8;
        
        // Reset the current event id
        currentEventIdAtTableBottom = nil;
        
        // Consider the visible cells (starting by those displayed at the bottom)
        NSArray *visibleCells = [_bubblesTableView visibleCells];
        NSInteger index = visibleCells.count;
        UITableViewCell *cell;
        while (index--)
        {
            cell = visibleCells[index];
            
            // Check whether the cell is actually visible
            if (cell && (cell.frame.origin.y < contentBottomOffsetY))
            {
                if (![cell isKindOfClass:MXKTableViewCell.class])
                {
                    continue;
                }
                
                MXKCellData *cellData = ((MXKTableViewCell *)cell).mxkCellData;
                
                // Only 'MXKRoomBubbleCellData' is supported here for the moment.
                if (![cellData isKindOfClass:MXKRoomBubbleCellData.class])
                {
                    continue;
                }

                MXKRoomBubbleCellData *bubbleData = (MXKRoomBubbleCellData*)cellData;
                
                // Check which bubble component is displayed at the bottom.
                // For that update each component position.
                [bubbleData prepareBubbleComponentsPosition];
                
                NSArray *bubbleComponents = bubbleData.bubbleComponents;
                NSInteger componentIndex = bubbleComponents.count;
                
                CGFloat bottomPositionY = cell.frame.size.height;
                
                MXKRoomBubbleComponent *component;
                
                while (componentIndex --)
                {
                    component = bubbleComponents[componentIndex];
                    if (![cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
                    {
                        continue;
                    }

                    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
                    
                    // Check whether the bottom part of the component is visible.
                    CGFloat pos = cell.frame.origin.y + bottomPositionY;
                    if (pos <= contentBottomOffsetY)
                    {
                        // We found the component
                        currentEventIdAtTableBottom = component.event.eventId;
                        break;
                    }
                    
                    // Prepare the bottom position for the next component
                    bottomPositionY = roomBubbleTableViewCell.msgTextViewTopConstraint.constant + component.position.y;
                }
                
                if (currentEventIdAtTableBottom)
                {
                    if (acknowledge && self.isEventsAcknowledgementEnabled)
                    {
                        // Indicate to the homeserver that the user has read this event.
                        
                        // Check whether the read marker must be updated.
                        BOOL updateReadMarker = _updateRoomReadMarker;
                        if (updateReadMarker && roomDataSource.room.accountData.readMarkerEventId)
                        {
                            MXEvent *currentReadMarkerEvent = [roomDataSource.mxSession.store eventWithEventId:roomDataSource.room.accountData.readMarkerEventId inRoom:roomDataSource.roomId];
                            if (!currentReadMarkerEvent)
                            {
                                currentReadMarkerEvent = [roomDataSource eventWithEventId:roomDataSource.room.accountData.readMarkerEventId];
                            }
                            
                            // Update the read marker only if the current event is available, and the new event is posterior to it.
                            updateReadMarker = (currentReadMarkerEvent && (currentReadMarkerEvent.originServerTs <= component.event.originServerTs));
                        }
                        
                        [roomDataSource.room acknowledgeEvent:component.event andUpdateReadMarker:updateReadMarker];
                    }
                    break;
                }
                // else we consider the previous cell.
            }
        }
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    return nil;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    Class class = [self cellViewClassForCellData:cellData];
    
    if ([class respondsToSelector:@selector(defaultReuseIdentifier)])
    {
        return [class defaultReuseIdentifier];
    }
    
    return nil;
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    UIApplication *sharedApplication = [UIApplication performSelector:@selector(sharedApplication)];
    if (sharedApplication && sharedApplication.applicationState != UIApplicationStateActive)
    {
        // Do nothing at the UI level if the application do a sync in background
        return;
    }

    if (isPaginationInProgress)
    {
        // Ignore these changes, the table will be full updated at the end of pagination.
        return;
    }
    
    if (self.attachmentsViewer)
    {
        // Refresh the current attachments list without changing the current displayed attachment (see focus = nil).
        NSArray *attachmentsWithThumbnail = self.roomDataSource.attachmentsWithThumbnail;
        [self.attachmentsViewer displayAttachments:attachmentsWithThumbnail focusOn:nil];
    }
    
    self.bubbleTableViewDisplayInTransition = YES;

    CGPoint contentOffset = self.bubblesTableView.contentOffset;

    BOOL hasScrolledToTheBottom = [self reloadBubblesTable:YES];

    // If the user is scrolling while we reload the data for a new incoming message for example,
    // there will be a jump in the table view display.
    // Resetting the contentOffset after the reload fixes the issue.
    if (hasScrolledToTheBottom == NO)
    {
        [self setBubbleTableViewContentOffset:contentOffset animated:NO];
    }
    
    self.bubbleTableViewDisplayInTransition = NO;
}

- (void)dataSource:(MXKDataSource *)dataSource didStateChange:(MXKDataSourceState)state
{
    [self updateViewControllerAppearanceOnRoomDataSourceState];
    
    if (state == MXKDataSourceStateReady)
    {
        [self onRoomDataSourceReady];
    }
}

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    MXLogDebug(@"Gesture %@ has been recognized in %@. UserInfo: %@", actionIdentifier, cell, userInfo);
    
    if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnMessageTextView])
    {
        MXLogDebug(@"    -> A message has been tapped");
    }
    else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnSenderNameLabel] || [actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAvatarView])
    {
//        MXLogDebug(@"    -> Name or avatar of %@ has been tapped", userInfo[kMXKRoomBubbleCellUserIdKey]);
        
        // Add the member display name in text input
        MXRoomMember *selectedRoomMember = [roomDataSource.roomState.members memberWithUserId:userInfo[kMXKRoomBubbleCellUserIdKey]];
        if (selectedRoomMember)
        {
            [self mention:selectedRoomMember];
        }
    }
    else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnDateTimeContainer])
    {
        roomDataSource.showBubblesDateTime = !roomDataSource.showBubblesDateTime;
        MXLogDebug(@"    -> Turn %@ cells date", roomDataSource.showBubblesDateTime ? @"ON" : @"OFF");
    }
    else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAttachmentView] && [cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        [self showAttachmentInCell:(MXKRoomBubbleTableViewCell *)cell];
    }
    else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnProgressView] && [cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
        
        // Check if there is a download in progress, then offer to cancel it
        NSString *downloadId = roomBubbleTableViewCell.bubbleData.attachment.downloadId;
        if ([MXMediaManager existingDownloaderWithIdentifier:downloadId])
        {
            if (currentAlert)
            {
                [currentAlert dismissViewControllerAnimated:NO completion:nil];
            }
            
            __weak __typeof(self) weakSelf = self;
            UIAlertController *cancelAlert = [UIAlertController alertControllerWithTitle:nil
                                                                                 message:[VectorL10n attachmentCancelDownload]
                                                                          preferredStyle:UIAlertControllerStyleAlert];
            
            [cancelAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n no]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                               
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                           }]];
            
            [cancelAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n yes]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                               
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                               // Get again the loader
                                                               MXMediaLoader *loader = [MXMediaManager existingDownloaderWithIdentifier:downloadId];
                                                               if (loader)
                                                               {
                                                                   [loader cancel];
                                                               }
                                                               
                                                               // Hide the progress animation
                                                               roomBubbleTableViewCell.progressView.hidden = YES;
                                                               
                                                           }]];
            
            [self presentViewController:cancelAlert animated:YES completion:nil];
            currentAlert = cancelAlert;
        }
        else if (roomBubbleTableViewCell.bubbleData.attachment.eventSentState == MXEventSentStatePreparing ||
                 roomBubbleTableViewCell.bubbleData.attachment.eventSentState == MXEventSentStateEncrypting ||
                 roomBubbleTableViewCell.bubbleData.attachment.eventSentState == MXEventSentStateUploading)
        {
            // Offer to cancel the upload in progress
            // Upload id is stored in attachment url (nasty trick)
            NSString *uploadId = roomBubbleTableViewCell.bubbleData.attachment.contentURL;
            if ([MXMediaManager existingUploaderWithId:uploadId])
            {
                if (currentAlert)
                {
                    [currentAlert dismissViewControllerAnimated:NO completion:nil];
                }
                
                __weak __typeof(self) weakSelf = self;
                UIAlertController *cancelAlert = [UIAlertController alertControllerWithTitle:nil
                                                                                     message:[VectorL10n attachmentCancelUpload]
                                                                              preferredStyle:UIAlertControllerStyleAlert];
                
                [cancelAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n no]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                   
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   
                                                               }]];
                
                [cancelAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n yes]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                   
                                                                   // TODO cancel the attachment encryption if it is in progress.
                                                                   
                                                                   // Get again the loader
                                                                   MXMediaLoader *loader = [MXMediaManager existingUploaderWithId:uploadId];
                                                                   if (loader)
                                                                   {
                                                                       [loader cancel];
                                                                   }
                                                                   
                                                                   // Hide the progress animation
                                                                   roomBubbleTableViewCell.progressView.hidden = YES;
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                       
                                                                       // Remove the outgoing message and its related cached file.
                                                                       [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.cacheFilePath error:nil];
                                                                       [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.thumbnailCachePath error:nil];
                                                                       [self.roomDataSource removeEventWithEventId:roomBubbleTableViewCell.bubbleData.attachment.eventId];
                                                                   }
                                                                   
                                                               }]];
                
                [self presentViewController:cancelAlert animated:YES completion:nil];
                currentAlert = cancelAlert;
            }
        }
    }
    else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnEvent] && [cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        [self dismissKeyboard];
        
        MXEvent *selectedEvent = userInfo[kMXKRoomBubbleCellEventKey];
        MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
        MXKAttachment *attachment = roomBubbleTableViewCell.bubbleData.attachment;
        
        if (selectedEvent)
        {
            if (currentAlert)
            {
                [currentAlert dismissViewControllerAnimated:NO completion:nil];
                currentAlert = nil;
                
                // Cancel potential text selection in other bubbles
                for (MXKRoomBubbleTableViewCell *bubble in self.bubblesTableView.visibleCells)
                {
                    [bubble highlightTextMessageForEvent:nil];
                }
            }
            
            __weak __typeof(self) weakSelf = self;
            UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            // Add actions for a failed event
            if (selectedEvent.sentState == MXEventSentStateFailed)
            {
                [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n resend]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                   
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   
                                                                   // Let the datasource resend. It will manage local echo, etc.
                                                                   [self.roomDataSource resendEventWithEventId:selectedEvent.eventId success:nil failure:nil];
                                                                   
                                                               }]];
                
                [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n delete]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                   
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   
                                                                   [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                                                                   
                                                               }]];
            }
            
            // Add actions for text message
            if (!attachment)
            {
                // Highlight the select event
                [roomBubbleTableViewCell highlightTextMessageForEvent:selectedEvent.eventId];
                
                // Retrieved data related to the selected event
                NSArray *components = roomBubbleTableViewCell.bubbleData.bubbleComponents;
                MXKRoomBubbleComponent *selectedComponent;
                for (selectedComponent in components)
                {
                    if ([selectedComponent.event.eventId isEqualToString:selectedEvent.eventId])
                    {
                        break;
                    }
                    selectedComponent = nil;
                }
                
                [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n copy]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                   
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   
                                                                   // Cancel event highlighting
                                                                   [roomBubbleTableViewCell highlightTextMessageForEvent:nil];
                                                                   
                                                                   NSString *textMessage = selectedComponent.textMessage;
                                                                   
                                                                   if (textMessage)
                                                                   {
                                                                       MXKPasteboardManager.shared.pasteboard.string = textMessage;
                                                                   }
                                                                   else
                                                                   {
                                                                       MXLogDebug(@"[MXKRoomViewController] Copy text failed. Text is nil for room id/event id: %@/%@", selectedComponent.event.roomId, selectedComponent.event.eventId);
                                                                   }
                                                               }]];
                
                if ([MXKAppSettings standardAppSettings].messageDetailsAllowSharing)
                {
                    [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n share]
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                        
                        typeof(self) self = weakSelf;
                        self->currentAlert = nil;
                        
                        // Cancel event highlighting
                        [roomBubbleTableViewCell highlightTextMessageForEvent:nil];
                        
                        NSArray *activityItems = [NSArray arrayWithObjects:selectedComponent.textMessage, nil];
                        
                        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                        if (activityViewController)
                        {
                            activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                            activityViewController.popoverPresentationController.sourceView = roomBubbleTableViewCell;
                            activityViewController.popoverPresentationController.sourceRect = roomBubbleTableViewCell.bounds;
                            
                            [self presentViewController:activityViewController animated:YES completion:nil];
                        }
                        
                    }]];
                }
                
                if (components.count > 1)
                {
                    [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n selectAll]
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                       
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                       
                                                                       [self selectAllTextMessageInCell:cell];
                                                                       
                                                                   }]];
                }
            }
            else // Add action for attachment
            {
                if (attachment.type == MXKAttachmentTypeImage || attachment.type == MXKAttachmentTypeVideo)
                {
                    if ([MXKAppSettings standardAppSettings].messageDetailsAllowSaving)
                    {
                        [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n save]
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                            
                            typeof(self) self = weakSelf;
                            self->currentAlert = nil;
                            
                            [self startActivityIndicator];
                            
                            [attachment save:^{
                                
                                typeof(self) self = weakSelf;
                                [self stopActivityIndicator];
                                
                            } failure:^(NSError *error) {
                                
                                typeof(self) self = weakSelf;
                                [self stopActivityIndicator];
                                
                                // Notify MatrixKit user
                                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                                
                            }];
                            
                            // Start animation in case of download during attachment preparing
                            [roomBubbleTableViewCell startProgressUI];
                            
                        }]];
                    }
                }
                
                if (attachment.type != MXKAttachmentTypeSticker)
                {
                    [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n copyButtonName]
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                       
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                       
                                                                       [self startActivityIndicator];
                                                                       
                                                                       [attachment copy:^{
                                                                           
                                                                           typeof(self) self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                       } failure:^(NSError *error) {
                                                                           
                                                                           typeof(self) self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                           // Notify MatrixKit user
                                                                           [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                                                                           
                                                                       }];
                                                                       
                                                                       // Start animation in case of download during attachment preparing
                                                                       [roomBubbleTableViewCell startProgressUI];
                                                                       
                                                                   }]];
                    
                    if ([MXKAppSettings standardAppSettings].messageDetailsAllowSharing)
                    {
                        [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n share]
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                            
                            typeof(self) self = weakSelf;
                            self->currentAlert = nil;
                            
                            [attachment prepareShare:^(NSURL *fileURL) {
                                
                                typeof(self) self = weakSelf;
                                self->documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
                                [self->documentInteractionController setDelegate:self];
                                self->currentSharedAttachment = attachment;
                                
                                if (![self->documentInteractionController presentOptionsMenuFromRect:self.view.frame inView:self.view animated:YES])
                                {
                                    self->documentInteractionController = nil;
                                    [attachment onShareEnded];
                                    self->currentSharedAttachment = nil;
                                }
                                
                            } failure:^(NSError *error) {
                                
                                // Notify MatrixKit user
                                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                                
                            }];
                            
                            // Start animation in case of download during attachment preparing
                            [roomBubbleTableViewCell startProgressUI];
                            
                        }]];
                    }
                }
                
                // Check status of the selected event
                if (selectedEvent.sentState == MXEventSentStatePreparing ||
                    selectedEvent.sentState == MXEventSentStateEncrypting ||
                    selectedEvent.sentState == MXEventSentStateUploading)
                {
                    // Upload id is stored in attachment url (nasty trick)
                    NSString *uploadId = roomBubbleTableViewCell.bubbleData.attachment.contentURL;
                    if ([MXMediaManager existingUploaderWithId:uploadId])
                    {
                        [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n cancelUpload]
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                           
                                                                           // TODO cancel the attachment encryption if it is in progress.
                                                                           
                                                                           // Cancel the loader
                                                                           MXMediaLoader *loader = [MXMediaManager existingUploaderWithId:uploadId];
                                                                           if (loader)
                                                                           {
                                                                               [loader cancel];
                                                                           }
                                                                           
                                                                           // Hide the progress animation
                                                                           roomBubbleTableViewCell.progressView.hidden = YES;
                                                                           
                                                                           if (weakSelf)
                                                                           {
                                                                               typeof(self) self = weakSelf;
                                                                               self->currentAlert = nil;
                                                                               
                                                                               // Remove the outgoing message and its related cached file.
                                                                               [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.cacheFilePath error:nil];
                                                                               [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.thumbnailCachePath error:nil];
                                                                               [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                                                                           }
                                                                           
                                                                       }]];
                    }
                }
            }
            
            // Check status of the selected event
            if (selectedEvent.sentState == MXEventSentStateSent)
            {
                // Check whether download is in progress
                if (selectedEvent.isMediaAttachment)
                {
                    NSString *downloadId = roomBubbleTableViewCell.bubbleData.attachment.downloadId;
                    if ([MXMediaManager existingDownloaderWithIdentifier:downloadId])
                    {
                        [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n cancelDownload]
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                           
                                                                           typeof(self) self = weakSelf;
                                                                           self->currentAlert = nil;
                                                                           
                                                                           // Get again the loader
                                                                           MXMediaLoader *loader = [MXMediaManager existingDownloaderWithIdentifier:downloadId];
                                                                           if (loader)
                                                                           {
                                                                               [loader cancel];
                                                                           }
                                                                           // Hide the progress animation
                                                                           roomBubbleTableViewCell.progressView.hidden = YES;
                                                                           
                                                                       }]];
                    }
                }
                
                [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n showDetails]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                   
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   
                                                                   // Cancel event highlighting (if any)
                                                                   [roomBubbleTableViewCell highlightTextMessageForEvent:nil];
                                                                   
                                                                   // Display event details
                                                                   [self showEventDetails:selectedEvent];
                                                                   
                                                               }]];
            }
            
            [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                               
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                               // Cancel event highlighting (if any)
                                                               [roomBubbleTableViewCell highlightTextMessageForEvent:nil];
                                                               
                                                           }]];
            
            // Do not display empty action sheet
            if (actionSheet.actions.count > 1)
            {
                [actionSheet popoverPresentationController].sourceView = roomBubbleTableViewCell;
                [actionSheet popoverPresentationController].sourceRect = roomBubbleTableViewCell.bounds;
                [self presentViewController:actionSheet animated:YES completion:nil];
                currentAlert = actionSheet;
            }
        }
    }
    else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnAvatarView])
    {
        MXLogDebug(@"    -> Avatar of %@ has been long pressed", userInfo[kMXKRoomBubbleCellUserIdKey]);
    }
    else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellUnsentButtonPressed])
    {
        MXEvent *selectedEvent = userInfo[kMXKRoomBubbleCellEventKey];
        if (selectedEvent)
        {
            // The user may want to resend it
            [self promptUserToResendEvent:selectedEvent.eventId];
        }
    }
}

#pragma mark - Clipboard

- (void)selectAllTextMessageInCell:(id<MXKCellRendering>)cell
{
    if (![MXKAppSettings standardAppSettings].messageDetailsAllowSharing)
    {
        return;
    }
    
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
        selectedText = roomBubbleTableViewCell.bubbleData.textMessage;
        roomBubbleTableViewCell.allTextHighlighted = YES;
        
        // Display Menu (dispatch is required here, else the attributed text change hides the menu)
        dispatch_async(dispatch_get_main_queue(), ^{
            MXWeakify(self);
            self.uiMenuControllerDidHideMenuNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIMenuControllerDidHideMenuNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                
                MXStrongifyAndReturnIfNil(self);
                // Deselect text
                roomBubbleTableViewCell.allTextHighlighted = NO;
                self->selectedText = nil;
                
                [UIMenuController sharedMenuController].menuItems = nil;
                
                [[NSNotificationCenter defaultCenter] removeObserver:self.uiMenuControllerDidHideMenuNotificationObserver];
            }];
            
            [self becomeFirstResponder];
            UIMenuController *menu = [UIMenuController sharedMenuController];
            menu.menuItems = @[[[UIMenuItem alloc] initWithTitle:[VectorL10n share] action:@selector(share:)]];
            [menu setTargetRect:roomBubbleTableViewCell.messageTextView.frame inView:roomBubbleTableViewCell];
            [menu setMenuVisible:YES animated:YES];
        });
    }
}

- (void)copy:(id)sender
{
    if (selectedText)
    {
        MXKPasteboardManager.shared.pasteboard.string = selectedText;
    }
    else
    {
        MXLogDebug(@"[MXKRoomViewController] Selected text copy failed. Selected text is nil");
    }
}

- (void)share:(id)sender
{
    if (selectedText)
    {
        NSArray *activityItems = [NSArray arrayWithObjects:selectedText, nil];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        if (activityViewController)
        {
            activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            activityViewController.popoverPresentationController.sourceView = self.view;
            activityViewController.popoverPresentationController.sourceRect = self.view.bounds;
            
            [self presentViewController:activityViewController animated:YES completion:nil];
        }
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (selectedText.length && (action == @selector(copy:) || action == @selector(share:)))
    {
        return YES;
    }
    return NO;
}

- (BOOL)canBecomeFirstResponder
{
    return (selectedText.length != 0);
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _bubblesTableView)
    {
        return [roomDataSource cellHeightAtIndex:indexPath.row withMaximumWidth:self.tableViewSafeAreaWidth];
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _bubblesTableView)
    {
        // Dismiss keyboard when user taps on messages table view content
        [self dismissKeyboard];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Release here resources, and restore reusable cells
    if ([cell respondsToSelector:@selector(didEndDisplay)])
    {
        [(id<MXKCellRendering>)cell didEndDisplay];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    // Detect vertical bounce at the top of the tableview to trigger pagination
    if (scrollView == _bubblesTableView)
    {
        // Detect top bounce
        if (scrollView.contentOffset.y < -scrollView.adjustedContentInset.top)
        {
            // Shall we add back pagination spinner?
            if (isPaginationInProgress && !backPaginationActivityView)
            {
                UIActivityIndicatorView* spinner  = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                spinner.hidesWhenStopped = NO;
                spinner.backgroundColor = [UIColor clearColor];
                [spinner startAnimating];
                
                // no need to manage constraints here
                // IOS defines them.
                // since IOS7 the spinner is centered so need to create a background and add it.
                _bubblesTableView.tableHeaderView = backPaginationActivityView = spinner;
            }
        }
        else
        {
            // Shall we add forward pagination spinner?
            if (!roomDataSource.isLive && isPaginationInProgress && scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height + 64 && !reconnectingView)
            {
                [self addReconnectingView];
            }
            else
            {
                [self detectPullToKick:scrollView];
            }
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView == _bubblesTableView)
    {
        // if the user scrolls the history content without animation
        // upateCurrentEventIdAtTableBottom must be called here (without dispatch).
        // else it will be done in scrollViewDidEndDecelerating
        if (!decelerate)
        {
            [self updateCurrentEventIdAtTableBottom:YES];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == _bubblesTableView)
    {
        // do not dispatch the upateCurrentEventIdAtTableBottom call
        // else it might triggers weird UI lags.
        [self updateCurrentEventIdAtTableBottom:YES];
        [self managePullToKick:scrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (scrollView == _bubblesTableView)
    {
        // do not dispatch the upateCurrentEventIdAtTableBottom call
        // else it might triggers weird UI lags.
        [self updateCurrentEventIdAtTableBottom:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == _bubblesTableView)
    {
        BOOL wasScrollingToBottom = isScrollingToBottom;

        // Consider this callback to reset scrolling to bottom flag
        isScrollingToBottom = NO;
        
        // shouldScrollToBottomOnTableRefresh is used to inhibit false detection of
        // scrolling action from the user when the viewVC appears or rotates
        if (scrollView == _bubblesTableView && scrollView.contentSize.height && !shouldScrollToBottomOnTableRefresh)
        {
            // when the content size if smaller that the frame
            // scrollViewDidEndDecelerating is not called
            // so test it when the content offset goes back to the screen top.
            if ((scrollView.contentSize.height < scrollView.frame.size.height) && (-scrollView.contentOffset.y == scrollView.adjustedContentInset.top))
            {
                [self managePullToKick:scrollView];
            }
            
            // Trigger inconspicuous pagination when user scrolls toward the top
            if (scrollView.contentOffset.y < _paginationThreshold)
            {
                [self triggerPagination:_paginationLimit direction:MXTimelineDirectionBackwards];
            }
            // Enable forwards pagination when displaying non live timeline
            else if (!roomDataSource.isLive && !wasScrollingToBottom && ((scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.size.height) < _paginationThreshold))
            {
                [self triggerPagination:_paginationLimit direction:MXTimelineDirectionForwards];
            }
        }
        
        if (wasScrollingToBottom)
        {
            // When scrolling to the bottom is performed without animation, 'scrollViewDidEndScrollingAnimation' is not called.
            // upateCurrentEventIdAtTableBottom must be called here (without dispatch).
            [self updateCurrentEventIdAtTableBottom:YES];
        }
    }
}

#pragma mark - MXKRoomTitleViewDelegate

- (void)roomTitleView:(MXKRoomTitleView*)titleView presentAlertController:(UIAlertController *)alertController
{
    [self dismissKeyboard];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)roomTitleViewShouldBeginEditing:(MXKRoomTitleView*)titleView
{
    return YES;
}

- (void)roomTitleView:(MXKRoomTitleView*)titleView isSaving:(BOOL)saving
{
    if (saving)
    {
        [self startActivityIndicator];
    }
    else
    {
        [self stopActivityIndicator];
    }
}

#pragma mark - MXKRoomInputToolbarViewDelegate

- (void)roomInputToolbarView:(MXKRoomInputToolbarView *)toolbarView hideStatusBar:(BOOL)isHidden
{
    isStatusBarHidden = isHidden;
    
    // Trigger status bar update
    [self setNeedsStatusBarAppearanceUpdate];
    
    // Handle status bar with the historical method.
    // TODO: remove this [UIApplication statusBarHidden] use (deprecated since iOS 9).
    // Note: setting statusBarHidden does nothing if your application is using the default UIViewController-based status bar system.
    UIApplication *sharedApplication = [UIApplication performSelector:@selector(sharedApplication)];
    if (sharedApplication)
    {
        sharedApplication.statusBarHidden = isHidden;
    }
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView isTyping:(BOOL)typing
{
    if (_saveProgressTextInput && roomDataSource)
    {
        // Store the potential message partially typed in text input
        roomDataSource.partialAttributedTextMessage = inputToolbarView.attributedTextMessage;
    }
    
    [self handleTypingState:typing];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView heightDidChanged:(CGFloat)height completion:(void (^)(BOOL finished))completion
{
    _roomInputToolbarContainerHeightConstraint.constant = height;
    
    // Update layout with animation
    [UIView animateWithDuration:self.resizeComposerAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         // We will scroll to bottom if the bottom of the table is currently visible
                         BOOL shouldScrollToBottom = [self isBubblesTableScrollViewAtTheBottom];
                         
                         CGFloat bubblesTableViewBottomConst = self->_roomInputToolbarContainerBottomConstraint.constant + self->_roomInputToolbarContainerHeightConstraint.constant + self->_roomActivitiesContainerHeightConstraint.constant;
                         
                        self->_bubblesTableViewBottomConstraint.constant = bubblesTableViewBottomConst;
                        
                        // Force to render the view
                        [self.view layoutIfNeeded];
                        
                        if (shouldScrollToBottom)
                        {
                            [self scrollBubblesTableViewToBottomAnimated:NO];
                        }
                     }
                     completion:^(BOOL finished){
                         if (completion)
                         {
                             completion(finished);
                         }
                     }];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView sendTextMessage:(NSString*)textMessage
{
    // Handle potential IRC commands in typed string
    if ([self sendAsIRCStyleCommandIfPossible:textMessage] == NO)
    {
        // Send text message in the current room
        [self sendTextMessage:textMessage];
    }
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView sendImage:(UIImage*)image
{
    // Let the datasource send it and manage the local echo
    [roomDataSource sendImage:image success:nil failure:^(NSError *error)
    {
        // Nothing to do. The image is marked as unsent in the room history by the datasource
        MXLogDebug(@"[MXKRoomViewController] sendImage failed.");
    }];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView sendImage:(NSData*)imageData withMimeType:(NSString*)mimetype
{
    // Let the datasource send it and manage the local echo
    [roomDataSource sendImage:imageData mimeType:mimetype success:nil failure:^(NSError *error)
    {
        // Nothing to do. The image is marked as unsent in the room history by the datasource
        MXLogDebug(@"[MXKRoomViewController] sendImage with mimetype failed.");
    }];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView sendVideo:(NSURL*)videoLocalURL withThumbnail:(UIImage*)videoThumbnail
{
    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:videoLocalURL];
    [self roomInputToolbarView:toolbarView sendVideoAsset:videoAsset withThumbnail:videoThumbnail];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView sendVideoAsset:(AVAsset*)videoAsset withThumbnail:(UIImage*)videoThumbnail
{
    // Let the datasource send it and manage the local echo
    [roomDataSource sendVideoAsset:videoAsset withThumbnail:videoThumbnail success:nil failure:^(NSError *error)
    {
        // Nothing to do. The video is marked as unsent in the room history by the datasource
        MXLogDebug(@"[MXKRoomViewController] sendVideo failed.");
    }];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView sendFile:(NSURL *)fileLocalURL withMimeType:(NSString*)mimetype
{
    // Let the datasource send it and manage the local echo
    [roomDataSource sendFile:fileLocalURL mimeType:mimetype success:nil failure:^(NSError *error)
     {
         // Nothing to do. The file is marked as unsent in the room history by the datasource
         MXLogDebug(@"[MXKRoomViewController] sendFile failed.");
     }];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView presentAlertController:(UIAlertController *)alertController
{
    [self dismissKeyboard];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView presentViewController:(UIViewController*)viewControllerToPresent
{
    [self dismissKeyboard];
    [self presentViewController:viewControllerToPresent animated:YES completion:nil];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self dismissViewControllerAnimated:flag completion:completion];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView updateActivityIndicator:(BOOL)isAnimating
{
    isInputToolbarProcessing = isAnimating;
    
    if (isAnimating)
    {
        [self startActivityIndicator];
    }
    else
    {
        [self stopActivityIndicator];
    }
}
# pragma mark - Typing notification

- (void)handleTypingState:(BOOL)typing
{
    NSUInteger notificationTimeoutMS = -1;
    if (typing)
    {
        // Check whether a typing event has been already reported to server (We wait for the end of the local timout before considering this new event)
        if (typingTimer)
        {
            // Refresh date of the last observed typing
            lastTypingDate = [[NSDate alloc] init];
            return;
        }
        
        // No typing event has been yet reported -> share encryption keys if requested
        if ([MXKAppSettings standardAppSettings].outboundGroupSessionKeyPreSharingStrategy == MXKKeyPreSharingWhenTyping)
        {
            [self shareEncryptionKeys];
        }
        
        // Launch a timer to prevent sending multiple typing notifications
        NSTimeInterval timerTimeout = MXKROOMVIEWCONTROLLER_DEFAULT_TYPING_TIMEOUT_SEC;
        if (lastTypingDate)
        {
            NSTimeInterval lastTypingAge = -[lastTypingDate timeIntervalSinceNow];
            if (lastTypingAge < timerTimeout)
            {
                // Subtract the time interval since last typing from the timer timeout
                timerTimeout -= lastTypingAge;
            }
            else
            {
                timerTimeout = 0;
            }
        }
        else
        {
            // Keep date of this typing event
            lastTypingDate = [[NSDate alloc] init];
        }
        
        if (timerTimeout)
        {
            typingTimer = [NSTimer scheduledTimerWithTimeInterval:timerTimeout target:self selector:@selector(typingTimeout:) userInfo:self repeats:NO];
            // Compute the notification timeout in ms (consider the double of the local typing timeout)
            notificationTimeoutMS = 2000 * MXKROOMVIEWCONTROLLER_DEFAULT_TYPING_TIMEOUT_SEC;
        }
        else
        {
            // This typing event is too old, we will ignore it
            typing = NO;
            MXLogDebug(@"[MXKRoomVC] Ignore typing event (too old)");
        }
    }
    else
    {
        // Cancel any typing timer
        [typingTimer invalidate];
        typingTimer = nil;
        // Reset last typing date
        lastTypingDate = nil;
    }
    
    [self sendTypingNotification:typing timeout:notificationTimeoutMS];
}

- (void)sendTypingNotification:(BOOL)typing timeout:(NSUInteger)notificationTimeoutMS
{
    MXWeakify(self);
    
    // Send typing notification to server
    [roomDataSource.room sendTypingNotification:typing
                                        timeout:notificationTimeoutMS
                                        success:^{
        
        MXStrongifyAndReturnIfNil(self);
                                            // Reset last typing date
                                            self->lastTypingDate = nil;
                                        } failure:^(NSError *error)
    {
        MXStrongifyAndReturnIfNil(self);
        
        MXLogDebug(@"[MXKRoomVC] Failed to send typing notification (%d)", typing);
        
        // Cancel timer (if any)
        [self->typingTimer invalidate];
        self->typingTimer = nil;
    }];
}

- (IBAction)typingTimeout:(id)sender
{
    [typingTimer invalidate];
    typingTimer = nil;
    
    // Check whether a new typing event has been observed
    BOOL typing = (lastTypingDate != nil);
    // Post a new typing notification
    [self handleTypingState:typing];
}


# pragma mark - Attachment handling

- (void)showAttachmentInCell:(UITableViewCell*)cell
{
    [self dismissKeyboard];

    // Retrieve the attachment information from the associated cell data
    if ([cell isKindOfClass:MXKTableViewCell.class])
    {
        MXKCellData *cellData = ((MXKTableViewCell*)cell).mxkCellData;

        // Only 'MXKRoomBubbleCellData' is supported here for the moment.
        if ([cellData isKindOfClass:MXKRoomBubbleCellData.class])
        {
            MXKRoomBubbleCellData *bubbleData = (MXKRoomBubbleCellData*)cellData;
            
            MXKAttachment *selectedAttachment = bubbleData.attachment;
            
            if (bubbleData.isAttachmentWithThumbnail)
            {
                // The attachments viewer is opened only on a valid attachment. It does not display the stickers.
                if (selectedAttachment.eventSentState == MXEventSentStateSent && selectedAttachment.type != MXKAttachmentTypeSticker)
                {
                    // Note: the stickers are presently excluded from the attachments list returned by the room dataSource.
                    NSArray *attachmentsWithThumbnail = self.roomDataSource.attachmentsWithThumbnail;
                    
                    MXKAttachmentsViewController *attachmentsViewer;
                    
                    // Present an attachment viewer
                    if (attachmentsViewerClass)
                    {
                        attachmentsViewer = [attachmentsViewerClass animatedAttachmentsViewControllerWithSourceViewController:self];
                    }
                    else
                    {
                        attachmentsViewer = [MXKAttachmentsViewController animatedAttachmentsViewControllerWithSourceViewController:self];
                    }
                    
                    attachmentsViewer.delegate = self;
                    attachmentsViewer.complete = ([roomDataSource.timeline canPaginate:MXTimelineDirectionBackwards] == NO);
                    attachmentsViewer.hidesBottomBarWhenPushed = YES;
                    [attachmentsViewer displayAttachments:attachmentsWithThumbnail focusOn:selectedAttachment.eventId];
                    
                    // Keep here the image view used to display the attachment in the selected cell.
                    // Note: Only `MXKRoomBubbleTableViewCell` and `MXKSearchTableViewCell` are supported for the moment.
                    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
                    {
                        self.openedAttachmentImageView = ((MXKRoomBubbleTableViewCell *)cell).attachmentView.imageView;
                    }
                    else if ([cell isKindOfClass:MXKSearchTableViewCell.class])
                    {
                        self.openedAttachmentImageView = ((MXKSearchTableViewCell *)cell).attachmentImageView.imageView;
                    }
                    
                    self.openedAttachmentEventId = selectedAttachment.eventId;
                    
                    // "Initializing" closedAttachmentEventId so it is equal to openedAttachmentEventId at the beginning
                    self.closedAttachmentEventId = self.openedAttachmentEventId;
                    
                    if (@available(iOS 13.0, *))
                    {
                        attachmentsViewer.modalPresentationStyle = UIModalPresentationFullScreen;
                    }
                    
                    [self presentViewController:attachmentsViewer animated:YES completion:nil];
                    
                    self.attachmentsViewer = attachmentsViewer;
                }
                else
                {
                    // Let's the application do something
                    MXLogDebug(@"[MXKRoomVC] showAttachmentInCell on an unsent media");
                }
            }
            else if (selectedAttachment.type == MXKAttachmentTypeFile || selectedAttachment.type == MXKAttachmentTypeAudio)
            {
                // Start activity indicator as feedback on file selection.
                [self startActivityIndicator];
                
                [selectedAttachment prepareShare:^(NSURL *fileURL) {
                    
                    [self stopActivityIndicator];

                    MXWeakify(self);
                    void(^viewAttachment)(void) = ^() {
                        
                        MXStrongifyAndReturnIfNil(self);
                        
                        if (![self canPreviewFileAttachment:selectedAttachment withLocalFileURL:fileURL])
                        {
                            // When we don't support showing a preview for a file, show a share
                            // sheet if allowed, otherwise display an error to inform the user.
                            if (self.allowActionsInDocumentPreview)
                            {
                                UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL]
                                                                                                         applicationActivities:nil];
                                MXWeakify(self);
                                shareSheet.completionWithItemsHandler = ^(UIActivityType activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                                    MXStrongifyAndReturnIfNil(self);
                                    [selectedAttachment onShareEnded];
                                    self->currentSharedAttachment = nil;
                                };
                                
                                self->currentSharedAttachment = selectedAttachment;
                                [self presentViewController:shareSheet animated:YES completion:nil];
                            }
                            else
                            {
                                UIAlertController *alert = [UIAlertController alertControllerWithTitle:VectorL10n.attachmentUnsupportedPreviewTitle
                                                                                               message:VectorL10n.attachmentUnsupportedPreviewMessage
                                                                                        preferredStyle:UIAlertControllerStyleAlert];
                                MXWeakify(self);
                                [alert addAction:[UIAlertAction actionWithTitle:VectorL10n.ok style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                                    MXStrongifyAndReturnIfNil(self);
                                    [selectedAttachment onShareEnded];
                                    self->currentAlert = nil;
                                }]];

                                [self presentViewController:alert animated:YES completion:nil];
                                self->currentAlert = alert;
                            }
                            
                            return;
                        }

                        if (self.allowActionsInDocumentPreview)
                        {
                            // We could get rid of this part of code and use only a MXKPreviewViewController
                            // Nevertheless, MXKRoomViewController is compliant to UIDocumentInteractionControllerDelegate
                            // and remove all this code could have effect on some custom implementations.
                            self->documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
                            [self->documentInteractionController setDelegate:self];
                            self->currentSharedAttachment = selectedAttachment;

                            if (![self->documentInteractionController presentPreviewAnimated:YES])
                            {
                                if (![self->documentInteractionController presentOptionsMenuFromRect:self.view.frame inView:self.view animated:YES])
                                {
                                    self->documentInteractionController = nil;
                                    [selectedAttachment onShareEnded];
                                    self->currentSharedAttachment = nil;
                                }
                            }
                        }
                        else
                        {
                            self->currentSharedAttachment = selectedAttachment;
                            [MXKPreviewViewController presentFrom:self fileUrl:fileURL allowActions:self.allowActionsInDocumentPreview delegate:self];
                        }
                    };

                    if (self->roomDataSource.mxSession.crypto
                        && [selectedAttachment.contentInfo[@"mimetype"] isEqualToString:@"text/plain"]
                        && [MXMegolmExportEncryption isMegolmKeyFile:fileURL])
                    {
                        // The file is a megolm key file
                        // Ask the user if they wants to view the file as a classic file attachment
                        // or open an import process
                        [self->currentAlert dismissViewControllerAnimated:NO completion:nil];

                        __weak typeof(self) weakSelf = self;
                        UIAlertController *keysPrompt = [UIAlertController alertControllerWithTitle:@""
                                                                                            message:[VectorL10n attachmentE2eKeysFilePrompt]
                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                        
                        [keysPrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n view]
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction * action) {
                                                                           
                                                                           // View file content
                                                                           if (weakSelf)
                                                                           {
                                                                               typeof(self) self = weakSelf;
                                                                               self->currentAlert = nil;
                                                                               
                                                                               viewAttachment();
                                                                           }
                                                                           
                                                                       }]];
                        
                        [keysPrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n attachmentE2eKeysImport]
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction * action) {
                                                                           
                                                                           if (weakSelf)
                                                                           {
                                                                               typeof(self) self = weakSelf;
                                                                               self->currentAlert = nil;
                                                                               
                                                                               // Show the keys import dialog
                                                                               self->importView = [[MXKEncryptionKeysImportView alloc] initWithMatrixSession:self->roomDataSource.mxSession];
                                                                               self->currentAlert = self->importView.alertController;
                                                                               [self->importView showInViewController:self toImportKeys:fileURL onComplete:^{
                                                                                   
                                                                                   if (weakSelf)
                                                                                   {
                                                                                       typeof(self) self = weakSelf;
                                                                                       self->currentAlert = nil;
                                                                                       self->importView = nil;
                                                                                   }
                                                                                   
                                                                               }];
                                                                           }
                                                                           
                                                                       }]];
                        
                        [self presentViewController:keysPrompt animated:YES completion:nil];
                        self->currentAlert = keysPrompt;
                    }
                    else
                    {
                        viewAttachment();
                    }

                } failure:^(NSError *error) {
                    
                    [self stopActivityIndicator];
                    
                    // Notify MatrixKit user
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                    
                }];
                
                if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
                {
                    // Start animation in case of download
                    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
                    [roomBubbleTableViewCell startProgressUI];
                }
            }
        }
    }
}

- (BOOL)canPreviewFileAttachment:(MXKAttachment *)attachment withLocalFileURL:(NSURL *)localFileURL
{
    // Sanity check.
    if (![NSFileManager.defaultManager isReadableFileAtPath:localFileURL.path])
    {
        return NO;
    }
    
    if (UIDevice.currentDevice.systemVersion.floatValue >= 13)
    {
        return YES;
    }
    
    MXKUTI *attachmentUTI = attachment.uti;
    MXKUTI *fileUTI = [[MXKUTI alloc] initWithLocalFileURL:localFileURL];
    if (!attachmentUTI || !fileUTI)
    {
        return NO;
    }
    
    NSArray<MXKUTI *> *unsupportedUTIs = @[MXKUTI.html, MXKUTI.xml, MXKUTI.svg];
    if ([attachmentUTI conformsToAnyOf:unsupportedUTIs] || [fileUTI conformsToAnyOf:unsupportedUTIs])
    {
        return NO;
    }
    
    return YES;
}

#pragma mark - MXKAttachmentsViewControllerDelegate

- (BOOL)attachmentsViewController:(MXKAttachmentsViewController*)attachmentsViewController paginateAttachmentBefore:(NSString*)eventId
{
    [self triggerAttachmentBackPagination:eventId];
    
    return [self.roomDataSource.timeline canPaginate:MXTimelineDirectionBackwards];
}

- (void)displayedNewAttachmentWithEventId:(NSString *)eventId {
    self.closedAttachmentEventId = eventId;
}

#pragma mark - MXKRoomActivitiesViewDelegate

- (void)didChangeHeight:(MXKRoomActivitiesView *)roomActivitiesView oldHeight:(CGFloat)oldHeight newHeight:(CGFloat)newHeight
{
    // We will scroll to bottom if the bottom of the table is currently visible
    BOOL shouldScrollToBottom = [self isBubblesTableScrollViewAtTheBottom];

    // Apply height change to constraints 
    _roomActivitiesContainerHeightConstraint.constant = newHeight;
    _bubblesTableViewBottomConstraint.constant += newHeight - oldHeight;

    // Force to render the view
    [self.view layoutIfNeeded];

    if (shouldScrollToBottom)
    {
        [self scrollBubblesTableViewToBottomAnimated:YES];
    }
}

#pragma mark - MXKPreviewViewControllerDelegate

- (void)previewViewControllerDidEndPreview:(MXKPreviewViewController *)controller
{
    if (currentSharedAttachment)
    {
        [currentSharedAttachment onShareEnded];
        currentSharedAttachment = nil;
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *) controller
{
    return self;
}

// Preview presented/dismissed on document.  Use to set up any HI underneath.
- (void)documentInteractionControllerWillBeginPreview:(UIDocumentInteractionController *)controller
{
    documentInteractionController = controller;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller
{
    documentInteractionController = nil;
    if (currentSharedAttachment)
    {
        [currentSharedAttachment onShareEnded];
        currentSharedAttachment = nil;
    }
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    documentInteractionController = nil;
    if (currentSharedAttachment)
    {
        [currentSharedAttachment onShareEnded];
        currentSharedAttachment = nil;
    }
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    documentInteractionController = nil;
    if (currentSharedAttachment)
    {
        [currentSharedAttachment onShareEnded];
        currentSharedAttachment = nil;
    }
}

#pragma mark - resync management

- (void)onSyncNotification
{
    latestServerSync = [NSDate date];
    [self removeReconnectingView];
}

- (BOOL)canReconnect
{
    // avoid restarting connection if some data has been received within 1 second (1000 : latestServerSync is null)
    NSTimeInterval interval = latestServerSync ? [[NSDate date] timeIntervalSinceDate:latestServerSync] : 1000;
    return  (interval > 1) && [self.mainSession reconnect];
}

- (void)addReconnectingView
{
    if (!reconnectingView)
    {
        UIActivityIndicatorView* spinner  = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinner sizeToFit];
        spinner.hidesWhenStopped = NO;
        spinner.backgroundColor = [UIColor clearColor];
        [spinner startAnimating];
        
        // no need to manage constraints here
        // IOS defines them.
        // since IOS7 the spinner is centered so need to create a background and add it.
        _bubblesTableView.tableFooterView = reconnectingView = spinner;
    }
}

- (void)removeReconnectingView
{
    if (reconnectingView && !restartConnection)
    {
        _bubblesTableView.tableFooterView = reconnectingView = nil;
    }
}

/**
 Detect if the current connection must be restarted.
 The spinner is displayed until the overscroll ends (and scrollViewDidEndDecelerating is called).
 */
- (void)detectPullToKick:(UIScrollView *)scrollView
{
    if (roomDataSource.isLive && !reconnectingView)
    {
        // detect if the user scrolls over the tableview bottom
        restartConnection = (
                             ((scrollView.contentSize.height < scrollView.frame.size.height) && (scrollView.contentOffset.y > 128))
                             ||
                             ((scrollView.contentSize.height > scrollView.frame.size.height) &&  (scrollView.contentOffset.y + scrollView.frame.size.height) > (scrollView.contentSize.height + 128)));
        
        if (restartConnection)
        {
            // wait that list decelerate to display / hide it
            [self addReconnectingView];
        }
    }
}


/**
 Restarts the current connection if it is required.
 The 0.3s delay is added to avoid flickering if the connection does not require to be restarted.
 */
- (void)managePullToKick:(UIScrollView *)scrollView
{
    // the current connection must be restarted
    if (roomDataSource.isLive && restartConnection)
    {
        // display at least 0.3s the spinner to show to the user that something is pending
        // else the UI is flickering
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self->restartConnection = NO;
            
            if (![self canReconnect])
            {
                // if the event stream has not been restarted
                // hide the spinner
                [self removeReconnectingView];
            }
            // else wait that onSyncNotification is called.
        });
    }
}

#pragma mark - MXKSourceAttachmentAnimatorDelegate

- (UIImageView *)originalImageView {
    if ([self.openedAttachmentEventId isEqualToString:self.closedAttachmentEventId]) {
        return self.openedAttachmentImageView;
    }
    return nil;
}


- (CGRect)convertedFrameForOriginalImageView {
    if ([self.openedAttachmentEventId isEqualToString:self.closedAttachmentEventId]) {
        return [self.openedAttachmentImageView convertRect:self.openedAttachmentImageView.frame toView:nil];
    }
    //default frame which will be used if the user scrolls to other attachments in MXKAttachmentsViewController
    return CGRectMake(CGRectGetWidth(self.view.frame)/2, 0.0, 0.0, 0.0);
}

#pragma mark - Encryption key sharing

- (void)shareEncryptionKeys
{
    __block NSString *roomId = roomDataSource.roomId;
    [roomDataSource.mxSession.crypto ensureEncryptionInRoom:roomId success:^{
        MXLogDebug(@"[MXKRoomViewController] Key shared for room: %@", roomId);
    } failure:^(NSError *error) {
        MXLogDebug(@"[MXKRoomViewController] Failed to share key for room %@: %@", roomId, error);
    }];
}

@end
