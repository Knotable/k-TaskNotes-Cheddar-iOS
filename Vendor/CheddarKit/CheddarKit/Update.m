//
//  Updates.m
//  CheddarKit
//
//  Created by M Abdul Sami on 9/25/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import "Update.h"


@implementation Update

@dynamic updated_entity;
@dynamic updated_ID;

+(NSArray*) getAllUpdates{
    NSManagedObjectContext *moc = [self mainContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kCDKUpdatesEntity inManagedObjectContext:moc]];
    
    NSError *error = nil;
    
    NSArray *results = [moc executeFetchRequest:request error:&error];
    
    if(error){
        NSLog(@"Fetch Updates Error");
    }

    return results;
}
@end
