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

#import "RecentsDataSource.h"

#import "RecentCellData.h"
#import "SectionHeaderView.h"

#import "ThemeService.h"

#import "MXRoom+Riot.h"
#import "MXSession+Riot.h"
#import "NSArray+Element.h"

#import "GeneratedInterface-Swift.h"
@import DesignKit;

#define RECENTSDATASOURCE_SECTION_DIRECTORY     0x01
#define RECENTSDATASOURCE_SECTION_INVITES       0x02
#define RECENTSDATASOURCE_SECTION_FAVORITES     0x04
#define RECENTSDATASOURCE_SECTION_CONVERSATIONS 0x08
#define RECENTSDATASOURCE_SECTION_LOWPRIORITY   0x10
#define RECENTSDATASOURCE_SECTION_SERVERNOTICE  0x20
#define RECENTSDATASOURCE_SECTION_PEOPLE        0x40
#define RECENTSDATASOURCE_SECTION_SUGGESTED     0x80
#define RECENTSDATASOURCE_SECTION_BREADCRUMBS   0x100
#define RECENTSDATASOURCE_SECTION_ALL_CHATS     0x101

#define RECENTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT             30.0
#define RECENTSDATASOURCE_ALL_CHATS_SECTION_BOTTOM_VIEW_HEIGHT      38.0

NSString *const kRecentsDataSourceTapOnDirectoryServerChange = @"kRecentsDataSourceTapOnDirectoryServerChange";

@interface RecentsDataSource() <SecureBackupBannerCellDelegate, CrossSigningSetupBannerCellDelegate, RecentsListServiceDelegate>
{
    dispatch_queue_t processingQueue;
    
    NSInteger shrinkedSectionsBitMask;

    NSMutableDictionary<NSString*, id> *roomTagsListenerByUserId;
    
    // Timer to not refresh publicRoomsDirectoryDataSource on every keystroke.
    NSTimer *publicRoomsTriggerTimer;
}

@property (nonatomic, strong, readwrite) RecentsDataSourceSections *sections;
@property (nonatomic, assign, readwrite) SecureBackupBannerDisplay secureBackupBannerDisplay;
@property (nonatomic, assign, readwrite) CrossSigningBannerDisplay crossSigningBannerDisplay;

@property (nonatomic, readwrite) id<RecentsListServiceProtocol> recentsListService;

@property (nonatomic, strong) CrossSigningService *crossSigningService;

@property (nonatomic, strong) AllChatsFilterOptions *allChatsFilterOptions;
@property (nonatomic, strong) AllChatsFilterOptionListView *allChatsOptionsView;

@end

@implementation RecentsDataSource
@synthesize hiddenCellIndexPath, droppingCellIndexPath, droppingCellBackGroundView;

- (instancetype)initWithMatrixSession:(MXSession *)mxSession
                   recentsListService:(id<RecentsListServiceProtocol>)theRecentsListService
{
    if (self = [super initWithMatrixSession:mxSession])
    {
        processingQueue = dispatch_queue_create("RecentsDataSource", DISPATCH_QUEUE_SERIAL);
        
        _sections = [[RecentsDataSourceSections alloc] initWithSectionTypes:@[]];
        _crossSigningBannerDisplay = CrossSigningBannerDisplayNone;
        _secureBackupBannerDisplay = SecureBackupBannerDisplayNone;
        
        _areSectionsShrinkable = !BuildSettings.newAppLayoutEnabled;
        shrinkedSectionsBitMask = 0;
        
        roomTagsListenerByUserId = [[NSMutableDictionary alloc] init];
        
        _crossSigningService = [CrossSigningService new];
        
        // Set default data and view classes
        [self registerCellDataClass:RecentCellData.class forCellIdentifier:kMXKRecentCellIdentifier];
        
        [self registerSpaceServiceDidBuildGraphNotification];
        self.recentsListService = theRecentsListService;
        [self.recentsListService addDelegate:self];
        
        [self registerAllChatsSettingsUpdateNotification];
        self.allChatsFilterOptions = [AllChatsFilterOptions new];
    }
    return self;
}

- (void)dealloc
{
    [self unregisterSpaceServiceDidBuildGraphNotification];
    [self unregisterAllChatsSettingsUpdateNotification];
}

#pragma mark - Properties

- (NSArray<id<MXRoomSummaryProtocol>> *)invitesCellDataArray
{
    return self.recentsListService.invitedRoomListData.rooms;
}
- (NSArray<id<MXRoomSummaryProtocol>> *)favoriteCellDataArray
{
    return self.recentsListService.favoritedRoomListData.rooms;
}
- (NSArray<id<MXRoomSummaryProtocol>> *)peopleCellDataArray
{
    return self.recentsListService.peopleRoomListData.rooms;
}
- (NSArray<id<MXRoomSummaryProtocol>> *)conversationCellDataArray
{
    return self.recentsListService.conversationRoomListData.rooms;
}
- (NSArray<id<MXRoomSummaryProtocol>> *)lowPriorityCellDataArray
{
    return self.recentsListService.lowPriorityRoomListData.rooms;
}
- (NSArray<id<MXRoomSummaryProtocol>> *)serverNoticeCellDataArray
{
    return self.recentsListService.serverNoticeRoomListData.rooms;
}
- (NSArray<id<MXRoomSummaryProtocol>> *)suggestedRoomCellDataArray
{
    return self.recentsListService.suggestedRoomListData.rooms;
}
- (NSArray<id<MXRoomSummaryProtocol>> *)breadcrumbsRoomCellDataArray
{
    return self.recentsListService.breadcrumbsRoomListData.rooms;
}
- (NSArray<id<MXRoomSummaryProtocol>> *)allChatsRoomCellDataArray
{
    return self.recentsListService.allChatsRoomListData.rooms;
}

- (NSInteger)totalVisibleItemCount
{
    return self.recentsListService.totalVisibleItemCount;
}

- (DiscussionsCount *)favoriteMissedDiscussionsCount
{
    return self.recentsListService.favoritedMissedDiscussionsCount;
}

- (DiscussionsCount *)directMissedDiscussionsCount
{
    return self.recentsListService.peopleMissedDiscussionsCount;
}

- (DiscussionsCount *)groupMissedDiscussionsCount
{
    return self.recentsListService.conversationMissedDiscussionsCount;
}

#pragma mark - Sections

- (RecentsDataSourceSections *)makeDataSourceSections
{
    NSMutableArray *types = [NSMutableArray array];
    if (self.recentsDataSourceMode == RecentsDataSourceModeRoomInvites)
    {
        [types addObject:@(RecentsDataSourceSectionTypeInvites)];
        return [[RecentsDataSourceSections alloc] initWithSectionTypes:types.copy];
    }
    
    if (self.crossSigningBannerDisplay != CrossSigningBannerDisplayNone)
    {
        [types addObject:@(RecentsDataSourceSectionTypeCrossSigningBanner)];
    }
    else if (self.secureBackupBannerDisplay != SecureBackupBannerDisplayNone)
    {
        [types addObject:@(RecentsDataSourceSectionTypeSecureBackupBanner)];
    }
    
    if (self.invitesCellDataArray.count > 0)
    {
        [types addObject:@(RecentsDataSourceSectionTypeInvites)];
    }
    
    if (self.breadcrumbsRoomCellDataArray.count > 0 && _recentsDataSourceMode == RecentsDataSourceModeAllChats)
    {
        AllChatsLayoutSettings *settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings;
        if ((settings.sections & AllChatsLayoutSectionTypeRecents) == AllChatsLayoutSectionTypeRecents)
        {
            [types addObject:@(RecentsDataSourceSectionTypeBreadcrumbs)];
        }
    }

    if (self.favoriteCellDataArray.count > 0)
    {
        if (_recentsDataSourceMode != RecentsDataSourceModeAllChats)
        {
            [types addObject:@(RecentsDataSourceSectionTypeFavorites)];
        }
        else
        {
            AllChatsLayoutSettings *settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings;
            if ((settings.sections & AllChatsLayoutSectionTypeFavourites) == AllChatsLayoutSectionTypeFavourites)
            {
                [types addObject:@(RecentsDataSourceSectionTypeFavorites)];
            }
        }
    }

    if (self.peopleCellDataArray.count > 0 && _recentsDataSourceMode != RecentsDataSourceModeAllChats)
    {
        [types addObject:@(RecentsDataSourceSectionTypePeople)];
    }

    // Keep visible the main rooms section even if it is empty, except on favourites screen.
    if (self.conversationCellDataArray.count > 0 || _recentsDataSourceMode == RecentsDataSourceModeHome)
    {
        [types addObject:@(RecentsDataSourceSectionTypeConversation)];
    }

    if (self.allChatsRoomCellDataArray.count > 0 || _recentsDataSourceMode == RecentsDataSourceModeAllChats)
    {
        [types addObject:@(RecentsDataSourceSectionTypeAllChats)];
    }
    
    if (self.currentSpace != nil && self.suggestedRoomCellDataArray.count > 0)
    {
        [types addObject:@(RecentsDataSourceSectionTypeSuggestedRooms)];
    }

    if (self.lowPriorityCellDataArray.count > 0)
    {
        [types addObject:@(RecentsDataSourceSectionTypeLowPriority)];
    }

    if (self.serverNoticeCellDataArray.count > 0)
    {
        [types addObject:@(RecentsDataSourceSectionTypeServerNotice)];
    }

    return [[RecentsDataSourceSections alloc] initWithSectionTypes:types.copy];
}

