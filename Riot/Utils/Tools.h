/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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

#pragma mark - Time utilities

/**
 * Convert a number of days to a duration in ms.
 */
+ (uint64_t)durationInMsFromDays:(uint)days;

@end
