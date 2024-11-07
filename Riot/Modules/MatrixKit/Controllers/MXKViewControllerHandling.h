/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import <MatrixSDK/MatrixSDK.h>

#import "MXKResponderRageShaking.h"
#import "MXKViewControllerActivityHandling.h"

/**
 `MXKViewControllerHandling` defines a protocol to handle requirements for
 all matrixKit view controllers and table view controllers.
 
 It manages the following points:
 - matrix sessions handling, one or more sessions are supported.
 - stop/start activity indicator according to the state of the associated matrix sessions.
 - update view appearance on matrix session state change.
 - support rage shake mechanism (depend on `rageShakeManager` property).
 */
@protocol MXKViewControllerHandling <MXKViewControllerActivityHandling>

/**
 The default navigation bar tint color (nil by default).
 */
@property (nonatomic) UIColor *defaultBarTintColor;

/**
 The color of the title in the navigation bar (nil by default).
 */
@property (nonatomic) UIColor *barTitleColor;

/**
 Enable the change of the navigation bar tint color according to the matrix homeserver reachability status (YES by default).
 Set NO this property to disable navigation tint color change.
 */
@property (nonatomic) BOOL enableBarTintColorStatusChange;

/**
 List of associated matrix sessions (empty by default).
 This property is used to update view appearance according to the session(s) state.
 */
@property (nonatomic, readonly) NSArray* mxSessions;

/**
 The first associated matrix session is considered as the main session (nil by default).
 */
@property (nonatomic, readonly) MXSession *mainSession;

/**
 Keep reference on the pushed and/or presented view controllers.
 */
@property (nonatomic, readonly) NSArray *childViewControllers;

/**
 An object implementing the `MXKResponderRageShaking` protocol.
 The view controller uses this object (if any) to report beginning and end of potential
 rage shake when it is the first responder.
 
 This property is nil by default.
 */
@property (nonatomic) id<MXKResponderRageShaking> rageShakeManager;

/**
 Called during UIViewController initialization to set the default
 properties values (see [initWithNibName:bundle:] and [initWithCoder:]).
 
 You should not call this method directly.
 
 Subclasses can override this method as needed to customize the initialization.
 */
- (void)finalizeInit;

/**
 Add a matrix session in the list of associated sessions (see 'mxSessions' property).
 
 The session is ignored if its state is 'MXSessionStateClosed'.
 In other case, the session is stored, and an observer on 'kMXSessionStateDidChangeNotification' is added if it's not already done.
 A session is automatically removed when its state returns to 'MXSessionStateClosed'.
 
 @param mxSession a Matrix session.
 */
- (void)addMatrixSession:(MXSession*)mxSession;

/**
 Remove a matrix session from the list of associated sessions (see 'mxSessions' property).
 
 Remove the session. The 'kMXSessionStateDidChangeNotification' observer is removed if there is no more matrix session.
 
 @param mxSession a Matrix session.
 */
- (void)removeMatrixSession:(MXSession*)mxSession;

/**
 The method specified as notification selector during 'kMXSessionStateDidChangeNotification' observer creation.
 
 By default this method consider ONLY notifications related to associated sessions (see 'mxSessions' property).
 A session is automatically removed from the list when its state is 'MXSessionStateClosed'. Else [self onMatrixSessionChange] is called.
 
 Override it to handle state change on associated sessions AND others.
 */
- (void)onMatrixSessionStateDidChange:(NSNotification *)notif;

/**
 This method is called on the following matrix session changes:
 - a new session is added.
 - a session is removed.
 - the state of an associated session changed (according to `MXSessionStateDidChangeNotification`).
 
 This method is called to refresh the display when the view controller will appear too.
 
 By default view controller appearance is updated according to the state of associated sessions:
 - starts activity indicator as soon as when `shouldShowActivityIndicator `returns true for the session.
 - switches in red the navigation bar tintColor when all sessions are in `MXSessionStateHomeserverNotReachable` state.
 - switches in orange the navigation bar tintColor when at least one session is in `MXSessionStateHomeserverNotReachable` state.
 
 Override it to customize view appearance according to associated session(s).
 */
- (void)onMatrixSessionChange;

/**
 Pop or dismiss the view controller. It depends if the view controller is embedded inside a navigation controller or not.
 
 @param animated YES to animate the transition.
 @param completion the block to execute after the view controller is popped or dismissed. This block has no return value and takes no parameters. You may specify nil for this parameter.
 */
- (void)withdrawViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion;

/**
 Dispose of any resources, and remove event observers.
 */
- (void)destroy;

@end

