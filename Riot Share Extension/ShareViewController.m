/*
 Copyright 2017 Aram Sargsyan
 
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

#import "ShareViewController.h"
#import "RoomTableViewCell.h"
#import "RoomsListViewController.h"
#import "SegmentedViewController.h"


@interface ShareViewController ()

@property (nonatomic) NSArray <MXRoom *> *rooms;

@property (weak, nonatomic) IBOutlet UIView *masterContainerView;
@property (weak, nonatomic) IBOutlet UILabel *tittleLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic) SegmentedViewController *segmentedViewController;


@end


@implementation ShareViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self prepareSession];
    [self configureViews];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSessionSync:) name:kMXSessionDidSyncNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private

- (void)prepareSession
{
    // Prepare account manager
    MXKAccountManager *accountManager = [MXKAccountManager sharedManager];
    
    // Use MXFileStore as MXStore to permanently store events.
    accountManager.storeClass = [MXFileStore class];
    
    // Start a matrix session for each enabled accounts.
    NSLog(@"[AppDelegate] initMatrixSessions: prepareSessionForActiveAccounts");
    [accountManager prepareSessionForActiveAccounts];
    
    // Resume all existing matrix sessions
    NSArray *mxAccounts = accountManager.activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account resume];
        [self addMatrixSession:account.mxSession];
    }
}

- (void)configureViews
{
    self.masterContainerView.layer.cornerRadius = 7;
    self.tittleLabel.text = @"Send to";
    
    self.segmentedViewController = [SegmentedViewController segmentedViewController];
    NSArray *titles = @[NSLocalizedStringFromTable(@"title_rooms", @"Vector", nil) , NSLocalizedStringFromTable(@"title_people", @"Vector", nil)];
    NSArray *viewControllers = @[[RoomsListViewController listViewControllerWithContext:self.shareExtensionContext], [RoomsListViewController listViewControllerWithContext:self.shareExtensionContext]];
    [self.segmentedViewController initWithTitles:titles viewControllers:viewControllers defaultSelected:0];
    
    [self addChildViewController:self.segmentedViewController];
    [self.contentView addSubview:self.segmentedViewController.view];
    [self.segmentedViewController didMoveToParentViewController:self];
    
    self.segmentedViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.segmentedViewController.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    widthConstraint.active = YES;
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.segmentedViewController.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    heightConstraint.active = YES;
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self.segmentedViewController.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    centerXConstraint.active = YES;
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:self.segmentedViewController.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    centerYConstraint.active = YES;
}

- (void)cancelSharing
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSError *error = [NSError errorWithDomain:@"MXUserCancelErrorDomain" code:4201 userInfo:nil];
        [self.shareExtensionContext cancelRequestWithError:error];
    }];
}

#pragma mark - Notifications

- (void)onSessionSync:(NSNotification *)notification
{
    if ([notification.object isEqual:self.mainSession] && !self.rooms.count)
    {
        self.rooms = self.mainSession.rooms;
        if (self.rooms.count)
        {
            
            NSMutableArray *directRooms = [NSMutableArray array];
            NSMutableArray *rooms = [NSMutableArray array];
            for (MXRoom *room in self.rooms)
            {
                if (room.isDirect)
                {
                    [directRooms addObject:room];
                }
                else
                {
                    [rooms addObject:room];
                }
            }
            
            [((RoomsListViewController *)self.segmentedViewController.viewControllers[0]) updateWithRooms:rooms];
            [((RoomsListViewController *)self.segmentedViewController.viewControllers[1]) updateWithRooms:directRooms];
        }
    }
}

#pragma mark - Actions

- (IBAction)close:(UIButton *)sender
{
    [self cancelSharing];
}

/*#pragma mark - SLComposeServiceViewController

- (BOOL)isContentValid
{
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

- (void)didSelectPost
{
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (NSArray *)configurationItems
{
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}*/

@end
