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