#pragma mark -

- (void)setDelegate:(id<MXKDataSourceDelegate>)delegate andRecentsDataSourceMode:(RecentsDataSourceMode)recentsDataSourceMode
{
    // Update the configuration, the recentsDataSourceMode setter will force a refresh.
    self.delegate = delegate;
    self.recentsDataSourceMode = recentsDataSourceMode;
}

- (void)setRecentsDataSourceMode:(RecentsDataSourceMode)recentsDataSourceMode
{
    _recentsDataSourceMode = recentsDataSourceMode;
    
    // Register to key backup state changes only on in home mode.
    if (recentsDataSourceMode == RecentsDataSourceModeHome)
    {
        [self registerKeyBackupStateDidChangeNotification];
    }
    else
    {
        [self unregisterKeyBackupStateDidChangeNotification];
    }

    [self updateSecureBackupBanner];
    [self refreshCrossSigningBannerDisplay];
    [self.recentsListService updateMode:_recentsDataSourceMode];
}

- (void)setCurrentSpace:(MXSpace *)currentSpace
{
    super.currentSpace = currentSpace;
    [self.recentsListService updateSpace:currentSpace];
}

- (UIView *)viewForStickyHeaderInSection:(NSInteger)section withFrame:(CGRect)frame inTableView:(UITableView*)tableView
{
    UIView *stickyHeader;

    NSInteger savedShrinkedSectionsBitMask = shrinkedSectionsBitMask;
    if ([self.sections sectionTypeForSectionIndex:section] == RecentsDataSourceSectionTypeDirectory)
    {
        // Return the section header used when the section is shrinked
        shrinkedSectionsBitMask = RECENTSDATASOURCE_SECTION_DIRECTORY;
    }

    stickyHeader = [self viewForHeaderInSection:section withFrame:frame inTableView:tableView];

    shrinkedSectionsBitMask = savedShrinkedSectionsBitMask;

    return stickyHeader;
}

- (void)registerAllChatsSettingsUpdateNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(allChatSettingsWillUpdateNotification:) name:AllChatsLayoutSettingsManager.willUpdateSettings object:nil];
}

- (void)allChatSettingsWillUpdateNotification:(NSNotification*)notification
{
    self.allChatsOptionsView = nil;
}

- (void)unregisterAllChatsSettingsUpdateNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AllChatsLayoutSettingsManager.willUpdateSettings object:nil];
}

#pragma mark - Space Service notifications

- (void)registerSpaceServiceDidBuildGraphNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spaceServiceDidBuildGraphNotification:) name:MXSpaceService.didBuildSpaceGraph object:nil];
}

- (void)spaceServiceDidBuildGraphNotification:(NSNotification*)notification
{
    [self forceRefresh];
}

- (void)unregisterSpaceServiceDidBuildGraphNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MXSpaceService.didBuildSpaceGraph object:nil];
}

#pragma mark - Key backup setup banner

- (void)registerKeyBackupStateDidChangeNotification
{
    // Check homeserver update in background
    [self.mxSession.crypto.backup forceRefresh:nil failure:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBackupStateDidChangeNotification:) name:kMXKeyBackupDidStateChangeNotification object:nil];
}

- (void)unregisterKeyBackupStateDidChangeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKeyBackupDidStateChangeNotification object:nil];
}

- (void)keyBackupStateDidChangeNotification:(NSNotification*)notification
{
    if ([self updateSecureBackupBanner])
    {
        [self forceRefresh];
    }
}

- (BOOL)updateSecureBackupBanner
{
    SecureBackupBannerDisplay secureBackupBanner = SecureBackupBannerDisplayNone;
    
    if (self.recentsDataSourceMode == RecentsDataSourceModeHome)
    {
        SecureBackupBannerPreferences *secureBackupBannersPreferences = SecureBackupBannerPreferences.shared;
        
        // Display the banner only if we can set up 4S, if there are messages keys to backup and key backup is disabled
        if (!secureBackupBannersPreferences.hideSetupBanner
            && [self.mxSession vc_canSetupSecureBackup]
            && self.mxSession.crypto.backup.hasKeysToBackup
            && self.mxSession.crypto.backup.state == MXKeyBackupStateDisabled)
        {
            MXLogDebug(@"[RecentsDataSource] updateSecureBackupBanner: Secure backup should be shown (crypto.backup.state = %lu)", (unsigned long)self.mxSession.crypto.backup.state);
            secureBackupBanner = SecureBackupBannerDisplaySetup;
        }
    }
    
    BOOL updated = (self.secureBackupBannerDisplay != secureBackupBanner);
    
    self.secureBackupBannerDisplay = secureBackupBanner;
    
    return updated;
}

- (void)hideKeyBackupBannerWithDisplay:(SecureBackupBannerDisplay)secureBackupBannerDisplay
{
    SecureBackupBannerPreferences *keyBackupBannersPreferences = SecureBackupBannerPreferences.shared;
    
    switch (secureBackupBannerDisplay) {
        case SecureBackupBannerDisplaySetup:
            keyBackupBannersPreferences.hideSetupBanner = YES;
            break;
        default:
            break;
    }
    
    [self updateSecureBackupBanner];
    [self forceRefresh];
}

#pragma mark - Cross-signing setup banner

- (void)refreshCrossSigningBannerDisplay
{
    if (self.recentsDataSourceMode == RecentsDataSourceModeHome)
    {
        CrossSigningBannerPreferences *crossSigningBannerPreferences = CrossSigningBannerPreferences.shared;
        
        if (!crossSigningBannerPreferences.hideSetupBanner)
        {
            [self.crossSigningService canSetupCrossSigningFor:self.mxSession success:^(BOOL canSetupCrossSigning) {

                CrossSigningBannerDisplay crossSigningBannerDisplay = canSetupCrossSigning ? CrossSigningBannerDisplaySetup : CrossSigningBannerDisplayNone;
                
                [self updateCrossSigningBannerDisplay:crossSigningBannerDisplay];
                
            } failure:^(NSError * _Nonnull error) {
                MXLogDebug(@"[RecentsDataSource] refreshCrossSigningBannerDisplay: Fail to verify if cross signing banner can be displayed");
            }];
        }
        else
        {
            [self updateCrossSigningBannerDisplay:CrossSigningBannerDisplayNone];
        }
    }
    else
    {
        [self updateCrossSigningBannerDisplay:CrossSigningBannerDisplayNone];
    }
}

- (void)updateCrossSigningBannerDisplay:(CrossSigningBannerDisplay)crossSigningBannerDisplay
{
    if (self.crossSigningBannerDisplay == crossSigningBannerDisplay)
    {
        return;
    }
    
    self.crossSigningBannerDisplay = crossSigningBannerDisplay;
    [self forceRefresh];
}


