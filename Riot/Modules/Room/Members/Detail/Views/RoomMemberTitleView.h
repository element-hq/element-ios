/*
 Copyright 2016 OpenMarket Ltd
 
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

#import "MatrixKit.h"

// We add here a protocol to handle title view layout update.
@class RoomMemberTitleView;
@protocol RoomMemberTitleViewDelegate <NSObject>

@optional
/**
 Tells the delegate that the layout has been updated.
 
 @param titleView the room member title view.
 */
- (void)roomMemberTitleViewDidLayoutSubview:(RoomMemberTitleView*)titleView;

@end

@interface RoomMemberTitleView : MXKView

/**
 *  Returns the `UINib` object initialized for the room member title view.
 *
 *  @return The initialized `UINib` object or `nil` if there were errors during
 *  initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `RoomMemberTitleView-inherited` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `RoomMemberTitleView-inherited` object if successful, `nil` otherwise.
 */
+ (instancetype)roomMemberTitleView;

@property (weak, nonatomic) IBOutlet UIView *memberAvatarMask;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *memberAvatarMaskCenterXConstraint;

/**
 The delegate.
 */
@property (nonatomic, weak) id<RoomMemberTitleViewDelegate> delegate;

@end
