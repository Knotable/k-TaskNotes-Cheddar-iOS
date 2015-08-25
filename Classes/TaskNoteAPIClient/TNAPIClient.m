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

//Create Note
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




- (void) sendInsertTaskList:(TNTaskList *)list
              withUserId:(NSString *)userId
              withUseData:(id)userData
        withCompleteBlock:(MongoCompletion)block
{
    /********************************************************
     
     Working State : Working
     
     ********************************************************/
    
    /*
     id, message_subject, name, from, to, date, options, title,
     isMailgun, headers,topic_type,topic_id, checklistId, order,
     task_type, section_id = null
     */
    
    NSMutableArray* paramArray = [[NSMutableArray alloc] initWithCapacity:15];
    
    [paramArray addObject:userId];
    [paramArray addObject:list.subject];
    [paramArray addObject:list.name];
    [paramArray addObject:list.from];
    [paramArray addObject:@""];
    [paramArray addObject:list.date];
    [paramArray addObject:list.options];
    [paramArray addObject:list.title];
    
    [paramArray addObject:@NO];
    [paramArray addObject:@[]];
    [paramArray addObject:@(0)];
    [paramArray addObject:list.topicId];
    [paramArray addObject:@""];
    [paramArray addObject:list.order];
    
    [paramArray addObject:list.taskType];
    [paramArray addObject:list.sectionId];
    
    [self.meteor callMethodName:@"add_checklist"
                parameters:paramArray
          responseCallback:^(NSDictionary *response, NSError *error)
     {
         if (error)
         {
             NSLog(@"add_checklist error: %@", error);
             
             block(NetworkFailure, error, response);
         }
         else
         {
             NSLog(@"add_checklist response type: %@ : %@", [response class], response);
             
             NSString *knote_id = response[@"result"];
             
             if (knote_id)
             {
//                 item.itemId = knote_id;
//                 item.isUpdating = NO;
//                 item.isSending = NO;
//                 item.needSend = NO;
//                 item.uploadRetryCount = 3;
//                 
//                 item.userData.message_id = knote_id;
//                 item.userData.need_send = NO;
//                 
//                 [item.cell stopProcess];
//                 
                 NSDictionary *parameters = Nil;
                 
//                 if (item.topic && item.topic.topic_id && item.itemId)
//                 {
//                     parameters = @{@"topicId": item.topic.topic_id,
//                                    @"knoteId": item.itemId};
//                 }
//                 else if (item.itemId)
//                 {
//                     parameters = @{@"topicId": @"NULL",
//                                    @"knoteId": item.itemId};
//                 } else {
//                     parameters = @{@"topicId": @"NULL",
//                                    @"knoteId":  @"NULL"};
//                 }
//                 
//                 [[AnalyticsManager sharedInstance] notifyListNoteWasAddedWithParameters:parameters];
//                 
//                 [self.processArray removeObject:item];
//                 
//                 if(item.topic)
//                 {
//                     [item.topic createdNewActivity];
//                 }
//                 
//                 if (postDic[@"topic_id"])
//                 {
//                     [self triggerEmailNotifications:postDic[@"topic_id"]];
//                 }
//                 /****Dhruv : Causes crash, Dont see it useful.*********/
//                 
//                 /*[[NSNotificationCenter defaultCenter] postNotificationName:@"new_knote_posted"
//                  object:item
//                  userInfo:nil];*/
                 
                 block(NetworkSucc, error, response);
             }
             else
             {
                 NSLog(@"add_checklist problem no knote id returned");
                 
                 block(NetworkFailure, error, response);
             }
         }
     }];
}


- (void) sendRequestUpdateTaskList:(NSString *)_id
               withOptionArray:(NSArray *)array
             withCompleteBlock:(MongoCompletion)block
{
    /********************************************************
     
     Function :
     
     Algorighm : Working
     
     ********************************************************/
    
    if (_id == Nil || _id.length == 0 )
    {
        return;
    }
    
    if (array == Nil || [array count] == 0)
    {
        return;
    }
    
    __block WM_NetworkStatus ret = NetworkFailure;
    
    if (_id)
    {
        NSString*   buildMethodNameStr = Nil;
        
        buildMethodNameStr = [NSString stringWithFormat:@"/%@/%@", METEORCOLLECTION_KNOTES, @"update"];
        
        NSArray *parameters = @[@{@"_id"    : _id},
                                @{@"$set"   :@{@"options" : array}}];
        
        [self.meteor callMethodName:buildMethodNameStr
                         parameters:parameters
                   responseCallback:^(NSDictionary *response, NSError *error) {
                       
                       NSLog(@"Success : %@", response);
                       
                       if (error)
                       {
                           NSLog(@"Func : %@ : Error : %@", buildMethodNameStr, error.description);
                           
                           ret = NetworkFailure;
                       }
                       else
                       {
                           ret = NetworkSucc;
                       }
                       
                       
                       dispatch_async(dispatch_get_main_queue(), ^{
                           
                           block(ret, nil, nil);
                           
                       });
                       
                   }];
    }
}



- (NSString*)mongo_id_generator
{
    /********************************************************
     
     Working State : Working
     
     ********************************************************/
    
    int i = 0;
    
    char result[20] = {0};
    
    const char *str = "23456789ABCDEFGHJKLMNPQRSTWXYZabcdefghijkmnopqrstuvwxyz";
    
    for (i=0; i< 17; i++)
    {
        uint32_t bytes[4]={0x00};
        
        if (0 != SecRandomCopyBytes(0, 10, (uint8_t*)bytes))
        {
            return nil;
        }
        
        double_t index = bytes[0] * 2.3283064365386963e-10 * strlen(str);
        
        result[i] = str[ (int)floor(index) ];
    }
    
    NSString *retID = [[NSString alloc] initWithBytes:result length:strlen(result) encoding:NSASCIIStringEncoding];
    
    NSLog(@"Mongo_id_generator: %@ ", retID);
    
    return retID;
}


@end
