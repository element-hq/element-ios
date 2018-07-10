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

#import <MatrixKit/MatrixKit.h>

@interface AuthenticationViewController : MXKAuthenticationViewController <MXKAuthenticationViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

@property (weak, nonatomic) IBOutlet UINavigationItem *mainNavigationItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightBarButtonItem;

@property (weak, nonatomic) IBOutlet UIView *optionsContainer;

@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *submitButtonMinLeadingConstraint;

@property (weak, nonatomic) IBOutlet UIView *serverOptionsContainer;
@property (weak, nonatomic) IBOutlet UIButton *customServersTickButton;
@property (weak, nonatomic) IBOutlet UIView *customServersContainer;
@property (weak, nonatomic) IBOutlet UIView *homeServerContainer;
@property (weak, nonatomic) IBOutlet UIView *identityServerContainer;

@property (weak, nonatomic) IBOutlet UIView *homeServerSeparator;
@property (weak, nonatomic) IBOutlet UIView *identityServerSeparator;

@end

