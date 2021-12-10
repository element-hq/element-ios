/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2018 New Vector Ltd
 
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

#import "MXKTableViewController.h"

#import "UIViewController+MatrixKit.h"
#import "MXSession+MatrixKit.h"

@interface MXKTableViewController ()
{
    /**
     Array of `MXSession` instances.
     */
    NSMutableArray *mxSessionArray;
    
    /**
     Keep reference on the pushed view controllers to release them correctly
     */
    NSMutableArray *childViewControllers;
}
@end

@implementation MXKTableViewController
@synthesize defaultBarTintColor, enableBarTintColorStatusChange;
@synthesize barTitleColor;
@synthesize mainSession;
@synthesize activityIndicator, rageShakeManager;
@synthesize childViewControllers;

#pragma mark -

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self finalizeInit];
    }
    
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self finalizeInit];
    }
    
    return self;
}

- (void)finalizeInit
{
    // Set default properties values
    defaultBarTintColor = nil;
    barTitleColor = nil;
    enableBarTintColorStatusChange = YES;
    rageShakeManager = nil;
    
    mxSessionArray = [NSMutableArray array];
    childViewControllers = [NSMutableArray array];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Add default activity indicator
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityIndicator.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGRect frame = activityIndicator.frame;
    frame.size.width += 30;
    frame.size.height += 30;
    activityIndicator.bounds = frame;
    [activityIndicator.layer setCornerRadius:5];
    
    activityIndicator.center = self.view.center;
    [self.view addSubview:activityIndicator];
}

- (void)dealloc
{
    if (activityIndicator)
    {
        [activityIndicator removeFromSuperview];
        activityIndicator = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.rageShakeManager)
    {
        [self.rageShakeManager cancel:self];
    }
    
    // Update UI according to mxSession state, and add observer (if need)
    if (mxSessionArray.count)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatrixSessionStateDidChange:) name:kMXSessionStateDidChangeNotification object:nil];
    }
    [self onMatrixSessionChange];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionStateDidChangeNotification object:nil];
    
    [activityIndicator stopAnimating];
    
    if (self.rageShakeManager)
    {
        [self.rageShakeManager cancel:self];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    MXLogDebug(@"[MXKTableViewController] %@ viewDidAppear", self.class);

    // Release properly pushed and/or presented view controller
    if (childViewControllers.count)
    {
        for (id viewController in childViewControllers)
        {
            if ([viewController isKindOfClass:[UINavigationController class]])
            {
                UINavigationController *navigationController = (UINavigationController*)viewController;
                for (id subViewController in navigationController.viewControllers)
                {
                    if ([subViewController respondsToSelector:@selector(destroy)])
                    {
                        [subViewController destroy];
                    }
                }
            }
            else if ([viewController respondsToSelector:@selector(destroy)])
            {
                [viewController destroy];
            }
        }
        
        [childViewControllers removeAllObjects];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    MXLogDebug(@"[MXKTableViewController] %@ viewDidDisappear", self.class);
}

- (void)setEnableBarTintColorStatusChange:(BOOL)enable
{
    if (enableBarTintColorStatusChange != enable)
    {
        enableBarTintColorStatusChange = enable;
        
        [self onMatrixSessionChange];
    }
}

- (void)setDefaultBarTintColor:(UIColor *)barTintColor
{
    defaultBarTintColor = barTintColor;
    
    if (enableBarTintColorStatusChange)
    {
        // Force update by taking into account the matrix session state.
        [self onMatrixSessionChange];
    }
    else
    {
        // Set default tintColor
        self.navigationController.navigationBar.barTintColor = defaultBarTintColor;
        self.mxk_mainNavigationController.navigationBar.barTintColor = defaultBarTintColor;
    }
}

- (void)setBarTitleColor:(UIColor *)titleColor
{
    barTitleColor = titleColor;
    
    // Retrieve the main navigation controller if the current view controller is embedded inside a split view controller.
    UINavigationController *mainNavigationController = self.mxk_mainNavigationController;
    
    // Set navigation bar title color
    NSDictionary<NSString *,id> *titleTextAttributes = self.navigationController.navigationBar.titleTextAttributes;
    if (titleTextAttributes)
    {
        NSMutableDictionary *textAttributes = [NSMutableDictionary dictionaryWithDictionary:titleTextAttributes];
        textAttributes[NSForegroundColorAttributeName] = barTitleColor;
        self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    }
    else if (barTitleColor)
    {
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: barTitleColor};
    }
    
    if (mainNavigationController)
    {
        titleTextAttributes = mainNavigationController.navigationBar.titleTextAttributes;
        if (titleTextAttributes)
        {
            NSMutableDictionary *textAttributes = [NSMutableDictionary dictionaryWithDictionary:titleTextAttributes];
            textAttributes[NSForegroundColorAttributeName] = barTitleColor;
            mainNavigationController.navigationBar.titleTextAttributes = textAttributes;
        }
        else if (barTitleColor)
        {
            mainNavigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: barTitleColor};
        }
    }
}

