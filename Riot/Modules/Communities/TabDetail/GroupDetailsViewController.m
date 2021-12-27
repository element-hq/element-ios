/*
 Copyright 2017 Vector Creations Ltd
 
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

#import "GroupDetailsViewController.h"

#import "GroupHomeViewController.h"
#import "GroupParticipantsViewController.h"
#import "GroupRoomsViewController.h"

#import "GeneratedInterface-Swift.h"

@interface GroupDetailsViewController ()
{
    GroupHomeViewController *groupHomeViewController;
    GroupParticipantsViewController *groupParticipantsViewController;
    GroupRoomsViewController *groupRoomsViewController;
    
    /**
     mask view while processing a request
     */
    UIActivityIndicatorView * pendingMaskSpinnerView;
    
    /**
     Current alert (if any).
     */
    UIAlertController *currentAlert;
    
    /**
     The current visibility of the status bar in this view controller.
     */
    BOOL isStatusBarHidden;
}
@end

@implementation GroupDetailsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)instantiate
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                          bundle:[NSBundle bundleForClass:self.class]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.sectionHeaderTintColor = ThemeService.shared.theme.tintColor;
    
    // Keep visible the status bar by default.
    isStatusBarHidden = NO;
}

- (void)viewDidLoad
{
    NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
    NSMutableArray* titles = [[NSMutableArray alloc] init];
    
    // home tab
    [titles addObject:[VectorL10n groupDetailsHome]];
    groupHomeViewController = [GroupHomeViewController groupHomeViewController];
    if (_group)
    {
        [groupHomeViewController setGroup:_group withMatrixSession:_mxSession];
    }
    [viewControllers addObject:groupHomeViewController];
    
    // People tab
    [titles addObject:[VectorL10n groupDetailsPeople]];
    groupParticipantsViewController = [GroupParticipantsViewController groupParticipantsViewController];
    if (_group)
    {
        [groupParticipantsViewController setGroup:_group withMatrixSession:_mxSession];
    }
    [viewControllers addObject:groupParticipantsViewController];
    
    // Rooms tab
    [titles addObject:[VectorL10n groupDetailsRooms]];
    groupRoomsViewController = [GroupRoomsViewController groupRoomsViewController];
    if (_group)
    {
        [groupRoomsViewController setGroup:_group withMatrixSession:_mxSession];
    }
    [viewControllers addObject:groupRoomsViewController];
    
    if (!self.title.length)
    {
        self.title = [VectorL10n groupDetailsTitle];
    }
    
    [self initWithTitles:titles viewControllers:viewControllers defaultSelected:0];
    
    [super viewDidLoad];
    
    // Display leftBarButtonItems or leftBarButtonItem to the right of the Back button
    self.navigationItem.leftItemsSupplementBackButton = YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    // Return the current status bar visibility.
    return isStatusBarHidden;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)setGroup:(MXGroup*)group withMatrixSession:(MXSession*)mxSession
{
    _group = group;
    _mxSession = mxSession;
    
    self.title = group.summary.profile.name.length ? group.summary.profile.name : group.groupId;
    
    [self addMatrixSession:mxSession];
    
    if (groupHomeViewController)
    {
        [groupHomeViewController setGroup:group withMatrixSession:mxSession];
    }
    if (groupParticipantsViewController)
    {
        [groupParticipantsViewController setGroup:group withMatrixSession:mxSession];
    }
    if (groupRoomsViewController)
    {
        [groupRoomsViewController setGroup:group withMatrixSession:mxSession];
    }
}

- (void)withdrawViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    [super withdrawViewControllerAnimated:animated completion:completion];
    
    // Fill the secondary navigation view controller of the split view controller if it is empty.
    UINavigationController *secondaryNavigationController = [AppDelegate theDelegate].secondaryNavigationController;
    if (secondaryNavigationController && !secondaryNavigationController.viewControllers.count)
    {
        [[AppDelegate theDelegate] restoreEmptyDetailsViewController];
    }
}

@end
