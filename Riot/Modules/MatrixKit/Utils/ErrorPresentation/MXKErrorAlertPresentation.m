/*
 Copyright 2018 New Vector Ltd
 
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

#import "MXKErrorAlertPresentation.h"

#import "MXKErrorPresentableBuilder.h"
#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

@interface MXKErrorAlertPresentation()

@property (nonatomic, strong) MXKErrorPresentableBuilder *errorPresentableBuidler;

@end

#pragma mark - Implementation

@implementation MXKErrorAlertPresentation

#pragma mark - Setup & Teardown

- (instancetype)init
{
    self = [super init];
    if (self) {
        _errorPresentableBuidler = [[MXKErrorPresentableBuilder alloc] init];
    }
    return self;
}

#pragma mark - MXKErrorPresentation

- (void)presentErrorFromViewController:(UIViewController*)viewController
                                 title:(NSString*)title
                               message:(NSString*)message
                              animated:(BOOL)animated
                               handler:(void (^)(void))handler
{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                if (handler)
                                                {
                                                    handler();
                                                }
                                            }]];
    
    [viewController presentViewController:alert animated:animated completion:nil];
}

- (void)presentErrorFromViewController:(UIViewController*)viewController
                              forError:(NSError*)error
                              animated:(BOOL)animated
                               handler:(void (^)(void))handler
{
    id <MXKErrorPresentable> errorPresentable = [self.errorPresentableBuidler errorPresentableFromError:error];
    
    if (errorPresentable)
    {
        [self presentErrorFromViewController:viewController
                         forErrorPresentable:errorPresentable
                                    animated:animated
                                     handler:handler];
    }
}

- (void)presentGenericErrorFromViewController:(UIViewController*)viewController
                                     animated:(BOOL)animated
                                      handler:(void (^)(void))handler
{
    id <MXKErrorPresentable> errorPresentable = [self.errorPresentableBuidler commonErrorPresentable];
    
    [self presentErrorFromViewController:viewController
                     forErrorPresentable:errorPresentable
                                animated:animated
                                 handler:handler];
}

- (void)presentErrorFromViewController:(UIViewController*)viewController
                   forErrorPresentable:(id<MXKErrorPresentable>)errorPresentable
                              animated:(BOOL)animated
                               handler:(void (^)(void))handler
{
    [self presentErrorFromViewController:viewController
                                   title:errorPresentable.title
                                 message:errorPresentable.message
                                animated:animated
                                 handler:handler];
}

@end
