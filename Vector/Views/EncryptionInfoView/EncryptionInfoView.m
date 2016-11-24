/*
 Copyright 2016 OpenMarket Ltd
 
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

#import "EncryptionInfoView.h"

#import "AppDelegate.h"

#import "VectorDesignValues.h"

static NSAttributedString *verticalWhitespace = nil;

@interface EncryptionInfoView ()
{
    /**
     The displayed event
     */
    MXEvent *mxEvent;
    
    /**
     The matrix session.
     */
    MXSession *mxSession;
    
    /**
     The event device info
     */
    MXDeviceInfo *deviceInfo;
    
    /**
     Current request in progress.
     */
    MXHTTPOperation *mxCurrentOperation;
    
}
@end

@implementation EncryptionInfoView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Localize string
    [_cancelButton setTitle:[NSBundle mxk_localizedStringForKey:@"ok"] forState:UIControlStateNormal];
    [_cancelButton setTitle:[NSBundle mxk_localizedStringForKey:@"ok"] forState:UIControlStateHighlighted];
    
    [_confirmVerifyButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_verify_ok", @"Vector", nil) forState:UIControlStateNormal];
    [_confirmVerifyButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_verify_ok", @"Vector", nil) forState:UIControlStateHighlighted];
}

- (void)removeFromSuperview
{
    if (mxCurrentOperation)
    {
        [mxCurrentOperation cancel];
        mxCurrentOperation = nil;
    }
    
    [super removeFromSuperview];
}

- (instancetype)initWithEvent:(MXEvent*)event andMatrixSession:(MXSession*)session
{
    NSArray *nibViews = [[NSBundle bundleForClass:[EncryptionInfoView class]] loadNibNamed:NSStringFromClass([EncryptionInfoView class])
                                                                                      owner:nil
                                                                                    options:nil];
    self = nibViews.firstObject;
    if (self)
    {
        mxEvent = event;
        mxSession = session;
        
        [self setTranslatesAutoresizingMaskIntoConstraints: NO];
        
        [self updateTextViewText];
    }
    
    return self;
}

- (void)dealloc
{
    mxEvent = nil;
    mxSession = nil;
}

#pragma mark - 

- (void)updateTextViewText
{
    if (mxEvent)
    {
        MXRoom *mxRoom = [mxSession roomWithRoomId:mxEvent.roomId];
        
        if (mxRoom)
        {
            deviceInfo = [mxRoom eventDeviceInfo:mxEvent];
        }
        
        // Prepare text view content
        NSMutableAttributedString *textViewAttributedString = [[NSMutableAttributedString alloc]
                                                               initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_title", @"Vector", nil)
                                                               attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                            NSFontAttributeName: [UIFont boldSystemFontOfSize:17]}];
        // Event information
        NSMutableAttributedString *eventInformationString = [[NSMutableAttributedString alloc]
                                                             initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_event", @"Vector", nil)
                                                             attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                          NSFontAttributeName: [UIFont boldSystemFontOfSize:15]}];
        [eventInformationString appendAttributedString:[EncryptionInfoView verticalWhitespace]];
        
        NSString *senderId = mxEvent.sender;
        NSString *senderKey = mxEvent.senderKey;
        NSString *claimedKey = mxEvent.keysClaimed[@"ed25519"];
        NSString *algorithm = mxEvent.wireContent[@"algorithm"];
        NSString *sessionId = mxEvent.wireContent[@"session_id"];
        
        NSString *decryptionError;
        if (mxEvent.decryptionError)
        {
            decryptionError = [NSString stringWithFormat:@"** %@ **", mxEvent.decryptionError.localizedDescription];
        }
        
        if (!senderKey.length)
        {
            senderKey = NSLocalizedStringFromTable(@"room_event_encryption_info_event_none", @"Vector", nil);
        }
        if (!claimedKey.length)
        {
            claimedKey = NSLocalizedStringFromTable(@"room_event_encryption_info_event_none", @"Vector", nil);
        }
        if (!algorithm.length)
        {
            algorithm = NSLocalizedStringFromTable(@"room_event_encryption_info_event_unencrypted", @"Vector", nil);
        }
        if (!sessionId.length)
        {
            sessionId = NSLocalizedStringFromTable(@"room_event_encryption_info_event_none", @"Vector", nil);
        }
        
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_event_user_id", @"Vector", nil)
                                                        attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:senderId
                                                        attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[EncryptionInfoView verticalWhitespace]];
        
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_event_identity_key", @"Vector", nil)
                                                        attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:senderKey
                                                        attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[EncryptionInfoView verticalWhitespace]];
        
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_event_fingerprint_key", @"Vector", nil)
                                                        attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:claimedKey
                                                        attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[EncryptionInfoView verticalWhitespace]];
        
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_event_algorithm", @"Vector", nil)
                                                        attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:algorithm
                                                        attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[EncryptionInfoView verticalWhitespace]];
        
        if (decryptionError.length)
        {
            [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                            initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_event_decryption_error", @"Vector", nil)
                                                            attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                         NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
            [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                            initWithString:decryptionError
                                                            attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                         NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            [eventInformationString appendAttributedString:[EncryptionInfoView verticalWhitespace]];
        }
        
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_event_session_id", @"Vector", nil)
                                                        attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:sessionId
                                                        attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[EncryptionInfoView verticalWhitespace]];
        
        [textViewAttributedString appendAttributedString:eventInformationString];
        
        
        
        // Device information
        NSMutableAttributedString *deviceInformationString = [[NSMutableAttributedString alloc]
                                                              initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_device", @"Vector", nil)
                                                              attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                           NSFontAttributeName: [UIFont boldSystemFontOfSize:15]}];
        [deviceInformationString appendAttributedString:[EncryptionInfoView verticalWhitespace]];
        
        if (deviceInfo)
        {
            NSString *name = deviceInfo.displayName;
            NSString *deviceId = deviceInfo.deviceId;
            NSMutableAttributedString *verification;
            NSString *fingerprint = deviceInfo.fingerprint;
            
            // Display here the Verify and Block buttons except if the device is the current one.
            _verifyButton.hidden = _blockButton.hidden = [deviceInfo.deviceId isEqualToString:mxSession.matrixRestClient.credentials.deviceId];
            
            switch (deviceInfo.verified)
            {
                case MXDeviceUnverified:
                {
                    verification = [[NSMutableAttributedString alloc]
                                    initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_device_not_verified", @"Vector", nil)
                                    attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                 NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}];
                    
                    [_verifyButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_info_verify", @"Vector", nil) forState:UIControlStateNormal];
                    [_verifyButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_info_verify", @"Vector", nil) forState:UIControlStateHighlighted];
                    [_blockButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_info_block", @"Vector", nil) forState:UIControlStateNormal];
                    [_blockButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_info_block", @"Vector", nil) forState:UIControlStateHighlighted];
                    break;
                }
                case MXDeviceVerified:
                {
                    verification = [[NSMutableAttributedString alloc]
                                    initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_device_verified", @"Vector", nil)
                                    attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                 NSFontAttributeName: [UIFont systemFontOfSize:14]}];
                    
                    [_verifyButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_info_unverify", @"Vector", nil) forState:UIControlStateNormal];
                    [_verifyButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_info_unverify", @"Vector", nil) forState:UIControlStateHighlighted];
                    [_blockButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_info_block", @"Vector", nil) forState:UIControlStateNormal];
                    [_blockButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_info_block", @"Vector", nil) forState:UIControlStateHighlighted];
                    
                    break;
                }
                case MXDeviceBlocked:
                {
                    verification = [[NSMutableAttributedString alloc]
                                    initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_device_blocked", @"Vector", nil)
                                    attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                 NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}];
                    
                    [_verifyButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_info_verify", @"Vector", nil) forState:UIControlStateNormal];
                    [_verifyButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_info_verify", @"Vector", nil) forState:UIControlStateHighlighted];
                    [_blockButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_info_unblock", @"Vector", nil) forState:UIControlStateNormal];
                    [_blockButton setTitle:NSLocalizedStringFromTable(@"room_event_encryption_info_unblock", @"Vector", nil) forState:UIControlStateHighlighted];
                    
                    break;
                }
                default:
                    break;
            }
            
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_device_name", @"Vector", nil)
                                                             attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                          NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:(name.length ? name : @"")
                                                             attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                          NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[EncryptionInfoView verticalWhitespace]];
            
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_device_id", @"Vector", nil)
                                                             attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                          NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:deviceId
                                                             attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                          NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[EncryptionInfoView verticalWhitespace]];
            
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_device_verification", @"Vector", nil)
                                                             attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                          NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:verification];
            [deviceInformationString appendAttributedString:[EncryptionInfoView verticalWhitespace]];
            
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_device_fingerprint", @"Vector", nil)
                                                             attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                          NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:fingerprint
                                                             attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                          NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[EncryptionInfoView verticalWhitespace]];
        }
        else
        {
            // Unknown device
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:NSLocalizedStringFromTable(@"room_event_encryption_info_device_unknown", @"Vector", nil)
                                                             attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                          NSFontAttributeName: [UIFont italicSystemFontOfSize:14]}]];
            
            // Trigger a server request to get the device information for the event sender
            mxCurrentOperation = [mxSession.crypto downloadKeys:@[senderId] forceDownload:YES success:^(MXUsersDevicesMap<MXDeviceInfo *> *usersDevicesInfoMap) {
                
                mxCurrentOperation = nil;
                
                // Sanity check: check whether some device information has been retrieved.
                if (usersDevicesInfoMap.map.count)
                {
                    [self updateTextViewText];
                }
                
            } failure:^(NSError *error) {
                
                mxCurrentOperation = nil;
                
                NSLog(@"[EncryptionInfoView] Crypto failed to download device info for user: %@", mxEvent.sender);
                
                [[AppDelegate theDelegate] showErrorAsAlert:error];
                
            }];
        }
        
        [textViewAttributedString appendAttributedString:deviceInformationString];
        
        self.textView.attributedText = textViewAttributedString;
    }
    else
    {
        _textView.text = nil;
    }
}

