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

#import "MXKRoomInputToolbarViewWithSimpleTextView.h"
#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation MXKRoomInputToolbarViewWithSimpleTextView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKRoomInputToolbarViewWithSimpleTextView class])
                          bundle:[NSBundle bundleForClass:[MXKRoomInputToolbarViewWithSimpleTextView class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Add an accessory view to the text view in order to retrieve keyboard view.
    inputAccessoryViewForKeyboard = [[UIView alloc] initWithFrame:CGRectZero];
    self.messageComposerTextView.inputAccessoryView = inputAccessoryViewForKeyboard;
}

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    // Set default message composer background color
    self.messageComposerTextView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.backgroundColor = ThemeService.shared.theme.colors.system;
    self.leftInputToolbarButton.tintColor = ThemeService.shared.theme.colors.accent;
    self.rightInputToolbarButton.tintColor = ThemeService.shared.theme.colors.accent;
}

- (NSString*)textMessage
{
    return _messageComposerTextView.text;
}

- (void)setTextMessage:(NSString *)textMessage
{
    _messageComposerTextView.text = textMessage;
    self.rightInputToolbarButton.enabled = textMessage.length;
}

- (void)pasteText:(NSString *)text
{
    self.textMessage = [_messageComposerTextView.text stringByReplacingCharactersInRange:_messageComposerTextView.selectedRange withString:text];
}

- (BOOL)becomeFirstResponder
{
    return [_messageComposerTextView becomeFirstResponder];
}

- (void)dismissKeyboard
{
    if (_messageComposerTextView)
    {
        [_messageComposerTextView resignFirstResponder];
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:isTyping:)])
    {
        [self.delegate roomInputToolbarView:self isTyping:NO];
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSString *msg = textView.text;
    
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

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (!self.isEditable)
    {
        return NO;
    }
    
    // Hanlde here `Done` key pressed
    if([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

@end
