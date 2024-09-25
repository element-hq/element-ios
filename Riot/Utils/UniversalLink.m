/*
Copyright 2024 New Vector Ltd.
Copyright 2020 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "UniversalLink.h"
#import "NSArray+Element.h"

@implementation UniversalLink

- (id)initWithUrl:(NSURL *)url
{
    self = [super init];
    if (self)
    {
        _url = url;

        // Extract required parameters from the link
        [self parsePathAndQueryParamsForURL:url];
    }
    return self;
}

- (id)initWithUrl:(NSURL *)url updatedFragment:(NSString *)fragment
{
    self = [super init];
    if (self)
    {
        _url = url;

        // Update the url with the fragment
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
        components.fragment = fragment;
        [self parsePathAndQueryParamsForURL:components.URL];
    }
    return self;
}

/**
 Extract params from the URL fragment part (after '#') of a vector.im Universal link:

 The fragment can contain a '?'. So there are two kinds of parameters: path params and query params.
 It is in the form of /[pathParam1]/[pathParam2]?[queryParam1Key]=[queryParam1Value]&[queryParam2Key]=[queryParam2Value]
 */
- (void)parsePathAndQueryParamsForURL:(NSURL *)url
{
    NSArray<NSString*> *pathParams;
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];

    NSArray<NSString*> *fragments = [url.fragment componentsSeparatedByString:@"?"];

    // Extract path params
    pathParams = [[fragments[0] stringByRemovingPercentEncoding] componentsSeparatedByString:@"/"];

    // Remove the first empty path param string
    pathParams = [pathParams filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];

    // URL decode each path param
    pathParams = [pathParams vc_map:^id _Nonnull(NSString * _Nonnull item) {
        return [item stringByRemovingPercentEncoding];
    }];
    
    // Extract query params
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    for (NSURLQueryItem *item in components.queryItems)
    {
        if (item.value)
        {
            NSString *key = item.name;
            NSString *value = item.value;
            value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
            value = [value stringByRemovingPercentEncoding];

            if ([key isEqualToString:@"via"])
            {
                // Special case the via parameter
                // As we can have several of them, store each value into an array
                if (!queryParams[key])
                {
                    queryParams[key] = [NSMutableArray array];
                }

                [queryParams[key] addObject:value];
            }
            else
            {
                queryParams[key] = value;
            }
        }
    }
    // Query params are in the form [queryParam1Key]=[queryParam1Value], so the
    // presence of at least one '=' character is mandatory
    if (fragments.count == 2 && (NSNotFound != [fragments[1] rangeOfString:@"="].location))
    {
        for (NSString *keyValue in [fragments[1] componentsSeparatedByString:@"&"])
        {
            // Get the parameter name
            NSString *key = [keyValue componentsSeparatedByString:@"="][0];

            // Get the parameter value
            NSString *value = [keyValue componentsSeparatedByString:@"="][1];
            if (value.length)
            {
                value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
                value = [value stringByRemovingPercentEncoding];

                if ([key isEqualToString:@"via"])
                {
                    // Special case the via parameter
                    // As we can have several of them, store each value into an array
                    if (!queryParams[key])
                    {
                        queryParams[key] = [NSMutableArray array];
                    }

                    if (![queryParams[key] containsObject:value])
                    {
                        [queryParams[key] addObject:value];
                    }
                }
                else
                {
                    queryParams[key] = value;
                }
            }
        }
    }

    _pathParams = pathParams;
    _queryParams = queryParams;
}

- (NSString *)homeserverUrl
{
    return _queryParams[@"hs_url"];
}

- (NSString *)identityServerUrl
{
    return _queryParams[@"is_url"];
}

- (NSArray<NSString *> *)via
{
    NSArray<NSString *> *result = _queryParams[@"via"];
    if (!result)
    {
        return @[];
    }
    return result;
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

- (NSString *)description
{
    return [NSString stringWithFormat:@"<UniversalLink: %@>", _url.absoluteString];
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    UniversalLink *link = [[self.class allocWithZone:zone] init];

    link->_url = [_url copyWithZone:zone];
    link->_pathParams = [_pathParams copyWithZone:zone];
    link->_queryParams = [_queryParams copyWithZone:zone];

    return link;
}

@end
