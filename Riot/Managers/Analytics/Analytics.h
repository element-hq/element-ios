/*
 Copyright 2018 New Vector Ltd

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

#import <MatrixSDK/MatrixSDK.h>
#import "DecryptionFailureTracker.h"

/**
 `Analytics` sends analytics to an analytics tool.
 */
@interface Analytics : NSObject <MXAnalyticsDelegate, MXDecryptionFailureDelegate>

/**
 Returns the shared Analytics manager.

 @return the shared Analytics manager.
 */
+ (instancetype)sharedInstance;

/**
 Start doing analytics if the settings `enableCrashReport` is enabled.
 */
- (void)start;

/**
 Stop doing analytics.
 */
- (void)stop;

/**
 Track a screen display.

 @param screenName the name of the displayed screen.
 */
- (void)trackScreen:(NSString*)screenName;

/**
 Flush analytics data.
 */
- (void)dispatch;

/**
 Track how long the launch screen has been displayed to the end user.

 @param seconds the duration in seconds.
 */
- (void)trackLaunchScreenDisplayDuration: (NSTimeInterval)seconds;

@end
