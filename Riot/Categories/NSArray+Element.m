// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import "NSArray+Element.h"

@implementation NSArray (Element)

- (NSArray *)vc_map:(id (^)(id obj))transform
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        [result addObject:transform(obj)];
    }];
    return result;
}

- (NSArray *)vc_compactMap:(id _Nullable (^)(id obj))transform
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        id mappedObject = transform(obj);
        if (mappedObject)
        {
            [result addObject:mappedObject];
        }
    }];
    return result;
}

- (NSArray *)vc_flatMap:(NSArray* (^)(id obj))transform
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        [result addObjectsFromArray:transform(obj)];
    }];
    return result;
}

@end
