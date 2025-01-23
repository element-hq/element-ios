// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import "VoiceBroadcastInfo.h"
#import "GeneratedInterface-Swift.h"

@implementation VoiceBroadcastInfo

- (instancetype)initWithDeviceId:(NSString *)deviceId
                           state:(NSString *)state
                     chunkLength:(NSInteger)chunkLength
                voiceBroadcastId:(NSString *)voiceBroadcastId
               lastChunkSequence:(NSInteger)lastChunkSequence
{
    if (self = [super init])
    {
        _deviceId = deviceId;
        _state = state;
        _chunkLength = chunkLength;
        _voiceBroadcastId = voiceBroadcastId;
        _lastChunkSequence = lastChunkSequence;
    }
    
    return self;
}

+ (id)modelFromJSON:(NSDictionary *)JSONDictionary
{
    // Return nil for redacted state event
    if (!JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyState])
    {
        return nil;
    }
    
    NSString *state;
    MXJSONModelSetString(state, JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyState]);
    
    NSString *deviceId;
    MXJSONModelSetString(deviceId, JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyDeviceId]);
    
    NSInteger chunkLength = BuildSettings.voiceBroadcastChunkLength;
    if (JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkLength])
    {
        MXJSONModelSetInteger(chunkLength, JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkLength]);
    }
    
    NSString *voiceBroadcastId;
    if (JSONDictionary[kMXEventRelationRelatesToKey]) {
        MXEventContentRelatesTo *relatesTo;
        
        MXJSONModelSetMXJSONModel(relatesTo, MXEventContentRelatesTo, JSONDictionary[kMXEventRelationRelatesToKey]);
        
        if (relatesTo && [relatesTo.relationType isEqualToString:MXEventRelationTypeReference])
        {
            voiceBroadcastId = relatesTo.eventId;
        }
    }
    
    NSInteger lastChunkSequence = 0;
    if (JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkLastSequence]) {
        MXJSONModelSetInteger(lastChunkSequence, JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkLastSequence]);
    }

    return [[VoiceBroadcastInfo alloc] initWithDeviceId:deviceId state:state chunkLength:chunkLength voiceBroadcastId:voiceBroadcastId lastChunkSequence:lastChunkSequence];
}

- (NSDictionary *)JSONDictionary
{
    NSMutableDictionary *JSONDictionary = [NSMutableDictionary dictionary];
    
    JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyDeviceId] = self.deviceId;
    
    JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyState] = self.state;
    
    if (_voiceBroadcastId) {
        MXEventContentRelatesTo *relatesTo = [[MXEventContentRelatesTo alloc] initWithRelationType:MXEventRelationTypeReference eventId:_voiceBroadcastId];

        JSONDictionary[kMXEventRelationRelatesToKey] = relatesTo.JSONDictionary;
    } else {
        JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkLength] = @(self.chunkLength);
    }
    
    if (self.lastChunkSequence != 0) {
        JSONDictionary[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkLastSequence] = @(self.lastChunkSequence);
    }
    
    return JSONDictionary;
}

@end
