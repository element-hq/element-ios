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
#import "DirectorySectionHeaderContainerView.h"

#import "ThemeService.h"

#import "MXRoom+Riot.h"
#import "MXSession+Riot.h"

#import "Riot-Swift.h"

#define RECENTSDATASOURCE_SECTION_DIRECTORY     0x01
#define RECENTSDATASOURCE_SECTION_INVITES       0x02
#define RECENTSDATASOURCE_SECTION_FAVORITES     0x04
#define RECENTSDATASOURCE_SECTION_CONVERSATIONS 0x08
#define RECENTSDATASOURCE_SECTION_LOWPRIORITY   0x10
#define RECENTSDATASOURCE_SECTION_SERVERNOTICE  0x20
#define RECENTSDATASOURCE_SECTION_PEOPLE        0x40

#define RECENTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT     30.0
#define RECENTSDATASOURCE_DIRECTORY_SECTION_HEADER_HEIGHT   65.0

NSString *const kRecentsDataSourceTapOnDirectoryServerChange = @"kRecentsDataSourceTapOnDirectoryServerChange";

@interface RecentsDataSource() <SecureBackupBannerCellDelegate, CrossSigningSetupBannerCellDelegate>
{
    NSMutableArray* invitesCellDataArray;
    NSMutableArray* favoriteCellDataArray;
    NSMutableArray* peopleCellDataArray;
    NSMutableArray* conversationCellDataArray;
    NSMutableArray* lowPriorityCellDataArray;
    NSMutableArray* serverNoticeCellDataArray;
    
    NSInteger shrinkedSectionsBitMask;

    DirectorySectionHeaderContainerView *directorySectionContainer;
    UILabel *networkLabel;
    UILabel *directoryServerLabel;

    NSMutableDictionary<NSString*, id> *roomTagsListenerByUserId;
    
    // Timer to not refresh publicRoomsDirectoryDataSource on every keystroke.
    NSTimer *publicRoomsTriggerTimer;
}

@property (nonatomic, assign, readwrite) SecureBackupBannerDisplay secureBackupBannerDisplay;
@property (nonatomic, assign, readwrite) CrossSigningBannerDisplay crossSigningBannerDisplay;

@property (nonatomic, strong) CrossSigningService *crossSigningService;

@end

@implementation RecentsDataSource
@synthesize directorySection, invitesSection, favoritesSection, peopleSection, conversationSection, lowPrioritySection, serverNoticeSection, secureBackupBannerSection, crossSigningBannerSection;
@synthesize hiddenCellIndexPath, droppingCellIndexPath, droppingCellBackGroundView;
@synthesize invitesCellDataArray, favoriteCellDataArray, peopleCellDataArray, conversationCellDataArray, lowPriorityCellDataArray, serverNoticeCellDataArray;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        invitesCellDataArray = [[NSMutableArray alloc] init];
        favoriteCellDataArray = [[NSMutableArray alloc] init];
        peopleCellDataArray = [[NSMutableArray alloc] init];
        lowPriorityCellDataArray = [[NSMutableArray alloc] init];
        serverNoticeCellDataArray = [[NSMutableArray alloc] init];
        conversationCellDataArray = [[NSMutableArray alloc] init];
        
        _crossSigningBannerDisplay = CrossSigningBannerDisplayNone;
        crossSigningBannerSection = -1;
        
        _secureBackupBannerDisplay = SecureBackupBannerDisplayNone;
        secureBackupBannerSection = -1;
        directorySection = -1;
        invitesSection = -1;
        favoritesSection = -1;
        peopleSection = -1;
        conversationSection = -1;
        lowPrioritySection = -1;
        serverNoticeSection = -1;
        
        _areSectionsShrinkable = NO;
        shrinkedSectionsBitMask = 0;
        
        roomTagsListenerByUserId = [[NSMutableDictionary alloc] init];
        
        _crossSigningService = [CrossSigningService new];
        
        // Set default data and view classes
        [self registerCellDataClass:RecentCellData.class forCellIdentifier:kMXKRecentCellIdentifier];
    }
    return self;
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
    [self forceRefresh];
    [self refreshCrossSigningBannerDisplay];
}

