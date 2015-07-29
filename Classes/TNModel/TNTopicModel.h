//
//  TNTopicModel.h
//  Cheddar for iOS
//
//  Created by Mac on 7/28/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TNTopicModel : NSObject
@property (nonatomic, strong) NSString* topic_id;
@property (nonatomic, strong) NSString* topic_accountId;
@property (nonatomic, strong) NSString* topic_cname;
@property (nonatomic, strong) NSString* topic_flagged;
@property (nonatomic, strong) NSString* topic_isSub;
@property (nonatomic, strong) NSString* topic_new;
@property (nonatomic, strong) NSDictionary* topic_order;
@property (nonatomic, strong) NSString* topic_parentId;
@property (nonatomic, strong) NSDictionary* topic_participator_account_ids;
@property (nonatomic, strong) NSString* topic_status;
@property (nonatomic, strong) NSString* topic_subject;
@property (nonatomic, strong) NSString* topic_topic_type;
@property (nonatomic, strong) NSString* topic_type;
@property (nonatomic, strong) NSString* topic_uniqueNumber;
@property (nonatomic, strong) NSDictionary* topic_viewers;
- (id)initTopicWithDict:(NSDictionary*)model;
@end
