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
@end
