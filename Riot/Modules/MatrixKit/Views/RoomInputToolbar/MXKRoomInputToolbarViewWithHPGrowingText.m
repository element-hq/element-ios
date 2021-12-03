/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "MXKRoomInputToolbarViewWithHPGrowingText.h"

@interface MXKRoomInputToolbarViewWithHPGrowingText()
{
    // HPGrowingTextView triggers growingTextViewDidChange event when it recomposes itself
    // Save the last edited text to prevent unexpected typing events
    NSString* lastEditedText;
}

/**
 Message composer defined in `messageComposerContainer`.
 */
@property (nonatomic) IBOutlet HPGrowingTextView *growingTextView;

@end

@implementation MXKRoomInputToolbarViewWithHPGrowingText
@synthesize growingTextView;

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKRoomInputToolbarViewWithHPGrowingText class])
                          bundle:[NSBundle bundleForClass:[MXKRoomInputToolbarViewWithHPGrowingText class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Handle message composer based on HPGrowingTextView use
    growingTextView.delegate = self;
    
    [growingTextView setTranslatesAutoresizingMaskIntoConstraints: NO];
    
    // Add an accessory view to the text view in order to retrieve keyboard view.
    inputAccessoryView = [[UIView alloc] initWithFrame:CGRectZero];
    growingTextView.internalTextView.inputAccessoryView = self.inputAccessoryView;
    
    // on IOS 8, the growing textview animation could trigger weird UI animations
    // indeed, the messages tableView can be refreshed while its height is updated (e.g. when setting a message)
    growingTextView.animateHeightChange = NO;
    
    lastEditedText = nil;
}

- (void)dealloc
{
    [self destroy];
}

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    // set text input font
    growingTextView.font = [UIFont systemFontOfSize:14];
    
    // draw a rounded border around the textView
    growingTextView.layer.cornerRadius = 5;
    growingTextView.layer.borderWidth = 1;
    growingTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    growingTextView.clipsToBounds = YES;
    growingTextView.backgroundColor = [UIColor whiteColor];
}

- (void)destroy
{
    if (growingTextView)
    {
        growingTextView.delegate = nil;
        growingTextView = nil;
    }
    
    [super destroy];
}

- (void)setMaxHeight:(CGFloat)maxHeight
{
    growingTextView.maxHeight = maxHeight - (self.messageComposerContainerTopConstraint.constant + self.messageComposerContainerBottomConstraint.constant);
    [growingTextView refreshHeight];
    
    super.maxHeight = maxHeight;
}

- (NSString*)textMessage
{
    return growingTextView.text;
}

- (void)setTextMessage:(NSString *)textMessage
{
    growingTextView.text = textMessage;
    self.rightInputToolbarButton.enabled = textMessage.length;    
}

- (void)pasteText:(NSString *)text
{
    self.textMessage = [growingTextView.text stringByReplacingCharactersInRange:growingTextView.selectedRange withString:text];
}

- (void)setPlaceholder:(NSString *)inPlaceholder
{
    [super setPlaceholder:inPlaceholder];
    growingTextView.placeholder = inPlaceholder;
}

- (BOOL)becomeFirstResponder
{
    return [growingTextView becomeFirstResponder];
}

- (void)dismissKeyboard
{
    [growingTextView resignFirstResponder];
}

#pragma mark - HPGrowingTextView delegate

- (void)growingTextViewDidEndEditing:(HPGrowingTextView *)sender
{
    if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:isTyping:)])
    {
        [self.delegate roomInputToolbarView:self isTyping:NO];
    }
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)sender
{
    NSString *msg = growingTextView.text;
    
    // HPGrowingTextView triggers growingTextViewDidChange event when it recomposes itself.
    // Save the last edited text to prevent unexpected typing events
    if (![lastEditedText isEqualToString:msg])
    {
        lastEditedText = msg;
        if (msg.length)
        {
            if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:isTyping:)])
            {
                [self.delegate roomInputToolbarView:self isTyping:YES];
            }
            self.rightInputToolbarButton.enabled = YES;
        }
        else
        {
            if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:isTyping:)])
            {
                [self.delegate roomInputToolbarView:self isTyping:NO];
            }
            self.rightInputToolbarButton.enabled = NO;
        }
    }
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    // Update growing text's superview (toolbar view)
    CGFloat updatedHeight = height + (self.messageComposerContainerTopConstraint.constant + self.messageComposerContainerBottomConstraint.constant);
    if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:heightDidChanged:completion:)])
    {
        [self.delegate roomInputToolbarView:self heightDidChanged:updatedHeight completion:nil];
    }
}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return self.isEditable;
}

@end