- (void)setView:(UIView *)view
{
    [super setView:view];
    
    // Keep the activity indicator (if any)
    if (view && activityIndicator)
    {
        [self.view addSubview:activityIndicator];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [childViewControllers addObject:segue.destinationViewController];
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    // Keep ref on presented view controller
    [childViewControllers addObject:viewControllerToPresent];
    
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

#pragma mark -

- (void)addMatrixSession:(MXSession*)mxSession
{
    if (!mxSession || mxSession.state == MXSessionStateClosed)
    {
        return;
    }
    
    if (!mxSessionArray.count)
    {
        [mxSessionArray addObject:mxSession];
        
        // Add matrix sessions observer on first added session
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatrixSessionStateDidChange:) name:kMXSessionStateDidChangeNotification object:nil];
    }
    else if ([mxSessionArray indexOfObject:mxSession] == NSNotFound)
    {
        [mxSessionArray addObject:mxSession];
    }
    
    // Force update
    [self onMatrixSessionChange];
}

- (void)removeMatrixSession:(MXSession*)mxSession
{
    if (!mxSession)
    {
        return;
    }
    
    NSUInteger index = [mxSessionArray indexOfObject:mxSession];
    if (index != NSNotFound)
    {
        [mxSessionArray removeObjectAtIndex:index];
        
        if (!mxSessionArray.count)
        {
            // Remove matrix sessions observer
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionStateDidChangeNotification object:nil];
        }
    }
    
    // Force update
    [self onMatrixSessionChange];
}

- (NSArray*)mxSessions
{
    return [NSArray arrayWithArray:mxSessionArray];
}

- (MXSession*)mainSession
{
    // We consider the first added session as the main one.
    if (mxSessionArray.count)
    {
        return [mxSessionArray firstObject];
    }
    return nil;
}

#pragma mark -

- (void)withdrawViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    // Check whether the view controller is embedded inside a navigation controller.
    if (self.navigationController)
    {
        [self popViewController:self navigationController:self.navigationController animated:animated completion:completion];
    }
    else
    {
        // Suppose here the view controller has been presented modally. We dismiss it
        [self dismissViewControllerAnimated:animated completion:completion];
    }
}

- (void)popViewController:(UIViewController*)viewController navigationController:(UINavigationController*)navigationController animated:(BOOL)animated completion:(void (^)(void))completion
{
    // We pop the view controller (except if it is the root view controller).
    NSUInteger index = [navigationController.viewControllers indexOfObject:viewController];
    if (index != NSNotFound)
    {
        if (index > 0)
        {
            UIViewController *previousViewController = [navigationController.viewControllers objectAtIndex:(index - 1)];
            [navigationController popToViewController:previousViewController animated:animated];
            
            if (completion)
            {
                completion();
            }
        }
        else
        {
            // Check whether the navigation controller is embedded inside a navigation controller, to pop it.
            if (navigationController.navigationController)
            {
                [self popViewController:navigationController navigationController:navigationController.navigationController animated:animated completion:completion];
            }
            else
            {
                // Remove the root view controller
                navigationController.viewControllers = @[];
                // Suppose here the navigation controller has been presented modally. We dismiss it
                [navigationController dismissViewControllerAnimated:animated completion:completion];
            }
        }
    }
}

- (void)destroy
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    mxSessionArray = nil;
    childViewControllers = nil;
}

#pragma mark - Sessions handling

- (void)onMatrixSessionStateDidChange:(NSNotification *)notif
{
    MXSession *mxSession = notif.object;
    
    NSUInteger index = [mxSessionArray indexOfObject:mxSession];
    if (index != NSNotFound)
    {
        if (mxSession.state == MXSessionStateClosed)
        {
            // Call here the dedicated method which may be overridden
            [self removeMatrixSession:mxSession];
        }
        else
        {
            [self onMatrixSessionChange];
        }
    }
}

