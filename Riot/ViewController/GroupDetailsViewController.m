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

#import "AppDelegate.h"

@interface GroupDetailsViewController ()
{
    GroupHomeViewController *groupHomeViewController;
    GroupParticipantsViewController *groupParticipantsViewController;
    
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

+ (instancetype)groupDetailsViewController
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
    
    // Keep visible the status bar by default.
    isStatusBarHidden = NO;
}

- (void)viewDidLoad
{
    NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
    NSMutableArray* titles = [[NSMutableArray alloc] init];
    
    // home tab
    [titles addObject: NSLocalizedStringFromTable(@"group_details_home", @"Vector", nil)];
    groupHomeViewController = [GroupHomeViewController groupHomeViewController];
    if (_group)
    {
        [groupHomeViewController setGroup:_group withMatrixSession:_mxSession];
    }
    [viewControllers addObject:groupHomeViewController];
    
    // People tab
    [titles addObject: NSLocalizedStringFromTable(@"group_details_people", @"Vector", nil)];
    groupParticipantsViewController = [GroupParticipantsViewController groupParticipantsViewController];
    if (_group)
    {
        [groupParticipantsViewController setGroup:_group withMatrixSession:_mxSession];
    }
    [viewControllers addObject:groupParticipantsViewController];
    
    // Rooms tab
    //[titles addObject: NSLocalizedStringFromTable(@"group_details_rooms", @"Vector", nil)];
    
    self.title = NSLocalizedStringFromTable(@"group_details_title", @"Vector", nil);
    [self initWithTitles:titles viewControllers:viewControllers defaultSelected:0];
    
    [super viewDidLoad];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    // Return the current status bar visibility.
    return isStatusBarHidden;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"GroupDetails"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)destroy
{
    [super destroy];
}

- (void)setGroup:(MXGroup*)group withMatrixSession:(MXSession*)mxSession
{
    _group = group;
    _mxSession = mxSession;
    
    [self addMatrixSession:mxSession];
    
    if (groupHomeViewController)
    {
        [groupHomeViewController setGroup:group withMatrixSession:mxSession];
    }
    if (groupParticipantsViewController)
    {
        [groupParticipantsViewController setGroup:group withMatrixSession:mxSession];
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
