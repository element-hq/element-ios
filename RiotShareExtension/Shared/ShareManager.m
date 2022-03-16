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

@import MobileCoreServices;

#import <mach/mach.h>

#import "ShareManager.h"
#import "ShareViewController.h"
#import "ShareDataSource.h"
#import "ShareItemSenderProtocol.h"

#import "GeneratedInterface-Swift.h"

@interface ShareManager () <ShareViewControllerDelegate, ShareItemSenderDelegate>

@property (nonatomic, strong, readonly) id<ShareItemSenderProtocol> shareItemSender;

@property (nonatomic, strong, readonly) ShareViewController *shareViewController;

@property (nonatomic, strong) MXKAccount *userAccount;
@property (nonatomic, strong) MXFileStore *fileStore;

/**
 An array of rooms that the item is being shared to. This is to maintain a strong ref
 to all necessary `MXRoom`s until sharing has completed.
 */
@property (nonatomic, strong) NSMutableArray<MXRoom *> *selectedRooms;

@end


@implementation ShareManager

/// A fake matrix session used to provide summaries with a REST client to handle room avatars.
/// The session is stored statically to prevent new ones from being created for each share.
static MXSession *fakeSession;

- (instancetype)initWithShareItemSender:(id<ShareItemSenderProtocol>)itemSender
                                   type:(ShareManagerType)type
{
    if (self = [super init])
    {
        _shareItemSender = itemSender;
        _shareItemSender.delegate = self;
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(checkUserAccount) name:kMXKAccountManagerDidRemoveAccountNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(checkUserAccount) name:NSExtensionHostWillEnterForegroundNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        _shareViewController = [[ShareViewController alloc] initWithType:(type == ShareManagerTypeForward ? ShareViewControllerTypeForward : ShareViewControllerTypeSend)
                                                            currentState:ShareViewControllerAccountStateNotConfigured];
        [_shareViewController setDelegate:self];
        
        // Set up runtime language on each context update.
        NSUserDefaults *sharedUserDefaults = [MXKAppSettings standardAppSettings].sharedUserDefaults;
        NSString *language = [sharedUserDefaults objectForKey:@"appLanguage"];
        [NSBundle mxk_setLanguage:language];
        [NSBundle mxk_setFallbackLanguage:@"en"];
        
        [self checkUserAccount];
    }
    
    return self;
}

#pragma mark - Public

- (UIViewController *)mainViewController
{
    return self.shareViewController;
}

#pragma mark - ShareViewControllerDelegate

- (void)shareViewController:(ShareViewController *)shareViewController didRequestShareForRoomIdentifiers:(NSSet<NSString *> *)roomIdentifiers
{
    MXWeakify(self);
    MXRestClient *restClient = [[MXRestClient alloc] initWithCredentials:self.userAccount.mxCredentials andOnUnrecognizedCertificateBlock:nil andPersistentTokenDataHandler:^(void (^handler)(NSArray<MXCredentials *> *credentials, void (^completion)(BOOL didUpdateCredentials))) {
        [[MXKAccountManager sharedManager] readAndWriteCredentials:handler];
    } andUnauthenticatedHandler:^(MXError *error, BOOL isSoftLogout, BOOL isRefreshTokenAuth, void (^completion)(void)) {
        MXStrongifyAndReturnIfNil(self);
        [self.userAccount handleUnauthenticatedWithError:error isSoftLogout:isSoftLogout isRefreshTokenAuth:isRefreshTokenAuth andCompletion:completion];
    }];
    MXSession *session = [[MXSession alloc] initWithMatrixRestClient:restClient];
    [MXFileStore setPreloadOptions:0];
    
    MXWeakify(session);
    [session setStore:self.fileStore success:^{
        MXStrongifyAndReturnIfNil(session);
        
        session.crypto.warnOnUnknowDevices = NO; // Do not warn for unknown devices. We have cross-signing now
        
        self.selectedRooms = [NSMutableArray array];
        for (NSString *roomIdentifier in roomIdentifiers) {
            MXRoom *room = [MXRoom loadRoomFromStore:self.fileStore withRoomId:roomIdentifier matrixSession:session];
            if (room) {
                [self.selectedRooms addObject:room];
            }
        }
        
        [self.shareItemSender sendItemsToRooms:self.selectedRooms success:^{
            self.selectedRooms = nil;
            self.completionCallback(ShareManagerResultFinished);
        } failure:^(NSArray<NSError *> *errors) {
            self.selectedRooms = nil;
            [self showFailureAlert:[VectorL10n roomEventFailedToSend]];
        }];
        
    } failure:^(NSError *error) {
        MXLogError(@"[ShareManager] Failed preparing matrix session");
    }];
}

