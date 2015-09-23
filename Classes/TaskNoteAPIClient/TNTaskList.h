//
//  TNTaskList.h
//  Cheddar for iOS
//
//  Created by M Abdul Sami on 8/23/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TNTaskList : NSObject
/*
 id, message_subject, name, from, to, date, options, title,
 isMailgun, headers,topic_type,topic_id, checklistId, order,
 task_type, section_id = null
 */
@property (nonatomic,strong) NSString* listId;
@property (nonatomic,strong) NSString* subject;
@property (nonatomic,strong) NSString* name;
@property (nonatomic,strong) NSString* from;
@property (nonatomic,strong) NSString* to;
@property (nonatomic,strong) NSString* date;
@property (nonatomic,strong) NSArray* options;
@property (nonatomic,strong) NSString* title;
@property (nonatomic,strong) NSString* topicId;
@property (nonatomic,strong) NSString* order;
@property (nonatomic,strong) NSString* taskType;
@property (nonatomic,strong) NSString* sectionId;


@end
