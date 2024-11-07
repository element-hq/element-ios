/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
