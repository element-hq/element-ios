/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKPhoneNumber.h"

@import libPhoneNumber_iOS;

@implementation MXKPhoneNumber

@synthesize msisdn;

- (id)initWithTextNumber:(NSString*)textNumber type:(NSString*)type contactID:(NSString*)contactID matrixID:(NSString*)matrixID
{
    self = [super initWithContactID:contactID matrixID:matrixID];
    
    if (self)
    {
        _type = type ? type : @"";
        _textNumber = textNumber ? textNumber : @"" ;
        _cleanedPhonenumber = [MXKPhoneNumber cleanPhonenumber:_textNumber];
        _defaultCountryCode = nil;
        msisdn = nil;
        
        _nbPhoneNumber = [[NBPhoneNumberUtil sharedInstance] parse:_cleanedPhonenumber defaultRegion:nil error:nil];
    }
    
    return self;
}

// remove the unuseful characters in a phonenumber
+ (NSString*)cleanPhonenumber:(NSString*)phoneNumber
{
    // sanity check
    if (nil == phoneNumber)
    {
        return nil;
    }
    
    // empty string
    if (0 == [phoneNumber length])
    {
        return @"";
    }
    
    static NSCharacterSet *invertedPhoneCharSet = nil;
    
    if (!invertedPhoneCharSet)
    {
        invertedPhoneCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789+*#,()"] invertedSet];
    }
    
    return [[phoneNumber componentsSeparatedByCharactersInSet:invertedPhoneCharSet] componentsJoinedByString:@""];
}


- (BOOL)matchedWithPatterns:(NSArray*)patterns
{
    // no number -> cannot match
    if (_textNumber.length == 0)
    {
        return NO;
    }
    
    if (patterns.count > 0)
    {
        for (NSString *pattern in patterns)
        {
            if ([_textNumber rangeOfString:pattern].location == NSNotFound)
            {
                NSString *cleanPattern = [[pattern componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
                
                if ([_cleanedPhonenumber rangeOfString:cleanPattern].location == NSNotFound)
                {
                    NSString *msisdnPattern;
                    
                    if ([cleanPattern hasPrefix:@"+"])
                    {
                        msisdnPattern = [cleanPattern substringFromIndex:1];
                    }
                    else if ([cleanPattern hasPrefix:@"00"])
                    {
                        msisdnPattern = [cleanPattern substringFromIndex:2];
                    }
                    else
                    {
                        msisdnPattern = cleanPattern;
                    }
                    
                    // Check the msisdn
                    if (!self.msisdn || !msisdnPattern.length || [self.msisdn rangeOfString:msisdnPattern].location == NSNotFound)
                    {
                        return NO;
                    }
                }
                
            }
        }
    }
    
    return YES;
}

- (BOOL)hasPrefix:(NSString*)prefix
{
    // no number -> cannot match
    if (_textNumber.length == 0)
    {
        return NO;
    }
    
    if ([_textNumber hasPrefix:prefix])
    {
        return YES;
    }
    
    // Remove whitespace before checking the cleaned phone number
    prefix = [[prefix componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    
    if ([_cleanedPhonenumber hasPrefix:prefix])
    {
        return YES;
    }
    
    if (self.msisdn)
    {
        if ([prefix hasPrefix:@"+"])
        {
            prefix = [prefix substringFromIndex:1];
        }
        else if ([prefix hasPrefix:@"00"])
        {
            prefix = [prefix substringFromIndex:2];
        }
        
        return [self.msisdn hasPrefix:prefix];
    }
    
    return NO;
}

- (void)setDefaultCountryCode:(NSString *)defaultCountryCode
{
    if (![defaultCountryCode isEqualToString:_defaultCountryCode])
    {
        _nbPhoneNumber = [[NBPhoneNumberUtil sharedInstance] parse:_cleanedPhonenumber defaultRegion:defaultCountryCode error:nil];
        
        _defaultCountryCode = defaultCountryCode;
        msisdn = nil;
    }
}

- (NSString*)msisdn
{
    if (!msisdn && _nbPhoneNumber)
    {
        NSString *e164 = [[NBPhoneNumberUtil sharedInstance] format:_nbPhoneNumber numberFormat:NBEPhoneNumberFormatE164 error:nil];
        if ([e164 hasPrefix:@"+"])
        {
            msisdn = [e164 substringFromIndex:1];
        }
        else if ([e164 hasPrefix:@"00"])
        {
            msisdn = [e164 substringFromIndex:2];
        }
    }
    return msisdn;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self)
    {
        _type = [coder decodeObjectForKey:@"type"];
        _textNumber = [coder decodeObjectForKey:@"textNumber"];
        _cleanedPhonenumber = [coder decodeObjectForKey:@"cleanedPhonenumber"];
        _defaultCountryCode = [coder decodeObjectForKey:@"countryCode"];
        
        _nbPhoneNumber = [[NBPhoneNumberUtil sharedInstance] parse:_cleanedPhonenumber defaultRegion:_defaultCountryCode error:nil];
        msisdn = nil;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:_type forKey:@"type"];
    [coder encodeObject:_textNumber forKey:@"textNumber"];
    [coder encodeObject:_cleanedPhonenumber forKey:@"cleanedPhonenumber"];
    [coder encodeObject:_defaultCountryCode forKey:@"countryCode"];
}

@end
