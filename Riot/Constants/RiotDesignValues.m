/*
 Copyright 2016 OpenMarket Ltd
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

#import "RiotDesignValues.h"

#ifdef IS_SHARE_EXTENSION
#import "RiotShareExtension-Swift.h"
#else
#import "Riot-Swift.h"
#endif


NSString *const kRiotDesignValuesDidChangeThemeNotification = @"kRiotDesignValuesDidChangeThemeNotification";

UIColor *kRiotPrimaryBgColor;
UIColor *kRiotSecondaryBgColor;
UIColor *kRiotPrimaryTextColor;
UIColor *kRiotSecondaryTextColor;
UIColor *kRiotPlaceholderTextColor;
UIColor *kRiotTopicTextColor;
UIColor *kRiotSelectedBgColor;
UIColor *kRiotAuxiliaryColor;
UIColor *kRiotOverlayColor;
UIColor *kRiotKeyboardColor;

// Riot Colors
UIColor *kRiotColorGreen;
UIColor *kRiotColorLightGreen;
UIColor *kRiotColorLightOrange;
UIColor *kRiotColorSilver;
UIColor *kRiotColorPinkRed;
UIColor *kRiotColorRed;
UIColor *kRiotColorIndigo;
UIColor *kRiotColorOrange;
UIColor *kRiotColorBlue;

// Riot Background Colors
UIColor *kRiotBgColorWhite;
UIColor *kRiotBgColorBlack;
UIColor *kRiotBgColorOLEDBlack;
UIColor *kRiotColorLightGrey;
UIColor *kRiotColorLightBlack;
UIColor *kRiotColorLightKeyboard;
UIColor *kRiotColorDarkKeyboard;

// Riot Text Colors
UIColor *kRiotTextColorBlack;
UIColor *kRiotTextColorDarkGray;
UIColor *kRiotTextColorGray;
UIColor *kRiotTextColorWhite;
UIColor *kRiotTextColorDarkWhite;

NSInteger const kRiotRoomModeratorLevel = 50;
NSInteger const kRiotRoomAdminLevel = 100;

UIStatusBarStyle kRiotDesignStatusBarStyle = UIStatusBarStyleDefault;
UIBarStyle kRiotDesignSearchBarStyle = UIBarStyleDefault;
UIColor *kRiotDesignSearchBarTintColor = nil;

UIKeyboardAppearance kRiotKeyboard;

@implementation RiotDesignValues

+ (RiotDesignValues *)sharedInstance
{
    static RiotDesignValues *sharedOnceInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedOnceInstance = [[RiotDesignValues alloc] init];
    });
    
    return sharedOnceInstance;
}

+ (void)load
{
    [super load];

    // Load colors at the app load time for the life of the app

    // Colors as defined by the design
    kRiotColorGreen = UIColorFromRGB(0x62CE9C);
    kRiotColorSilver = UIColorFromRGB(0xC7C7CC);
    kRiotColorPinkRed = UIColorFromRGB(0xFF0064);
    kRiotColorRed = UIColorFromRGB(0xFF4444);
    kRiotColorIndigo = UIColorFromRGB(0xBD79CC);
    kRiotColorOrange = UIColorFromRGB(0xF8A15F);
    kRiotColorBlue = UIColorFromRGB(0x81BDDB);
    
    kRiotBgColorWhite = [UIColor whiteColor];
    kRiotBgColorBlack = UIColorFromRGB(0x2D2D2D);
    kRiotBgColorOLEDBlack = [UIColor blackColor];
    
    kRiotColorLightGrey = UIColorFromRGB(0xF2F2F2);
    kRiotColorLightBlack = UIColorFromRGB(0x353535);
    
    kRiotColorLightKeyboard = UIColorFromRGB(0xE7E7E7);
    kRiotColorDarkKeyboard = UIColorFromRGB(0x7E7E7E);

    kRiotTextColorBlack = UIColorFromRGB(0x3C3C3C);
    kRiotTextColorDarkGray = UIColorFromRGB(0x4A4A4A);
    kRiotTextColorGray = UIColorFromRGB(0x9D9D9D);
    kRiotTextColorWhite = UIColorFromRGB(0xDDDDDD);
    kRiotTextColorDarkWhite = UIColorFromRGB(0xD9D9D9);

    // Colors copied from Vector web
    kRiotColorLightGreen = UIColorFromRGB(0x50e2c2);
    kRiotColorLightOrange = UIColorFromRGB(0xf4c371);

    // Observe user interface theme change.
    [[NSUserDefaults standardUserDefaults] addObserver:[RiotDesignValues sharedInstance] forKeyPath:@"userInterfaceTheme" options:0 context:nil];
    [[RiotDesignValues sharedInstance] userInterfaceThemeDidChange];

    // Observe "Invert Colours" settings changes (available since iOS 11)
    [[NSNotificationCenter defaultCenter] addObserver:[RiotDesignValues sharedInstance] selector:@selector(accessibilityInvertColorsStatusDidChange) name:UIAccessibilityInvertColorsStatusDidChangeNotification object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"userInterfaceTheme" isEqualToString:keyPath])
    {
        [self userInterfaceThemeDidChange];
    }
}

- (void)accessibilityInvertColorsStatusDidChange
{
    // Refresh the theme only for "auto"
    NSString *theme = RiotSettings.shared.userInterfaceTheme;
    if (!theme || [theme isEqualToString:@"auto"])
    {
        [self userInterfaceThemeDidChange];
    }
}

- (void)userInterfaceThemeDidChange
{
    // Retrieve the current selected theme ("light" if none. "auto" is used as default from iOS 11).
    NSString *theme = RiotSettings.shared.userInterfaceTheme;

    if (!theme || [theme isEqualToString:@"auto"])
    {
        theme = UIAccessibilityIsInvertColorsEnabled() ? @"dark" : @"light";
    }
    
    if ([theme isEqualToString:@"dark"])
    {
        // Set dark theme colors
        kRiotPrimaryBgColor = kRiotBgColorBlack;
        kRiotSecondaryBgColor = kRiotColorLightBlack;
        kRiotPrimaryTextColor = kRiotTextColorWhite;
        kRiotSecondaryTextColor = kRiotTextColorGray;
        kRiotPlaceholderTextColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        kRiotTopicTextColor = kRiotTextColorDarkWhite;
        kRiotSelectedBgColor = [UIColor blackColor];
        
        kRiotDesignStatusBarStyle = UIStatusBarStyleLightContent;
        kRiotDesignSearchBarStyle = UIBarStyleBlack;
        kRiotDesignSearchBarTintColor = kRiotColorGreen;
        
        kRiotAuxiliaryColor = kRiotTextColorGray;
        kRiotOverlayColor = [UIColor colorWithWhite:0.3 alpha:0.5];
        kRiotKeyboardColor = kRiotColorDarkKeyboard;
        
        [UITextField appearance].keyboardAppearance = UIKeyboardAppearanceDark;
        kRiotKeyboard = UIKeyboardAppearanceDark;
    }
    else if ([theme isEqualToString:@"black"])
    {
        // Set black theme colors
        kRiotPrimaryBgColor = kRiotBgColorOLEDBlack;
        kRiotSecondaryBgColor = kRiotColorLightBlack;
        kRiotPrimaryTextColor = kRiotTextColorWhite;
        kRiotSecondaryTextColor = kRiotTextColorGray;
        kRiotPlaceholderTextColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        kRiotTopicTextColor = kRiotTextColorDarkWhite;
        kRiotSelectedBgColor = [UIColor blackColor];
        
        kRiotDesignStatusBarStyle = UIStatusBarStyleLightContent;
        kRiotDesignSearchBarStyle = UIBarStyleBlack;
        kRiotDesignSearchBarTintColor = kRiotColorGreen;
        
        kRiotAuxiliaryColor = kRiotTextColorGray;
        kRiotOverlayColor = [UIColor colorWithWhite:0.3 alpha:0.5];
        kRiotKeyboardColor = kRiotColorDarkKeyboard;
        
        [UITextField appearance].keyboardAppearance = UIKeyboardAppearanceDark;
        kRiotKeyboard = UIKeyboardAppearanceDark;
    }
    else
    {
        // Set light theme colors by default.
        kRiotPrimaryBgColor = kRiotBgColorWhite;
        kRiotSecondaryBgColor = kRiotColorLightGrey;
        kRiotPrimaryTextColor = kRiotTextColorBlack;
        kRiotSecondaryTextColor = kRiotTextColorGray;
        kRiotPlaceholderTextColor = nil; // Use default 70% gray color.
        kRiotTopicTextColor = kRiotTextColorDarkGray;
        kRiotSelectedBgColor = nil; // Use the default selection color.
        
        kRiotDesignStatusBarStyle = UIStatusBarStyleDefault;
        kRiotDesignSearchBarStyle = UIBarStyleDefault;
        kRiotDesignSearchBarTintColor = nil; // Default tint color.
        
        kRiotAuxiliaryColor = kRiotColorSilver;
        kRiotOverlayColor = [UIColor colorWithWhite:0.7 alpha:0.5];
        kRiotKeyboardColor = kRiotColorLightKeyboard;
                
        [UITextField appearance].keyboardAppearance = UIKeyboardAppearanceLight;
        kRiotKeyboard = UIKeyboardAppearanceLight;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kRiotDesignValuesDidChangeThemeNotification object:nil];
}

@end
