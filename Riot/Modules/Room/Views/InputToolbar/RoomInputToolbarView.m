/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomInputToolbarView.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

static const CGFloat kContextBarHeight = 24;
static const CGFloat kActionMenuAttachButtonSpringVelocity = 7;
static const CGFloat kActionMenuAttachButtonSpringDamping = .45;

static const NSTimeInterval kSendModeAnimationDuration = .15;
static const NSTimeInterval kActionMenuAttachButtonAnimationDuration = .4;
static const NSTimeInterval kActionMenuContentAlphaAnimationDuration = .2;
static const NSTimeInterval kActionMenuComposerHeightAnimationDuration = .3;

@interface RoomInputToolbarView() <UITextViewDelegate, RoomInputToolbarTextViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *mainToolbarView;

@property (nonatomic, weak) IBOutlet UIButton *attachMediaButton;

@property (nonatomic, weak) IBOutlet RoomInputToolbarTextView *textView;
@property (nonatomic, weak) IBOutlet UIImageView *inputTextBackgroundView;

@property (nonatomic, weak) IBOutlet UIImageView *inputContextImageView;
@property (nonatomic, weak) IBOutlet UILabel *inputContextLabel;
@property (nonatomic, weak) IBOutlet UIButton *inputContextButton;

@property (nonatomic, weak) IBOutlet RoomActionsBar *actionsBar;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mainToolbarMinHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mainToolbarHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *messageComposerContainerTrailingConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *inputContextViewHeightConstraint;

@property (nonatomic, weak) UIView *voiceMessageToolbarView;

@property (nonatomic, assign) CGFloat expandedMainToolbarHeight;

@end

@implementation RoomInputToolbarView
@dynamic delegate;

+ (MXKRoomInputToolbarView *)instantiateRoomInputToolbarView
{
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([RoomInputToolbarView class]) bundle:nil];
    return [nib instantiateWithOwner:nil options:nil].firstObject;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _sendMode = RoomInputToolbarViewSendModeSend;
    self.inputContextViewHeightConstraint.constant = 0;
    self.inputContextLabel.isAccessibilityElement = NO;
    self.inputContextButton.isAccessibilityElement = NO;

    [self.rightInputToolbarButton setTitle:nil forState:UIControlStateNormal];
    [self.rightInputToolbarButton setTitle:nil forState:UIControlStateHighlighted];

    self.isEncryptionEnabled = _isEncryptionEnabled;
    
    [self updateUIWithAttributedTextMessage:nil animated:NO];
    
    self.textView.toolbarDelegate = self;

    inputAccessoryViewForKeyboard = [[UIView alloc] initWithFrame:CGRectZero];
    self.textView.inputAccessoryView = inputAccessoryViewForKeyboard;
}

#pragma mark - Override MXKView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    // Remove default toolbar background color
    self.backgroundColor = [UIColor clearColor];
    
    // Custom the growingTextView display
    self.textView.layer.cornerRadius = 0;
    self.textView.layer.borderWidth = 0;
    self.textView.backgroundColor = [UIColor clearColor];

    self.textView.font = [UIFont systemFontOfSize:15];
    self.textView.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.textView.tintColor = ThemeService.shared.theme.tintColor;
    self.textView.placeholderColor = ThemeService.shared.theme.textTertiaryColor;
    self.textView.showsVerticalScrollIndicator = NO;

    // Trigger textView redraw using proper color/font.
    NSAttributedString *newText = self.textView.attributedText;
    self.textView.attributedText = nil;
    self.textView.attributedText = newText;
    
    self.textView.keyboardAppearance = ThemeService.shared.theme.keyboardAppearance;
    if (self.textView.isFirstResponder)
    {
        [self.textView resignFirstResponder];
        [self.textView becomeFirstResponder];
    }

    self.attachMediaButton.accessibilityLabel = [VectorL10n roomAccessibilityUpload];
    
    UIImage *image = AssetImages.inputTextBackground.image;
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(9, 15, 10, 16)];
    self.inputTextBackgroundView.image = image;
    self.inputTextBackgroundView.tintColor = ThemeService.shared.theme.roomInputTextBorder;
    
    if ([ThemeService.shared.themeId isEqualToString:@"light"])
    {
        [self.attachMediaButton setImage:AssetImages.uploadIcon.image forState:UIControlStateNormal];
    }
    else if ([ThemeService.shared.themeId isEqualToString:@"dark"] || [ThemeService.shared.themeId isEqualToString:@"black"])
    {
        [self.attachMediaButton setImage:AssetImages.uploadIconDark.image forState:UIControlStateNormal];
    }
    else if (ThemeService.shared.theme.userInterfaceStyle == UIUserInterfaceStyleDark) {
        [self.attachMediaButton setImage:AssetImages.uploadIconDark.image forState:UIControlStateNormal];
    }
    
    self.inputContextImageView.tintColor = ThemeService.shared.theme.textSecondaryColor;
    self.inputContextLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
    self.inputContextButton.tintColor = ThemeService.shared.theme.textSecondaryColor;
    [self.actionsBar updateWithTheme:ThemeService.shared.theme];
}