- (UIView *)viewForStickyHeaderInSection:(NSInteger)section withFrame:(CGRect)frame
{
    UIView *stickyHeader;

    NSInteger savedShrinkedSectionsBitMask = shrinkedSectionsBitMask;
    if (section == directorySection)
    {
        // Return the section header used when the section is shrinked
        shrinkedSectionsBitMask = RECENTSDATASOURCE_SECTION_DIRECTORY;
    }

    stickyHeader = [self viewForHeaderInSection:section withFrame:frame];

    shrinkedSectionsBitMask = savedShrinkedSectionsBitMask;

    return stickyHeader;
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
        if (-1 != directorySection && !self.droppingCellIndexPath)
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
            id roomTagsListener = [dataSource.mxSession listenToEventsOfTypes:@[kMXEventTypeStringRoomTag]
                                                                onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {

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
        [self refreshRoomsSections];
        
        // And inform the delegate about the update
        [self.delegate dataSource:self didCellChange:nil];
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
    
    NSInteger sectionsCount = 0;
    
    // Check whether all data sources are ready before rendering recents
    if (self.state == MXKDataSourceStateReady)
    {
        crossSigningBannerSection = secureBackupBannerSection = directorySection = favoritesSection = peopleSection = conversationSection = lowPrioritySection = invitesSection = serverNoticeSection = -1;
        
        if (self.crossSigningBannerDisplay != CrossSigningBannerDisplayNone)
        {
            crossSigningBannerSection = sectionsCount++;
        }
        else if (self.secureBackupBannerDisplay != SecureBackupBannerDisplayNone)
        {
            secureBackupBannerSection = sectionsCount++;
        }
        
        if (invitesCellDataArray.count > 0)
        {
            invitesSection = sectionsCount++;
        }
        
        if (favoriteCellDataArray.count > 0)
        {
            favoritesSection = sectionsCount++;
        }
        
        if (_recentsDataSourceMode == RecentsDataSourceModeHome)
        {
            peopleSection = sectionsCount++;
        }
        
        // Keep visible the main rooms section even if it is empty, except on favourites screen.
        if (_recentsDataSourceMode != RecentsDataSourceModeFavourites)
        {
            conversationSection = sectionsCount++;
        }
        
        if (_recentsDataSourceMode == RecentsDataSourceModeRooms
            && BuildSettings.publicRoomsShowDirectory)
        {
            // Add the directory section after "ROOMS"
            directorySection = sectionsCount++;
        }
        
        if (lowPriorityCellDataArray.count > 0)
        {
            lowPrioritySection = sectionsCount++;
        }

        if (serverNoticeCellDataArray.count > 0)
        {
            serverNoticeSection = sectionsCount++;
        }
    }
    
    return sectionsCount;
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

    if (section == self.crossSigningBannerSection && self.crossSigningBannerDisplay != CrossSigningBannerDisplayNone)
    {
        count = 1;
    }
    else if (section == self.secureBackupBannerSection && self.secureBackupBannerDisplay != SecureBackupBannerDisplayNone)
    {
        count = 1;
    }
    else if (section == favoritesSection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_FAVORITES))
    {
        count = favoriteCellDataArray.count;
    }
    else if (section == peopleSection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_PEOPLE))
    {
        count = peopleCellDataArray.count ? peopleCellDataArray.count : 1;
    }
    else if (section == conversationSection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_CONVERSATIONS))
    {
        count = conversationCellDataArray.count ? conversationCellDataArray.count : 1;
    }
    else if (section == directorySection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_DIRECTORY))
    {
        count = [_publicRoomsDirectoryDataSource tableView:tableView numberOfRowsInSection:0];
    }
    else if (section == lowPrioritySection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_LOWPRIORITY))
    {
        count = lowPriorityCellDataArray.count;
    }
    else if (section == serverNoticeSection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_SERVERNOTICE))
    {
        count = serverNoticeCellDataArray.count;
    }
    else if (section == invitesSection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_INVITES))
    {
        count = invitesCellDataArray.count;
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
    if (section == self.secureBackupBannerSection || section == self.crossSigningBannerSection)
    {
        return 0.0;
    }
    else if (section == directorySection
             && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_DIRECTORY)
             && BuildSettings.publicRoomsAllowServerChange)
    {
        return RECENTSDATASOURCE_DIRECTORY_SECTION_HEADER_HEIGHT;
    }

    return RECENTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT;
}

