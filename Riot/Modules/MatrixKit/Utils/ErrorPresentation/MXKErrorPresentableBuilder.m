/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKErrorPresentableBuilder.h"

#import "NSBundle+MatrixKit.h"
#import "MXKErrorViewModel.h"

#import "MXKSwiftHeader.h"

@implementation MXKErrorPresentableBuilder

- (id <MXKErrorPresentable>)errorPresentableFromError:(NSError*)error
{
    // Ignore nil error or connection cancellation error
    if (!error || ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled))
    {
        return nil;
    }
    
    NSString *title;
    NSString *message;

    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet)
    {
        title = [VectorL10n networkOfflineTitle];
        message = [VectorL10n networkOfflineMessage];
    }
    else
    {
        title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
        message = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
        
        if (!title)
        {
            title = [VectorL10n error];
        }
        
        if (!message)
        {
            message = [VectorL10n errorCommonMessage];
        }
    }
    
    return  [[MXKErrorViewModel alloc] initWithTitle:title message:message];
}

- (id <MXKErrorPresentable>)commonErrorPresentable
{
    return  [[MXKErrorViewModel alloc] initWithTitle:[VectorL10n error]
                                             message:[VectorL10n errorCommonMessage]];
}

@end
