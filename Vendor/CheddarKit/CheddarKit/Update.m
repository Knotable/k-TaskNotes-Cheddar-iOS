//
//  Update.m
//  
//
//  Created by M Abdul Sami on 9/30/15.
//
//

#import "Update.h"


@implementation Update

@dynamic type;
@dynamic updated_entity;
@dynamic updated_ID;



+(NSString*)getEntityName{
    return @"Update";
}

+(NSArray*) getAllUpdates{
    NSManagedObjectContext *moc = [self mainContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:[self getEntityName] inManagedObjectContext:moc]];
    
    NSError *error = nil;
    
    NSArray *results = [moc executeFetchRequest:request error:&error];
    
    if(error){
        NSLog(@"Fetch Updates Error");
    }
    
    return results;
}
@end
