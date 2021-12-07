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
