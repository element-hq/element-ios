/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKEncryptionInfoView.h"

#import "NSBundle+MatrixKit.h"

#import "MXKConstants.h"

#import "MXKSwiftHeader.h"

static NSAttributedString *verticalWhitespace = nil;

@interface MXKEncryptionInfoView ()
{    
    /**
     Current request in progress.
     */
    MXHTTPOperation *mxCurrentOperation;
    
}
@end

@implementation MXKEncryptionInfoView

+ (UINib *)nib
{
    // Check whether a nib file is available
    NSBundle *mainBundle = [NSBundle mxk_bundleForClass:self.class];
    
    NSString *path = [mainBundle pathForResource:NSStringFromClass([self class]) ofType:@"nib"];
    if (path)
    {
        return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:mainBundle];
    }
    return [UINib nibWithNibName:NSStringFromClass([MXKEncryptionInfoView class]) bundle:[NSBundle mxk_bundleForClass:[MXKEncryptionInfoView class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Localize string
    [_cancelButton setTitle:[VectorL10n ok] forState:UIControlStateNormal];
    [_cancelButton setTitle:[VectorL10n ok] forState:UIControlStateHighlighted];
    
    [_confirmVerifyButton setTitle:[VectorL10n roomEventEncryptionVerifyOk] forState:UIControlStateNormal];
    [_confirmVerifyButton setTitle:[VectorL10n roomEventEncryptionVerifyOk] forState:UIControlStateHighlighted];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Scroll to the top the text view content
    self.textView.contentOffset = CGPointZero;
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

#pragma mark - Override MXKView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    _defaultTextColor = [UIColor blackColor];
}

#pragma mark -

- (instancetype)initWithEvent:(MXEvent*)event andMatrixSession:(MXSession*)session
{
    self = [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
    if (self)
    {
        _mxEvent = event;
        _mxSession = session;
        _mxDeviceInfo = nil;
        
        [self setTranslatesAutoresizingMaskIntoConstraints: NO];
        
        [self updateTextViewText];
    }
    
    return self;
}

- (instancetype)initWithDeviceInfo:(MXDeviceInfo*)deviceInfo andMatrixSession:(MXSession*)session
{
    self = [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
    if (self)
    {
        _mxEvent = nil;
        _mxDeviceInfo = deviceInfo;
        _mxSession = session;
        
        [self setTranslatesAutoresizingMaskIntoConstraints: NO];
        
        [self updateTextViewText];
    }
    
    return self;
}

- (void)dealloc
{
    _mxEvent = nil;
    _mxSession = nil;
    _mxDeviceInfo = nil;
}

#pragma mark - 

- (void)updateTextViewText
{
    // Prepare the text view content
    NSMutableAttributedString *textViewAttributedString = [[NSMutableAttributedString alloc]
                                                           initWithString:[VectorL10n roomEventEncryptionInfoTitle]
                                                           attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                        NSFontAttributeName: [UIFont boldSystemFontOfSize:17]}];

    if (_mxEvent)
    {
        NSString *senderId = _mxEvent.sender;
        
        if (_mxSession && _mxSession.crypto && !_mxDeviceInfo)
        {
            _mxDeviceInfo = [_mxSession.crypto eventDeviceInfo:_mxEvent];
            
            if (!_mxDeviceInfo)
            {
                // Trigger a server request to get the device information for the event sender
                mxCurrentOperation = [_mxSession.crypto downloadKeys:@[senderId] forceDownload:NO success:^(MXUsersDevicesMap<MXDeviceInfo *> *usersDevicesInfoMap, NSDictionary<NSString *,MXCrossSigningInfo *> *crossSigningKeysMap) {
                    
                    self->mxCurrentOperation = nil;
                    
                    // Sanity check: check whether some device information has been retrieved.
                    self->_mxDeviceInfo = [self.mxSession.crypto eventDeviceInfo:self.mxEvent];
                    if (self.mxDeviceInfo)
                    {
                        [self updateTextViewText];
                    }
                    
                } failure:^(NSError *error) {
                    
                    self->mxCurrentOperation = nil;

                    MXLogDebug(@"[MXKEncryptionInfoView] Crypto failed to download device info for user: %@", self.mxEvent.sender);
                    
                    // Notify MatrixKit user
                    NSString *myUserId = self.mxSession.myUser.userId;

                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                    
                }];
            }
        }
        
        // Event information
        NSMutableAttributedString *eventInformationString = [[NSMutableAttributedString alloc]
                                                             initWithString:[VectorL10n roomEventEncryptionInfoEvent]
                                                             attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                          NSFontAttributeName: [UIFont boldSystemFontOfSize:15]}];
        [eventInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];
        
        NSString *senderKey = _mxEvent.senderKey;
        NSString *claimedKey = _mxEvent.keysClaimed[@"ed25519"];
        NSString *algorithm = _mxEvent.wireContent[@"algorithm"];
        NSString *sessionId = _mxEvent.wireContent[@"session_id"];
        NSString *safetyMessage = _mxEvent.decryptionDecoration.message;
        if (!safetyMessage)
        {
            // Use default copy if none is provided by the decryption decoration
            BOOL isUntrusted = _mxEvent.decryptionDecoration && _mxEvent.decryptionDecoration.color != MXEventDecryptionDecorationColorNone;
            safetyMessage = isUntrusted ? [VectorL10n roomEventEncryptionInfoKeyAuthenticityNotGuaranteed] : [VectorL10n userVerificationSessionsListSessionTrusted];
        }
        
        NSString *decryptionError;
        if (_mxEvent.decryptionError)
        {
            decryptionError = [NSString stringWithFormat:@"** %@ **", _mxEvent.decryptionError.localizedDescription];
        }
        
        if (!senderKey.length)
        {
            senderKey = [VectorL10n roomEventEncryptionInfoEventNone];
        }
        if (!claimedKey.length)
        {
            claimedKey = [VectorL10n roomEventEncryptionInfoEventNone];
        }
        if (!algorithm.length)
        {
            algorithm = [VectorL10n roomEventEncryptionInfoEventUnencrypted];
        }
        if (!sessionId.length)
        {
            sessionId = [VectorL10n roomEventEncryptionInfoEventNone];
        }
        
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:[VectorL10n roomEventEncryptionInfoEventUserId]
                                                        attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:senderId
                                                        attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];
        
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:[VectorL10n roomEventEncryptionInfoEventIdentityKey]
                                                        attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:senderKey
                                                        attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];
        
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:[VectorL10n roomEventEncryptionInfoEventFingerprintKey]
                                                        attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:claimedKey
                                                        attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];
        
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:[VectorL10n roomEventEncryptionInfoEventAlgorithm]
                                                        attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:algorithm
                                                        attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];
        
        if (decryptionError.length)
        {
            [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                            initWithString:[VectorL10n roomEventEncryptionInfoEventDecryptionError]
                                                            attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                         NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
            [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                            initWithString:decryptionError
                                                            attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                         NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            [eventInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];
        }
        
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:[VectorL10n roomEventEncryptionInfoEventSessionId]
                                                        attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:sessionId
                                                        attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];

        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:[NSString stringWithFormat:@"%@\n", [VectorL10n sslTrust]]
                                                        attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                        initWithString:safetyMessage
                                                        attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [eventInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];
        
        [textViewAttributedString appendAttributedString:eventInformationString];
    }
    
    // Device information
    NSMutableAttributedString *deviceInformationString = [[NSMutableAttributedString alloc]
                                                          initWithString:[VectorL10n roomEventEncryptionInfoDevice]
                                                          attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                       NSFontAttributeName: [UIFont boldSystemFontOfSize:15]}];
    [deviceInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];
    
    if (_mxDeviceInfo)
    {
        NSString *name = _mxDeviceInfo.displayName;
        NSString *deviceId = _mxDeviceInfo.deviceId;
        NSMutableAttributedString *verification;
        NSString *fingerprint = _mxDeviceInfo.fingerprint;
        
        // Display here the Verify and Block buttons except if the device is the current one.
        _verifyButton.hidden = _blockButton.hidden = [_mxDeviceInfo.deviceId isEqualToString:_mxSession.matrixRestClient.credentials.deviceId];
        
        switch (_mxDeviceInfo.trustLevel.localVerificationStatus)
        {
            case MXDeviceUnknown:
            case MXDeviceUnverified:
            {
                verification = [[NSMutableAttributedString alloc]
                                initWithString:[VectorL10n roomEventEncryptionInfoDeviceNotVerified]
                                attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                             NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}];
                
                [_verifyButton setTitle:[VectorL10n roomEventEncryptionInfoVerify] forState:UIControlStateNormal];
                [_verifyButton setTitle:[VectorL10n roomEventEncryptionInfoVerify] forState:UIControlStateHighlighted];
                [_blockButton setTitle:[VectorL10n roomEventEncryptionInfoBlock] forState:UIControlStateNormal];
                [_blockButton setTitle:[VectorL10n roomEventEncryptionInfoBlock] forState:UIControlStateHighlighted];
                break;
            }
            case MXDeviceVerified:
            {
                verification = [[NSMutableAttributedString alloc]
                                initWithString:[VectorL10n roomEventEncryptionInfoDeviceVerified]
                                attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                             NSFontAttributeName: [UIFont systemFontOfSize:14]}];
                
                [_verifyButton setTitle:[VectorL10n roomEventEncryptionInfoUnverify] forState:UIControlStateNormal];
                [_verifyButton setTitle:[VectorL10n roomEventEncryptionInfoUnverify] forState:UIControlStateHighlighted];
                [_blockButton setTitle:[VectorL10n roomEventEncryptionInfoBlock] forState:UIControlStateNormal];
                [_blockButton setTitle:[VectorL10n roomEventEncryptionInfoBlock] forState:UIControlStateHighlighted];
                
                break;
            }
            case MXDeviceBlocked:
            {
                verification = [[NSMutableAttributedString alloc]
                                initWithString:[VectorL10n roomEventEncryptionInfoDeviceBlocked]
                                attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                             NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}];
                
                [_verifyButton setTitle:[VectorL10n roomEventEncryptionInfoVerify] forState:UIControlStateNormal];
                [_verifyButton setTitle:[VectorL10n roomEventEncryptionInfoVerify] forState:UIControlStateHighlighted];
                [_blockButton setTitle:[VectorL10n roomEventEncryptionInfoUnblock] forState:UIControlStateNormal];
                [_blockButton setTitle:[VectorL10n roomEventEncryptionInfoUnblock] forState:UIControlStateHighlighted];
                
                break;
            }
            default:
                break;
        }
        
        [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[VectorL10n roomEventEncryptionInfoDeviceName]
                                                         attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                      NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:(name.length ? name : @"")
                                                         attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                      NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [deviceInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];
        
        [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[VectorL10n roomEventEncryptionInfoDeviceId]
                                                         attributes:@{NSForegroundColorAttributeName: _defaultTextColor, NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:deviceId
                                                         attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                      NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [deviceInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];
        
        [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[VectorL10n roomEventEncryptionInfoDeviceVerification]
                                                         attributes:@{NSForegroundColorAttributeName: _defaultTextColor, NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [deviceInformationString appendAttributedString:verification];
        [deviceInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];
        
        [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[VectorL10n roomEventEncryptionInfoDeviceFingerprint]
                                                         attributes:@{NSForegroundColorAttributeName: _defaultTextColor, NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
        [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:fingerprint
                                                         attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                      NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
        [deviceInformationString appendAttributedString:[MXKEncryptionInfoView verticalWhitespace]];
    }
    else
    {
        // Unknown device
        [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[VectorL10n roomEventEncryptionInfoDeviceUnknown]
                                                         attributes:@{NSForegroundColorAttributeName: _defaultTextColor, NSFontAttributeName: [UIFont italicSystemFontOfSize:14]}]];
    }
    
    [textViewAttributedString appendAttributedString:deviceInformationString];
    
    self.textView.attributedText = textViewAttributedString;
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

        if ([_delegate respondsToSelector:@selector(encryptionInfoViewDidClose:)])
        {
            [_delegate encryptionInfoViewDidClose:self];
        }
    }
    // Note: Verify and Block buttons are hidden when the deviceInfo is not available
    else if (sender == _confirmVerifyButton && _mxDeviceInfo)
    {
        [_mxSession.crypto setDeviceVerification:MXDeviceVerified forDevice:_mxDeviceInfo.deviceId ofUser:_mxDeviceInfo.userId success:^{

            // Refresh data
            self->_mxDeviceInfo = [self.mxSession.crypto eventDeviceInfo:self.mxEvent];
            if (self->_delegate)
            {
                [self->_delegate encryptionInfoView:self didDeviceInfoVerifiedChange:self.mxDeviceInfo];
            }
            [self removeFromSuperview];

        } failure:^(NSError *error) {
            [self removeFromSuperview];
        }];
    }
    else if (_mxDeviceInfo)
    {
        MXDeviceVerification verificationStatus;
        
        if (sender == _verifyButton)
        {
            verificationStatus = ((_mxDeviceInfo.trustLevel.localVerificationStatus == MXDeviceVerified) ? MXDeviceUnverified : MXDeviceVerified);
        }
        else if (sender == _blockButton)
        {
            verificationStatus = ((_mxDeviceInfo.trustLevel.localVerificationStatus == MXDeviceBlocked) ? MXDeviceUnverified : MXDeviceBlocked);
        }
        else
        {
            // Unexpected case
            MXLogDebug(@"[MXKEncryptionInfoView] Invalid button pressed.");
            return;
        }
        
        if (verificationStatus == MXDeviceVerified)
        {
            // Prompt user
            NSMutableAttributedString *textViewAttributedString = [[NSMutableAttributedString alloc]
                                                                   initWithString:[VectorL10n roomEventEncryptionVerifyTitle]
                                                                   attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                                NSFontAttributeName: [UIFont boldSystemFontOfSize:17]}];
            
            NSString *message = [VectorL10n roomEventEncryptionVerifyMessage:_mxDeviceInfo.displayName :_mxDeviceInfo.deviceId :_mxDeviceInfo.fingerprint];
            
            [textViewAttributedString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:message
                                                             attributes:@{NSForegroundColorAttributeName: _defaultTextColor,
                                                                          NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            
            self.textView.attributedText = textViewAttributedString;
            
            [_cancelButton setTitle:[VectorL10n cancel] forState:UIControlStateNormal];
            [_cancelButton setTitle:[VectorL10n cancel] forState:UIControlStateHighlighted];
            _verifyButton.hidden = _blockButton.hidden = YES;
            _confirmVerifyButton.hidden = NO;
        }
        else
        {
            [_mxSession.crypto setDeviceVerification:verificationStatus forDevice:_mxDeviceInfo.deviceId ofUser:_mxDeviceInfo.userId success:^{

                // Refresh data
                self->_mxDeviceInfo = [self.mxSession.crypto eventDeviceInfo:self.mxEvent];

                if (self->_delegate)
                {
                    [self->_delegate encryptionInfoView:self didDeviceInfoVerifiedChange:self.mxDeviceInfo];
                }

                [self removeFromSuperview];

            } failure:^(NSError *error) {
                [self removeFromSuperview];
            }];
        }
    }
}

@end
