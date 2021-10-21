// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