- (void)hideCrossSigningBannerWithDisplay:(CrossSigningBannerDisplay)crossSigningBannerDisplay
{
    CrossSigningBannerPreferences *crossSigningBannerPreferences = CrossSigningBannerPreferences.shared;
    
    switch (crossSigningBannerDisplay) {
        case CrossSigningBannerDisplaySetup:
            crossSigningBannerPreferences.hideSetupBanner = YES;
            break;
        default:
            break;
    }
    
    [self refreshCrossSigningBannerDisplay];
}

#pragma mark -

- (MXKSessionRecentsDataSource *)addMatrixSession:(MXSession *)mxSession
{
    MXKSessionRecentsDataSource *recentsDataSource = [super addMatrixSession:mxSession];

    // Initialise the public room directory data source
    // Note that it is single matrix session only for now
    if (!_publicRoomsDirectoryDataSource)
    {
        _publicRoomsDirectoryDataSource = [[PublicRoomsDirectoryDataSource alloc] initWithMatrixSession:mxSession];
        _publicRoomsDirectoryDataSource.showNSFWRooms = RiotSettings.shared.showNSFWPublicRooms;
        _publicRoomsDirectoryDataSource.delegate = self;
    }
    
    return recentsDataSource;
}

- (void)removeMatrixSession:(MXSession*)matrixSession
{
    [super removeMatrixSession:matrixSession];
    
    // sanity check
    if (matrixSession.myUser && matrixSession.myUser.userId)
    {
        id roomTagListener = roomTagsListenerByUserId[matrixSession.myUser.userId];
        
        if (roomTagListener)
        {
            [matrixSession removeListener:roomTagListener];
            [roomTagsListenerByUserId removeObjectForKey:matrixSession.myUser.userId];
        }
    }
    
    if (_publicRoomsDirectoryDataSource.mxSession == matrixSession)
    {
        [_publicRoomsDirectoryDataSource destroy];
        _publicRoomsDirectoryDataSource = nil;
    }
}

- (void)dataSource:(MXKDataSource*)dataSource didStateChange:(MXKDataSourceState)aState
{
    if (dataSource == _publicRoomsDirectoryDataSource)
    {
        if ([self.sections contains:RecentsDataSourceSectionTypeDirectory] && !self.droppingCellIndexPath)
        {
            // TODO: We should only update the directory section
            [self.delegate dataSource:self didCellChange:nil];
        }
    }
    else
    {
        [super dataSource:dataSource didStateChange:aState];

        if ((aState == MXKDataSourceStateReady) && dataSource.mxSession.myUser.userId)
        {
            // Register the room tags updates to refresh the favorites order
            MXWeakify(self);
            id roomTagsListener = [dataSource.mxSession listenToEventsOfTypes:@[kMXEventTypeStringRoomTag]
                                                                onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {

                                                                    MXStrongifyAndReturnIfNil(self);

                                                                    // Consider only live event
                                                                    if (direction == MXTimelineDirectionForwards)
                                                                    {
                                                                        dispatch_async(dispatch_get_main_queue(), ^{

                                                                            [self forceRefresh];

                                                                        });
                                                                    }

                                                                }];

            roomTagsListenerByUserId[dataSource.mxSession.myUser.userId] = roomTagsListener;
        }
    }
}

- (void)forceRefresh
{
    // Refresh is disabled during drag&drop animation"
    if (!self.droppingCellIndexPath)
    {
        [self.recentsListService refresh];
    }
}

- (void)didMXSessionInviteRoomUpdate:(NSNotification *)notif
{
    MXSession *mxSession = notif.object;
    if ([self.mxSessions indexOfObject:mxSession] != NSNotFound)
    {
        [self forceRefresh];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Sanity check
    if (tableView.tag != self.recentsDataSourceMode)
    {
        // The view controller of this table view is not the current selected one in the tab bar controller.
        return 0;
    }
    
    // Check whether all data sources are ready before rendering recents
    if (self.state != MXKDataSourceStateReady)
    {
        return 0;
    }
    
    self.sections = [self makeDataSourceSections];
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Sanity check
    if (tableView.tag != self.recentsDataSourceMode)
    {
        // The view controller of this table view is not the current selected one in the tab bar controller.
        return 0;
    }
    
    NSUInteger count = 0;

    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:section];
    if (sectionType == RecentsDataSourceSectionTypeCrossSigningBanner && self.crossSigningBannerDisplay != CrossSigningBannerDisplayNone)
    {
        count = 1;
    }
    else if (sectionType == RecentsDataSourceSectionTypeSecureBackupBanner && self.secureBackupBannerDisplay != SecureBackupBannerDisplayNone)
    {
        count = 1;
    }
    else if (sectionType == RecentsDataSourceSectionTypeFavorites && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_FAVORITES))
    {
        count = self.favoriteCellDataArray.count;
    }
    else if (sectionType == RecentsDataSourceSectionTypePeople && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_PEOPLE))
    {
        count = self.peopleCellDataArray.count ? self.peopleCellDataArray.count : 1;
    }
    else if (sectionType == RecentsDataSourceSectionTypeConversation && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_CONVERSATIONS))
    {
        count = self.conversationCellDataArray.count ? self.conversationCellDataArray.count : 1;
    }
    else if (sectionType == RecentsDataSourceSectionTypeDirectory && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_DIRECTORY))
    {
        count = [_publicRoomsDirectoryDataSource tableView:tableView numberOfRowsInSection:0];
    }
    else if (sectionType == RecentsDataSourceSectionTypeLowPriority && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_LOWPRIORITY))
    {
        count = self.lowPriorityCellDataArray.count;
    }
    else if (sectionType == RecentsDataSourceSectionTypeServerNotice && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_SERVERNOTICE))
    {
        count = self.serverNoticeCellDataArray.count;
    }
    else if (sectionType == RecentsDataSourceSectionTypeInvites && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_INVITES))
    {
        if (self.recentsDataSourceMode == RecentsDataSourceModeAllChats)
        {
            count = 1;
        }
        else {
            count = self.invitesCellDataArray.count;
        }
    }
    else if (sectionType == RecentsDataSourceSectionTypeSuggestedRooms && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_SUGGESTED))
    {
        count = self.suggestedRoomCellDataArray.count;
    }
    else if (sectionType == RecentsDataSourceSectionTypeBreadcrumbs && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_BREADCRUMBS))
    {
        count = self.breadcrumbsRoomCellDataArray.count;
    }
    else if (sectionType == RecentsDataSourceSectionTypeAllChats && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_ALL_CHATS))
    {
        count = self.allChatsRoomCellDataArray.count ?: 1;
    }
    
    // Adjust this count according to the potential dragged cell.
    if ([self isMovingCellSection:section])
    {
        count++;
    }
    
    if (count && [self isHiddenCellSection:section])
    {
        count--;
    }
    
    return count;
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section
{
    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:section];
    if (sectionType == RecentsDataSourceSectionTypeSecureBackupBanner ||
        sectionType == RecentsDataSourceSectionTypeCrossSigningBanner ||
        sectionType == RecentsDataSourceSectionTypeBreadcrumbs ||
        (sectionType == RecentsDataSourceSectionTypeInvites && self.recentsDataSourceMode == RecentsDataSourceModeAllChats) ||
        (sectionType == RecentsDataSourceSectionTypeAllChats && !self.allChatsFilterOptions.optionsCount) ||
        (sectionType == RecentsDataSourceSectionTypeAllChats && self.currentSpace != nil && self.currentSpace.childRoomIds.count == 0))
    {
        return 0.0;
    }

    if (sectionType == RecentsDataSourceSectionTypeAllChats && _recentsDataSourceMode == RecentsDataSourceModeAllChats)
    {
        if (self.allChatsFilterOptions.optionsCount)
        {
            return RECENTSDATASOURCE_ALL_CHATS_SECTION_BOTTOM_VIEW_HEIGHT;
        }
    }
    
    return RECENTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT;
}

