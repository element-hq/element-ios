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

#import "MXKAttachmentInteractionController.h"
#import "MXLog.h"

@interface MXKAttachmentInteractionController ()

@property (nonatomic, weak) UIViewController <MXKDestinationAttachmentAnimatorDelegate> *destinationViewController;
@property (nonatomic, weak) UIViewController <MXKSourceAttachmentAnimatorDelegate> *sourceViewController;

@property (nonatomic) UIImageView *transitioningImageView;
@property (nonatomic, weak) id <UIViewControllerContextTransitioning> transitionContext;

@property (nonatomic) CGPoint translation;
@property (nonatomic) CGPoint delta;

@end

@implementation MXKAttachmentInteractionController

#pragma mark - Lifecycle

- (instancetype)initWithDestinationViewController:(UIViewController <MXKDestinationAttachmentAnimatorDelegate> *)viewController sourceViewController:(UIViewController <MXKSourceAttachmentAnimatorDelegate> *)sourceViewController
{
    self = [super init];
    if (self) {
        self.destinationViewController = viewController;
        self.sourceViewController = sourceViewController;
        self.interactionInProgress = NO;
        
        [self preparePanGestureRecognizerInView:viewController.view];
    }
    return self;
}

#pragma mark - Gesture recognizer

- (void)preparePanGestureRecognizerInView:(UIView *)view
{
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    recognizer.minimumNumberOfTouches = 1;
    recognizer.maximumNumberOfTouches = 3;
    [view addGestureRecognizer:recognizer];
}

- (void)handleGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.destinationViewController.view];
    self.delta = CGPointMake(translation.x - self.translation.x, translation.y - self.translation.y);
    self.translation = translation;
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            
            self.interactionInProgress = YES;
            
            if (self.destinationViewController.navigationController) {
                [self.destinationViewController.navigationController popViewControllerAnimated:YES];
            } else {
                [self.destinationViewController dismissViewControllerAnimated:YES completion:nil];
            }
            
            break;
            
        case UIGestureRecognizerStateChanged:
            
            [self updateInteractiveTransition:(ABS(translation.y) / (CGRectGetHeight(self.destinationViewController.view.frame) / 2))];
            
            break;
            
        case UIGestureRecognizerStateCancelled:
            
            self.interactionInProgress = NO;
            [self cancelInteractiveTransition];
            
            break;
            
        case UIGestureRecognizerStateEnded:
            
            self.interactionInProgress = NO;
            if (ABS(self.translation.y) < CGRectGetHeight(self.destinationViewController.view.frame)/6) {
                [self cancelInteractiveTransition];
            } else {
                [self finishInteractiveTransition];
            }
            
            break;
            
        default:
            MXLogDebug(@"UIGestureRecognizerState not handled");
            break;
    }
}

#pragma mark - UIPercentDrivenInteractiveTransition

- (void)startInteractiveTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionContext = transitionContext;

    [self.destinationViewController prepareSubviewsForTransition:YES];

    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIImageView *destinationImageView = [self.destinationViewController finalImageView];
    destinationImageView.hidden = YES;

    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    [[transitionContext containerView] insertSubview:toViewController.view belowSubview:fromViewController.view];
    UIImageView *originalImageView = [self.sourceViewController originalImageView];
    originalImageView.hidden = YES;
    
    self.transitioningImageView = [[UIImageView alloc] initWithImage:destinationImageView.image];
    self.transitioningImageView.frame = [MXKAttachmentAnimator aspectFitImage:destinationImageView.image inFrame:destinationImageView.frame];
    [[transitionContext containerView] addSubview:self.transitioningImageView];
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    self.destinationViewController.view.alpha = MAX(0, (1 - percentComplete));
    
    CGRect newFrame = CGRectMake(self.transitioningImageView.frame.origin.x, self.transitioningImageView.frame.origin.y + self.delta.y, CGRectGetWidth(self.transitioningImageView.frame), CGRectGetHeight(self.transitioningImageView.frame));
    self.transitioningImageView.frame = newFrame;
}

- (void)cancelInteractiveTransition {
    UIViewController *fromViewController = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIImageView *destinationImageView = [self.destinationViewController finalImageView];
    UIImageView *originalImageView = [self.sourceViewController originalImageView];

    __weak typeof(self) weakSelf = self;

    [UIView animateWithDuration:([self transitionDuration:self.transitionContext]/2) animations:^{
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            fromViewController.view.alpha = 1;
            self.transitioningImageView.frame = [MXKAttachmentAnimator aspectFitImage:destinationImageView.image inFrame:destinationImageView.frame];
        }
    } completion:^(BOOL finished) {
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            destinationImageView.hidden = NO;
            originalImageView.hidden = NO;
            [self.transitioningImageView removeFromSuperview];

            [self.transitionContext cancelInteractiveTransition];
            [self.transitionContext completeTransition:NO];

            [self.destinationViewController prepareSubviewsForTransition:NO];
        }
    }];
}

- (void)finishInteractiveTransition
{
    UIViewController *fromViewController = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIImageView *destinationImageView = [self.destinationViewController finalImageView];
    
    UIImageView *originalImageView = [self.sourceViewController originalImageView];
    CGRect originalImageViewFrame = [self.sourceViewController convertedFrameForOriginalImageView];

    __weak typeof(self) weakSelf = self;
    
    [UIView animateWithDuration:[self transitionDuration:self.transitionContext] animations:^{
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            fromViewController.view.alpha = 0.0;
            self.transitioningImageView.frame = originalImageViewFrame;
        }
    } completion:^(BOOL finished) {
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            [self.transitioningImageView removeFromSuperview];
            destinationImageView.hidden = NO;
            originalImageView.hidden = NO;

            [self.transitionContext finishInteractiveTransition];
            [self.transitionContext completeTransition:YES];
        }
    }];
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.3;
}


@end
