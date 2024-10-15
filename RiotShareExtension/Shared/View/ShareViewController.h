/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

@import UIKit;

@class ShareViewController;
@class ShareDataSource;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ShareViewControllerType) {
    ShareViewControllerTypeSend,
    ShareViewControllerTypeForward
};

typedef NS_ENUM(NSUInteger, ShareViewControllerAccountState) {
    ShareViewControllerAccountStateConfigured,
    ShareViewControllerAccountStateNotConfigured
};

@protocol ShareViewControllerDelegate <NSObject>

- (void)shareViewController:(ShareViewController *)shareViewController didRequestShareForRoomIdentifiers:(NSSet<NSString *> *)roomIdentifiers;
- (void)shareViewControllerDidRequestDismissal:(ShareViewController *)shareViewController;

@end

@interface ShareViewController : UIViewController

@property (nonatomic, weak, nullable) id<ShareViewControllerDelegate> delegate;

- (instancetype)initWithType:(ShareViewControllerType)type
                currentState:(ShareViewControllerAccountState)state;

- (void)configureWithState:(ShareViewControllerAccountState)state
            roomDataSource:(nullable ShareDataSource *)roomDataSource;

- (void)showProgressIndicator;

- (void)setProgress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_END