- (NSAttributedString *)attributedStringForHeaderTitleInSection:(NSInteger)section
{
    NSAttributedString *sectionTitle;
    NSString *title;
    NSUInteger count = 0;
    
    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:section];
    if (sectionType == RecentsDataSourceSectionTypeFavorites)
    {
        count = self.recentsListService.favoritedRoomListData.counts.total.numberOfRooms;
        title = [VectorL10n roomRecentsFavouritesSection];
    }
    else if (sectionType == RecentsDataSourceSectionTypePeople)
    {
        count = self.recentsListService.peopleRoomListData.counts.total.numberOfRooms;
        title = [VectorL10n roomRecentsPeopleSection];
    }
    else if (sectionType == RecentsDataSourceSectionTypeConversation)
    {
        count = self.recentsListService.conversationRoomListData.counts.total.numberOfRooms;
        
        if (_recentsDataSourceMode == RecentsDataSourceModePeople)
        {
            title = [VectorL10n peopleConversationSection];
        }
        else
        {
            title = [VectorL10n roomRecentsConversationsSection];
        }
    }
    else if (sectionType == RecentsDataSourceSectionTypeDirectory)
    {
        title = [VectorL10n roomRecentsDirectorySection];
    }
    else if (sectionType == RecentsDataSourceSectionTypeLowPriority)
    {
        count = self.recentsListService.lowPriorityRoomListData.counts.total.numberOfRooms;
        title = [VectorL10n roomRecentsLowPrioritySection];
    }
    else if (sectionType == RecentsDataSourceSectionTypeServerNotice)
    {
        count = self.recentsListService.serverNoticeRoomListData.counts.total.numberOfRooms;
        title = [VectorL10n roomRecentsServerNoticeSection];
    }
    else if (sectionType == RecentsDataSourceSectionTypeInvites)
    {
        count = self.recentsListService.invitedRoomListData.counts.total.numberOfRooms;
        
        if (_recentsDataSourceMode == RecentsDataSourceModePeople)
        {
            title = [VectorL10n peopleInvitesSection];
        }
        else
        {
            title = [VectorL10n roomRecentsInvitesSection];
        }
    }
    else if (sectionType == RecentsDataSourceSectionTypeSuggestedRooms)
    {
        count = self.recentsListService.suggestedRoomListData.counts.total.numberOfRooms;
        title = [VectorL10n roomRecentsSuggestedRoomsSection];
    }
    else if (sectionType == RecentsDataSourceSectionTypeBreadcrumbs)
    {
        count = self.recentsListService.breadcrumbsRoomListData.counts.total.numberOfRooms;
        title = [VectorL10n roomRecentsRecentlyViewedSection];
    }
    else if (sectionType == RecentsDataSourceSectionTypeAllChats)
    {
        count = self.recentsListService.allChatsRoomListData.counts.total.numberOfRooms;
        title = [VectorL10n allChatsSectionTitle];
    }

    
    if (count && !(sectionType == RecentsDataSourceSectionTypeInvites) && !BuildSettings.newAppLayoutEnabled)
    {
        NSString *roomCount = [NSString stringWithFormat:@"   %tu", count];

        NSMutableAttributedString *mutableSectionTitle = [[NSMutableAttributedString alloc] initWithString:title
                                                                                                attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.headerTextPrimaryColor,
                                                                                                             NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0]}];
        [mutableSectionTitle appendAttributedString:[[NSMutableAttributedString alloc] initWithString:roomCount
                                                                                           attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.headerTextSecondaryColor,
                                                                                                        NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0]}]];

        sectionTitle = mutableSectionTitle;
    }
    else if (title)
    {
        sectionTitle = [[NSAttributedString alloc] initWithString:[title capitalizedString]
                                                       attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.headerTextPrimaryColor,
                                                                    NSFontAttributeName: [ThemeService shared].theme.fonts.calloutSB}];
    }
    
    return sectionTitle;
}

