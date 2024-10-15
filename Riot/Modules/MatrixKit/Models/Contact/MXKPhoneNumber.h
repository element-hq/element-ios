/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import "MXKContactField.h"

@class NBPhoneNumber;

@interface MXKPhoneNumber : MXKContactField

/**
 The phone number information
 */
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *textNumber;
@property (nonatomic, readonly) NSString *cleanedPhonenumber;

/**
 When the number is considered to be a possible number. We expose here
 the corresponding NBPhoneNumber instance. Use the NBPhoneNumberUtil interface 
 to format this phone number, or check whether the number is actually a
 valid number.
 */
@property (nonatomic, readonly) NBPhoneNumber* nbPhoneNumber;

/**
 The default ISO 3166-1 country code used to parse the text number,
 and create the nbPhoneNumber instance.
 */
@property (nonatomic) NSString *defaultCountryCode;

/**
 The Mobile Station International Subscriber Directory Number.
 Available when the nbPhoneNumber is not nil.
 */
@property (nonatomic, readonly) NSString *msisdn;

/**
 Create a new MXKPhoneNumber instance
 
 @param textNumber the phone number
 @param type the phone number type
 @param contactID The identifier of the contact to whom the data belongs to.
 @param matrixID The linked matrix identifier if any.
 */
- (id)initWithTextNumber:(NSString*)textNumber type:(NSString*)type contactID:(NSString*)contactID matrixID:(NSString*)matrixID;

/**
 Return YES when all the provided patterns are found in the phone number or its msisdn.
 
 @param patterns an array of patterns (The potential "+" (or "00") prefix is ignored during the msisdn handling).
 */
- (BOOL)matchedWithPatterns:(NSArray*)patterns;

/**
 Tell whether the phone number or its msisdn has the provided prefix.
 
 @param prefix a non empty string (The potential "+" (or "00") prefix is ignored during the msisdn handling).
 @return YES when the phone number or its msisdn has the provided prefix.
 */
- (BOOL)hasPrefix:(NSString*)prefix;

@end
