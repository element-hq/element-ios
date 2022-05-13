/*
 Copyright 2019 New Vector Ltd
 
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 MXKMessageTextView is a UITextView subclass with link detection without text selection.
 */
@interface MXKMessageTextView : UITextView

// The last hit test location received by the view.
@property (nonatomic, readonly) CGPoint lastHitTestLocation;


/// Register a view that has been added as a pill to this text view.
/// This is needed in order to flush pills that are not always removed properly by the system.
/// All registered views will be manually removed from hierarchy on attributedText or text updates.
///
/// @param pillView pill view to register
- (void)registerPillView:(UIView *)pillView API_AVAILABLE(ios(15));

@end

NS_ASSUME_NONNULL_END