- (UIView *)badgeViewForHeaderTitleInSection:(NSInteger)section
{
    // Prepare a badge to display the total of missed notifications in this section.
    id<MXRoomListDataCounts> counts = nil;
    UIView *missedNotifAndUnreadBadgeBgView = nil;

    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:section];
    if (sectionType == RecentsDataSourceSectionTypeInvites)
    {
        counts = self.recentsListService.invitedRoomListData.counts;
    }
    if (sectionType == RecentsDataSourceSectionTypeFavorites)
    {
        counts = self.recentsListService.favoritedRoomListData.counts;
    }
    else if (sectionType == RecentsDataSourceSectionTypePeople)
    {
        counts = self.recentsListService.peopleRoomListData.counts;
    }
    else if (sectionType == RecentsDataSourceSectionTypeConversation)
    {
        counts = self.recentsListService.conversationRoomListData.counts;
    }
    else if (sectionType == RecentsDataSourceSectionTypeLowPriority)
    {
        counts = self.recentsListService.lowPriorityRoomListData.counts;
    }
    else if (sectionType == RecentsDataSourceSectionTypeServerNotice)
    {
        counts = self.recentsListService.serverNoticeRoomListData.counts;
    }
    else if (sectionType == RecentsDataSourceSectionTypeSuggestedRooms)
    {
        counts = self.recentsListService.suggestedRoomListData.counts;
    }
    else if (sectionType == RecentsDataSourceSectionTypeAllChats)
    {
        counts = self.recentsListService.allChatsRoomListData.counts;
    }

    // Invites are counted as highlights for the badge view display.
    NSUInteger numberOfNotifications = counts.total.numberOfNotifications + counts.total.numberOfInvitedRooms;
    NSUInteger numberOfHighlights = counts.total.numberOfHighlights + counts.total.numberOfInvitedRooms;
    
    if (numberOfNotifications)
    {
        UILabel *missedNotifAndUnreadBadgeLabel = [[UILabel alloc] init];
        missedNotifAndUnreadBadgeLabel.textColor = ThemeService.shared.theme.baseTextPrimaryColor;
        missedNotifAndUnreadBadgeLabel.font = [UIFont boldSystemFontOfSize:14];
        if (numberOfNotifications > 1000)
        {
            CGFloat value = numberOfNotifications / 1000.0;
            missedNotifAndUnreadBadgeLabel.text = [VectorL10n largeBadgeValueKFormat:value];
        }
        else
        {
            missedNotifAndUnreadBadgeLabel.text = [NSString stringWithFormat:@"%tu", numberOfNotifications];
        }
        
        [missedNotifAndUnreadBadgeLabel sizeToFit];
        
        CGFloat bgViewWidth = missedNotifAndUnreadBadgeLabel.frame.size.width + 18;
        
        BOOL highlight = numberOfHighlights > 0;
        missedNotifAndUnreadBadgeBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bgViewWidth, 20)];
        [missedNotifAndUnreadBadgeBgView.layer setCornerRadius:10];
        missedNotifAndUnreadBadgeBgView.backgroundColor = highlight ? ThemeService.shared.theme.noticeColor : ThemeService.shared.theme.noticeSecondaryColor;
        
        [missedNotifAndUnreadBadgeBgView addSubview:missedNotifAndUnreadBadgeLabel];
        missedNotifAndUnreadBadgeLabel.center = missedNotifAndUnreadBadgeBgView.center;
        [missedNotifAndUnreadBadgeLabel.centerXAnchor constraintEqualToAnchor:missedNotifAndUnreadBadgeBgView.centerXAnchor
                                                                     constant:0].active = YES;
        [missedNotifAndUnreadBadgeLabel.centerYAnchor constraintEqualToAnchor:missedNotifAndUnreadBadgeBgView.centerYAnchor
                                                                     constant:0].active = YES;
    }
    
    return missedNotifAndUnreadBadgeBgView;
}

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame inTableView:(UITableView*)tableView
{
    // No header view in key backup banner section, in cross signing banner section, in recent section, nor in all chats section if flters are disabled
    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:section];
    if (sectionType == RecentsDataSourceSectionTypeSecureBackupBanner ||
        sectionType == RecentsDataSourceSectionTypeCrossSigningBanner ||
        sectionType == RecentsDataSourceSectionTypeBreadcrumbs ||
        (sectionType == RecentsDataSourceSectionTypeInvites && self.recentsDataSourceMode == RecentsDataSourceModeRoomInvites) ||
        (sectionType == RecentsDataSourceSectionTypeAllChats && !self.allChatsFilterOptions.optionsCount))
    {
        return nil;
    }
    
    SectionHeaderView *sectionHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:SectionHeaderView.defaultReuseIdentifier];
    if (sectionHeader == nil)
    {
        sectionHeader = [[SectionHeaderView alloc] initWithReuseIdentifier:SectionHeaderView.defaultReuseIdentifier];
    }
    sectionHeader.backgroundView = [UIView new];
    sectionHeader.frame = frame;
    sectionHeader.backgroundView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    sectionHeader.topPadding = 0;
    sectionHeader.topViewHeight = RECENTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT;
    NSInteger sectionBitwise = 0;

    if (_areSectionsShrinkable)
    {
        if (sectionType == RecentsDataSourceSectionTypeFavorites)
        {
            sectionBitwise =  RECENTSDATASOURCE_SECTION_FAVORITES;
        }
        else if (sectionType == RecentsDataSourceSectionTypePeople)
        {
            sectionBitwise =  RECENTSDATASOURCE_SECTION_PEOPLE;
        }
        else if (sectionType == RecentsDataSourceSectionTypeConversation)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_CONVERSATIONS;
        }
        else if (sectionType == RecentsDataSourceSectionTypeDirectory)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_CONVERSATIONS;
        }
        else if (sectionType == RecentsDataSourceSectionTypeLowPriority)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_LOWPRIORITY;
        }
        else if (sectionType == RecentsDataSourceSectionTypeServerNotice)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_SERVERNOTICE;
        }
        else if (sectionType == RecentsDataSourceSectionTypeInvites)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_INVITES;
        }
        else if (sectionType == RecentsDataSourceSectionTypeSuggestedRooms)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_SUGGESTED;
        }
        else if (sectionType == RecentsDataSourceSectionTypeBreadcrumbs)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_BREADCRUMBS;
        }
        else if (sectionType == RecentsDataSourceSectionTypeAllChats)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_ALL_CHATS;
        }
    }
    
    if (sectionBitwise)
    {
        // Add shrink button
        UIButton *shrinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        shrinkButton.backgroundColor = [UIColor clearColor];
        [shrinkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        shrinkButton.tag = sectionBitwise;
        sectionHeader.topSpanningView = shrinkButton;
        sectionHeader.userInteractionEnabled = YES;
        
        // Add shrink icon
        UIImage *chevron;
        if (shrinkedSectionsBitMask & sectionBitwise)
        {
            chevron = AssetImages.disclosureIcon.image;
        }
        else
        {
            chevron = AssetImages.shrinkIcon.image;
        }
        UIImageView *chevronView = [[UIImageView alloc] initWithImage:chevron];
        chevronView.tintColor = ThemeService.shared.theme.textSecondaryColor;
        chevronView.contentMode = UIViewContentModeCenter;
        sectionHeader.accessoryView = chevronView;
    }
    
    if (_recentsDataSourceMode == RecentsDataSourceModeHome
        || _recentsDataSourceMode == RecentsDataSourceModePeople
        || _recentsDataSourceMode == RecentsDataSourceModeRooms)
    {
        // Add a badge to display the total of missed notifications by section.
        UIView *badgeView = [self badgeViewForHeaderTitleInSection:section];

        if (badgeView)
        {
            sectionHeader.rightAccessoryView = badgeView;
        }
    }
    
    if (_recentsDataSourceMode == RecentsDataSourceModeAllChats && sectionType == RecentsDataSourceSectionTypeAllChats) {
        if (!self.allChatsOptionsView) {
            self.allChatsOptionsView = [self.allChatsFilterOptions createFilterListView];
        }

        if (self.allChatsOptionsView)
        {
            [self.allChatsFilterOptions updateWithFilterOptionListView:self.allChatsOptionsView
                                                          unreadsCount:1 // unreads is allways visible
                                                       favouritesCount:self.favoriteCellDataArray.count
                                                      directRoomsCount:self.peopleCellDataArray.count];
            return self.allChatsOptionsView;
        }
    }
    else
    {
        sectionHeader.bottomView = nil;
    }
    
    if (!BuildSettings.newAppLayoutEnabled || !sectionHeader.bottomView)
    {
        // Add label
        frame.size.height = RECENTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT - 10;
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.attributedText = [self attributedStringForHeaderTitleInSection:section];
        sectionHeader.headerLabel = headerLabel;
    }
    else
    {
        sectionHeader.headerLabel = nil;
    }

    return sectionHeader;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Sanity check
    if (tableView.tag != self.recentsDataSourceMode)
    {
        // The view controller of this table view is not the current selected one in the tab bar controller.
        // Return a fake cell to prevent app from crashing
        return [[UITableViewCell alloc] init];
    }
    
    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:indexPath.section];
    if (sectionType == RecentsDataSourceSectionTypeCrossSigningBanner)
    {
        CrossSigningSetupBannerCell* crossSigningSetupBannerCell = [tableView dequeueReusableCellWithIdentifier:CrossSigningSetupBannerCell.defaultReuseIdentifier forIndexPath:indexPath];
        crossSigningSetupBannerCell.delegate = self;
        return crossSigningSetupBannerCell;
    }
    else if (sectionType == RecentsDataSourceSectionTypeSecureBackupBanner)
    {
        SecureBackupBannerCell* keyBackupBannerCell = [tableView dequeueReusableCellWithIdentifier:SecureBackupBannerCell.defaultReuseIdentifier forIndexPath:indexPath];
        [keyBackupBannerCell configureFor:self.secureBackupBannerDisplay];
        keyBackupBannerCell.delegate = self;
        return keyBackupBannerCell;
    }
    else if (sectionType == RecentsDataSourceSectionTypeDirectory)
    {
        NSIndexPath *indexPathInPublicRooms = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        return [_publicRoomsDirectoryDataSource tableView:tableView cellForRowAtIndexPath:indexPathInPublicRooms];
    }
    else if (self.droppingCellIndexPath && [indexPath isEqual:self.droppingCellIndexPath])
    {
        static NSString* cellIdentifier = @"RiotRecentsMovingCell";
        
        UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RiotRecentsMovingCell"];
        
        // add an imageview of the cell.
        // The image is a shot of the genuine cell.
        // Thus, this cell has the same look as the genuine cell without computing it.
        UIImageView* imageView = [cell viewWithTag:[cellIdentifier hash]];
        
        if (!imageView || (imageView != self.droppingCellBackGroundView))
        {
            if (imageView)
            {
                [imageView removeFromSuperview];
            }
            self.droppingCellBackGroundView.tag = [cellIdentifier hash];
            [cell.contentView addSubview:self.droppingCellBackGroundView];
        }
        
        self.droppingCellBackGroundView.frame = self.droppingCellBackGroundView.frame;
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = [UIColor clearColor];
        
        return cell;
    }
    else if ((sectionType == RecentsDataSourceSectionTypeConversation && !self.conversationCellDataArray.count)
             || (sectionType == RecentsDataSourceSectionTypePeople && !self.peopleCellDataArray.count))
    {
        MXKTableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
        if (!tableViewCell)
        {
            tableViewCell = [[MXKTableViewCell alloc] init];
            tableViewCell.textLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
            tableViewCell.textLabel.font = [UIFont systemFontOfSize:15.0];
            tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        // Check whether a search session is in progress
        if (self.searchPatternsList)
        {
            tableViewCell.textLabel.text = [VectorL10n searchNoResult];
        }
        else if (_recentsDataSourceMode == RecentsDataSourceModePeople || sectionType == RecentsDataSourceSectionTypePeople)
        {
            tableViewCell.textLabel.text = [VectorL10n peopleNoConversation];
        }
        else
        {
            tableViewCell.textLabel.text = [VectorL10n roomRecentsNoConversation];
        }
        
        return tableViewCell;
    }
    else if (sectionType == RecentsDataSourceSectionTypeAllChats && !self.allChatsRoomCellDataArray.count) {
        RecentEmptySectionTableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:[RecentEmptySectionTableViewCell defaultReuseIdentifier]];
        
        if (self.searchPatternsList)
        {
            tableViewCell.iconView.image = [UIImage systemImageNamed:@"magnifyingglass"];
            tableViewCell.titleLabel.text = VectorL10n.allChatsNothingFoundPlaceholderTitle;
            tableViewCell.messageLabel.text = VectorL10n.allChatsNothingFoundPlaceholderMessage;
        }
        else if (self.currentSpace && !self.currentSpace.childRoomIds.count)
        {
            RecentEmptySectionTableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:[RecentEmptySpaceSectionTableViewCell defaultReuseIdentifier]];

            tableViewCell.iconView.image = [ThemeService.shared isCurrentThemeDark] ? AssetImages.allChatsEmptySpaceArtworkDark.image : AssetImages.allChatsEmptySpaceArtwork.image;
            tableViewCell.titleLabel.text = [VectorL10n allChatsEmptyViewTitle: self.currentSpace.summary.displayname];
            tableViewCell.messageLabel.text = VectorL10n.allChatsEmptySpaceInformation;
            
            return tableViewCell;
        }
        else
        {
            tableViewCell.iconView.image = AssetImages.allChatsEmptyListPlaceholderIcon.image;
            tableViewCell.titleLabel.text = VectorL10n.allChatsEmptyListPlaceholderTitle;
            tableViewCell.messageLabel.text = VectorL10n.allChatsEmptyUnreadsPlaceholderMessage;
        }

        return tableViewCell;
    }
    else if (sectionType == RecentsDataSourceSectionTypeInvites && self.recentsDataSourceMode == RecentsDataSourceModeAllChats)
    {
        RecentsInvitesTableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:[RecentsInvitesTableViewCell defaultReuseIdentifier]];
        
        tableViewCell.invitesCount = self.recentsListService.invitedRoomListData.counts.total.numberOfRooms;

        return tableViewCell;
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (id<MXKRecentCellDataStoring>)cellDataAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXRoomSummaryProtocol> summary = nil;
    NSUInteger cellDataIndex = indexPath.row;
    NSInteger tableSection = indexPath.section;
    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:tableSection];
    
    // Compute the actual cell data index by taking into account the current droppingCellIndexPath and hiddenCellIndexPath (if any).
    if ([self isMovingCellSection:tableSection] && (cellDataIndex > self.droppingCellIndexPath.row))
    {
        cellDataIndex --;
    }
    if ([self isHiddenCellSection:tableSection] && (cellDataIndex >= self.hiddenCellIndexPath.row))
    {
        cellDataIndex ++;
    }
    
    if (sectionType == RecentsDataSourceSectionTypeFavorites)
    {
        if (cellDataIndex < self.favoriteCellDataArray.count)
        {
            summary = self.favoriteCellDataArray[cellDataIndex];
        }
    }
    else if (sectionType == RecentsDataSourceSectionTypePeople)
    {
        if (cellDataIndex < self.peopleCellDataArray.count)
        {
            summary = self.peopleCellDataArray[cellDataIndex];
        }
    }
    else if (sectionType == RecentsDataSourceSectionTypeConversation)
    {
        if (cellDataIndex < self.conversationCellDataArray.count)
        {
            summary = self.conversationCellDataArray[cellDataIndex];
        }
    }
    else if (sectionType == RecentsDataSourceSectionTypeLowPriority)
    {
        if (cellDataIndex < self.lowPriorityCellDataArray.count)
        {
            summary = self.lowPriorityCellDataArray[cellDataIndex];
        }
    }
    else if (sectionType == RecentsDataSourceSectionTypeServerNotice)
    {
        if (cellDataIndex < self.serverNoticeCellDataArray.count)
        {
            summary = self.serverNoticeCellDataArray[cellDataIndex];
        }
    }
    else if (sectionType == RecentsDataSourceSectionTypeInvites)
    {
        if (cellDataIndex < self.invitesCellDataArray.count)
        {
            summary = self.invitesCellDataArray[cellDataIndex];
        }
    }
    else if (sectionType == RecentsDataSourceSectionTypeSuggestedRooms)
    {
        if (cellDataIndex < self.suggestedRoomCellDataArray.count)
        {
            summary = self.suggestedRoomCellDataArray[cellDataIndex];
        }
    }
    else if (sectionType == RecentsDataSourceSectionTypeBreadcrumbs)
    {
        if (cellDataIndex < self.breadcrumbsRoomCellDataArray.count)
        {
            summary = self.breadcrumbsRoomCellDataArray[cellDataIndex];
        }
    }
    else if (sectionType == RecentsDataSourceSectionTypeAllChats)
    {
        if (cellDataIndex < self.allChatsRoomCellDataArray.count)
        {
            summary = self.allChatsRoomCellDataArray[cellDataIndex];
        }
    }

    if (summary)
    {
        return [[MXKRecentCellData alloc] initWithRoomSummary:summary dataSource:self];
    }
    return nil;
}