- (NSAttributedString *)attributedStringForHeaderTitleInSection:(NSInteger)section
{
    NSAttributedString *sectionTitle;
    NSString *title;
    NSUInteger count = 0;
    
    if (section == favoritesSection)
    {
        count = favoriteCellDataArray.count;
        title = NSLocalizedStringFromTable(@"room_recents_favourites_section", @"Vector", nil);
    }
    else if (section == peopleSection)
    {
        count = peopleCellDataArray.count;
        title = NSLocalizedStringFromTable(@"room_recents_people_section", @"Vector", nil);
    }
    else if (section == conversationSection)
    {
        count = conversationCellDataArray.count;
        
        if (_recentsDataSourceMode == RecentsDataSourceModePeople)
        {
            title = NSLocalizedStringFromTable(@"people_conversation_section", @"Vector", nil);
        }
        else
        {
            title = NSLocalizedStringFromTable(@"room_recents_conversations_section", @"Vector", nil);
        }
    }
    else if (section == directorySection)
    {
        title = NSLocalizedStringFromTable(@"room_recents_directory_section", @"Vector", nil);
    }
    else if (section == lowPrioritySection)
    {
        count = lowPriorityCellDataArray.count;
        title = NSLocalizedStringFromTable(@"room_recents_low_priority_section", @"Vector", nil);
    }
    else if (section == serverNoticeSection)
    {
        count = serverNoticeCellDataArray.count;
        title = NSLocalizedStringFromTable(@"room_recents_server_notice_section", @"Vector", nil);
    }
    else if (section == invitesSection)
    {
        count = invitesCellDataArray.count;
        
        if (_recentsDataSourceMode == RecentsDataSourceModePeople)
        {
            title = NSLocalizedStringFromTable(@"people_invites_section", @"Vector", nil);
        }
        else
        {
            title = NSLocalizedStringFromTable(@"room_recents_invites_section", @"Vector", nil);
        }
    }
    
    if (count)
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
        sectionTitle = [[NSAttributedString alloc] initWithString:title
                                               attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.headerTextPrimaryColor,
                                                            NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0]}];
    }
    
    return sectionTitle;
}

