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
