/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
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

@protocol Theme;

NS_ASSUME_NONNULL_BEGIN

/**
 Posted when the user interface theme has been changed.
 */
extern NSString *const kThemeServiceDidChangeThemeNotification;


/**
 `ThemeService` class manages the application design values.
 */
@interface ThemeService : NSObject

/**
 Returns the shared instance.

 @return the shared instance.
 */
+ (instancetype)shared;

/**
 The id of the theme being used.
 */
@property (nonatomic, nullable) NSString *themeId;

/**
 The current theme.
 Default value is the Default theme.
 */
@property (nonatomic, readonly) id<Theme> theme;

/**
 Get the theme with the given id.

 @param themeId the theme id.
 @return the theme.
 */
- (id<Theme>)themeWithThemeId:(NSString*)themeId;


/// Retrun YES if the current is Dark or Black
- (BOOL)isCurrentThemeDark;

#pragma mark - Riot Colors not yet themeable

@property (nonatomic, readonly) UIColor *riotColorCuriousBlue;

@end

NS_ASSUME_NONNULL_END
