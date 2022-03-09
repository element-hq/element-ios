/*
Copyright 2020 New Vector Ltd

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