#pragma mark -

- (void)setTextMessage:(NSString *)textMessage
{
    [self setAttributedTextMessage:textMessage ? [[NSAttributedString alloc] initWithString:textMessage] : nil];
}

- (void)setAttributedTextMessage:(NSAttributedString *)attributedTextMessage
{
    if (attributedTextMessage)
    {
        NSMutableAttributedString *mutableTextMessage = [[NSMutableAttributedString alloc] initWithAttributedString:attributedTextMessage];
        [mutableTextMessage addAttributes:@{ NSForegroundColorAttributeName: ThemeService.shared.theme.textPrimaryColor,
                                             NSFontAttributeName: self.defaultFont }
                                    range:NSMakeRange(0, mutableTextMessage.length)];
        attributedTextMessage = mutableTextMessage;
    }

    self.textView.attributedText = attributedTextMessage;

    if (@available(iOS 15.0, *)) {
        // Fixes an iOS 16 issue where attachment are not drawn properly by
        // forcing the layoutManager to redraw the glyphs at all NSAttachment positions.
        [self.textView vc_invalidateTextAttachmentsDisplay];
    }

    [self updateUIWithAttributedTextMessage:attributedTextMessage animated:YES];
    [self textViewDidChange:self.textView];
}

- (NSAttributedString *)attributedTextMessage
{
    return self.textView.attributedText;
}

- (NSString *)textMessage
{
    return self.textView.text;
}

- (UIFont *)defaultFont
{
    if (self.textView.font)
    {
        return self.textView.font;
    }
    else
    {
        return [UIFont systemFontOfSize:15.f];
    }
}

- (void)setIsEncryptionEnabled:(BOOL)isEncryptionEnabled
{
    _isEncryptionEnabled = isEncryptionEnabled;
    
    [self updatePlaceholder];
}

- (void)setSendMode:(RoomInputToolbarViewSendMode)sendMode
{
    RoomInputToolbarViewSendMode previousMode = _sendMode;
    _sendMode = sendMode;

    self.actionMenuOpened = NO;
    [self updatePlaceholder];
    [self updateToolbarButtonLabelWithPreviousMode: previousMode];
}

- (void)updateToolbarButtonLabelWithPreviousMode:(RoomInputToolbarViewSendMode)previousMode
{
    UIImage *buttonImage;

    double updatedHeight = self.mainToolbarHeightConstraint.constant;
    
    switch (_sendMode)
    {
        case RoomInputToolbarViewSendModeReply:
            buttonImage = AssetImages.sendIcon.image;
            self.inputContextImageView.image = AssetImages.inputReplyIcon.image;
            self.inputContextLabel.text = [VectorL10n roomMessageReplyingTo:self.eventSenderDisplayName];

            self.inputContextViewHeightConstraint.constant = kContextBarHeight;
            updatedHeight += kContextBarHeight;
            self.textView.maxHeight -= kContextBarHeight;
            break;
        case RoomInputToolbarViewSendModeEdit:
            buttonImage = AssetImages.saveIcon.image;
            self.inputContextImageView.image = AssetImages.inputEditIcon.image;
            self.inputContextLabel.text = [VectorL10n roomMessageEditing];

            self.inputContextViewHeightConstraint.constant = kContextBarHeight;
            updatedHeight += kContextBarHeight;
            self.textView.maxHeight -= kContextBarHeight;
            break;
        case RoomInputToolbarViewSendModeCreateDM:
            buttonImage = AssetImages.sendIcon.image;
            self.inputContextViewHeightConstraint.constant = 0;
            break;
        default:
            buttonImage = AssetImages.sendIcon.image;

            if (previousMode != _sendMode)
            {
                updatedHeight -= kContextBarHeight;
                self.textView.maxHeight += kContextBarHeight;
            }
            self.inputContextViewHeightConstraint.constant = 0;
            break;
    }
    
    // Hide the context items from VoiceOver when the context view is "hidden".
    self.inputContextLabel.isAccessibilityElement = self.inputContextViewHeightConstraint.constant > 0;
    self.inputContextButton.isAccessibilityElement = self.inputContextViewHeightConstraint.constant > 0;
    
    [self.rightInputToolbarButton setImage:buttonImage forState:UIControlStateNormal];
    
    if (self.maxHeight && updatedHeight > self.maxHeight)
    {
        self.textView.maxHeight -= updatedHeight - self.maxHeight;
        updatedHeight = self.maxHeight;
    }

    if (updatedHeight < self.mainToolbarMinHeightConstraint.constant)
    {
        updatedHeight = self.mainToolbarMinHeightConstraint.constant;
    }

    if (self.mainToolbarHeightConstraint.constant != updatedHeight)
    {
        [UIView animateWithDuration:kSendModeAnimationDuration animations:^{
            self.mainToolbarHeightConstraint.constant = updatedHeight;
            [self layoutIfNeeded];
            
            // Update toolbar superview
            if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:heightDidChanged:completion:)])
            {
                [self.delegate roomInputToolbarView:self heightDidChanged:updatedHeight completion:nil];
            }
        }];
    }
}