- (CGFloat)cellHeightAtIndexPath:(NSIndexPath *)indexPath
{
    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:indexPath.section];
    if (sectionType == RecentsDataSourceSectionTypeDirectory)
    {
        return [_publicRoomsDirectoryDataSource cellHeightAtIndexPath:indexPath];
    }
    if (self.droppingCellIndexPath && [indexPath isEqual:self.droppingCellIndexPath])
    {
        return self.droppingCellBackGroundView.frame.size.height;
    }
    if ((sectionType == RecentsDataSourceSectionTypeConversation && !self.conversationCellDataArray.count)
        || (sectionType == RecentsDataSourceSectionTypePeople && !self.peopleCellDataArray.count))
    {
        return 50.0;
    }
    if (sectionType == RecentsDataSourceSectionTypeAllChats && !self.allChatsRoomCellDataArray.count) {
        return 320.0;
    }
    if (sectionType == RecentsDataSourceSectionTypeInvites && self.recentsDataSourceMode == RecentsDataSourceModeAllChats)
    {
        return 32.0;
    }
    
    // Override this method here to use our own cellDataAtIndexPath
    id<MXKRecentCellDataStoring> cellData = [self cellDataAtIndexPath:indexPath];
    
    if (cellData && self.delegate)
    {
        Class<MXKCellRendering> class = [self.delegate cellViewClassForCellData:cellData];
        
        return [class heightForCellData:cellData withMaximumWidth:0];
    }

    return 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Sanity check
    if (tableView.tag != self.recentsDataSourceMode)
    {
        // The view controller of this table view is not the current selected one in the tab bar controller.
        return NO;
    }
    
    // Invited rooms are not editable.
    return ([self.sections sectionTypeForSectionIndex:indexPath.section] != RecentsDataSourceSectionTypeInvites);
}

#pragma mark -

- (NSInteger)cellIndexPosWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)matrixSession within:(NSArray<id<MXRoomSummaryProtocol>> *)summaries
{
    if (!roomId || !matrixSession || !summaries.count || self.mxSession != matrixSession)
    {
        return NSNotFound;
    }
    return [summaries indexOfObjectPassingTest:^BOOL(id<MXRoomSummaryProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.roomId isEqualToString:roomId];
    }];
}

