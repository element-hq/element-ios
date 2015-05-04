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

#import "MatrixHandler.h"
#import "AppDelegate.h"

static MatrixHandler *sharedHandler = nil;

@implementation MatrixHandler

+ (MatrixHandler *)sharedHandler {
    @synchronized(self) {
        if(sharedHandler == nil)
        {
            sharedHandler = [[super allocWithZone:NULL] init];
        }
    }
    return sharedHandler;
}

- (MXSession*)mxSession {
    // Only the first account is presently used
    MXKAccount *account = [[MXKAccountManager sharedManager].accounts firstObject];
    return account.mxSession;
}

- (MXRestClient*)mxRestClient {
    // Only the first account is presently used
    MXKAccount *account = [[MXKAccountManager sharedManager].accounts firstObject];
    return account.mxRestClient;
}

@end
