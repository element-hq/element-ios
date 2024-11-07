/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomTitleView.h"

#import "MXKConstants.h"

#import "NSBundle+MatrixKit.h"
#import "MXRoom+Sync.h"

#import "MXKSwiftHeader.h"

@interface MXKRoomTitleView ()
{
    // Observer kMXRoomSummaryDidChangeNotification to keep updated the room name.
    __weak id mxRoomSummaryDidChangeObserver;
}
@end

@implementation MXKRoomTitleView
@synthesize inputAccessoryView;

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKRoomTitleView class])
                          bundle:[NSBundle bundleForClass:[MXKRoomTitleView class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setTranslatesAutoresizingMaskIntoConstraints: NO];
    
    // Add an accessory view to the text view in order to retrieve keyboard view.
    inputAccessoryView = [[UIView alloc] initWithFrame:CGRectZero];
    self.displayNameTextField.inputAccessoryView = inputAccessoryView;
    
    self.displayNameTextField.enabled = NO;
    self.displayNameTextField.returnKeyType = UIReturnKeyDone;
    self.displayNameTextField.hidden = YES;
}

+ (instancetype)roomTitleView
{
    return [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
}

- (void)dealloc
{
    inputAccessoryView = nil;
}

#pragma mark - Override MXKView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

#pragma mark -

- (void)refreshDisplay
{
    if (_mxRoom)
    {
        // Replace empty string by nil : avoid having the placeholder 'Room name" when there is no displayname
        self.displayNameTextField.text = (_mxRoom.summary.displayName.length) ? _mxRoom.summary.displayName : nil;
    }
    else if (_mxUser)
    {
        self.displayNameTextField.text = (_mxUser.displayname.length) ? _mxUser.displayname : _mxUser.userId;
    }
    else
    {
        self.displayNameTextField.text = [VectorL10n roomPleaseSelect];
        self.displayNameTextField.enabled = NO;
    }
    self.displayNameTextField.hidden = NO;
}

- (void)destroy
{
    self.delegate = nil;
    self.mxRoom = nil;
    
    if (mxRoomSummaryDidChangeObserver)
    {
        [NSNotificationCenter.defaultCenter removeObserver:mxRoomSummaryDidChangeObserver];
        mxRoomSummaryDidChangeObserver = nil;
    }
}

- (void)dismissKeyboard
{
    // Hide the keyboard
    [self.displayNameTextField resignFirstResponder];
}

#pragma mark -

- (void)setMxRoom:(MXRoom *)mxRoom
{
    // Check whether the room is actually changed
    if (_mxRoom != mxRoom)
    {
        // Remove potential listener
        if (mxRoomSummaryDidChangeObserver)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:mxRoomSummaryDidChangeObserver];
            mxRoomSummaryDidChangeObserver = nil;
        }
        
        if (mxRoom)
        {
            MXWeakify(self);
            
            // Register a listener to handle the room name change
            mxRoomSummaryDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomSummaryDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                
                MXStrongifyAndReturnIfNil(self);
                
                // Check whether the text field is editing before refreshing title view
                if (!self.isEditing)
                {
                    [self refreshDisplay];
                }
                
            }];
        }
        _mxRoom = mxRoom;
    }
    // Force refresh
    [self refreshDisplay];
}

- (void)setMxUser:(MXUser *)mxUser
{
    _mxUser = mxUser;
    
    if (mxUser) {
        // Force refresh
        [self refreshDisplay];
    }
}

- (void)setEditable:(BOOL)editable
{
    self.displayNameTextField.enabled = editable;
}

- (BOOL)isEditing
{
    return self.displayNameTextField.isEditing;
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // check if the deleaget allows the edition
    if (!self.delegate || [self.delegate roomTitleViewShouldBeginEditing:self])
    {
        NSString *alertMsg = nil;
        
        if (textField == self.displayNameTextField)
        {
            // Check whether the user has enough power to rename the room
            MXRoomPowerLevels *powerLevels = _mxRoom.dangerousSyncState.powerLevels;

            NSInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:_mxRoom.mxSession.myUser.userId];
            if (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomName])
            {
                // Only the room name is edited here, update the text field with the room name
                textField.text = _mxRoom.summary.displayName;
                textField.backgroundColor = [UIColor whiteColor];
            }
            else
            {
                alertMsg = [VectorL10n roomErrorNameEditionNotAuthorized];
            }
        }
        
        if (alertMsg)
        {
            // Alert user
            __weak typeof(self) weakSelf = self;
            if (currentAlert)
            {
                [currentAlert dismissViewControllerAnimated:NO completion:nil];
            }
            
            currentAlert = [UIAlertController alertControllerWithTitle:nil message:alertMsg preferredStyle:UIAlertControllerStyleAlert];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                                                        
                                                        typeof(self) self = weakSelf;
                                                        self->currentAlert = nil;
                                                        
                                                    }]];
            
            [self.delegate roomTitleView:self presentAlertController:currentAlert];
            return NO;
        }
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.displayNameTextField)
    {
        textField.backgroundColor = [UIColor clearColor];
        
        NSString *roomName = textField.text;
        if ((roomName.length || _mxRoom.summary.displayName.length) && [roomName isEqualToString:_mxRoom.summary.displayName] == NO)
        {
            if ([self.delegate respondsToSelector:@selector(roomTitleView:isSaving:)])
            {
                [self.delegate roomTitleView:self isSaving:YES];
            }
            
            __weak typeof(self) weakSelf = self;
            [_mxRoom setName:roomName success:^{
                
                if (weakSelf)
                {
                    typeof(weakSelf)strongSelf = weakSelf;
                    if ([strongSelf.delegate respondsToSelector:@selector(roomTitleView:isSaving:)])
                    {
                        [strongSelf.delegate roomTitleView:strongSelf isSaving:NO];
                    }
                }
                
            } failure:^(NSError *error) {
                
                if (weakSelf)
                {
                    typeof(weakSelf)strongSelf = weakSelf;
                    if ([strongSelf.delegate respondsToSelector:@selector(roomTitleView:isSaving:)])
                    {
                        [strongSelf.delegate roomTitleView:strongSelf isSaving:NO];
                    }
                    
                    // Revert change
                    textField.text = strongSelf.mxRoom.summary.displayName;
                    MXLogDebug(@"[MXKRoomTitleView] Rename room failed");
                    // Notify MatrixKit user
                    NSString *myUserId = strongSelf.mxRoom.mxSession.myUser.userId;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                }
                
            }];
        }
        else
        {
            // No change on room name, restore title with room displayName
            textField.text = _mxRoom.summary.displayName;
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*) textField
{
    // "Done" key has been pressed
    [textField resignFirstResponder];
    return YES;
}

@end
