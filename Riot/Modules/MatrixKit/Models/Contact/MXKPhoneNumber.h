/*
 Copyright 2015 OpenMarket Ltd
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
