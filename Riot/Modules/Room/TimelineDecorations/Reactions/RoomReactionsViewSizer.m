/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

#import "RoomReactionsViewSizer.h"
#import <MatrixSDK/MatrixSDK.h>

#import "GeneratedInterface-Swift.h"

@implementation RoomReactionsViewSizer

- (CGFloat)heightForViewModel:(RoomReactionsViewModel*)viewModel
                 fittingWidth:(CGFloat)fittingWidth
{
                            
    CGSize fittingSize = UILayoutFittingCompressedSize;
    fittingSize.width = fittingWidth;
    
    static RoomReactionsView *reactionsView;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reactionsView = [RoomReactionsView new];
    });
    
    reactionsView.frame = CGRectMake(0, 0, fittingWidth, 1.0);
    reactionsView.viewModel = viewModel;
    [reactionsView setNeedsLayout];
    [reactionsView layoutIfNeeded];
            
    return [reactionsView systemLayoutSizeFittingSize:fittingSize withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
}

@end
