// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 The Matrix.org Foundation C.I.C
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import "MXKActivityHandlingViewController.h"

@interface MXKActivityHandlingViewController ()

@end

@implementation MXKActivityHandlingViewController
@synthesize activityIndicator;

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self providesCustomActivityIndicator]) {
        // If a subclass provides custom activity indicator, the default one will not even be initialized.
        return;
    }
    
    // Add default activity indicator
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityIndicator.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    activityIndicator.hidesWhenStopped = YES;
    
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

#pragma mark - Activity indicator

- (BOOL)providesCustomActivityIndicator {
    return NO;
}

- (void)startActivityIndicator
{
    if (activityIndicator && ![self providesCustomActivityIndicator])
    {
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

- (BOOL)canStopActivityIndicator {
    return YES;
}

- (void)stopActivityIndicator
{
    if ([self canStopActivityIndicator]) {
        [activityIndicator stopAnimating];
    }
}

@end
