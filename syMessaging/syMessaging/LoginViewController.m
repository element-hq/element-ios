/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "LoginViewController.h"

#import "MatrixHandler.h"
#import "AppDelegate.h"

NSString* const defaultHomeserver = @"http://www.matrix.org";

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewBottomConstraint;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UITextField *homeServerTextField;
@property (weak, nonatomic) IBOutlet UITextField *userLoginTextField;
@property (weak, nonatomic) IBOutlet UITextField *passWordTextField;

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIButton *createAccountBtn;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Finalize scrollView content size
    _contentViewBottomConstraint.constant = 0;
    
    // Force contentView in full width
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:0
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1.0
                                                                       constant:0];
    [self.view addConstraint:leftConstraint];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:0
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeRight
                                                                      multiplier:1.0
                                                                        constant:0];
    [self.view addConstraint:rightConstraint];

    
    // Prefill text field
    _userLoginTextField.text = [[MatrixHandler sharedHandler] userLogin];
    _homeServerTextField.text = [[MatrixHandler sharedHandler] homeServerURL];
    if (! _homeServerTextField.text.length) {
        [[MatrixHandler sharedHandler] setHomeServerURL:defaultHomeserver];
        self.homeServerTextField.text = defaultHomeserver;
    }
    _passWordTextField.text = nil;
    _loginBtn.enabled = NO;
    _loginBtn.alpha = 0.5;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextFieldChange:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)onKeyboardWillShow:(NSNotification *)notif {
    NSValue *rectVal = notif.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect endRect = rectVal.CGRectValue;
    
    UIEdgeInsets insets = self.scrollView.contentInset;
    // Handle portrait/landscape mode
    insets.bottom = (endRect.origin.y == 0) ? endRect.size.width : endRect.size.height;
    self.scrollView.contentInset = insets;
    
    for (UITextField *tf in @[ self.userLoginTextField, self.passWordTextField, self.homeServerTextField]) {
        if ([tf isFirstResponder]) {
            CGRect tfFrame = tf.frame;
            [self.scrollView scrollRectToVisible:tfFrame animated:YES];
        }
    }
}

- (void)onKeyboardWillHide:(NSNotification *)notif {
    UIEdgeInsets insets = self.scrollView.contentInset;
    insets.bottom = 0;
    self.scrollView.contentInset = insets;
}

- (void)dismissKeyboard
{
    // Hide the keyboard
    [_userLoginTextField resignFirstResponder];
    [_passWordTextField resignFirstResponder];
    [_homeServerTextField resignFirstResponder];
}

#pragma mark - UITextField delegate

- (void)onTextFieldChange:(NSNotification *)notif {
    NSString *user = _userLoginTextField.text;
    NSString *pass = _passWordTextField.text;
    NSString *homeServerURL = _homeServerTextField.text;
    
    if (user.length && pass.length && homeServerURL.length) {
        _loginBtn.enabled = YES;
        _loginBtn.alpha = 1;
    } else {
        _loginBtn.enabled = NO;
        _loginBtn.alpha = 0.5;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    MatrixHandler *matrix = [MatrixHandler sharedHandler];
    
    if (textField == _userLoginTextField) {
        [matrix setUserLogin:textField.text];
    }
    else if (textField == _homeServerTextField) {
        [matrix setHomeServerURL:textField.text];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*) textField
{
    if (textField == _userLoginTextField) {
        // "Next" key has been pressed
        [_passWordTextField becomeFirstResponder];
    }
    else {
        // "Done" key has been pressed
        [textField resignFirstResponder];
        
        if (_loginBtn.isEnabled)
        {
            // Launch authentication now
            [self onButtonPressed:_loginBtn];
        }
    }
    
    return YES;
}

- (IBAction)onButtonPressed:(id)sender
{
    [self dismissKeyboard];
    
    if (sender == _loginBtn) {
        MatrixHandler *matrix = [MatrixHandler sharedHandler];
        
        if (matrix.homeServer)
        {
            [matrix.homeServer loginWithUser:matrix.userLogin  andPassword:_passWordTextField.text
                                     success:^(MXLoginResponse *credentials){
                                         // Report credentials
                                         [matrix setUserId:credentials.user_id];
                                         [matrix setAccessToken:credentials.access_token];
                                         
                                         [self dismissViewControllerAnimated:YES completion:nil];
                                     }
                                     failure:^(NSError *error){
                                         NSLog(@"Login failed: %@", error);
                                         //Alert user
                                         [[AppDelegate theDelegate] showErrorAsAlert:error];
                                     }];
        }
    } else if (sender == _createAccountBtn){
        // TODO
    }
}

@end
