//
//  ShareViewController.m
//  Riot Share Extension
//
//  Created by Aram Sargsyan on 7/6/17.
//  Copyright © 2017 matrix.org. All rights reserved.
//

#import "ShareViewController.h"

//#import "ReadReceiptsViewController.h"

//#import <MatrixSDK/MatrixSDK.h>


@interface ShareViewController ()

@end

@implementation ShareViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //UI configuration
    self.view.opaque = YES;
    
    [self.view setBackgroundColor:[UIColor yellowColor]];
    self.view.alpha = 0.5;
    
    //MatrixSDK test
    //NSLog(@"SDK VERSION ====== %@", MatrixSDKVersion);
    
    //UserDefaults test
    //NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.org.matrix.riot"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //[ReadReceiptsViewController openInViewController:self fromContainer:nil withSession:nil];
}


#pragma mark - SLComposeServiceViewController

- (BOOL)isContentValid
{
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

- (void)didSelectPost
{
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (NSArray *)configurationItems
{
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

@end
