/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PhotoBrowserAnimationType) {
    PhotoBrowserZoomInAnimation,
    PhotoBrowserZoomOutAnimation
};

@protocol MXKSourceAttachmentAnimatorDelegate <NSObject>

- (UIImageView *)originalImageView;

- (CGRect)convertedFrameForOriginalImageView;

@end

@protocol MXKDestinationAttachmentAnimatorDelegate <NSObject>

- (BOOL)prepareSubviewsForTransition:(BOOL)isStartInteraction;

- (UIImageView *)finalImageView;

@end

@interface MXKAttachmentAnimator : NSObject <UIViewControllerAnimatedTransitioning>

- (instancetype)initWithAnimationType:(PhotoBrowserAnimationType)animationType sourceViewController:(UIViewController <MXKSourceAttachmentAnimatorDelegate> *)viewController;

+ (CGRect)aspectFitImage:(UIImage *)image inFrame:(CGRect)targetFrame;

@end
