/*
 Copyright 2014 OpenMarket Ltd
 
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
#import <MatrixKit/MatrixKit.h>

#import "MasterTabBarController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, MXKCallViewControllerDelegate, MXKContactDetailsViewControllerDelegate, MXKRoomMemberDetailsViewControllerDelegate> {
    BOOL isAPNSRegistered;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MasterTabBarController *masterTabBarController;

@property (strong, nonatomic) MXKAlert *errorNotification;

@property (strong, nonatomic) NSString *appVersion;
@property (strong, nonatomic) NSString *build;

@property (nonatomic) BOOL isAppForeground;
@property (nonatomic) BOOL isOffline;

+ (AppDelegate*)theDelegate;

- (void)selectMatrixAccount:(void (^)(MXKAccount *selectedAccount))onSelection;

- (void)registerUserNotificationSettings;

- (void)reloadMatrixSessions:(BOOL)clearCache;

- (void)logout;

- (MXKAlert*)showErrorAsAlert:(NSError*)error;

/**
 Reopen an existing private OneToOne room with this userId or creates a new one (if it doesn't exist)
 
 @param userId 
 */
- (void)startPrivateOneToOneRoomWithUserId:(NSString*)userId;

@end

