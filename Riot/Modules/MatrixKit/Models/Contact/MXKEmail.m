/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