- (UIView *)badgeViewForHeaderTitleInHomeSection:(NSInteger)section
{
    // Prepare a badge to display the total of missed notifications in this section.
    NSUInteger count = 0;
    NSArray *sectionArray;
    UIView *missedNotifAndUnreadBadgeBgView = nil;
    
    if (section == favoritesSection)
    {
        sectionArray = favoriteCellDataArray;
    }
    else if (section == peopleSection)
    {
        sectionArray = peopleCellDataArray;
    }
    else if (section == conversationSection)
    {
        sectionArray = conversationCellDataArray;
    }
    else if (section == lowPrioritySection)
    {
        sectionArray = lowPriorityCellDataArray;
    }
    else if (section == serverNoticeSection)
    {
        sectionArray = serverNoticeCellDataArray;
    }

    BOOL highlight = NO;
    for (id<MXKRecentCellDataStoring> cellData in sectionArray)
    {
        count += cellData.notificationCount;
        highlight |= (cellData.highlightCount > 0);
    }
    
    if (count)
    {
        UILabel *missedNotifAndUnreadBadgeLabel = [[UILabel alloc] init];
        missedNotifAndUnreadBadgeLabel.textColor = ThemeService.shared.theme.baseTextPrimaryColor;
        missedNotifAndUnreadBadgeLabel.font = [UIFont boldSystemFontOfSize:14];
        if (count > 1000)
        {
            CGFloat value = count / 1000.0;
            missedNotifAndUnreadBadgeLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"large_badge_value_k_format", @"Vector", nil), value];
        }
        else
        {
            missedNotifAndUnreadBadgeLabel.text = [NSString stringWithFormat:@"%tu", count];
        }
        
        [missedNotifAndUnreadBadgeLabel sizeToFit];
        
        CGFloat bgViewWidth = missedNotifAndUnreadBadgeLabel.frame.size.width + 18;
        
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

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame
{
    // No header view in key backup banner section
    if (section == self.secureBackupBannerSection || section == self.crossSigningBannerSection)
    {
        return nil;
    }
    
    SectionHeaderView *sectionHeader = [[SectionHeaderView alloc] initWithFrame:frame];
    sectionHeader.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    sectionHeader.topViewHeight = RECENTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT;
    NSInteger sectionBitwise = 0;

    if (_areSectionsShrinkable)
    {
        if (section == favoritesSection)
        {
            sectionBitwise =  RECENTSDATASOURCE_SECTION_FAVORITES;
        }
        else if (section == peopleSection)
        {
            sectionBitwise =  RECENTSDATASOURCE_SECTION_PEOPLE;
        }
        else if (section == conversationSection)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_CONVERSATIONS;
        }
        else if (section == directorySection)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_CONVERSATIONS;
        }
        else if (section == lowPrioritySection)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_LOWPRIORITY;
        }
        else if (section == serverNoticeSection)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_SERVERNOTICE;
        }
        else if (section == invitesSection)
        {
            sectionBitwise = RECENTSDATASOURCE_SECTION_INVITES;
        }
    }
    
    if (sectionBitwise)
    {
        // Add shrink button
        UIButton *shrinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        shrinkButton.backgroundColor = [UIColor clearColor];
        [shrinkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        shrinkButton.tag = sectionBitwise;
        [sectionHeader addSubview:shrinkButton];
        sectionHeader.topSpanningView = shrinkButton;
        sectionHeader.userInteractionEnabled = YES;
        
        // Add shrink icon
        UIImage *chevron;
        if (shrinkedSectionsBitMask & sectionBitwise)
        {
            chevron = [UIImage imageNamed:@"disclosure_icon"];
        }
        else
        {
            chevron = [UIImage imageNamed:@"shrink_icon"];
        }
        UIImageView *chevronView = [[UIImageView alloc] initWithImage:chevron];
        chevronView.tintColor = ThemeService.shared.theme.textSecondaryColor;
        chevronView.contentMode = UIViewContentModeCenter;
        [sectionHeader addSubview:chevronView];
        sectionHeader.accessoryView = chevronView;
    }
    else if (_recentsDataSourceMode == RecentsDataSourceModeHome)
    {
        // Add a badge to display the total of missed notifications by section.
        UIView *badgeView = [self badgeViewForHeaderTitleInHomeSection:section];
        
        if (badgeView)
        {
            [sectionHeader addSubview:badgeView];
            sectionHeader.accessoryView = badgeView;
        }
    }
    
    // Add label
    frame.size.height = RECENTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT - 10;
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.attributedText = [self attributedStringForHeaderTitleInSection:section];
    [sectionHeader addSubview:headerLabel];
    sectionHeader.headerLabel = headerLabel;

    if (section == directorySection
        && _recentsDataSourceMode == RecentsDataSourceModeRooms
        && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_DIRECTORY)
        && BuildSettings.publicRoomsAllowServerChange)
    {
        if (!directorySectionContainer)
        {
            directorySectionContainer = [[DirectorySectionHeaderContainerView alloc] initWithFrame:CGRectZero];
            directorySectionContainer.backgroundColor = [UIColor clearColor];

            // Add the "Network" label at the left
            networkLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
            networkLabel.font = [UIFont systemFontOfSize:16.0];
            networkLabel.text = NSLocalizedStringFromTable(@"room_recents_directory_section_network", @"Vector", nil);
            [directorySectionContainer addSubview:networkLabel];
            directorySectionContainer.networkLabel = networkLabel;

            // Add label for selected directory server
            directoryServerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
            directoryServerLabel.font = [UIFont systemFontOfSize:16.0];
            directoryServerLabel.textAlignment = NSTextAlignmentRight;
            [directorySectionContainer addSubview:directoryServerLabel];
            directorySectionContainer.directoryServerLabel = directoryServerLabel;

            // Chevron
            UIImageView *chevronImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 6, 12)];
            chevronImageView.contentMode = UIViewContentModeScaleAspectFit;
            chevronImageView.image = [UIImage imageNamed:@"disclosure_icon"];
            chevronImageView.tintColor = ThemeService.shared.theme.textSecondaryColor;
            [directorySectionContainer addSubview:chevronImageView];
            directorySectionContainer.disclosureView = chevronImageView;

            // Set a tap listener on all the container
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDirectoryServerPickerTap:)];
            [tapGesture setNumberOfTouchesRequired:1];
            [tapGesture setNumberOfTapsRequired:1];
            [directorySectionContainer addGestureRecognizer:tapGesture];
        }
        
        // Apply the current UI theme.
        networkLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
        directoryServerLabel.textColor = ThemeService.shared.theme.textSecondaryColor;

        // Set the current directory server name
        directoryServerLabel.text = _publicRoomsDirectoryDataSource.directoryServerDisplayname;

        // Add the check box container
        [sectionHeader addSubview:directorySectionContainer];
        sectionHeader.bottomView = directorySectionContainer;
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
    
    if (indexPath.section == self.crossSigningBannerSection)
    {
        CrossSigningSetupBannerCell* crossSigningSetupBannerCell = [tableView dequeueReusableCellWithIdentifier:CrossSigningSetupBannerCell.defaultReuseIdentifier forIndexPath:indexPath];
        crossSigningSetupBannerCell.delegate = self;
        return crossSigningSetupBannerCell;
    }
    else if (indexPath.section == self.secureBackupBannerSection)
    {
        SecureBackupBannerCell* keyBackupBannerCell = [tableView dequeueReusableCellWithIdentifier:SecureBackupBannerCell.defaultReuseIdentifier forIndexPath:indexPath];
        [keyBackupBannerCell configureFor:self.secureBackupBannerDisplay];
        keyBackupBannerCell.delegate = self;
        return keyBackupBannerCell;
    }
    else if (indexPath.section == directorySection)
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
    else if ((indexPath.section == conversationSection && !conversationCellDataArray.count)
             || (indexPath.section == peopleSection && !peopleCellDataArray.count))
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
            tableViewCell.textLabel.text = NSLocalizedStringFromTable(@"search_no_result", @"Vector", nil);
        }
        else if (_recentsDataSourceMode == RecentsDataSourceModePeople || indexPath.section == peopleSection)
        {
            tableViewCell.textLabel.text = NSLocalizedStringFromTable(@"people_no_conversation", @"Vector", nil);
        }
        else
        {
            tableViewCell.textLabel.text = NSLocalizedStringFromTable(@"room_recents_no_conversation", @"Vector", nil);
        }
        
        return tableViewCell;
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (id<MXKRecentCellDataStoring>)cellDataAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKRecentCellDataStoring> cellData = nil;
    NSUInteger cellDataIndex = indexPath.row;
    NSInteger tableSection = indexPath.section;
    
    // Compute the actual cell data index by taking into account the current droppingCellIndexPath and hiddenCellIndexPath (if any).
    if ([self isMovingCellSection:tableSection] && (cellDataIndex > self.droppingCellIndexPath.row))
    {
        cellDataIndex --;
    }
    if ([self isHiddenCellSection:tableSection] && (cellDataIndex >= self.hiddenCellIndexPath.row))
    {
        cellDataIndex ++;
    }
    
    if (tableSection == favoritesSection)
    {
        if (cellDataIndex < favoriteCellDataArray.count)
        {
            cellData = favoriteCellDataArray[cellDataIndex];
        }
    }
    else if (tableSection == peopleSection)
    {
        if (cellDataIndex < peopleCellDataArray.count)
        {
            cellData = peopleCellDataArray[cellDataIndex];
        }
    }
    else if (tableSection== conversationSection)
    {
        if (cellDataIndex < conversationCellDataArray.count)
        {
            cellData = conversationCellDataArray[cellDataIndex];
        }
    }
    else if (tableSection == lowPrioritySection)
    {
        if (cellDataIndex < lowPriorityCellDataArray.count)
        {
            cellData = lowPriorityCellDataArray[cellDataIndex];
        }
    }
    else if (tableSection == serverNoticeSection)
    {
        if (cellDataIndex < serverNoticeCellDataArray.count)
        {
            cellData = serverNoticeCellDataArray[cellDataIndex];
        }
    }
    else if (tableSection == invitesSection)
    {
        if (cellDataIndex < invitesCellDataArray.count)
        {
            cellData = invitesCellDataArray[cellDataIndex];
        }
    }
    
    return cellData;
}

