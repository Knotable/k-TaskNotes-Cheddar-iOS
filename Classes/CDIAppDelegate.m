//
//  CDIAppDelegate.m
//  Cheddar for iOS
//
//  Created by Sam Soffes on 3/25/12.
//  Copyright (c) 2012 Nothing Magical. All rights reserved.
//

#import "CDIAppDelegate.h"
#import "CDISplitViewController.h"
#import "CDIListsViewController.h"
#import "CDITransactionObserver.h"
#import "CDIDefines.h"
#import "CDISettingsTapPickerViewController.h"
#import "CDISettingsFontPickerViewController.h"
#import "CDISettingsTextSizePickerViewController.h"
#import "UIFont+CheddariOSAdditions.h"
#import "LocalyticsUtilities.h"
#import <Crashlytics/Crashlytics.h>
#import <StoreKit/StoreKit.h>

@implementation CDIAppDelegate

@synthesize window = _window;


+ (CDIAppDelegate *)sharedAppDelegate {
	return (CDIAppDelegate *)[[UIApplication sharedApplication] delegate];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Configure analytics
	// If you don't work at Nothing Magical, you shouldn't turn these on.
#if CHEDDAR_PRODUCTION_MODE
	#ifdef CHEDDAR_CRASHLYTICS_KEY
	[Crashlytics startWithAPIKey:CHEDDAR_CRASHLYTICS_KEY];
	#endif

	#ifdef CHEDDAR_LOCALYTICS_KEY
	LLStartSession(CHEDDAR_LOCALYTICS_KEY);
	#endif
#endif
	
	// Optionally enable development mode
	// If you don't work at Nothing Magical, you shouldn't turn this on.
#ifdef CHEDDAR_API_DEVELOPMENT_MODE
	[CDKHTTPClient setDevelopmentModeEnabled:YES];
	[CDKPushController setDevelopmentModeEnabled:YES];
#endif

	// Default defaults
	NSDictionary *defaults = @{
		kCDITapActionDefaultsKey: kCDITapActionCompleteKey,
		kCDIFontDefaultsKey: kCDIFontGothamKey,
		kCDITextSizeDefaultsKey: kCDITextSizeMediumKey
	};
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

	// Initialize the window
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.backgroundColor = [UIColor blackColor];
	
	[self applyStylesheet];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.window.rootViewController = [[CDISplitViewController alloc] init];
	} else {
		UIViewController *viewController = [[CDIListsViewController alloc] init];
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
		self.window.rootViewController = navigationController;
	}
    [self loadServerConfig];
    [MagicalRecord setupCoreDataStackWithStoreNamed:kDBName];
	[self.window makeKeyAndVisible];
	
	// Defer some stuff to make launching faster
	dispatch_async(dispatch_get_main_queue(), ^{
		// Setup status bar network indicator
		[AFNetworkActivityIndicatorManager sharedManager].enabled = YES;

		// Set the OAuth client
		[[CDKHTTPClient sharedClient] setClientID:kCDIAPIClientID secret:kCDIAPIClientSecret];
		
		// Initialize the connection to Pusher		
		[CDKPushController sharedController];
		
		// Add the transaction observer
		[[SKPaymentQueue defaultQueue] addTransactionObserver:[CDITransactionObserver defaultObserver]];
	});

//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(meteorError:)
//                                                 name:MeteorClientTransportErrorDomain
//                                               object:nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(meteorAdded:)
//                                                 name:@"added"
//                                               object:nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(meteorRemoved:)
//                                                 name:@"removed"
//                                               object:nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(popUpMessage:)
//                                                 name:KnotebleShowPopUpMessage
//                                               object:nil];

//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(needChangeMogoDbServer:)
//                                                 name:kNeedChangeMongoDbServer
//                                               object:nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(needChangeApplicationHost:)
//                                                 name:kNeedChangeApplicationHost
//                                               object:nil];

	return YES;
}


#if ANALYTICS_ENABLED
- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}
#endif


- (void)applicationWillTerminate:(UIApplication *)application {
	[[SSManagedObject mainContext] save:nil];
	#if ANALYTICS_ENABLED
    [[LocalyticsSession sharedLocalyticsSession] close];
	#endif
}



#pragma mark - Stylesheet

