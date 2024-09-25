/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKAttachmentAnimator.h"
#import "MXLog.h"

@interface MXKAttachmentAnimator ()

@property (nonatomic) PhotoBrowserAnimationType animationType;
@property (nonatomic, weak) UIViewController <MXKSourceAttachmentAnimatorDelegate> *sourceViewController;

@end

@implementation MXKAttachmentAnimator

#pragma mark - Lifecycle

- (instancetype)initWithAnimationType:(PhotoBrowserAnimationType)animationType sourceViewController:(UIViewController <MXKSourceAttachmentAnimatorDelegate> *)viewController
{
    self = [self init];
    if (self) {
        self.animationType = animationType;
        self.sourceViewController = viewController;
    }
    return self;
}

#pragma mark - Public

+ (CGRect)aspectFitImage:(UIImage *)image inFrame:(CGRect)targetFrame
{
    // Sanity check
    if (!image)
    {
        MXLogDebug(@"[MXKAttachmentAnimator] aspectFitImage failed: image is nil");
        return CGRectZero;
    }
    
    if (CGSizeEqualToSize(image.size, targetFrame.size))
    {
        return targetFrame;
    }
    
    CGFloat targetWidth = CGRectGetWidth(targetFrame);
    CGFloat targetHeight = CGRectGetHeight(targetFrame);
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    
    CGFloat factor = MIN(targetWidth/imageWidth, targetHeight/imageHeight);
    
    CGSize finalSize = CGSizeMake(imageWidth * factor, imageHeight * factor);
    CGRect finalFrame = CGRectMake((targetWidth - finalSize.width)/2 + targetFrame.origin.x, (targetHeight - finalSize.height)/2 + targetFrame.origin.y, finalSize.width, finalSize.height);
    
    return finalFrame;
}

#pragma mark - Animations

- (void)animateZoomInAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    //originalImageView
    UIImageView *originalImageView = [self.sourceViewController originalImageView];
    originalImageView.hidden = YES;
    CGRect convertedFrame = [self.sourceViewController convertedFrameForOriginalImageView];
    
    //toViewController
    UIViewController<MXKDestinationAttachmentAnimatorDelegate> *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    [[transitionContext containerView] addSubview:toViewController.view];
    toViewController.view.alpha = 0.0;
    
    //destinationImageView
    UIImageView *destinationImageView = [toViewController finalImageView];
    destinationImageView.hidden = YES;
    
    //transitioningImageView
    UIImageView *transitioningImageView = [[UIImageView alloc] initWithImage:originalImageView.image];
    transitioningImageView.frame = convertedFrame;
    [[transitionContext containerView] addSubview:transitioningImageView];
    CGRect finalFrameForTransitioningView = [[self class] aspectFitImage:originalImageView.image inFrame:toViewController.view.frame];
    
    
    //animation
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        toViewController.view.alpha = 1.0;
        transitioningImageView.frame = finalFrameForTransitioningView;
    } completion:^(BOOL finished) {
        [transitioningImageView removeFromSuperview];
        destinationImageView.hidden = NO;
        originalImageView.hidden = NO;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)animateZoomOutAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    //fromViewController
    UIViewController<MXKDestinationAttachmentAnimatorDelegate> *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIImageView *destinationImageView = [fromViewController finalImageView];
    destinationImageView.hidden = YES;
    
    //toViewController
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    [[transitionContext containerView] insertSubview:toViewController.view belowSubview:fromViewController.view];
    UIImageView *originalImageView = [self.sourceViewController originalImageView];
    originalImageView.hidden = YES;
    CGRect convertedFrame = [self.sourceViewController convertedFrameForOriginalImageView];
    
    //transitioningImageView
    UIImageView *transitioningImageView = [[UIImageView alloc] initWithImage:destinationImageView.image];
    transitioningImageView.frame = [[self class] aspectFitImage:destinationImageView.image inFrame:destinationImageView.frame];
    [[transitionContext containerView] addSubview:transitioningImageView];
    
    //animation
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        fromViewController.view.alpha = 0.0;
        transitioningImageView.frame = convertedFrame;
    } completion:^(BOOL finished) {
        [transitioningImageView removeFromSuperview];
        destinationImageView.hidden = NO;
        originalImageView.hidden = NO;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    switch (self.animationType) {
        case PhotoBrowserZoomInAnimation:
            [self animateZoomInAnimation:transitionContext];
            break;
            
        case PhotoBrowserZoomOutAnimation:
            [self animateZoomOutAnimation:transitionContext];
            break;
    }
}


@end
