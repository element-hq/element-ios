/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MXKSoundPlayer : NSObject

+ (instancetype)sharedInstance;

+ (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)playSoundAt:(NSURL *)url repeat:(BOOL)repeat vibrate:(BOOL)vibrate routeToBuiltInReceiver:(BOOL)useBuiltInReceiver;
- (void)stopPlayingWithAudioSessionDeactivation:(BOOL)deactivateAudioSession;

- (void)vibrateWithRepeat:(BOOL)repeat;
- (void)stopVibrating;

@end

NS_ASSUME_NONNULL_END
