//
//  CDISignInViewController.h
//  Cheddar for iOS
//
//  Created by Sam Soffes on 4/23/12.
//  Copyright (c) 2012 Nothing Magical. All rights reserved.
//
#import "Constant.h"
#import "CDIAppDelegate.h"
@class MeteorClient;
@interface CDISignInViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong, readonly) UITextField *usernameTextField;
@property (nonatomic, strong, readonly) UITextField *emailTextField;
@property (nonatomic, strong, readonly) UITextField *passwordTextField;
@property (atomic,strong) MeteorClient *meteor;
+ (CGFloat)textFieldWith;

- (void)signIn:(id)sender;
- (void)signUp:(id)sender;
- (void)forgot:(id)sender;

@end
