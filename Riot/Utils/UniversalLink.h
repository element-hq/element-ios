/*
Copyright 2024 New Vector Ltd.
Copyright 2020 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UniversalLink : NSObject <NSCopying>

/// Original url
@property (nonatomic, copy, readonly) NSURL *url;

/// Path params from the link.
@property (nonatomic, copy, readonly) NSArray<NSString*> *pathParams;

/// Query params from the link. Does not conform to RFC 1808. Designed for simplicity.
@property (nonatomic, copy, readonly) NSDictionary<NSString*, id> *queryParams;

/// Homeserver url in the link if any
@property (nonatomic, copy, readonly, nullable) NSString *homeserverUrl;
/// Identity server url in the link if any
@property (nonatomic, copy, readonly, nullable) NSString *identityServerUrl;
/// via parameters url in the link if any
@property (nonatomic, copy, readonly) NSArray<NSString*> *via;

/// Initializer
/// @param url original url
- (id)initWithUrl:(NSURL *)url;

/// An Initializer that preserves the original URL, but parses the parameters from an updated fragment.
/// @param url original url
/// @param fragment the updated fragment to parse.
- (id)initWithUrl:(NSURL *)url updatedFragment:(NSString *)fragment;

@end

NS_ASSUME_NONNULL_END
