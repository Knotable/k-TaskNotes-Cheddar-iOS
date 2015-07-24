//
//  ServerConfigModel.m
//  Cheddar for iOS
//
//  Created by Mac on 7/20/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import "ServerConfigModel.h"

@implementation ServerConfigModel
-(id)initWithDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {

        self.name = dict[@"name"];
        self.server_id = dict[@"id"];
        self.application_host = dict[@"application_host"];
        self.mongodb_host = dict[@"mongodb_host"];
        self.mongodb_database = dict[@"mongodb_database"];
        NSNumber *needsAuth = dict[@"mongodb_needs_auth"];
        if (needsAuth != nil) {
            self.mongodb_needs_auth = needsAuth.boolValue;
        } else {
            self.mongodb_needs_auth = NO;
        }
        self.mongodb_username = dict[@"mongodb_username"];
        self.mongodb_password = dict[@"mongodb_password"];
        self.s3_bucket = dict[@"s3_bucket"];
        self.s3_access_key = dict[@"s3_access_key"];
        self.s3_secret_key = dict[@"s3_secret_key"];
        self.google_client_id = dict[@"google_client_id"];
        self.google_client_secret = dict[@"google_client_secret"];

        // Lin - Added to use static google client

        if (UseStaticGoogleClient)
        {
//            [self useStaticGoogleInfo];
        }

        self.google_redirectURI = @"http://localhost";

        // Lin - Ended

        if (dict[@"mongodb_host_index"]) {
            NSInteger index = [dict[@"mongodb_host_index"] integerValue];
            NSArray *serArr = dict[@"mongodb_host1"];
            if(!serArr)
                serArr=[dict[@"mongodb_host"] componentsSeparatedByString:@","];
            if (index < [serArr count]) {
                self.mongodb_host = serArr[index];
            } else {
                self.mongodb_host = serArr[0];
                NSMutableDictionary *tDic = [dict mutableCopy];
                tDic[@"mongodb_host_index"] = @(0);
                dict = [tDic copy];
            }
        } else {
            NSLog(@"check");
        }
        if (dict[@"application_host_index"]) {
            NSInteger index = [dict[@"application_host_index"] integerValue];
            NSArray *serArr = dict[@"application_host1"];
            if (index< [serArr count]) {
                self.application_host = serArr[index];
                //                self.application_host = @"desktop1.knotable.com";// serArr[index];
            } else {
                self.application_host = serArr[0];
                NSMutableDictionary *tDic = [dict mutableCopy];
                tDic[@"application_host_index"] = @(0);
                dict = [tDic copy];
            }
        } else {
            NSLog(@"check");
        }
        if (!self.mongodb_host) {
            self.mongodb_host = dict[@"mongodb_host"];
        }
        if (!self.application_host) {
            self.application_host = dict[@"application_host"];
        }

        self.dic = dict;
    }
    
    return self;
}

-(NSString *)meteorWebsocketURL
{
    return [NSString stringWithFormat:METEOR_DDP_URL_FORMAT, self.application_host];
}
@end
