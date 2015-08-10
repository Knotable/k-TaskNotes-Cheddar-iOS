//
//  TNUserModel.h
//  Cheddar for iOS
//
//  Created by Mac on 7/21/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDIHUDView.h"
@interface TNUserModel : NSObject
@property (nonatomic, strong) NSString* user_id;
@property (nonatomic, strong) NSString* user_email;
@property (nonatomic, strong) NSString* user_username;
@property (nonatomic, strong) NSString* user_sessiontoken;
-(id)initWithDict:(NSDictionary*)model;
+(TNUserModel*)currentUser;
+ (void)setCurrentUser:(TNUserModel*)user;
@end
