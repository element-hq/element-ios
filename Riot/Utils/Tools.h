/*
 Copyright 2016 OpenMarket Ltd

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

@interface Tools : NSObject

/**
 Compute the text to display user's presence
 
 @param user the user. Can be nil.
 @return the string to display.
 */
+ (NSString*)presenceText:(MXUser*)user;

#pragma mark - Universal link

/**
 Detect if a URL is a universal link for the application.

 @return YES if the URL can be handled by the app.
 */
+ (BOOL)isUniversalLink:(NSURL*)url;

/**
 Fix a http://vector.im or http://vector.im path url.

 This method fixes the issue with iOS which handles URL badly when there are several hash
 keys ('%23') in the link.
 Vector.im links have often several hash keys...

 @param url a NSURL with possibly several hash keys and thus badly parsed.
 @return a NSURL correctly parsed.
 */
+ (NSURL*)fixURLWithSeveralHashKeys:(NSURL*)url;

@end
