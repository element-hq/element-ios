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

#import <MatrixSDK/MatrixSDK.h>

/**
 Temporary category to help in the transition from synchronous access to room.state
 to asynchronous access.
 */
@interface MXRoom (Sync)

/**
 Get the room state if it has been already loaded else return nil.

 Use this method only where you are sure the room state is already mounted.
 */
@property (nonatomic, readonly) MXRoomState *dangerousSyncState;

@end
