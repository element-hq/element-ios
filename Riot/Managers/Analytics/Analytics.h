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


// Metrics related to notifications
FOUNDATION_EXPORT NSString *const AnalyticsNoficationsCategory;
FOUNDATION_EXPORT NSString *const AnalyticsNoficationsTimeToDisplayContent;


/**
 `Analytics` sends analytics to an analytics tool.
 */
@interface Analytics : NSObject <MXAnalyticsDelegate>

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

@end