- (CGFloat)cellHeightAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == directorySection)
    {
        return [_publicRoomsDirectoryDataSource cellHeightAtIndexPath:indexPath];
    }
    if (self.droppingCellIndexPath && [indexPath isEqual:self.droppingCellIndexPath])
    {
        return self.droppingCellBackGroundView.frame.size.height;
    }
    if ((indexPath.section == conversationSection && !conversationCellDataArray.count)
         || (indexPath.section == peopleSection && !peopleCellDataArray.count))
    {
        return 50.0;
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
    return (indexPath.section != invitesSection);
}

#pragma mark -

- (NSInteger)cellIndexPosWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)matrixSession within:(NSMutableArray*)cellDataArray
{
    if (roomId && matrixSession && cellDataArray.count)
    {
        for (int index = 0; index < cellDataArray.count; index++)
        {
            id<MXKRecentCellDataStoring> cellDataStoring = cellDataArray[index];

            if ([roomId isEqualToString:cellDataStoring.roomSummary.roomId] && (matrixSession == cellDataStoring.roomSummary.room.mxSession))
            {
                return index;
            }
        }
    }

    return NSNotFound;
}

- (NSIndexPath*)cellIndexPathWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)matrixSession
{
    NSIndexPath *indexPath = nil;
    NSInteger index;
    
    if (invitesSection >= 0)
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:invitesCellDataArray];
        
        if (index != NSNotFound)
        {
            // Check whether the invitations are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_INVITES)
            {
                return nil;
            }
            indexPath = [NSIndexPath indexPathForRow:index inSection:invitesSection];
        }
    }
    
    if (!indexPath && (favoritesSection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:favoriteCellDataArray];
        
        if (index != NSNotFound)
        {
            // Check whether the favorites are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_FAVORITES)
            {
                return nil;
            }
            indexPath = [NSIndexPath indexPathForRow:index inSection:favoritesSection];
        }
    }
    
    if (!indexPath && (peopleSection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:peopleCellDataArray];
        
        if (index != NSNotFound)
        {
            // Check whether the favorites are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_PEOPLE)
            {
                return nil;
            }
            indexPath = [NSIndexPath indexPathForRow:index inSection:peopleSection];
        }
    }
    
    if (!indexPath && (conversationSection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:conversationCellDataArray];
        
        if (index != NSNotFound)
        {
            // Check whether the conversations are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_CONVERSATIONS)
            {
                return nil;
            }
            indexPath = [NSIndexPath indexPathForRow:index inSection:conversationSection];
        }
    }
    
    if (!indexPath && (lowPrioritySection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:lowPriorityCellDataArray];
        
        if (index != NSNotFound)
        {
            // Check whether the low priority rooms are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_LOWPRIORITY)
            {
                return nil;
            }
            indexPath = [NSIndexPath indexPathForRow:index inSection:lowPrioritySection];
        }
    }

    if (!indexPath && (serverNoticeSection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:serverNoticeCellDataArray];

        if (index != NSNotFound)
        {
            // Check whether the low priority rooms are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_SERVERNOTICE)
            {
                return nil;
            }
            indexPath = [NSIndexPath indexPathForRow:index inSection:serverNoticeSection];
        }
    }
    
    return indexPath;
}


