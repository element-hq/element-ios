/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class RoomReactionsViewModel;

NS_ASSUME_NONNULL_BEGIN

// `RoomReactionsViewSizer` allows to determine reactions view height for a given viewModel and width.
@interface RoomReactionsViewSizer : NSObject

// Use Objective-C as workaround as there is an issue affecting UICollectionView sizing. See https://developer.apple.com/forums/thread/105523 for more information.
- (CGFloat)heightForViewModel:(RoomReactionsViewModel*)viewModel
                 fittingWidth:(CGFloat)fittingWidth;

@end

NS_ASSUME_NONNULL_END
