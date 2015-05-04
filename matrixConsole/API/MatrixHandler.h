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

#import <MatrixSDK/MatrixSDK.h>

@interface MatrixHandler : NSObject

@property (strong, nonatomic) MXRestClient *mxRestClient;
@property (strong, nonatomic) MXSession *mxSession;

+ (MatrixHandler *)sharedHandler;



// user power level in a dedicated room
- (CGFloat)getPowerLevel:(MXRoomMember *)roomMember inRoom:(MXRoom *)room;

// return the presence ring color
// nil means there is no ring to display
- (UIColor*)getPresenceRingColor:(MXPresence)presence;

@end
