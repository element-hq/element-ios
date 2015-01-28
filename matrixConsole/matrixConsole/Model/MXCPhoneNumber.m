/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "MXCPhoneNumber.h"

@interface MXCPhoneNumber ()
@property (nonatomic, readonly) NSString *cleanedPhonenumber;
@end

@implementation MXCPhoneNumber

- (id)initWithTextNumber:(NSString*)aTextNumber type:(NSString*)aType contactID:(NSString*)aContactID matrixID:(NSString*)matrixID {
    self = [super initWithContactID:aContactID matrixID:matrixID];
    
    if (self) {
        _type = aType ? aType : @"";
        _textNumber = aTextNumber ? aTextNumber : @"" ;
        _cleanedPhonenumber = [MXCPhoneNumber cleanPhonenumber:_textNumber];
        _internationalPhoneNumber = _cleanedPhonenumber;
    }
    
    return self;
}

// remove the unuseful characters in a phonenumber
+ (NSString*) cleanPhonenumber:(NSString*)phoneNumber {
    
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
        invertedPhoneCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789+*#,"] invertedSet];
    }
    
    return  [[phoneNumber componentsSeparatedByCharactersInSet:invertedPhoneCharSet] componentsJoinedByString:@""];
}


- (BOOL)matchedWithPatterns:(NSArray*)patterns {
    // no number -> cannot match
    if (_textNumber.length == 0) {
        return NO;
    }
    
    if (patterns.count > 0) {
        for(NSString *pattern in patterns) {
            if (([_textNumber rangeOfString:pattern].location == NSNotFound) && ([_cleanedPhonenumber rangeOfString:pattern].location == NSNotFound)) {
                return NO;
            }
        }
    }
    
    return YES;
}

- (void)internationalize:(NSString*)countryCode {    
    // need to plug to libphonenumber
    _internationalPhoneNumber = _cleanedPhonenumber;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self) {
        _type = [coder decodeObjectForKey:@"type"];
        _textNumber = [coder decodeObjectForKey:@"textNumber"];
        _cleanedPhonenumber = [coder decodeObjectForKey:@"cleanedPhonenumber"];
        _internationalPhoneNumber = [coder decodeObjectForKey:@"internationalPhoneNumber"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeObject:_type forKey:@"type"];
    [coder encodeObject:_textNumber forKey:@"textNumber"];
    [coder encodeObject:_cleanedPhonenumber forKey:@"cleanedPhonenumber"];
    [coder encodeObject:_internationalPhoneNumber forKey:@"internationalPhoneNumber"];
}

@end