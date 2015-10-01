//
//  Update.h
//  
//
//  Created by M Abdul Sami on 9/30/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SSDataKit.h"

@interface Update : SSManagedObject

@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * updated_entity;
@property (nonatomic, retain) NSString * updated_ID;

+(NSArray*) getAllUpdates;

@end
