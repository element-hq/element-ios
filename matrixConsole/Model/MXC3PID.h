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

#import <Foundation/Foundation.h>

#import "MXRestClient.h"

typedef enum : NSUInteger {
    MXC3PIDAuthStateUnknown,
    MXC3PIDAuthStateTokenRequested,
    MXC3PIDAuthStateTokenReceived,
    MXC3PIDAuthStateTokenSubmitted,
    MXC3PIDAuthStateAuthenticated
} MXC3PIDAuthState;


@interface MXC3PID : NSObject

/**
 The 3rd party system where the user is defined.
 */
@property (nonatomic, readonly) MX3PIDMedium medium;

/**
 The id of the user in the 3rd party system.
 */
@property (nonatomic, readonly) NSString *address;

/**
 The id of the user on Matrix.
 nil if unknown or not yet resolved.
 */
@property (nonatomic) NSString *userId;

@property (nonatomic, readonly) MXC3PIDAuthState validationState;

/**
 Initialise the instance with a 3PID.

 @param medium the medium.
 @param address the id of the contact on this medium.
 @return the new instance.
 */
- (instancetype)initWithMedium:(NSString*)medium andAddress:(NSString*)address;

/**
 Start the validation process 
 The identity server will send a validation token to the user's address.
 This validation token must be then send back to the identity server with [MXC3PID validateWithToken]
 in order to complete the 3PID authentication.
 
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)requestValidationToken:(void (^)())success
                       failure:(void (^)(NSError *error))failure;

/**
 Complete the 3rd party id validation by sending the validation token the user received.
 
 @param validationToken the validation token the user received.
 @param success A block object called when the operation succeeds. It indicates if the
 validation has succeeded.
 @param failure A block object called when the operation fails.
 */
- (void)validateWithToken:(NSString*)validationToken
              success:(void (^)(BOOL success))success
              failure:(void (^)(NSError *error))failure;

/**
 Link an authenticated 3rd party id to a Matrix user id.
 
 @param userId the Matrix user id to link the 3PID with.
 @param success A block object called when the operation succeeds. It provides the raw
 server response.
 @param failure A block object called when the operation fails.
 */
- (void)bindWithUserId:(NSString*)userId
         success:(void (^)())success
         failure:(void (^)(NSError *error))failure;

@end