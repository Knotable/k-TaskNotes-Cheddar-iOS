//
//  TNTopicModel.h
//  Cheddar for iOS
//
//  Created by Mac on 8/3/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TNTopicModel : NSManagedObject

@property (nonatomic, retain) NSString * topic_id;
@property (nonatomic, retain) NSString * topic_accountId;
@property (nonatomic, retain) NSString * topic_cname;
@property (nonatomic, retain) NSNumber * topic_flagged;
@property (nonatomic, retain) NSString * topic_status;
@property (nonatomic, retain) NSString * topic_subject;
@property (nonatomic, retain) NSString * topic_type;
@property (nonatomic, retain) NSNumber * topic_uniqueNumber;
@property (nonatomic, retain) NSDate * topic_date;

@end