- (void)setPlaceholder:(NSString *)inPlaceholder
{
    [super setPlaceholder:inPlaceholder];
    self.textView.placeholder = inPlaceholder;
}

- (void)pasteText:(NSString *)text
{
    self.textMessage = [self.textView.text stringByReplacingCharactersInRange:self.textView.selectedRange withString:text];
}

#pragma mark - Actions

- (IBAction)cancelAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(roomInputToolbarViewDidTapCancel:)])
    {
        [self.delegate roomInputToolbarViewDidTapCancel:self];
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSMutableAttributedString *newText = [[NSMutableAttributedString alloc] initWithAttributedString:textView.attributedText];
    [newText replaceCharactersInRange:range withString:text];
    [self updateUIWithAttributedTextMessage:newText animated:YES];

    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    // Clean the carriage return added on return press
    if ([self.textMessage isEqualToString:@"\n"])
    {
        self.textMessage = nil;
    }
    
    if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:isTyping:)])
    {
        [self.delegate roomInputToolbarView:self isTyping:(self.textMessage.length > 0 ? YES : NO)];
    }

    [self.delegate roomInputToolbarViewDidChangeTextMessage:self];
}

#pragma mark - RoomInputToolbarTextViewDelegate

- (void)textView:(RoomInputToolbarTextView *)textView didChangeHeight:(CGFloat)height
{
    // Update height of the main toolbar (message composer)
    CGFloat updatedHeight = height + (self.messageComposerContainerTopConstraint.constant + self.messageComposerContainerBottomConstraint.constant) + self.inputContextViewHeightConstraint.constant;

    if (self.maxHeight && updatedHeight > self.maxHeight)
    {
        textView.maxHeight -= updatedHeight - self.maxHeight;
        updatedHeight = self.maxHeight;
    }

    if (updatedHeight < self.mainToolbarMinHeightConstraint.constant)
    {
        updatedHeight = self.mainToolbarMinHeightConstraint.constant;
    }

    self.mainToolbarHeightConstraint.constant = updatedHeight;

    // Update toolbar superview
    if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:heightDidChanged:completion:)])
    {
        [self.delegate roomInputToolbarView:self heightDidChanged:updatedHeight completion:nil];
    }
}

- (void)textView:(RoomInputToolbarTextView *)textView didReceivePasteForMediaFromSender:(id)sender
{
    [self paste:sender];
}

#pragma mark - Override MXKRoomInputToolbarView

- (IBAction)onTouchUpInside:(UIButton*)button
{
    if (button == self.attachMediaButton)
    {
        self.actionMenuOpened = !self.actionMenuOpened;
    }

    [super onTouchUpInside:button];
}