- (void)applyStylesheet {
	// Navigation bar
	UINavigationBar *navigationBar = [UINavigationBar appearance];
	[navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-background"] forBarMetrics:UIBarMetricsDefault];

	[navigationBar setTitleVerticalPositionAdjustment:-1.0f forBarMetrics:UIBarMetricsDefault];
	[navigationBar setTitleTextAttributes:[[NSDictionary alloc] initWithObjectsAndKeys:
										   [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0f], UITextAttributeFont,
										   [UIColor colorWithWhite:0.0f alpha:0.2f], UITextAttributeTextShadowColor,
										   [NSValue valueWithUIOffset:UIOffsetMake(0.0f, 1.0f)], UITextAttributeTextShadowOffset,
										   [UIColor whiteColor], UITextAttributeTextColor,
										   nil]];
	
	// Navigation bar mini
	[navigationBar setTitleVerticalPositionAdjustment:-2.0f forBarMetrics:UIBarMetricsLandscapePhone];
	[navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-background-mini"] forBarMetrics:UIBarMetricsLandscapePhone];
	
	// Navigation button
	NSDictionary *barButtonTitleTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
												  [UIFont cheddarInterfaceFontOfSize:14.0f], UITextAttributeFont,
												  [UIColor colorWithWhite:0.0f alpha:0.2f], UITextAttributeTextShadowColor,
												  [NSValue valueWithUIOffset:UIOffsetMake(0.0f, 1.0f)], UITextAttributeTextShadowOffset,
												  nil];
	UIBarButtonItem *barButton = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil];
	//	[barButton setTitlePositionAdjustment:UIOffsetMake(0.0f, 1.0f) forBarMetrics:UIBarMetricsDefault];
	[barButton setTitleTextAttributes:barButtonTitleTextAttributes forState:UIControlStateNormal];
	[barButton setTitleTextAttributes:barButtonTitleTextAttributes forState:UIControlStateHighlighted];
	[barButton setBackgroundImage:[[UIImage imageNamed:@"nav-button"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
	[barButton setBackgroundImage:[[UIImage imageNamed:@"nav-button-highlighted"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
	
	// Navigation back button
	[barButton setBackButtonTitlePositionAdjustment:UIOffsetMake(2.0f, -2.0f) forBarMetrics:UIBarMetricsDefault];
	[barButton setBackButtonBackgroundImage:[[UIImage imageNamed:@"nav-back"] stretchableImageWithLeftCapWidth:13 topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
	[barButton setBackButtonBackgroundImage:[[UIImage imageNamed:@"nav-back-highlighted"] stretchableImageWithLeftCapWidth:13 topCapHeight:0] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
	
	// Navigation button mini
	//	[barButton setTitlePositionAdjustment:UIOffsetMake(0.0f, 1.0f) forBarMetrics:UIBarMetricsLandscapePhone];
	[barButton setBackgroundImage:[[UIImage imageNamed:@"nav-button-mini"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
	[barButton setBackgroundImage:[[UIImage imageNamed:@"nav-button-mini-highlighted"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
	
	// Navigation back button mini
	[barButton setBackButtonTitlePositionAdjustment:UIOffsetMake(2.0f, -2.0f) forBarMetrics:UIBarMetricsLandscapePhone];
	[barButton setBackButtonBackgroundImage:[[UIImage imageNamed:@"nav-back-mini"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
	[barButton setBackButtonBackgroundImage:[[UIImage imageNamed:@"nav-back-mini-highlighted"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
	
	// Toolbar
	UIToolbar *toolbar = [UIToolbar appearance];
	[toolbar setBackgroundImage:[UIImage imageNamed:@"navigation-background"] forToolbarPosition:UIToolbarPositionTop barMetrics:UIBarMetricsDefault];
	[toolbar setBackgroundImage:[UIImage imageNamed:@"toolbar-background"] forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
	
	// Toolbar mini
	[toolbar setBackgroundImage:[UIImage imageNamed:@"navigation-background-mini"] forToolbarPosition:UIToolbarPositionTop barMetrics:UIBarMetricsLandscapePhone];
	[toolbar setBackgroundImage:[UIImage imageNamed:@"toolbar-background-mini"] forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsLandscapePhone];

//    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)loadServerConfig{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"servers_dev" ofType:@"plist"];
    NSArray *serverDicts = [NSArray arrayWithContentsOfFile:plistPath];
    if ([serverDicts isKindOfClass:[NSArray class]]) {
        ServerConfigModel *model = [[ServerConfigModel alloc]initWithDictionary:[serverDicts firstObject]];
        [self initServer:model];
    }
}

- (void)initServer :(ServerConfigModel* )model{
    if (!self.meteorClient) {
        self.meteorClient = [[MeteorClient alloc]initWithDDPVersion:@"pre2"];
        self.ddp = [[ObjectiveDDP alloc]initWithURLString:[model meteorWebsocketURL] delegate:self.meteorClient];
        self.meteorClient.ddp = self.ddp;
        [self.ddp connectWebSocket];
        [self.meteorClient addSubscription:METEORCOLLECTION_KNOTES];
        [self.meteorClient addSubscription:METEORCOLLECTION_MESSAGES];
        [self.meteorClient addSubscription:METEORCOLLECTION_MUTEKNOTES];
        [self.meteorClient addSubscription:METEORCOLLECTION_NOTIFICATIONS];
        [self.meteorClient addSubscription:METEORCOLLECTION_PEOPLE];
        [self.meteorClient addSubscription:METEORCOLLECTION_TOPICS];
        [self.meteorClient addSubscription:METEORCOLLECTION_USERPRIVATEDATA];
        [self.meteorClient addSubscription:METEORCOLLECTION_USERS];
        [self.meteorClient addSubscription:METEORCOLLECTION_KNOTE_TOPIC];
        [self.meteorClient addSubscription:METEORCOLLECTION_KNOTE_REST];
        [self.meteorClient addSubscription:METEORCOLLECTION_KNOTE_PINNED];
        [self.meteorClient addSubscription:METEORCOLLECTION_KNOTE_ARCHIVED];
        [self.meteorClient addSubscription:METEORCOLLECTION_KEY];
        [self.meteorClient addSubscription:METEORCOLLECTION_HOTKNOTES];
        
//        [self.meteorClient addSubscription:METEORCOLLECTION_KNOTES];
//        [self.meteorClient addObserver:self
//                      forKeyPath:@"connected"
//                         options:NSKeyValueObservingOptionNew
//                         context:nil];
//        [self.meteorClient addObserver:self
//                      forKeyPath:@"sessionToken"
//                         options:NSKeyValueObservingOptionNew
//                         context:nil];
    }else if (![self.meteorClient.ddp.urlString isEqualToString:[model meteorWebsocketURL]]){
        [self closePreMeteor];
        self.meteorClient = [[MeteorClient alloc]initWithDDPVersion:@"pre2"];
        self.ddp = [[ObjectiveDDP alloc]initWithURLString:[model meteorWebsocketURL] delegate:self.meteorClient];
        self.meteorClient.ddp = self.ddp;
        [self.ddp connectWebSocket];
        [self.meteorClient addObserver:self
                            forKeyPath:@"connected"
                               options:NSKeyValueObservingOptionNew
                               context:nil];
        [self.meteorClient addObserver:self
                            forKeyPath:@"sessionToken"
                               options:NSKeyValueObservingOptionNew
                               context:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportConnection) name:MeteorClientDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportDisconnection) name:MeteorClientDidDisconnectNotification object:nil];
}

-(void)closePreMeteor{
    self.meteorClientOld = self.meteorClient;
    [self.meteorClient removeObserver:self forKeyPath:@"connected"];
    [self.meteorClient removeObserver:self forKeyPath:@"sessionToken"];
    [self.meteorClient disconnect];
    self.meteorClient = nil;
}

- (void)reportConnection {
    NSLog(@"================> connected to server!");
    TNUserModel *model = [TNUserModel currentUser];
    if (model) {
        [[TNAPIClient sharedClient] logonWithSessionToken:model.user_sessiontoken withBlock:^(NSDictionary *response, NSError *error) {
            if (!error) {
                 NSLog(@"Login is ok");
            }
        }];
    }
}

- (void)reportDisconnection {
    NSLog(@"================> disconnected from server!");
}

-(void)meteorError: (NSNotification *)note
{
    NSLog(@"meteorError: %@ %@", note.userInfo, note.object);
}

-(void)meteorAdded:(NSNotification *)note
{
    NSLog(@"meteorAdded: %@", note);
}

-(void)meteorRemoved:(NSNotification *)note
{
    NSLog(@"meteorRemoved: %@", note);
}

- (NSString* )idRandom
{
    static char const possibleChars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    unichar characters[10];
    for( int index=0; index < 10; ++index )
    {
        characters[ index ] = possibleChars[arc4random_uniform(sizeof(possibleChars)-1)];
    }

    return [ NSString stringWithCharacters:characters length:10 ] ;
}

@end
