// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "VoiceBroadcastEventContent.h"
#import "GeneratedInterface-Swift.h"

@implementation VoiceBroadcastEventContent

- (instancetype)initWithState:(NSString *)state
                  chunkLength:(NSInteger)chunkLength
{
    if (self = [super init])
    {
        _state = state;
        _chunkLength = chunkLength;
    }
    
    return self;
}

+ (id)modelFromJSON:(NSDictionary *)JSONDictionary
{
    NSString *state;
    MXJSONModelSetString(state, JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyState]);
    
    NSInteger chunkLength = VoiceBroadcastSettings.defaultChunkLength;
    if (JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkLength])
    {
        MXJSONModelSetInteger(chunkLength, JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkLength]);
    }
    
    

    return [[VoiceBroadcastEventContent alloc] initWithState:state chunkLength:chunkLength];
}

- (NSDictionary *)JSONDictionary
{
    NSMutableDictionary *JSONDictionary = [NSMutableDictionary dictionary];
    
    JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyState] = self.state;
    JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkLength] = @(self.chunkLength);
    
    return JSONDictionary;
}

@end
