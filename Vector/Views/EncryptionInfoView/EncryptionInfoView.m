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
    
}
@end

@implementation EncryptionInfoView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Localize string
    [_okButton setTitle:[NSBundle mxk_localizedStringForKey:@"ok"] forState:UIControlStateNormal];
    [_okButton setTitle:[NSBundle mxk_localizedStringForKey:@"ok"] forState:UIControlStateHighlighted];
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
            
            NSString *senderId = event.sender;
            NSString *senderKey = event.senderKey;
            NSString *claimedKey = event.keysClaimed[@"ed25519"];
            NSString *algorithm = event.wireContent[@"algorithm"];
            NSString *sessionId = event.wireContent[@"session_id"];
            
            NSString *decryptionError;
            if (event.decryptionError)
            {
                decryptionError = [NSString stringWithFormat:@"** %@ **", event.decryptionError.localizedDescription];
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
                
                _verifyButton.hidden = NO;
                _blockButton.hidden = NO;
                
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
            }
            
            
            [textViewAttributedString appendAttributedString:deviceInformationString];
            
            self.textView.attributedText = textViewAttributedString;
        }
        else
        {
            _textView.text = nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    mxEvent = nil;
    mxSession = nil;
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
    if (sender == _okButton)
    {
        [self removeFromSuperview];
    }
    else
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
        
        [mxSession.crypto setDeviceVerification:verificationStatus forDevice:deviceInfo.deviceId ofUser:deviceInfo.userId];
        [self removeFromSuperview];
    }
}

@end