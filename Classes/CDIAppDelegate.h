//
//  CDIAppDelegate.h
//  Cheddar for iOS
//
//  Created by Sam Soffes on 3/25/12.
//  Copyright (c) 2012 Nothing Magical. All rights reserved.
//

@class MeteorClient,ObjectiveDDP,TNUserModel;
@interface CDIAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MeteorClient *meteorClient;
@property (strong, nonatomic) MeteorClient *meteorClientOld;
@property (strong, nonatomic) ObjectiveDDP *ddp;
@property (strong, nonatomic) TNUserModel* userModel;
@property (nonatomic, assign) BOOL isFirstLaunch;
@property (nonatomic, strong) NSString *previousUserID;
@property (nonatomic, strong) NSString *currentUserID;
+ (CDIAppDelegate *)sharedAppDelegate;
- (void)applyStylesheet;
- (NSString*)idRandom;
@end

#define K_SERVER_BETA       0
#define K_SERVER_STAGING    0
#define K_SERVER_DEV        1
