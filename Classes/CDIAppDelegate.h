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
+ (CDIAppDelegate *)sharedAppDelegate;
- (void)applyStylesheet;
- (NSString*)idRandom;
@end
