//
//  CDIListsViewController.h
//  Cheddar for iOS
//
//  Created by Sam Soffes on 3/30/12.
//  Copyright (c) 2012 Nothing Magical. All rights reserved.
//

#import "CDIManagedTableViewController.h"

extern NSString *const kCDISelectedListKey;
@class TNTopicModel;
@interface CDIListsViewController : CDIManagedTableViewController
@property (nonatomic,strong) MeteorClient *meteor;
- (void)showSettings:(id)sender;
- (void)createList:(id)sender;
-(void)turnOnBackground;
@end
