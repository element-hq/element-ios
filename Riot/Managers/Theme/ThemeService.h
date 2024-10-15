/*
Copyright 2019-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
