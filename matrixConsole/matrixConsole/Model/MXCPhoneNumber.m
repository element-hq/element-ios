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

@interface MXCPhoneNumber() {
    // for search purpose
    NSString* cleanedPhonenumber;
}
@end

@implementation MXCPhoneNumber

- (id)initWithTextNumber:(NSString*)aTextNumber type:(NSString*)aType contactID:(NSString*)aContactID matrixID:(NSString*)matrixID {
    self = [super initWithContactID:aContactID matrixID:matrixID];
    
    if (self) {
        _type = aType;
        _textNumber = aTextNumber;
        cleanedPhonenumber = nil;
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
    
    if (!cleanedPhonenumber) {
        cleanedPhonenumber = [MXCPhoneNumber cleanPhonenumber:_textNumber];
    }
    
    if (patterns.count > 0) {
        for(NSString *pattern in patterns) {
            if (([_textNumber rangeOfString:pattern].location == NSNotFound) && ([cleanedPhonenumber rangeOfString:pattern].location == NSNotFound)) {
                return NO;
            }
        }
    }
    
    return YES;
}

@end