- (NSIndexPath*)cellIndexPathWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)matrixSession
{
    NSIndexPath *indexPath = nil;
    NSInteger index;

    if ([self.sections contains:RecentsDataSourceSectionTypeInvites])
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:self.invitesCellDataArray];

        if (index != NSNotFound)
        {
            // Check whether the invitations are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_INVITES)
            {
                return nil;
            }
            NSInteger sectionIndex = [self.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeInvites];
            indexPath = [NSIndexPath indexPathForRow:index inSection:sectionIndex];
        }
    }

    if (!indexPath && ([self.sections contains:RecentsDataSourceSectionTypeFavorites]))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:self.favoriteCellDataArray];

        if (index != NSNotFound)
        {
            // Check whether the favorites are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_FAVORITES)
            {
                return nil;
            }
            NSInteger sectionIndex = [self.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeFavorites];
            indexPath = [NSIndexPath indexPathForRow:index inSection:sectionIndex];
        }
    }

    if (!indexPath && ([self.sections contains:RecentsDataSourceSectionTypePeople]))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:self.peopleCellDataArray];

        if (index != NSNotFound)
        {
            // Check whether the favorites are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_PEOPLE)
            {
                return nil;
            }
            NSInteger sectionIndex = [self.sections sectionIndexForSectionType:RecentsDataSourceSectionTypePeople];
            indexPath = [NSIndexPath indexPathForRow:index inSection:sectionIndex];
        }
    }

    if (!indexPath && ([self.sections contains:RecentsDataSourceSectionTypeConversation]))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:self.conversationCellDataArray];

        if (index != NSNotFound)
        {
            // Check whether the conversations are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_CONVERSATIONS)
            {
                return nil;
            }
            NSInteger sectionIndex = [self.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeConversation];
            indexPath = [NSIndexPath indexPathForRow:index inSection:sectionIndex];
        }
    }

    if (!indexPath && ([self.sections contains:RecentsDataSourceSectionTypeLowPriority]))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:self.lowPriorityCellDataArray];

        if (index != NSNotFound)
        {
            // Check whether the low priority rooms are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_LOWPRIORITY)
            {
                return nil;
            }
            NSInteger sectionIndex = [self.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeLowPriority];
            indexPath = [NSIndexPath indexPathForRow:index inSection:sectionIndex];
        }
    }

    if (!indexPath && ([self.sections contains:RecentsDataSourceSectionTypeServerNotice]))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:self.serverNoticeCellDataArray];

        if (index != NSNotFound)
        {
            // Check whether the low priority rooms are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_SERVERNOTICE)
            {
                return nil;
            }
            NSInteger sectionIndex = [self.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeServerNotice];
            indexPath = [NSIndexPath indexPathForRow:index inSection:sectionIndex];
        }
    }

    if (!indexPath && ([self.sections contains:RecentsDataSourceSectionTypeSuggestedRooms]))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:self.suggestedRoomCellDataArray];

        if (index != NSNotFound)
        {
            // Check whether the low priority rooms are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_SUGGESTED)
            {
                return nil;
            }
            NSInteger sectionIndex = [self.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeSuggestedRooms];
            indexPath = [NSIndexPath indexPathForRow:index inSection:sectionIndex];
        }
    }
    
    if (!indexPath && ([self.sections contains:RecentsDataSourceSectionTypeBreadcrumbs]))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:self.breadcrumbsRoomCellDataArray];

        if (index != NSNotFound)
        {
            // Check whether the recent rooms are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_BREADCRUMBS)
            {
                return nil;
            }
            NSInteger sectionIndex = [self.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeBreadcrumbs];
            indexPath = [NSIndexPath indexPathForRow:index inSection:sectionIndex];
        }
    }
    
    if (!indexPath && ([self.sections contains:RecentsDataSourceSectionTypeAllChats]))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:self.allChatsRoomCellDataArray];

        if (index != NSNotFound)
        {
            // Check whether the all chats rooms are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_ALL_CHATS)
            {
                return nil;
            }
            NSInteger sectionIndex = [self.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeAllChats];
            indexPath = [NSIndexPath indexPathForRow:index inSection:sectionIndex];
        }
    }

    return indexPath;
}

#pragma mark - MXKDataSourceDelegate

- (void)dataSource:(MXKDataSource*)dataSource didCellChange:(id)changes
{
    // Refresh is disabled during drag&drop animation
    if (self.droppingCellIndexPath)
    {
        return;
    }
    
    // FIXME : manage multi accounts
    // to manage multi accounts
    // this method in MXKInterleavedRecentsDataSource must be split in two parts
    // 1 - the intervealing cells method
    // 2 - [super dataSource:dataSource didCellChange:changes] call.
    // the [self refreshRoomsSections] call should be done at the end of the 1- method
    // so a dedicated method must be implemented in MXKInterleavedRecentsDataSource
    // this class will inherit of this new method
    // 1 - call [super thisNewMethod]
    // 2 - call [self refreshRoomsSections]
    
    // Call super to keep update readyRecentsDataSourceArray.
    [super dataSource:dataSource didCellChange:changes];
}

#pragma mark - Drag & Drop handling

- (BOOL)isMovingCellSection:(NSInteger)section
{
    return self.droppingCellIndexPath && (self.droppingCellIndexPath.section == section);
}

- (BOOL)isHiddenCellSection:(NSInteger)section
{
    return self.hiddenCellIndexPath && (self.hiddenCellIndexPath.section == section);
}

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *shrinkButton = (UIButton*)sender;
        NSInteger selectedSectionBit = shrinkButton.tag;
        
        if (shrinkedSectionsBitMask & selectedSectionBit)
        {
            // Disclose the section
            shrinkedSectionsBitMask &= ~selectedSectionBit;
        }
        else
        {
            // Shrink this section
            shrinkedSectionsBitMask |= selectedSectionBit;
        }
        
        // Inform the delegate about the update
        [self.delegate dataSource:self didCellChange:nil];
    }
}

- (IBAction)onPublicRoomsSearchPatternUpdate:(id)sender
{
    if (publicRoomsTriggerTimer)
    {
        NSString *searchPattern = publicRoomsTriggerTimer.userInfo;

        [publicRoomsTriggerTimer invalidate];
        publicRoomsTriggerTimer = nil;

        _publicRoomsDirectoryDataSource.searchPattern = searchPattern;
        [_publicRoomsDirectoryDataSource paginate:nil failure:nil];
    }
}

#pragma mark - Action

- (IBAction)onDirectoryServerPickerTap:(UITapGestureRecognizer*)sender
{
    [self.delegate dataSource:self didRecognizeAction:kRecentsDataSourceTapOnDirectoryServerChange inCell:nil userInfo:nil];
}

#pragma mark - Override MXKDataSource

- (void)destroy
{
    [super destroy];

    [publicRoomsTriggerTimer invalidate];
    publicRoomsTriggerTimer = nil;
    
    [self.recentsListService stop];
}

#pragma mark - Override MXKRecentsDataSource

- (void)searchWithPatterns:(NSArray *)patternsList
{
    [super searchWithPatterns:patternsList];
    
    NSString *searchPattern = [patternsList componentsJoinedByString:@" "];
    
    [self.recentsListService updateQuery:searchPattern];

    if (_publicRoomsDirectoryDataSource)
    {
        // Do not send a /publicRooms request for every keystroke
        // Let user finish typing
        [publicRoomsTriggerTimer invalidate];
        publicRoomsTriggerTimer = [NSTimer scheduledTimerWithTimeInterval:0.7 target:self selector:@selector(onPublicRoomsSearchPatternUpdate:) userInfo:searchPattern repeats:NO];
    }
}

#pragma mark - drag and drop managemenent

- (BOOL)isDraggableCellAt:(NSIndexPath*)path
{
    if (_recentsDataSourceMode == RecentsDataSourceModePeople || _recentsDataSourceMode == RecentsDataSourceModeRooms || _recentsDataSourceMode == RecentsDataSourceModeRoomInvites)
    {
        return NO;
    }

    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:path.section];
    return (path && ((sectionType == RecentsDataSourceSectionTypeFavorites)
                     || (sectionType == RecentsDataSourceSectionTypePeople)
                     || (sectionType == RecentsDataSourceSectionTypeLowPriority)
                     || (sectionType == RecentsDataSourceSectionTypeServerNotice)
                     || (sectionType == RecentsDataSourceSectionTypeConversation)));
}

- (BOOL)canCellMoveFrom:(NSIndexPath*)oldPath to:(NSIndexPath*)newPath
{
    BOOL res = [self isDraggableCellAt:oldPath] && [self isDraggableCellAt:newPath];
    
    // the both index pathes are movable
    if (res)
    {
        // only the favorites cell can be moved within the same section
        RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:oldPath.section];
        res &= (sectionType == RecentsDataSourceSectionTypeFavorites) || (newPath.section != oldPath.section);
        
        // other cases ?
    }
    
    return res;
}

- (NSString*)roomTagAt:(NSIndexPath*)path
{
    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:path.section];
    if (sectionType == RecentsDataSourceSectionTypeFavorites)
    {
        return kMXRoomTagFavourite;
    }
    else if (sectionType == RecentsDataSourceSectionTypeLowPriority)
    {
        return kMXRoomTagLowPriority;
    }
    else if (sectionType == RecentsDataSourceSectionTypeServerNotice)
    {
        return kMXRoomTagServerNotice;
    }
    
    return nil;
}