- (BOOL)isFirstResponder
{
    return [self.textView isFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    return [self.textView becomeFirstResponder];
}

- (void)dismissKeyboard
{
    [self.textView resignFirstResponder];
}

- (void)destroy
{
    [super destroy];
}

#pragma mark - properties

- (void)setActionMenuOpened:(BOOL)actionMenuOpened
{
    if (_actionMenuOpened != actionMenuOpened)
    {
        _actionMenuOpened = actionMenuOpened;
        
        if (self.textView.selectedRange.length > 0)
        {
            NSRange range = self.textView.selectedRange;
            range.location = range.location + range.length;
            range.length = 0;
            self.textView.selectedRange = range;
        }

        if (_actionMenuOpened) {
            self.actionsBar.hidden = NO;
            [self.actionsBar animateWithShowIn:_actionMenuOpened completion:nil];
            [self.delegate roomInputToolbarViewDidOpenActionMenu:self];
        }
        else
        {
            [self.actionsBar animateWithShowIn:_actionMenuOpened completion:^(BOOL finished) {
                self.actionsBar.hidden = YES;
            }];
        }
        
        [UIView animateWithDuration:kActionMenuAttachButtonAnimationDuration delay:0 usingSpringWithDamping:kActionMenuAttachButtonSpringDamping initialSpringVelocity:kActionMenuAttachButtonSpringVelocity options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.attachMediaButton.transform = actionMenuOpened ? CGAffineTransformMakeRotation(M_PI * 3 / 4) : CGAffineTransformIdentity;
        } completion:nil];
        
        [UIView animateWithDuration:kActionMenuContentAlphaAnimationDuration delay:_actionMenuOpened ? 0 : .1 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self->messageComposerContainer.alpha = actionMenuOpened ? 0 : 1;
            self.rightInputToolbarButton.alpha = self.textView.text.length == 0 || actionMenuOpened ? 0 : 1;
            self.voiceMessageToolbarView.alpha = self.textView.text.length > 0 || actionMenuOpened ? 0 : 1;
        } completion:nil];
        
        [UIView animateWithDuration:kActionMenuComposerHeightAnimationDuration animations:^{
            if (actionMenuOpened)
            {
                self.expandedMainToolbarHeight = self.mainToolbarHeightConstraint.constant;
                self.mainToolbarHeightConstraint.constant = self.mainToolbarMinHeightConstraint.constant;
            }
            else
            {
                self.mainToolbarHeightConstraint.constant = self.expandedMainToolbarHeight;
            }
            [self layoutIfNeeded];
            [self.delegate roomInputToolbarView:self heightDidChanged:self.mainToolbarHeightConstraint.constant completion:nil];
        }];
    }
}

#pragma mark - Private

- (void)updateUIWithAttributedTextMessage:(NSAttributedString *)attributedTextMessage animated:(BOOL)animated
{
    self.actionMenuOpened = NO;
        
    [UIView animateWithDuration:(animated ? 0.15f : 0.0f) animations:^{
        self.rightInputToolbarButton.alpha = attributedTextMessage.length ? 1.0f : 0.0f;
        self.rightInputToolbarButton.enabled = attributedTextMessage.length;
        
        self.voiceMessageToolbarView.alpha = attributedTextMessage.length ? 0.0f : 1.0;
    }];
}

#pragma mark - RoomInputToolbarViewProtocol

- (CGFloat)toolbarHeight {
    return self.mainToolbarHeightConstraint.constant;
}

- (void)setVoiceMessageToolbarView:(UIView *)voiceMessageToolbarView
{
    if (voiceMessageToolbarView) {
        _voiceMessageToolbarView = voiceMessageToolbarView;
        self.voiceMessageToolbarView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.voiceMessageToolbarView];

        [NSLayoutConstraint activateConstraints:@[[self.mainToolbarView.topAnchor constraintEqualToAnchor:self.voiceMessageToolbarView.topAnchor],
                                                  [self.mainToolbarView.leftAnchor constraintEqualToAnchor:self.voiceMessageToolbarView.leftAnchor],
                                                  [self.mainToolbarView.bottomAnchor constraintEqualToAnchor:self.voiceMessageToolbarView.bottomAnchor],
                                                  [self.mainToolbarView.rightAnchor constraintEqualToAnchor:self.voiceMessageToolbarView.rightAnchor]]];
        
        // The voice message toolbar is taller than the input toolbar so the record button is read
        // out before the other subviews. Fix this by manually adding the elements in the right order.
        self.accessibilityElements = @[self.attachMediaButton,
                                       self.actionsBar,
                                       self.inputContextLabel,
                                       self.inputContextButton,
                                       self.textView,
                                       self.rightInputToolbarButton,
                                       self.voiceMessageToolbarView];
    }
    else
    {
        [self.voiceMessageToolbarView removeFromSuperview];
        _voiceMessageToolbarView = nil;
        self.accessibilityElements = nil;
    }
}
@end
