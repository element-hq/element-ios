/*
 Copyright 2017 Aram Sargsyan
 
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

#import "SharePresentingViewController.h"
#import "ShareViewController.h"
#import "ShareExtensionManager.h"

@interface SharePresentingViewController ()

@property (nonatomic) ShareViewController *shareViewController;

@end

@implementation SharePresentingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ShareExtensionManager *sharedManager = [ShareExtensionManager sharedManager];
    
    sharedManager.primaryViewController = self;
    sharedManager.shareExtensionContext = self.extensionContext;
    
    [self presentShareViewController];
}

- (void)destroy
{
    if (self.shareViewController)
    {
        [self.shareViewController destroy];
        self.shareViewController = nil;
    }
}

- (void)presentShareViewController
{
    self.shareViewController = [[ShareViewController alloc] init];
    
    self.shareViewController.providesPresentationContextTransitionStyle = YES;
    self.shareViewController.definesPresentationContext = YES;
    self.shareViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    self.shareViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self presentViewController:self.shareViewController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
