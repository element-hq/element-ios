/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKAuthInputsView.h"

#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

NSString *const MXKAuthErrorDomain = @"MXKAuthErrorDomain";

@implementation MXKAuthInputsView

+ (UINib *)nib
{
    // By default, no nib is available.
    return nil;
}

+ (instancetype)authInputsView
{
    // Check whether a xib is defined
    if ([[self class] nib])
    {
        return [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
    }
    
    return [[[self class] alloc] init];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setTranslatesAutoresizingMaskIntoConstraints: NO];
    
    type = MXKAuthenticationTypeLogin;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        type = MXKAuthenticationTypeLogin;
    }
    return self;
}

#pragma mark -

- (BOOL)setAuthSession:(MXAuthenticationSession *)authSession withAuthType:(MXKAuthenticationType)authType
{
    if (authSession)
    {
        type = authType;
        currentSession = authSession;
        
        return YES;
    }
    
    return NO;
}

- (NSString *)validateParameters
{
    // Currently no field to check here
    return nil;
}

- (void)prepareParameters:(void (^)(NSDictionary *parameters, NSError *error))callback
{
    // Do nothing by default
    if (callback)
    {
        callback (nil, [NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:[VectorL10n notSupportedYet]}]);
    }
}

- (void)updateAuthSessionWithCompletedStages:(NSArray *)completedStages didUpdateParameters:(void (^)(NSDictionary *parameters, NSError *error))callback
{
    // Do nothing by default
    if (callback)
    {
        callback (nil, [NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:[VectorL10n notSupportedYet]}]);
    }
}

- (BOOL)setExternalRegistrationParameters:(NSDictionary *)registrationParameters
{
    // Not supported by default
    return NO;
}

- (BOOL)areAllRequiredFieldsSet
{
    // Currently no field to check here
    return YES;
}

- (void)dismissKeyboard
{
    
}

- (void)nextStep
{
    
}

- (void)destroy
{
    if (inputsAlert)
    {
        [inputsAlert dismissViewControllerAnimated:NO completion:nil];
        inputsAlert = nil;
    }
}

#pragma mark -

- (MXKAuthenticationType)authType
{
    return type;
}

- (MXAuthenticationSession*)authSession
{
    return currentSession;
}

- (NSString*)userId
{
    return nil;
}

- (NSString*)password
{
    return nil;
}

@end
