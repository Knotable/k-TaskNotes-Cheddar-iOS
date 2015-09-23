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
            if ([model objectForKeyedSubscript:@"userId"]) {
                self.user_id = [model objectForKeyedSubscript:@"userId"];
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
        NSString* user_ID = [[NSUserDefaults standardUserDefaults] objectForKey:kTNUserIDKey] ;
    
        TNUserModel *userModel =[[TNUserModel alloc]init];
    
        if (user_ID != nil ) {
            userModel.user_id = user_ID;
            userModel.user_email = [[NSUserDefaults standardUserDefaults] objectForKey:kTNUserEmail];
            userModel.user_sessiontoken = [[NSUserDefaults standardUserDefaults] objectForKey:kTNUserSessionToken];
            userModel.user_username = [[NSUserDefaults standardUserDefaults] objectForKey:kTNUserName];
            return userModel;
        }
    return nil;
}

+ (void)setCurrentUser:(TNUserModel*)user{
        if (user == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kTNUserIDKey];
        }else{
//            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
//            f.numberStyle = NSNumberFormatterDecimalStyle;
//            NSNumber *user_ID = [f numberFromString:user.user_id];
//            
            [[NSUserDefaults standardUserDefaults] setObject:user.user_id forKey:kTNUserIDKey];
            [[NSUserDefaults standardUserDefaults] setObject:user.user_email forKey:kTNUserEmail];
            [[NSUserDefaults standardUserDefaults] setObject:user.user_sessiontoken forKey:kTNUserSessionToken];
            [[NSUserDefaults standardUserDefaults] setObject:user.user_username forKey:kTNUserName];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        [CDIAppDelegate sharedAppDelegate].userModel = user;
}
@end
