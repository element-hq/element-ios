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

#import "DecryptionFailureTracker.h"


// Call `checkFailures` every `CHECK_INTERVAL`
#define CHECK_INTERVAL 5

// Give events a chance to be decrypted by waiting `GRACE_PERIOD` before counting
// and reporting them as failures
#define GRACE_PERIOD 60


@interface DecryptionFailureTracker()
{
    // Reported failures
    // Every `CHECK_INTERVAL`, this list is checked for failures that happened
    // more than`GRACE_PERIOD` ago. Those that did are reported to the delegate.
    NSMutableDictionary<NSString* /* eventId */, DecryptionFailure*> *reportedFailures;

    // Event ids of failures that were tracked previously
    NSMutableSet<NSString*> *trackedEvents;

    // Timer for periodic check
    NSTimer *checkFailuresTimer;
}
@end

@implementation DecryptionFailureTracker

+ (instancetype)sharedInstance
{
    static DecryptionFailureTracker *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[DecryptionFailureTracker alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        reportedFailures = [NSMutableDictionary dictionary];
        trackedEvents = [NSMutableSet set];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventDidDecrypt:) name:kMXEventDidDecryptNotification object:nil];

        checkFailuresTimer = [NSTimer scheduledTimerWithTimeInterval:CHECK_INTERVAL
                                         target:self
                                       selector:@selector(checkFailures)
                                       userInfo:nil
                                        repeats:YES];
    }
    return self;
}

- (void)reportUnableToDecryptErrorForEvent:(MXEvent *)event withRoomState:(MXRoomState *)roomState myUser:(NSString *)userId
{
    if (reportedFailures[event.eventId] || [trackedEvents containsObject:event.eventId])
    {
        return;
    }

    // Filter out "expected" UTDs
    // We cannot decrypt messages sent before the user joined the room
    MXRoomMember *myUser = [roomState.members memberWithUserId:userId];
    if (!myUser || myUser.membership != MXMembershipJoin)
    {
        return;
    }

    DecryptionFailure *decryptionFailure = [[DecryptionFailure alloc] init];
    decryptionFailure.failedEventId = event.eventId;

    // Categorise the error
    switch (event.decryptionError.code)
    {
        case MXDecryptingErrorUnknownInboundSessionIdCode:
            decryptionFailure.reason = DecryptionFailureReason.olmKeysNotSent;
            break;

        case MXDecryptingErrorOlmCode:
            decryptionFailure.reason = DecryptionFailureReason.olmIndexError;
            break;

        case MXDecryptingErrorEncryptionNotEnabledCode:
        case MXDecryptingErrorUnableToDecryptCode:
            decryptionFailure.reason = DecryptionFailureReason.unexpected;
            break;

        default:
            decryptionFailure.reason = DecryptionFailureReason.unspecified;
            break;
    }

    reportedFailures[event.eventId] = decryptionFailure;
}

- (void)dispatch
{
    [self checkFailures];
}

#pragma mark - Private methods

/**
 Mark reported failures that occured before tsNow - GRACE_PERIOD as failures that should be
 tracked.
 */
- (void)checkFailures
{
    NSTimeInterval tsNow = [NSDate date].timeIntervalSince1970;

    NSMutableArray *failuresToTrack = [NSMutableArray array];

    for (DecryptionFailure *reportedFailure in reportedFailures.allValues)
    {
        if (reportedFailure.ts < tsNow - GRACE_PERIOD)
        {
            [failuresToTrack addObject:reportedFailure];
            [reportedFailures removeObjectForKey:reportedFailure.failedEventId];
            [trackedEvents addObject:reportedFailure.failedEventId];
        }
    }

    if (_delegate && failuresToTrack.count)
    {
        // Sort failures by error reason
        NSMutableDictionary<NSString*, NSNumber*> *failuresCounts = [NSMutableDictionary dictionary];
        for (DecryptionFailure *failure in failuresToTrack)
        {
            failuresCounts[failure.reason] = @(failuresCounts[failure.reason].unsignedIntegerValue + 1);
        }

        NSLog(@"[DecryptionFailureTracker] trackFailures: %@", failuresCounts);

        [_delegate trackFailures:failuresCounts];
    }
}

- (void)eventDidDecrypt:(NSNotification *)notif
{
    // Could be an event in the reportedFailures, remove it
    MXEvent *event = notif.object;
    [reportedFailures removeObjectForKey:event.eventId];
}

@end
