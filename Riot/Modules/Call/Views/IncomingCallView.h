/*
 Copyright 2017 Vector Creations Ltd
 
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

typedef void (^IncomingCallViewAction)(void);
@class MXMediaManager;

@interface IncomingCallView : UIView

/**
 Size that is applied to displayed user avatar
 */
@property (class, readonly) CGSize callerAvatarSize;

/**
 Block which is performed on call answer action
 */
@property (nonatomic, nullable, copy) IncomingCallViewAction onAnswer;

/**
 Block which is performed on call reject
 */
@property (nonatomic, nullable, copy) IncomingCallViewAction onReject;

/**
 Contructors.
 
 @param mxcAvatarURI the Matrix Content URI of the caller avatar.
 @param mediaManager the media manager used to download this avatar if it is not cached yet.
 */
- (instancetype)initWithCallerAvatar:(NSString *)mxcAvatarURI
                        mediaManager:(MXMediaManager *)mediaManager
                    placeholderImage:(UIImage *)placeholderImage
                          callerName:(NSString *)callerName
                            callInfo:(NSString *)callInfo;

@end

NS_ASSUME_NONNULL_END