- (void)paginateInSection:(NSInteger)section
{
    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:section];
    if (sectionType == RecentsDataSourceSectionTypeInvites)
    {
        [self.recentsListService paginateInSection:RecentsListServiceSectionInvited];
    }
    else if (sectionType == RecentsDataSourceSectionTypeFavorites)
    {
        [self.recentsListService paginateInSection:RecentsListServiceSectionFavorited];
    }
    else if (sectionType == RecentsDataSourceSectionTypePeople)
    {
        [self.recentsListService paginateInSection:RecentsListServiceSectionPeople];
    }
    else if (sectionType == RecentsDataSourceSectionTypeConversation)
    {
        [self.recentsListService paginateInSection:RecentsListServiceSectionConversation];
    }
    else if (sectionType == RecentsDataSourceSectionTypeLowPriority)
    {
        [self.recentsListService paginateInSection:RecentsListServiceSectionLowPriority];
    }
    else if (sectionType == RecentsDataSourceSectionTypeServerNotice)
    {
        [self.recentsListService paginateInSection:RecentsListServiceSectionServerNotice];
    }
    else if (sectionType == RecentsDataSourceSectionTypeSuggestedRooms)
    {
        [self.recentsListService paginateInSection:RecentsListServiceSectionSuggested];
    }
    else if (sectionType == RecentsDataSourceSectionTypeAllChats)
    {
        [self.recentsListService paginateInSection:RecentsListServiceSectionAllChats];
    }
}

- (void)moveRoomCell:(MXRoom*)room from:(NSIndexPath*)oldPath to:(NSIndexPath*)newPath success:(void (^)(void))moveSuccess failure:(void (^)(NSError *error))moveFailure;
{
    MXLogDebug(@"[RecentsDataSource] moveCellFrom (%tu, %tu) to (%tu, %tu)", oldPath.section, oldPath.row, newPath.section, newPath.row);
    
    if ([self canCellMoveFrom:oldPath to:newPath] && ![newPath isEqual:oldPath])
    {
        if ([self.sections sectionTypeForSectionIndex:newPath.section] == RecentsDataSourceSectionTypePeople)
        {
            [room setIsDirect:YES
                   withUserId:nil
                      success:moveSuccess
                      failure:^(NSError *error) {
                          
                          MXLogDebug(@"[RecentsDataSource] Failed to mark as direct");
                          
                          if (moveFailure)
                          {
                              moveFailure(error);
                          }
                          
                          [self forceRefresh];
                          
                          // Notify user
                          [[AppDelegate theDelegate] showErrorAsAlert:error];
                      }];
        }
        else
        {
            NSString* oldRoomTag = [self roomTagAt:oldPath];
            NSString* dstRoomTag = [self roomTagAt:newPath];
            NSUInteger oldPos = (oldPath.section == newPath.section) ? oldPath.row : NSNotFound;
            
            NSString* tagOrder = [room.mxSession tagOrderToBeAtIndex:newPath.row from:oldPos withTag:dstRoomTag];
            
            MXLogDebug(@"[RecentsDataSource] Update the room %@ [%@] tag from %@ to %@ with tag order %@", room.roomId, room.summary.displayname, oldRoomTag, dstRoomTag, tagOrder);
            
            [room replaceTag:oldRoomTag
                       byTag:dstRoomTag
                   withOrder:tagOrder
                     success: ^{
                         
                         MXLogDebug(@"[RecentsDataSource] move is done");
                         
                         if (moveSuccess)
                         {
                             moveSuccess();
                         }
                         
                         // wait the server echo to reload the tableview.
                         
                     } failure:^(NSError *error) {
                         
                         MXLogDebug(@"[RecentsDataSource] Failed to update the tag %@ of room (%@)", dstRoomTag, room.roomId);
                         
                         if (moveFailure)
                         {
                             moveFailure(error);
                         }
                         
                         [self forceRefresh];
                         
                         // Notify user
                         [[AppDelegate theDelegate] showErrorAsAlert:error];
                     }];
        }
    }
    else
    {
        MXLogDebug(@"[RecentsDataSource] cannot move this cell");
        
        if (moveFailure)
        {
            moveFailure(nil);
        }
        
        [self forceRefresh];
    }
}

#pragma mark - SecureBackupSetupBannerCellDelegate

- (void)secureBackupBannerCellDidTapCloseAction:(SecureBackupBannerCell * _Nonnull)cell
{
    [self hideKeyBackupBannerWithDisplay:self.secureBackupBannerDisplay];
}

#pragma mark - CrossSigningSetupBannerCellDelegate

- (void)crossSigningSetupBannerCellDidTapCloseAction:(CrossSigningSetupBannerCell *)cell
{
    [self hideCrossSigningBannerWithDisplay:self.crossSigningBannerDisplay];
}

#pragma mark - RecentsListServiceDelegate

- (void)recentsListServiceDidChangeData:(id<RecentsListServiceProtocol>)service
                     totalCountsChanged:(BOOL)totalCountsChanged
{
    if (!BuildSettings.newAppLayoutEnabled)
    {
        [[AppDelegate theDelegate].masterTabBarController refreshTabBarBadges];
    }
}

- (void)recentsListServiceDidChangeData:(id<RecentsListServiceProtocol>)service
                             forSection:(RecentsListServiceSection)section
                     totalCountsChanged:(BOOL)totalCountsChanged
{
    RecentsDataSourceSections *updatedSections = [self makeDataSourceSections];
    BOOL hasChangedSections = ![self.sections isEqual:updatedSections];
    if (hasChangedSections)
    {
        // If the number or order of sections has changed, we reload all of the data
        [self.delegate dataSource:self didCellChange:nil];
        return;
    }
    
    RecentsDataSourceSectionType sectionType = [self sectionTypeForServiceSection:section];
    NSInteger sectionIndex = [self.sections sectionIndexForSectionType:sectionType];
    if (sectionIndex >= 0)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:(NSUInteger)sectionIndex];
        [self.delegate dataSource:self didCellChange:indexPath];
    }
}

- (RecentsDataSourceSectionType)sectionTypeForServiceSection:(RecentsListServiceSection)serviceSection
{
    switch (serviceSection)
    {
        case RecentsListServiceSectionInvited:
            return RecentsDataSourceSectionTypeInvites;
        case RecentsListServiceSectionFavorited:
            return RecentsDataSourceSectionTypeFavorites;
        case RecentsListServiceSectionPeople:
            return RecentsDataSourceSectionTypePeople;
        case RecentsListServiceSectionConversation:
            return RecentsDataSourceSectionTypeConversation;
        case RecentsListServiceSectionLowPriority:
            return RecentsDataSourceSectionTypeLowPriority;
        case RecentsListServiceSectionServerNotice:
            return RecentsDataSourceSectionTypeServerNotice;
        case RecentsListServiceSectionSuggested:
            return RecentsDataSourceSectionTypeSuggestedRooms;
        case RecentsListServiceSectionBreadcrumbs:
            return RecentsDataSourceSectionTypeBreadcrumbs;
        case RecentsListServiceSectionAllChats:
            return RecentsDataSourceSectionTypeAllChats;
    }
}

#pragma mark - Shrinkable
- (BOOL)isSectionShrinkedAt:(NSInteger)section
{
    if (_areSectionsShrinkable == NO)
    {
        return NO;
    }

    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:section];
    if (sectionType == RecentsDataSourceSectionTypeFavorites && (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_FAVORITES))
    {
        return YES;
    }

    if (sectionType == RecentsDataSourceSectionTypePeople && (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_PEOPLE))
    {
        return YES;
    }

    if (sectionType == RecentsDataSourceSectionTypeConversation && (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_CONVERSATIONS))
    {
        return YES;
    }

    if (sectionType == RecentsDataSourceSectionTypeDirectory && (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_DIRECTORY))
    {
        return YES;
    }

    if (sectionType == RecentsDataSourceSectionTypeLowPriority && (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_LOWPRIORITY))
    {
        return YES;
    }

    if (sectionType == RecentsDataSourceSectionTypeServerNotice && (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_SERVERNOTICE))
    {
        return YES;
    }

    if (sectionType == RecentsDataSourceSectionTypeInvites && (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_INVITES))
    {
        return YES;
    }

    if (sectionType == RecentsDataSourceSectionTypeSuggestedRooms && (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_SUGGESTED))
    {
        return YES;
    }

    if (sectionType == RecentsDataSourceSectionTypeBreadcrumbs && (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_BREADCRUMBS))
    {
        return YES;
    }

    if (sectionType == RecentsDataSourceSectionTypeAllChats && (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_ALL_CHATS))
    {
        return YES;
    }

    return NO;
}

@end
