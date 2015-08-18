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

// Logon with token
- (void)logonWithSessionToken:(NSString *)sessiontoken withBlock:(void (^)(NSDictionary *, NSError *))block{
    @try {
        [self.meteor logonWithSessionToken:sessiontoken responseCallback:^(NSDictionary *response, NSError *error) {
            if (error) {
                block (nil, error);
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
                 withPram:(NSDictionary *)paramDict
                withBlock:(void(^)(NSDictionary *model, NSError *error))block{
    @try {
        NSString *methodName = [NSString stringWithFormat:@"/%@/%@",METEORCOLLECTION_KNOTES,modelName];
        [self.meteor callMethodName:methodName parameters:@[paramDict] responseCallback:^(NSDictionary *response, NSError *error) {
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

- (void) insertTopicWithParam:(NSString *)modelName
                     withPram:(NSArray *)param
                    withBlock:(void(^)(NSDictionary *model, NSError *error))block{
    @try {
        [self.meteor callMethodName:modelName parameters:param responseCallback:^(NSDictionary *response, NSError *error) {
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



- (void) sendInsertPadWithName:(NSString *)modelName
               withUserId:(NSString*)userId
                withBlock:(void(^)(NSDictionary *model, NSError *error))block{
    
            
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

- (void) sendRequestKnotes:(NSString *)topic_id
         withCompleteBlock:(MongoCompletion)block
{
    /********************************************************
     
     Working State : Working
     
     ********************************************************/
    
    NSArray *resultDocArray = nil;
    WM_NetworkStatus ret =  NetworkFailure;
    
    M13MutableOrderedDictionary *mongo_Knotes = self.meteor.collections[METEORCOLLECTION_KNOTES];
    
    ret = NetworkSucc;
    
    if(mongo_Knotes != nil)
    {
        
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"(topic_id LIKE %@)", topic_id];
        NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"(NOT type LIKE %@) AND (NOT type LIKE %@)", @"lock", @"unlock"];
        
        NSArray *subPredicates = [NSArray arrayWithObjects:predicate1, predicate2, nil];
        
        NSPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
        
        resultDocArray = [mongo_Knotes.allObjects filteredArrayUsingPredicate:finalPredicate];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        block(ret, nil, resultDocArray);
        
    });
    
}


@end
