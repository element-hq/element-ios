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

#import <Foundation/Foundation.h>

#import "MatrixSDK+Swift.h"

@implementation MXSession (Swift)

- (MXHTTPOperation*)createRoomFromSwift:(NSString*)name
                             visibility:(MXRoomDirectoryVisibility)visibility
                              roomAlias:(NSString*)roomAlias
                                  topic:(NSString*)topic
                                 invite:(NSArray<NSString*>*)inviteArray
                             invite3PID:(NSArray<MXInvite3PID*>*)invite3PIDArray
                               isDirect:(BOOL)isDirect
                                 preset:(MXRoomPreset)preset
                                success:(void (^)(void))success
                                failure:(void (^)(NSError *error))failure
{
    return [self createRoom:name visibility:visibility roomAlias:roomAlias topic:topic invite:inviteArray invite3PID:invite3PIDArray isDirect:isDirect preset:preset success:^(MXRoom *room) {

        if (success)
        {
            success();
        }
    } failure:failure];
}

@end

@implementation MXRoomSummary (Swift)

- (MXMembership)membershipFromSwift
{
    return self.membership;
}

@end
