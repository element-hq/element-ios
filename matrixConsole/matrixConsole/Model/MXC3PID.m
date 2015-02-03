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

#import "MXC3PID.h"
#import "MatrixSDKHandler.h"
#import "MXTools.h"

@interface MXC3PID ()
@property (nonatomic) NSString *clientSecret;
@property (nonatomic) NSUInteger sendAttempt;
@property (nonatomic) NSString *sid;
@end

@implementation MXC3PID

- (instancetype)initWithMedium:(NSString *)medium andAddress:(NSString *)address
{
    self = [super init];
    if (self)
    {
        _medium = [medium copy];
        _address = [address copy];
    }
    return self;
}

- (void)resetValidationParameters {
    _validationState = MXC3PIDAuthStateUnknown;
    self.clientSecret = nil;
    self.sendAttempt = 1;
    self.sid = nil;
    // Removed potential linked userId
    self.userId = nil;
}

- (void)requestValidationToken:(void (^)())success
                       failure:(void (^)(NSError *error))failure {
    // Sanity Check
    if (_validationState != MXC3PIDAuthStateTokenRequested) {
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        // Reset if the current state is different than "Unknown"
        if (_validationState != MXC3PIDAuthStateUnknown) {
            [self resetValidationParameters];
        }
        
        if ([self.medium isEqualToString:kMX3PIDMediumEmail]) {
            self.clientSecret = [MXTools generateSecret];
            _validationState = MXC3PIDAuthStateTokenRequested;
            [mxHandler.mxRestClient requestEmailValidation:self.address clientSecret:self.clientSecret sendAttempt:self.sendAttempt success:^(NSString *sid) {
                _validationState = MXC3PIDAuthStateTokenReceived;
                self.sid = sid;
                if (success) {
                    success();
                }
            } failure:^(NSError *error) {
                // Return in unknown state
                _validationState = MXC3PIDAuthStateUnknown;
                // Increment attempt counter
                self.sendAttempt++;
                if (failure) {
                    failure (error);
                }
            }];
            
            return;
        } else if ([self.medium isEqualToString:kMX3PIDMediumMSISDN]) {
            // FIXME: support msisdn as soon as identity server supports it
            NSLog(@"MXC3PID requestValidationToken: is not supported for this 3PID: %@ (%@)", self.address, self.medium);
        } else {
            NSLog(@"MXC3PID requestValidationToken: is not supported for this 3PID: %@ (%@)", self.address, self.medium);
        }
    } else {
        NSLog(@"MXC3PID requestValidationToken: Wrong validation flow for this 3PID: %@ (%@), state: %lu", self.address, self.medium, (unsigned long)_validationState);
    }
    
}

- (void)validateWithToken:(NSString*)validationToken
              success:(void (^)(BOOL success))success
              failure:(void (^)(NSError *error))failure {
    // Sanity check
    if (_validationState == MXC3PIDAuthStateTokenReceived) {
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        
        if ([self.medium isEqualToString:kMX3PIDMediumEmail]) {
            _validationState = MXC3PIDAuthStateTokenSubmitted;
            [mxHandler.mxRestClient validateEmail:self.sid validationToken:validationToken clientSecret:self.clientSecret success:^(BOOL successFlag) {
                if (successFlag) {
                    // Validation is complete
                    _validationState = MXC3PIDAuthStateAuthenticated;
                } else {
                    // Return in previous step
                    _validationState = MXC3PIDAuthStateTokenReceived;
                }
                if (success) {
                    success(successFlag);
                }
            } failure:^(NSError *error) {
                // Return in previous step
                _validationState = MXC3PIDAuthStateTokenReceived;
                if (failure) {
                    failure (error);
                }
            }];
            
            return;
        } else if ([self.medium isEqualToString:kMX3PIDMediumMSISDN]) {
            // FIXME: support msisdn as soon as identity server supports it
            NSLog(@"MXC3PID validateWithToken: is not supported for this 3PID: %@ (%@)", self.address, self.medium);
        } else {
            NSLog(@"MXC3PID validateWithToken: is not supported for this 3PID: %@ (%@)", self.address, self.medium);
        }
    } else {
        NSLog(@"MXC3PID validateWithToken: Wrong validation flow for this 3PID: %@ (%@), state: %lu", self.address, self.medium, (unsigned long)_validationState);
    }
    
    // Here the validation process failed
    if (failure) {
        failure (nil);
    }
}

- (void)bindWithUserId:(NSString*)userId
               success:(void (^)())success
               failure:(void (^)(NSError *error))failure {
    // Sanity check
    if (_validationState == MXC3PIDAuthStateAuthenticated) {
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        
        if ([self.medium isEqualToString:kMX3PIDMediumEmail]) {
            [mxHandler.mxRestClient bind3PID:userId sid:self.sid clientSecret:self.clientSecret success:^(NSDictionary *JSONResponse) {
                // Update linked userId in 3PID
                self.userId = userId;
                if (success) {
                    success();
                }
            } failure:failure];
            
            return;
        } else if ([self.medium isEqualToString:kMX3PIDMediumMSISDN]) {
            // FIXME: support msisdn as soon as identity server supports it
            NSLog(@"MXC3PID bindWithUserId: is not supported for this 3PID: %@ (%@)", self.address, self.medium);
        } else {
            NSLog(@"MXC3PID bindWithUserId: is not supported for this 3PID: %@ (%@)", self.address, self.medium);
        }
    } else {
        NSLog(@"MXC3PID bindWithUserId: Wrong validation flow for this 3PID: %@ (%@), state: %lu", self.address, self.medium, (unsigned long)_validationState);
    }
    
    // Here the validation process failed
    if (failure) {
        failure (nil);
    }
}

@end
