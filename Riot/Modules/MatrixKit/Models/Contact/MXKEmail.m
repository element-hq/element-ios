/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2019 The Matrix.org Foundation C.I.C
 
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

#import "MXKEmail.h"

@implementation MXKEmail

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _emailAddress = nil;
        _type = nil;
    }
    
    return self;
}

- (id)initWithEmailAddress:(NSString*)anEmailAddress type:(NSString*)aType contactID:(NSString*)aContactID matrixID:(NSString*)matrixID
{
    self = [super initWithContactID:aContactID matrixID:matrixID];
    
    if (self)
    {
        _emailAddress = [anEmailAddress lowercaseString];
        _type = aType;
    }
    
    return self;
}

- (BOOL)matchedWithPatterns:(NSArray*)patterns
{
    // no number -> cannot match
    if (_emailAddress.length == 0)
    {
        return NO;
    }
    if (patterns.count > 0)
    {
        for(NSString *pattern in patterns)
        {
            if ([_emailAddress rangeOfString:pattern options:NSCaseInsensitiveSearch].location == NSNotFound)
            {
                return NO;
            }
        }
    }
    
    return YES;
}
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self)
    {
        _type = [coder decodeObjectForKey:@"type"];
        _emailAddress = [[coder decodeObjectForKey:@"emailAddress"] lowercaseString];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:_type forKey:@"type"];
    [coder encodeObject:_emailAddress forKey:@"emailAddress"];
}

@end
