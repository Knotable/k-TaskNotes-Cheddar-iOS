//
//  TNAPIClient.m
//  Cheddar for iOS
//
//  Created by Mac on 7/20/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import "TNAPIClient.h"

@implementation TNAPIClient
+ (instancetype)sharedClient
{
    static TNAPIClient *_sharedClient = nil;

    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedClient = [[TNAPIClient alloc] init];
        _sharedClient.meteor = [CDIAppDelegate sharedAppDelegate].meteorClient;
    });

    return _sharedClient;
}

//Logon with email
- (void)logonWithEmail:(NSString *)username password:(NSString *)password withBlock:(void (^)(NSDictionary *, NSError *))block{
    @try {
        [self.meteor logonWithEmail:username password:password responseCallback:^(NSDictionary *response, NSError *error) {
            if (error) {
                block(nil, error);
            }
            if (response) {
                block(response, nil);
            }
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
        NSLog(@"%@",[exception callStackSymbols]);
    }
}

//Logon with username or email
- (void)logonWithUsernameOrEmail:(NSString *)usernameOrEmail password:(NSString *)password withBlock:(void (^)(NSDictionary *, NSError *))block{
    @try {
        [self.meteor logonWithUsernameOrEmail:usernameOrEmail password:password responseCallback:^(NSDictionary *response, NSError *error) {
            if (error) {
                block(nil, error);
            }
            if (response) {
                block(response, nil);
            }
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
        NSLog(@"%@",[exception callStackSymbols]);
    }
}

//Sign up
- (void)sigupWithUsernameAndEmail:(NSString *)modelName withDict:(NSDictionary*)paramDict withBlock:(void (^)(NSDictionary *, NSError *))block{
    @try {
        [self.meteor callMethodName:modelName parameters:@[paramDict] responseCallback:^(NSDictionary *response, NSError *error) {
            if (error) {
                block(nil, error);
            }
            if (response) {
                block(response, nil);
            }
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
        NSLog(@"%@",[exception callStackSymbols]);
    }
}

//Creat Note
- (void) sendInsertKnotes:(NSString *)modelName
                 withUserId:(NSString*)userId
                withBlock:(void(^)(NSDictionary *model, NSError *error))block{
    @try {
        
        NSString *subject = modelName;
        NSArray *participator_account_ids = @[userId];
        
        NSDictionary *requiredTopicParams = @{
                                              @"userId": userId,
                                              @"participator_account_ids": participator_account_ids,
                                              @"subject":subject,
                                              @"permissions":@[@"read", @"write", @"upload"],
                                              };
        NSLog(@"required Topics = %@",requiredTopicParams);
        
        
        NSDictionary *optionalTopicParams = @{
                                              /*@"file_ids":tInfo.filesIds ? tInfo.filesIds : @[],
                                              @"_id":[topic.topic_id noPrefix:kKnoteIdPrefix],
                                              @"order":@{[DataManager sharedInstance].currentAccount.user.user_id : topic.order_to_set != nil? topic.order_to_set : @(999)},
                                              @"to":participator_emails,*/
                                              };
        
        NSDictionary *additionalOptions = @{/*@"topicId":[topic.topic_id noPrefix:kKnoteIdPrefix]*/};
        
        NSArray *params = @[requiredTopicParams, optionalTopicParams, additionalOptions];
        
        
        NSString *methodName = @"create_topic";
        [self.meteor callMethodName:methodName parameters:params responseCallback:^(NSDictionary *response, NSError *error) {
            
            if (error) {
                NSLog(@"%@",error);
                block(nil, error);
            }
            if (response) {
                NSLog(@"%@ inserted pad = ",response);
                block(response, nil);
            }
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
        NSLog(@"%@",[exception callStackSymbols]);
    }
}
@end