#pragma mark - MXKDataSourceDelegate

- (void)refreshRoomsSections
{
    NSDate *startDate = [NSDate date];

    [invitesCellDataArray removeAllObjects];
    [favoriteCellDataArray removeAllObjects];
    [peopleCellDataArray removeAllObjects];
    [conversationCellDataArray removeAllObjects];
    [lowPriorityCellDataArray removeAllObjects];
    [serverNoticeCellDataArray removeAllObjects];
    
    _missedFavouriteDiscussionsCount = _missedHighlightFavouriteDiscussionsCount = 0;
    _missedDirectDiscussionsCount = _missedHighlightDirectDiscussionsCount = 0;
    _missedGroupDiscussionsCount = _missedHighlightGroupDiscussionsCount = 0;
    _unsentMessagesDirectDiscussionsCount = 0;
    _unsentMessagesGroupDiscussionsCount = 0;
    
    secureBackupBannerSection = directorySection = favoritesSection = peopleSection = conversationSection = lowPrioritySection = serverNoticeSection = invitesSection = -1;
    
    if (displayedRecentsDataSourceArray.count > 0)
    {
        // FIXME manage multi accounts
        MXKSessionRecentsDataSource *recentsDataSource = displayedRecentsDataSourceArray[0];
        MXSession* session = recentsDataSource.mxSession;
        
        NSInteger count = recentsDataSource.numberOfCells;
        
        for (int index = 0; index < count; index++)
        {
            id<MXKRecentCellDataStoring> recentCellDataStoring = [recentsDataSource cellDataAtIndex:index];
            MXRoom* room = recentCellDataStoring.roomSummary.room;
            
            if (_recentsDataSourceMode == RecentsDataSourceModeHome)
            {
                if (room.accountData.tags[kMXRoomTagServerNotice])
                {
                    [serverNoticeCellDataArray addObject:recentCellDataStoring];
                }
                else if (room.accountData.tags[kMXRoomTagFavourite])
                {
                    [favoriteCellDataArray addObject:recentCellDataStoring];
                }
                else if (room.accountData.tags[kMXRoomTagLowPriority])
                {
                    [lowPriorityCellDataArray addObject:recentCellDataStoring];
                }
                else if (room.summary.membership == MXMembershipInvite)
                {
                    [invitesCellDataArray addObject:recentCellDataStoring];
                }
                else if (room.isDirect)
                {
                    [peopleCellDataArray addObject:recentCellDataStoring];
                }
                else
                {
                    // Hide spaces from home (keep space invites)
                    if (room.summary.roomType != MXRoomTypeSpace)
                    {
                        [conversationCellDataArray addObject:recentCellDataStoring];
                    }
                }
            }
            else if (_recentsDataSourceMode == RecentsDataSourceModeFavourites)
            {
                // Keep only the favourites rooms.
                if (room.accountData.tags[kMXRoomTagFavourite])
                {
                    [favoriteCellDataArray addObject:recentCellDataStoring];
                }
            }
            else if (_recentsDataSourceMode == RecentsDataSourceModePeople)
            {
                // Keep only the direct rooms which are not low priority
                if (room.isDirect && !room.accountData.tags[kMXRoomTagLowPriority])
                {
                    if (room.summary.membership == MXMembershipInvite)
                    {
                        [invitesCellDataArray addObject:recentCellDataStoring];
                    }
                    else
                    {
                        [conversationCellDataArray addObject:recentCellDataStoring];
                    }
                }
            }
            else if (_recentsDataSourceMode == RecentsDataSourceModeRooms)
            {
                // Consider only non direct rooms.
                if (!room.isDirect)
                {
                    // Keep only the invites, the favourites and the rooms without tag and room type different from space
                    if (room.summary.membership == MXMembershipInvite)
                    {
                        [invitesCellDataArray addObject:recentCellDataStoring];
                    }
                    else if ((!room.accountData.tags.count || room.accountData.tags[kMXRoomTagFavourite]) && room.summary.roomType != MXRoomTypeSpace)
                    {
                        [conversationCellDataArray addObject:recentCellDataStoring];
                    }
                }
            }
            
            // Update missed conversations counts
            NSUInteger notificationCount = recentCellDataStoring.roomSummary.notificationCount;
            
            // Ignore the regular notification count if the room is in 'mentions only" mode at the Riot level.
            if (room.isMentionsOnly)
            {
                // Only the highlighted missed messages must be considered here.
                notificationCount = recentCellDataStoring.roomSummary.highlightCount;
            }
            
            if (notificationCount)
            {
                if (room.accountData.tags[kMXRoomTagFavourite])
                {
                    _missedFavouriteDiscussionsCount ++;
                    
                    if (recentCellDataStoring.roomSummary.highlightCount)
                    {
                        _missedHighlightFavouriteDiscussionsCount ++;
                    }
                }
                
                if (room.isDirect)
                {
                    _missedDirectDiscussionsCount ++;
                    
                    if (recentCellDataStoring.roomSummary.highlightCount)
                    {
                        _missedHighlightDirectDiscussionsCount ++;
                    }
                }
                else if (!room.accountData.tags.count || room.accountData.tags[kMXRoomTagFavourite])
                {
                    _missedGroupDiscussionsCount ++;
                    
                    if (recentCellDataStoring.roomSummary.highlightCount)
                    {
                        _missedHighlightGroupDiscussionsCount ++;
                    }
                }
            }
            else if (room.summary.membership == MXMembershipInvite)
            {
                if (room.isDirect)
                {
                    _missedDirectDiscussionsCount ++;
                }
                else
                {
                    _missedGroupDiscussionsCount ++;
                }
            }
            
            if (room.sentStatus != RoomSentStatusOk)
            {
                if (room.isDirect)
                {
                    _unsentMessagesDirectDiscussionsCount ++;
                }
                else
                {
                    _unsentMessagesGroupDiscussionsCount ++;
                }
            }
            
        }
        
        if (_recentsDataSourceMode == RecentsDataSourceModeHome)
        {
            BOOL pinMissedNotif = RiotSettings.shared.pinRoomsWithMissedNotificationsOnHome;
            BOOL pinUnread = RiotSettings.shared.pinRoomsWithUnreadMessagesOnHome;            
            NSComparator comparator = nil;
            
            if (pinMissedNotif)
            {
                // Sort each rooms collection by considering first the rooms with some missed notifs, the rooms with unread, then the others.
                comparator = ^NSComparisonResult(id<MXKRecentCellDataStoring> recentCellData1, id<MXKRecentCellDataStoring> recentCellData2) {
                    
                    if (recentCellData1.roomSummary.room.sentStatus != RoomSentStatusOk
                        && recentCellData2.roomSummary.room.sentStatus == RoomSentStatusOk)
                    {
                        return NSOrderedAscending;
                    }
                    
                    if (recentCellData2.roomSummary.room.sentStatus != RoomSentStatusOk
                        && recentCellData1.roomSummary.room.sentStatus == RoomSentStatusOk)
                    {
                        return NSOrderedDescending;
                    }
                    
                    if (recentCellData1.highlightCount)
                    {
                        if (recentCellData2.highlightCount)
                        {
                            return NSOrderedSame;
                        }
                        else
                        {
                            return NSOrderedAscending;
                        }
                    }
                    else if (recentCellData2.highlightCount)
                    {
                        return NSOrderedDescending;
                    }
                    else if (recentCellData1.notificationCount)
                    {
                        if (recentCellData2.notificationCount)
                        {
                            return NSOrderedSame;
                        }
                        else
                        {
                            return NSOrderedAscending;
                        }
                    }
                    else if (recentCellData2.notificationCount)
                    {
                        return NSOrderedDescending;
                    }
                    else if (pinUnread)
                    {
                        if (recentCellData1.hasUnread)
                        {
                            if (recentCellData2.hasUnread)
                            {
                                return NSOrderedSame;
                            }
                            else
                            {
                                return NSOrderedAscending;
                            }
                        }
                        else if (recentCellData2.hasUnread)
                        {
                            return NSOrderedDescending;
                        }
                    }
                    
                    return NSOrderedSame;
                };
            }
            else if (pinUnread)
            {
                // Sort each rooms collection by considering first the rooms with some unread messages then the others.
                comparator = ^NSComparisonResult(id<MXKRecentCellDataStoring> recentCellData1, id<MXKRecentCellDataStoring> recentCellData2) {
                    
                    if (recentCellData1.roomSummary.room.sentStatus != RoomSentStatusOk
                        && recentCellData2.roomSummary.room.sentStatus == RoomSentStatusOk)
                    {
                        return NSOrderedAscending;
                    }
                    
                    if (recentCellData2.roomSummary.room.sentStatus != RoomSentStatusOk
                        && recentCellData1.roomSummary.room.sentStatus == RoomSentStatusOk)
                    {
                        return NSOrderedDescending;
                    }
                    
                    if (recentCellData1.hasUnread)
                    {
                        if (recentCellData2.hasUnread)
                        {
                            return NSOrderedSame;
                        }
                        else
                        {
                            return NSOrderedAscending;
                        }
                    }
                    else if (recentCellData2.hasUnread)
                    {
                        return NSOrderedDescending;
                    }
                    
                    return NSOrderedSame;
                };
            }
            
            if (comparator)
            {
                // Sort the rooms collections
                [favoriteCellDataArray sortUsingComparator:comparator];
                [peopleCellDataArray sortUsingComparator:comparator];
                [conversationCellDataArray sortUsingComparator:comparator];
                [lowPriorityCellDataArray sortUsingComparator:comparator];
                [serverNoticeCellDataArray sortUsingComparator:comparator];
            }
        }
        else if (favoriteCellDataArray.count > 0 && _recentsDataSourceMode == RecentsDataSourceModeFavourites)
        {
            // Sort them according to their tag order
            [favoriteCellDataArray sortUsingComparator:^NSComparisonResult(id<MXKRecentCellDataStoring> recentCellData1, id<MXKRecentCellDataStoring> recentCellData2) {
                
                return [session compareRoomsByTag:kMXRoomTagFavourite room1:recentCellData1.roomSummary.room room2:recentCellData2.roomSummary.room];
                
            }];
        }
        else if (conversationCellDataArray.count > 0 && (_recentsDataSourceMode == RecentsDataSourceModeRooms || _recentsDataSourceMode == RecentsDataSourceModePeople))
        {
            [conversationCellDataArray sortUsingComparator:^NSComparisonResult(id<MXKRecentCellDataStoring> recentCellData1, id<MXKRecentCellDataStoring> recentCellData2) {
                
                if (recentCellData1.roomSummary.room.sentStatus != RoomSentStatusOk
                    && recentCellData2.roomSummary.room.sentStatus == RoomSentStatusOk)
                {
                    return NSOrderedAscending;
                }
                
                if (recentCellData2.roomSummary.room.sentStatus != RoomSentStatusOk
                    && recentCellData1.roomSummary.room.sentStatus == RoomSentStatusOk)
                {
                    return NSOrderedDescending;
                }

                return NSOrderedAscending;
            }];
        }
    }

    MXLogDebug(@"[RecentsDataSource] refreshRoomsSections: Done in %.0fms", [[NSDate date] timeIntervalSinceDate:startDate] * 1000);
}

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
    
    // refresh the sections
    [self refreshRoomsSections];
    
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
}