- (void)shareViewControllerDidRequestDismissal:(ShareViewController *)shareViewController
{
    self.completionCallback(ShareManagerResultCancelled);
}

#pragma mark - ShareItemSenderDelegate

- (void)shareItemSenderDidStartSending:(id<ShareItemSenderProtocol>)shareItemSender
{
    [self.shareViewController showProgressIndicator];
}

- (void)shareItemSender:(id<ShareItemSenderProtocol>)shareItemSender didUpdateProgress:(CGFloat)progress
{
    [self.shareViewController setProgress:progress];
}

#pragma mark - Private

- (void)showFailureAlert:(NSString *)title
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    MXWeakify(self);
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[VectorL10n ok] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        MXStrongifyAndReturnIfNil(self);
        
        if (self.completionCallback)
        {
            self.completionCallback(ShareManagerResultFailed);
        }
    }];
    
    [alertController addAction:okAction];
    
    [self.mainViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)checkUserAccount
{
    // Force account manager to reload account from the local storage.
    [MXKAccountManager sharedManagerWithReload:YES];
    
    if (self.userAccount)
    {
        // Check whether the used account is still the first active one
        MXKAccount *firstAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        
        // Compare the access token
        if (!firstAccount || ![self.userAccount.mxCredentials.accessToken isEqualToString:firstAccount.mxCredentials.accessToken])
        {
            // Remove this account
            self.userAccount = nil;
        }
    }
    
    if (!self.userAccount)
    {
        // We consider the first enabled account.
        // TODO: Handle multiple accounts
        self.userAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        [self checkFakeSession];
    }
    
    // Reset the file store to reload the room data.
    if (_fileStore)
    {
        [_fileStore close];
        _fileStore = nil;
    }
    
    if (self.userAccount && fakeSession)
    {
        _fileStore = [[MXFileStore alloc] initWithCredentials:self.userAccount.mxCredentials];
        
        ShareDataSource *roomDataSource = [[ShareDataSource alloc] initWithFileStore:_fileStore
                                                                             session:fakeSession];
        
        [self.shareViewController configureWithState:ShareViewControllerAccountStateConfigured
                                      roomDataSource:roomDataSource];
    } else {
        [self.shareViewController configureWithState:ShareViewControllerAccountStateNotConfigured
                                      roomDataSource:nil];
    }
}

- (void)checkFakeSession
{
    if (!self.userAccount)
    {
        return;
    }
    
    if (fakeSession && [fakeSession.credentials.userId isEqualToString:self.userAccount.mxCredentials.userId])
    {
        return;
    }
    
    MXRestClient *mxRestClient = [[MXRestClient alloc] initWithCredentials:self.userAccount.mxCredentials
                                         andOnUnrecognizedCertificateBlock:nil
                                             andPersistentTokenDataHandler:^(void (^handler)(NSArray<MXCredentials *> *credentials, void (^completion)(BOOL didUpdateCredentials))) {
        [[MXKAccountManager sharedManager] readAndWriteCredentials:handler];
    } andUnauthenticatedHandler:nil];
    
    fakeSession = [[MXSession alloc] initWithMatrixRestClient:mxRestClient];
}

- (void)didStartSending
{
    [self.shareViewController showProgressIndicator];
}

- (void)didReceiveMemoryWarning:(NSNotification*)notification
{
    MXLogDebug(@"[ShareManager] Did receive memory warning");
    [self logMemoryUsage];
}

// Log memory usage.
// NOTE: This result may not be reliable for all iOS versions (see https://forums.developer.apple.com/thread/64665 for more information).
- (void)logMemoryUsage
{
    struct task_basic_info basicInfo;
    mach_msg_type_number_t size = TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&basicInfo,
                                   &size);
    
    vm_size_t memoryUsedInBytes = basicInfo.resident_size;
    CGFloat memoryUsedInMegabytes = memoryUsedInBytes / (1024*1024);
    
    if (kerr == KERN_SUCCESS)
    {
        MXLogDebug(@"[ShareManager] Memory in use (in MB): %f", memoryUsedInMegabytes);
    }
    else
    {
        MXLogDebug(@"[ShareManager] Error with task_info(): %s", mach_error_string(kerr));
    }
}

@end
