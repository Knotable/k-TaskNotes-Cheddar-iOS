//
//  TNAPIClient.h
//  Cheddar for iOS
//
//  Created by Mac on 7/20/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TNAPIClient : NSObject
typedef enum
{
    NetworkErr = -2,
    NetworkTimeOut  = -1,
    NetworkSucc,
    NetworkFailure,
} WM_NetworkStatus;


typedef void (^MongoCompletion)(WM_NetworkStatus success, NSError *error, id userData);




@property (nonatomic, strong) MeteorClient *meteor;
+ (instancetype)sharedClient;
//Logon with email
- (void)logonWithEmail:(NSString*)username password :(NSString*)password withBlock:(void(^)(NSDictionary *response, NSError *error))block;

//Logon with username or email
- (void)logonWithUsernameOrEmail:(NSString*)usernameOrEmail password:(NSString*)password withBlock:(void(^)(NSDictionary *response, NSError *error))block;

//Logon with token
- (void)logonWithSessionToken:(NSString*)sessiontoken withBlock:(void(^)(NSDictionary *response, NSError* error))block;

//Sign up
- (void)sigupWithUsernameAndEmail:(NSString*)modelName withDict :(NSDictionary*)paramDict withBlock:(void(^)(NSDictionary *response, NSError *error))block;

//Create List
- (void) sendInsertKnotes:(NSString *)modelName
                 withPram:(NSDictionary *)paramDict
                withBlock:(void(^)(NSDictionary *model, NSError *error))block;

- (void) insertTopicWithParam:(NSString *)modelName
                 withPram:(NSArray *)param
                withBlock:(void(^)(NSDictionary *model, NSError *error))block;

- (void) sendInsertPadWithName:(NSString *)modelName
                    withUserId:(NSString*)userId
                     withBlock:(void(^)(NSDictionary *model, NSError *error))block;

//Get Knotes Explicitly for perticular Pad
- (void) sendRequestKnotes:(NSString *)topic_id
         withCompleteBlock:(MongoCompletion)block;


@end
