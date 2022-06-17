/*
 Copyright 2018 New Vector Ltd
 
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
