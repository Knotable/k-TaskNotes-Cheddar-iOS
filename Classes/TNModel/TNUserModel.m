//
//  TNUserModel.m
//  Cheddar for iOS
//
//  Created by Mac on 7/21/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import "TNUserModel.h"

@implementation TNUserModel
@synthesize user_id,user_email,user_username,user_sessiontoken;
- (id)initWithDict:(NSDictionary *)model{
    self = [super init];
 
    if (self)
    {
        @try {
            self.user_id = @"";
            self.user_email = @"";
            self.user_username = @"";
            self.user_sessiontoken = @"";
            if ([model objectForKeyedSubscript:@"id"]) {
                self.user_id = [model objectForKeyedSubscript:@"id"];
            }

            if ([model objectForKeyedSubscript:@"email"]) {
                    self.user_email = [model objectForKeyedSubscript:@"email"];
            }

            if ([model objectForKeyedSubscript:@"username"]) {
                self.user_username = [model objectForKeyedSubscript:@"username"];
            }

            if ([model objectForKeyedSubscript:@"token"]) {
                self.user_sessiontoken = [model objectForKeyedSubscript:@"token"];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@",[exception description]);
            NSLog(@"%@",[exception callStackSymbols]);
        }
    }
    return self;
}

+ (TNUserModel*)currentUser{
        NSDictionary* userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kTNUserIDKey] ;
        TNUserModel *userModel =[[TNUserModel alloc]initWithDict:userInfo];
        NSString *savedPass = [SSKeychain passwordForService:@"Tasknote" account:userModel.user_username];
        if (userInfo != nil && savedPass) {
            [[TNAPIClient sharedClient] logonWithUsernameOrEmail:userModel.user_username password:savedPass withBlock:^(NSDictionary *response, NSError *error) {

            }];

            return userModel;
        }
    return nil;
}

+ (void)setCurrentUser:(TNUserModel*)user{
        if (user == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kTNUserIDKey];
        }else{
            [[NSUserDefaults standardUserDefaults] setObject:user forKey:kTNUserIDKey];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        [CDIAppDelegate sharedAppDelegate].userModel = user;
}
@end
