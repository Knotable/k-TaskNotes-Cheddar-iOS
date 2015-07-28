//
//  TNAPIClient.h
//  Cheddar for iOS
//
//  Created by Mac on 7/20/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TNAPIClient : NSObject
@property (nonatomic, strong) MeteorClient *meteor;
+ (instancetype)sharedClient;
//Logon with email
- (void)logonWithEmail:(NSString*)username password :(NSString*)password withBlock:(void(^)(NSDictionary *response, NSError *error))block;

//Logon with username or email
- (void)logonWithUsernameOrEmail:(NSString*)usernameOrEmail password:(NSString*)password withBlock:(void(^)(NSDictionary *response, NSError *error))block;

//Logon with token
- (void)logonWithToken:(NSString*)token withBlock:(void(^)(NSDictionary *response, NSError* error))block;

//Sign up
- (void)sigupWithUsernameAndEmail:(NSString*)modelName withDict :(NSDictionary*)paramDict withBlock:(void(^)(NSDictionary *response, NSError *error))block;

//Create List
- (void) sendInsertKnotes:(NSString *)modelName
                 withPram:(NSDictionary *)paramDict
                withBlock:(void(^)(NSDictionary *model, NSError *error))block;


@end
