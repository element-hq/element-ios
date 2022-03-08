/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "SegmentedViewController.h"

@class Contact;
@class RoomParticipantsViewController;
@class AnalyticsScreenTracker;

/**
 `RoomParticipantsViewController` delegate.
 */
@protocol RoomParticipantsViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user wants to mention a room member.
 
 @discussion the `RoomParticipantsViewController` instance is withdrawn automatically.
 
 @param roomParticipantsViewController the `RoomParticipantsViewController` instance.
 @param member the room member to mention.
 */
- (void)roomParticipantsViewController:(RoomParticipantsViewController *)roomParticipantsViewController mention:(MXRoomMember*)member;

@end

/**
 'RoomParticipantsViewController' instance is used to edit members of the room defined by the property 'mxRoom'.
 When this property is nil, the view controller is empty.
 */
@interface RoomParticipantsViewController : MXKViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIGestureRecognizerDelegate, MXKRoomMemberDetailsViewControllerDelegate>
{
@protected
    /**
     Section indexes
     */
    NSInteger participantsSection;
    NSInteger invitedSection;
    
    /**
     The current list of joined members.
     */
    NSMutableArray<Contact*> *actualParticipants;
    
    /**
     The current list of invited members.
     */
    NSMutableArray<Contact*> *invitedParticipants;
    
    /**
     The contact used to describe the current user (nil if the user is not a participant of the room).
     */
    Contact *userParticipant;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *searchBarHeader;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBarView;
@property (weak, nonatomic) IBOutlet UIView *searchBarHeaderBorder;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarTopConstraint;

/**
 A matrix room (nil by default).
 */
@property (nonatomic) MXRoom *mxRoom;

/**
 The ID of the parent space. `nil` for home space
 */
@property (nonatomic) NSString *parentSpaceId;

/**
 Enable mention option in member details view. NO by default
 */
@property (nonatomic) BOOL enableMention;

@property (nonatomic) BOOL showCancelBarButtonItem;
@property (nonatomic) BOOL showParticipantCustomAccessoryView;
@property (nonatomic) BOOL showInviteUserFab;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<RoomParticipantsViewControllerDelegate> delegate;

/**
 The screen timer used for analytics if they've been enabled. The default value is nil.
 */
@property (nonatomic) AnalyticsScreenTracker *screenTracker;

/**
 Returns the `UINib` object initialized for a `RoomParticipantsViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `RoomParticipantsViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `RoomParticipantsViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)roomParticipantsViewController;

@end

