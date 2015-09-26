//
//  Updates.h
//  CheddarKit
//
//  Created by M Abdul Sami on 9/25/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SSManagedObject.h"

//Update Entity Coredata

#define kCDKUpdatesEntity  @"Update"
#define kCDKUpdatedItemEntity  @"updated_entity"
#define kCDKUpdatedItemID  @"updated_ID"


@interface Update : SSManagedObject

@property (nonatomic, retain) NSNumber * updated_entity;
@property (nonatomic, retain) NSString * updated_ID;

+(NSArray*) getAllUpdates;
@end