+ (NSAttributedString *)verticalWhitespace
{
    if (verticalWhitespace == nil)
    {
        verticalWhitespace = [[NSAttributedString alloc] initWithString:@"\n\n" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:4]}];
    }
    return verticalWhitespace;
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == _cancelButton)
    {
        [self removeFromSuperview];
    }
    else if (sender == _confirmVerifyButton && deviceInfo)
    {
        [mxSession.crypto setDeviceVerification:MXDeviceVerified forDevice:deviceInfo.deviceId ofUser:deviceInfo.userId];
        [self removeFromSuperview];
    }
    else if (deviceInfo)
    {
        MXDeviceVerification verificationStatus;
        
        if (sender == _verifyButton)
        {
            verificationStatus = ((deviceInfo.verified == MXDeviceVerified) ? MXDeviceUnverified : MXDeviceVerified);
        }
        else if (sender == _blockButton)
        {
            verificationStatus = ((deviceInfo.verified == MXDeviceBlocked) ? MXDeviceUnverified : MXDeviceBlocked);
        }
        else
        {
            // Unexpected case
            NSLog(@"EncryptionInfoView: invalid button pressed.");
            return;
        }
        
        if (verificationStatus == MXDeviceVerified)
        {
            // Prompt user
            NSMutableAttributedString *textViewAttributedString = [[NSMutableAttributedString alloc]
                                                                   initWithString:NSLocalizedStringFromTable(@"room_event_encryption_verify_title", @"Vector", nil)
                                                                   attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                                NSFontAttributeName: [UIFont boldSystemFontOfSize:17]}];
            
            NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_event_encryption_verify_message", @"Vector", nil), deviceInfo.displayName, deviceInfo.deviceId, deviceInfo.fingerprint];
            
            [textViewAttributedString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:message
                                                             attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                          NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            
            self.textView.attributedText = textViewAttributedString;
            
            [_cancelButton setTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] forState:UIControlStateNormal];
            [_cancelButton setTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] forState:UIControlStateHighlighted];
            _verifyButton.hidden = _blockButton.hidden = YES;
            _confirmVerifyButton.hidden = NO;
        }
        else
        {
            [mxSession.crypto setDeviceVerification:verificationStatus forDevice:deviceInfo.deviceId ofUser:deviceInfo.userId];
            [self removeFromSuperview];
        }
    }
}

@end