- (void)onMatrixSessionChange
{
    // This method is called to refresh view controller appearance on session state change,
    // It is called when the view will appear to update session array by removing closed sessions.
    // Indeed 'kMXSessionStateDidChangeNotification' are observed only when the view controller is visible.
    
    // Retrieve the main navigation controller if the current view controller is embedded inside a split view controller.
    UINavigationController *mainNavigationController = self.mxk_mainNavigationController;
    
    if (mxSessionArray.count)
    {
        // Check each session state
        UIColor *barTintColor = defaultBarTintColor;
        BOOL allHomeserverNotReachable = YES;
        BOOL isActivityInProgress = NO;
        for (NSUInteger index = 0; index < mxSessionArray.count;)
        {
            MXSession *mxSession = mxSessionArray[index];
            
            // Remove here closed sessions
            if (mxSession.state == MXSessionStateClosed)
            {
                // Call here the dedicated method which may be overridden.
                // This method will call again [onMatrixSessionChange] when session is removed.
                [self removeMatrixSession:mxSession];
                return;
            }
            else
            {
                if (mxSession.state == MXSessionStateHomeserverNotReachable)
                {
                    barTintColor = [UIColor orangeColor];
                }
                else
                {
                    allHomeserverNotReachable = NO;
                    isActivityInProgress = mxSession.shouldShowActivityIndicator;
                }
                
                index ++;
            }
        }
        
        // Check whether the navigation bar color depends on homeserver reachability.
        if (enableBarTintColorStatusChange)
        {
            // The navigation bar tintColor reflects the matrix homeserver reachability status.
            if (allHomeserverNotReachable)
            {
                self.navigationController.navigationBar.barTintColor = [UIColor redColor];
                if (mainNavigationController)
                {
                    mainNavigationController.navigationBar.barTintColor = [UIColor redColor];
                }
            }
            else
            {
                self.navigationController.navigationBar.barTintColor = barTintColor;
                if (mainNavigationController)
                {
                    mainNavigationController.navigationBar.barTintColor = barTintColor;
                }
            }
        }
        
        // Run activity indicator if need
        if (isActivityInProgress)
        {
            [self startActivityIndicator];
        }
        else
        {
            [self stopActivityIndicator];
        }
    }
    else
    {
        // Hide potential activity indicator
        [self stopActivityIndicator];
        
        // Check whether the navigation bar color depends on homeserver reachability.
        if (enableBarTintColorStatusChange)
        {
            // Restore default tintColor
            self.navigationController.navigationBar.barTintColor = defaultBarTintColor;
            if (mainNavigationController)
            {
                mainNavigationController.navigationBar.barTintColor = defaultBarTintColor;
            }
        }
    }
}

#pragma mark - Activity indicator

- (void)startActivityIndicator
{
    if (activityIndicator)
    {
        // Keep centering the loading wheel
        CGPoint center = self.view.center;
        center.y +=  self.tableView.contentOffset.y - self.tableView.adjustedContentInset.top;
        activityIndicator.center = center;
        [self.view bringSubviewToFront:activityIndicator];
        
        [activityIndicator startAnimating];
        
        // Show the loading wheel after a delay so that if the caller calls stopActivityIndicator
        // in a short future, the loading wheel will not be displayed to the end user.
        activityIndicator.alpha = 0;
        [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self->activityIndicator.alpha = 1;
        } completion:^(BOOL finished)
         {
         }];
    }
}

- (void)stopActivityIndicator
{
    // Check whether all conditions are satisfied before stopping loading wheel
    BOOL isActivityInProgress = NO;
    for (MXSession *mxSession in mxSessionArray)
    {
        if (mxSession.shouldShowActivityIndicator)
        {
            isActivityInProgress = YES;
        }
    }
    if (!isActivityInProgress)
    {
        [activityIndicator stopAnimating];
    }
}

#pragma mark - Shake handling

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake && self.rageShakeManager)
    {
        [self.rageShakeManager startShaking:self];
    }
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    [self motionEnded:motion withEvent:event];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (self.rageShakeManager)
    {
        [self.rageShakeManager stopShaking:self];
    }
}

- (BOOL)canBecomeFirstResponder
{
    return (self.rageShakeManager != nil);
}


@end
