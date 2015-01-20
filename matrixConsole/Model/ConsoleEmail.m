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

#import "ConsoleEmail.h"
#import "MatrixHandler.h"

#import "ConsoleContact.h"

@implementation ConsoleEmail
@synthesize type, emailAddress, contactID, matrixUserID;

- (id)init {
    self = [super init];
    
    if (self) {
        // init statuses
        gotMatrixID = NO;
        pendingMatrixIDRequest = NO;

        // init members
        self.emailAddress = nil;
        self.type = nil;
        self.contactID = nil;
        self.matrixUserID = nil;
    }
    
    return self;
}

- (id)initWithEmailAddress:(NSString*)anEmailAddress andType:(NSString*)aType within:(NSString*)aContactID {
    self = [super init];
    
    if (self) {
        self.emailAddress = anEmailAddress;
        self.type = aType;
        self.contactID = aContactID;
    }
    
    return self;
}

- (void)getMatrixID {
    
    // sanity check
    if ((self.emailAddress.length > 0) && (self.contactID.length > 0)) {
        
        // check if the matrix id was not requested
        if (!gotMatrixID && !pendingMatrixIDRequest) {
            MatrixHandler *matrix = [MatrixHandler sharedHandler];
        
            if (matrix.mxRestClient) {
                pendingMatrixIDRequest = YES;
                
                [matrix.mxRestClient lookup3pid:self.emailAddress
                                      forMedium:@"email"
                                        success:^(NSString *userId) {
                                            pendingMatrixIDRequest = NO;
                                            self.matrixUserID = userId;
                                            gotMatrixID = YES;
                                            
                                            if (self.matrixUserID) {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:kConsoleContactMatrixIdentifierUpdateNotification object:self.contactID userInfo:nil];
                                                });
                                            }
                                        }
                                        failure:^(NSError *error) {
                                            pendingMatrixIDRequest = NO;
                                        }
                 ];
            }
        }
    }
}

@end
