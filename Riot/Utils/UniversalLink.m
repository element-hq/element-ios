/*
 Copyright 2020 Vector Creations Ltd
 
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

#import "UniversalLink.h"

@implementation UniversalLink

- (id)initWithUrl:(NSURL *)url pathParams:(NSArray<NSString *> *)pathParams queryParams:(NSDictionary<NSString *,NSString *> *)queryParams
{
    self = [super init];
    if (self)
    {
        _url = url;
        _pathParams = pathParams;
        _queryParams = queryParams;
    }
    return self;
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;

    if (![other isKindOfClass:UniversalLink.class])
        return NO;

    UniversalLink *otherLink = (UniversalLink *)other;

    return [_url isEqual:otherLink.url]
        && [_pathParams isEqualToArray:otherLink.pathParams]
        && [_queryParams isEqualToDictionary:otherLink.queryParams];
}

- (NSUInteger)hash
{
    NSUInteger prime = 31;
    NSUInteger result = 1;

    result = prime * result + [_url hash];
    result = prime * result + [_pathParams hash];
    result = prime * result + [_queryParams hash];

    return result;
}

@end
