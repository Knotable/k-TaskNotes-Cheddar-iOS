//
//  TNTopicModel.m
//  Cheddar for iOS
//
//  Created by Mac on 7/28/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import "TNTopicModel.h"

@implementation TNTopicModel
@synthesize topic_accountId,topic_cname,topic_flagged,topic_id,topic_isSub,topic_new,topic_order,topic_parentId,topic_participator_account_ids,topic_status,topic_subject,topic_topic_type,topic_type,topic_uniqueNumber,topic_viewers;
-(id)initTopicWithDict:(NSDictionary *)model{
    self = [super init];
    if (self) {
        @try {
             self.topic_accountId = @"";
            self.topic_cname = @"";
            self.topic_flagged = @"";
            self.topic_id = @"";
            self.topic_isSub = @"";
            self.topic_new = @"";
            self.topic_order = [[NSDictionary alloc]init];
            self.topic_parentId = @"";
            self.topic_participator_account_ids = [[NSDictionary alloc]init];
            self.topic_status = @"";
            self.topic_subject = @"";
            self.topic_topic_type  = @"";
            self.topic_type = @"";
            self.topic_uniqueNumber =@"";
            self.topic_viewers = [[NSDictionary alloc]init];

            if ([model objectForKeyedSubscript:@"account_id"]) {
                self.topic_accountId = [model objectForKeyedSubscript:@"account_id"];
            }

            if ([model objectForKeyedSubscript:@"_id"]) {
                self.topic_id = [model objectForKeyedSubscript:@"_id"];
            }

            if ([model objectForKeyedSubscript:@"cname"]) {
                self.topic_cname = [model objectForKeyedSubscript:@"cname"];
            }

            if ([model objectForKeyedSubscript:@"flagged"]) {
                self.topic_flagged = [model objectForKeyedSubscript:@"flagged"];
            }

            if ([model objectForKeyedSubscript:@"is_sub"]) {
                self.topic_isSub = [model objectForKeyedSubscript:@"is_sub"];
            }

            if ([model objectForKeyedSubscript:@"new"]) {
                self.topic_new = [model objectForKeyedSubscript:@"new"];
            }

            if ([[model objectForKeyedSubscript:@"order"] isKindOfClass:[NSDictionary class]]) {
                self.topic_order = [model objectForKeyedSubscript:@"order"];
            }

            if ([model objectForKeyedSubscript:@"parent_id"]) {
                self.topic_parentId = [model objectForKeyedSubscript:@"parent_id"];
            }

            if ([[model objectForKeyedSubscript:@"participator_account_ids"] isKindOfClass:[NSDictionary class]]) {
                self.topic_participator_account_ids = [model objectForKeyedSubscript:@"participator_account_ids"];
            }

            if ([model objectForKeyedSubscript:@"status"]) {
                self.topic_status = [model objectForKeyedSubscript:@"status"];
            }

            if ([model objectForKeyedSubscript:@"subject"]) {
                self.topic_subject = [model objectForKeyedSubscript:@"subject"];
            }

            if ([model objectForKeyedSubscript:@"topic_type"]) {
                self.topic_topic_type = [model objectForKeyedSubscript:@"topic_type"];
            }

            if ([model objectForKeyedSubscript:@"type"]) {
                self.topic_type = [model objectForKeyedSubscript:@"type"];
            }

            if ([model objectForKeyedSubscript:@"uniqueNumber"]) {
                self.topic_uniqueNumber = [model objectForKeyedSubscript:@"uniqueNumber"];
            }

            if ([[model objectForKeyedSubscript:@"viewers"] isKindOfClass:[NSDictionary class]]) {
                self.topic_viewers = [model objectForKeyedSubscript:@"viewers"];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@",[exception description]);
            NSLog(@"%@",[exception callStackSymbols]);
        }
    }
    return self;
}
@end
