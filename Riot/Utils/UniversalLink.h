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

@interface UniversalLink : NSObject

@property (nonatomic, copy, readonly) NSURL *url;

@property (nonatomic, copy, readonly) NSArray<NSString*> *pathParams;

@property (nonatomic, copy, readonly) NSDictionary<NSString*, NSString*> *queryParams;

- (id)initWithUrl:(NSURL *)url
       pathParams:(NSArray<NSString*> *)pathParams
      queryParams:(NSDictionary<NSString*, NSString*> *)queryParams;

@end

NS_ASSUME_NONNULL_END
