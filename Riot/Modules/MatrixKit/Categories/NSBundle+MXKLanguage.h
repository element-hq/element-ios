/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

@interface NSBundle (MXKLanguage)

/**
 Set the application language independently from the device language.
 
 The language can be changed at runtime but the app display must be reloaded.
 
 @param language the ISO language code. nil lets the OS choose it according to the device language
                 and languages available in the app bundle.
 */
+ (void)mxk_setLanguage:(NSString *)language;

/**
 The language set by mxk_setLanguage.

 @return the ISO language code of the current language.
 */
+ (NSString *)mxk_language;

/**
 Some strings may lack a translation in a language. 
 Use mxk_setFallbackLanguage to define a fallback language where all the 
 translation is complete.

 @param language the ISO language code.
 */
+ (void)mxk_setFallbackLanguage:(NSString*)language;

/**
 The fallback language set by mxk_setFallbackLanguage.

 @return the ISO language code of the current fallback language.
 */
+ (NSString *)mxk_fallbackLanguage;

@end