#pragma mark - Override MXKRecentsDataSource

- (void)searchWithPatterns:(NSArray *)patternsList
{
    [super searchWithPatterns:patternsList];

    if (_publicRoomsDirectoryDataSource)
    {
        NSString *searchPattern = [patternsList componentsJoinedByString:@" "];

        // Do not send a /publicRooms request for every keystroke
        // Let user finish typing
        [publicRoomsTriggerTimer invalidate];
        publicRoomsTriggerTimer = [NSTimer scheduledTimerWithTimeInterval:0.7 target:self selector:@selector(onPublicRoomsSearchPatternUpdate:) userInfo:searchPattern repeats:NO];
    }
}

#pragma mark - drag and drop managemenent

- (BOOL)isDraggableCellAt:(NSIndexPath*)path
{
    if (_recentsDataSourceMode == RecentsDataSourceModePeople || _recentsDataSourceMode == RecentsDataSourceModeRooms)
    {
        return NO;
    }

    return (path && ((path.section == favoritesSection) || (path.section == peopleSection) || (path.section == lowPrioritySection) || (path.section == serverNoticeSection) || (path.section == conversationSection)));
}

- (BOOL)canCellMoveFrom:(NSIndexPath*)oldPath to:(NSIndexPath*)newPath
{
    BOOL res = [self isDraggableCellAt:oldPath] && [self isDraggableCellAt:newPath];
    
    // the both index pathes are movable
    if (res)
    {
        // only the favorites cell can be moved within the same section
        res &= (oldPath.section == favoritesSection) || (newPath.section != oldPath.section);
        
        // other cases ?
    }
    
    return res;
}

- (NSString*)roomTagAt:(NSIndexPath*)path
{
    if (path.section == favoritesSection)
    {
        return kMXRoomTagFavourite;
    }
    else if (path.section == lowPrioritySection)
    {
        return kMXRoomTagLowPriority;
    }
    else if (path.section == serverNoticeSection)
    {
        return kMXRoomTagServerNotice;
    }
    
    return nil;
}

- (void)moveRoomCell:(MXRoom*)room from:(NSIndexPath*)oldPath to:(NSIndexPath*)newPath success:(void (^)(void))moveSuccess failure:(void (^)(NSError *error))moveFailure;
{
    MXLogDebug(@"[RecentsDataSource] moveCellFrom (%tu, %tu) to (%tu, %tu)", oldPath.section, oldPath.row, newPath.section, newPath.row);
    
    if ([self canCellMoveFrom:oldPath to:newPath] && ![newPath isEqual:oldPath])
    {
        if (newPath.section == peopleSection)
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

@end
