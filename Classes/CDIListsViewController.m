//
//  CDIListsViewController.m
//  Cheddar for iOS
//
//  Created by Sam Soffes on 3/30/12.
//  Copyright (c) 2012 Nothing Magical. All rights reserved.
//

#import "CDIListsViewController.h"
#import "CDIListTableViewCell.h"
#import "CDITasksViewController.h"
#import "CDICreateListViewController.h"
#import "CDISettingsViewController.h"
#import "CDISplitViewController.h"
#import "UIColor+CheddariOSAdditions.h"
#import "CDIUpgradeViewController.h"
#import "CDIListsPlaceholderView.h"
#import "CDIAddListTableViewCell.h"
#import "CDIHUDView.h"
#import "CDIViewArchiveButton.h"
#import "Update.h"

#import <SSToolkit/UIScrollView+SSToolkitAdditions.h>
#import "SMTEDelegateController.h"
//#import "MagicalRecord.h"
#ifdef CHEDDAR_USE_PASSWORD_FLOW
	#import "CDISignInViewController.h"
#else
	#import "CDIWebSignInViewController.h"
#endif

NSString *const kCDISelectedListKey = @"CDISelectedListKey";

@interface CDIListsViewController ()
{
    NSString *modelId;
    NSInteger numberTopic;
    NSString* savingKnoteId;
    BOOL isUpdateFirst;
    BOOL isListeningToUpdates;
    BOOL isUpdateNeeded;
    dispatch_queue_t myCustomQueue;
    NSMutableArray* savedLists;
}
@property (nonatomic, strong) CDKList *selectedList;
@property (nonatomic, assign) BOOL adding;
@property (nonatomic, assign) BOOL checkForOneList;
@property (nonatomic, strong) SMTEDelegateController *textExpander;
@property (nonatomic, strong) CDIViewArchiveButton *archiveButton;
@property (nonatomic, strong) NSMutableArray *dataList;

@property (nonatomic, strong) TNTopicModel *topicModel;
@property (nonatomic, strong) NSMutableArray *models;
- (void)_listUpdated:(NSNotification *)notification;
- (void)_currentUserDidChange:(NSNotification *)notification;
- (void)_createList:(id)sender;
- (void)_cancelAddingList:(id)sender;
- (void)_selectListAtIndexPath:(NSIndexPath *)indexPath newList:(BOOL)newList;
- (void)_checkUser;
- (void)_beginEditingWithGesture:(UIGestureRecognizer *)gestureRecognizer;
- (BOOL)_shouldEditRowForGesture:(UIGestureRecognizer *)gestureRecognizer;
@end

@implementation CDIListsViewController

#pragma mark - NSObject

- (void)dealloc {
	if (self.textExpander) {
		[[NSNotificationCenter defaultCenter] removeObserver:self.textExpander];
	}
}


#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    savedLists = [[NSMutableArray alloc]init];
    isListeningToUpdates = false;
    isUpdateFirst = NO;
    _meteor = [CDIAppDelegate sharedAppDelegate].meteorClient;
    
	UIImageView *title = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-title"]];
    title.accessibilityLabel = @"Tasknotes";
	title.frame = CGRectMake(0.0f, 0.0f, 116.0f, 21.0f);
    self.title = @"Tasknotes";
    self.navigationController.navigationBarHidden=false; 
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Lists " style:UIBarButtonItemStyleBordered target:nil action:nil];
    
    [backButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    
    self.navigationItem.backBarButtonItem = backButton;
    
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"+"] style:UIBarButtonItemStyleBordered target:self action:@selector(createList:)];

	[self setEditing:NO animated:NO];

	self.noContentView = [[CDIListsPlaceholderView alloc] initWithFrame:CGRectZero];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_listUpdated:) name:kCDKListDidUpdateNotificationName object:nil];
	}
	
	_checkForOneList = YES;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_currentUserDidChange:) name:kCDKCurrentUserChangedNotificationName object:nil];
	
	if ([SMTEDelegateController isTextExpanderTouchInstalled]) {
		self.textExpander = [[SMTEDelegateController alloc] init];
		self.textExpander.nextDelegate = self;
		[[NSNotificationCenter defaultCenter] addObserver:self.textExpander selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
	}

	UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 50.0f)];
	footer.autoresizingMask = UIViewAutoresizingFlexibleWidth;

	UIView *shadow = self.tableView.tableFooterView;
	self.tableView.tableFooterView = footer;
	shadow.frame = CGRectMake(0.0f, 0.0f, 320.0f, 3.0f);
	[footer addSubview:shadow];

	_archiveButton = [[CDIViewArchiveButton alloc] initWithFrame:CGRectMake(20.0f, 12.0f, 280.0f, 32.0)];
	_archiveButton.alpha = 0.0f;
	[footer addSubview:_archiveButton];
    //[self removePreviousSavedLists];

    
//    if([CDKUser currentUser])
    isUpdateNeeded = [[Update getAllUpdates] count]>0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(meteorConnectedNotification:) name:MeteorClientConnectionReadyNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doUpdateNotification:)
                                                 name:kDoUpdateNotification
                                               object:nil];
        [self turnOnBackground];
}

-(void)removePreviousSavedLists{
    
    self.fetchedResultsController.fetchRequest.predicate = self.predicate;
    [self.fetchedResultsController performFetch:nil];
    NSArray* lists = [self.fetchedResultsController fetchedObjects];
    for(int t=0; t<lists.count; t++){
        CDKList* list = lists[t];
        [[self managedObjectContext] deleteObject:list];
    }
    [self.managedObjectContext performBlockAndWait:^{
        [[self managedObjectContext] save:nil];
    }];
    
}


- (void)viewWillAppear:(BOOL)animated {
   
    self.topicModel = nil;
	[super viewWillAppear:animated];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[self _checkUser];
	}
//    [self registerNotification];
    myCustomQueue = dispatch_queue_create("com.kNotables.taskNotes", DISPATCH_QUEUE_SERIAL);


}

- (void)registerNotification{
/*


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveAdd:)
                                                 name:@"added"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(topicsUpdated:)
                                                 name:@"topics_added"
                                               object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveUpdate:)
                                                 name:@"updated"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveRemove:)
                                                 name:@"removed"
                                               object:nil];
 */

}

- (void)turnOnBackground{
    
//    if(isListeningToUpdates)return;
//    isListeningToUpdates=true;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(gotTopicCount:)
                                                 name:@"TopicsCount_added"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(gotArchivedTopicCount:)
                                                 name:@"ArchivedTopicsCount_added"
                                               object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(topicsUpdated:)
                                                 name:@"topics_added"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(topicsChanged:)
                                                 name:@"topics_changed"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(topicsRemoved:)
                                                 name:@"topics_removed"
                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(topicsUpdated:)
//                                                 name:@"archivedKnotesForTopic_added"
//                                               object:nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(topicsUpdated:)
//                                                 name:@"archivedKnotesForTopic_changed"
//                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(topicsRemoved:)
                                                 name:@"archivedKnotesForTopic_removed"
                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(topicsUpdated:)
//                                                 name:@"pinnedKnotesForTopic_added"
//                                               object:nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(topicsUpdated:)
//                                                 name:@"pinnedKnotesForTopic_changed"
//                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(topicsRemoved:)
                                                 name:@"pinnedKnotesForTopic_removed"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactsCountAdded:)
                                                 name:@"OtherContactsCount_added"
                                               object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactsAdded:)
                                                 name:@"contacts_added"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactsChanged:)
                                                 name:@"contacts_changed"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactsRemoved:)
                                                 name:@"contacts_removed"
                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(knotesAdded:)
//                                                 name:@"topic_added"
//                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(knotesAdded:)
//                                                 name:@"date_events_added"
//                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(topicsChanged:)
//                                                 name:@"topic_changed"
//                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(knotesAdded:)
//                                                 name:@"allRestKnotesByTopicId_added"
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(knotesChanged:)
//                                                 name:@"allRestKnotesByTopicId_changed"
//                                               object:nil];
    
//    [NSNotificationCenter defaultCenter] addObserver:self
//                                                     selector:@selector(knotesRemoved:)
//                                                         name:@"allRestKnotesByTopicId_removed"
//                                                       object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(knotesAdded:)
                                                 name:@"knotes_added"
                                               object:nil];

//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(knotesAdded:)
//                                                 name:@"messages_added"
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(knotesAdded:)
//                                                 name:@"messages_changed"
//                                               object:nil];
    
    //        [[NSNotificationCenter defaultCenter] addObserver:self
    //                                                 selector:@selector(knotesRemoved:)
    //                                                     name:@"knotes_removed"
    //                                                   object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(knotesChanged:)
                                                 name:@"knotes_changed"
                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(Ready_topic)
//                                                 name:@"topic_ready"
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(Ready_pinnedKnotes)
//                                                 name:@"pinnedKnotesForTopic_ready"
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(Ready_archivedKnotes)
//                                                 name:@"archivedKnotesForTopic_ready"
//                                               object:nil];
//    
//    
//
    [self.meteor addSubscription:METEORCOLLECTION_TOPICS];
    
}

- (void)topicsUpdated:(NSNotification *)note{
    NSLog(@"Topic Updated");
    NSDictionary *models = self.meteor.collections[METEORCOLLECTION_TOPICS];
    NSDictionary *topic = [models objectForKey:modelId];
    //Update from web
    if (topic){
        isUpdateFirst = NO;
        modelId = nil;
        [self __createList:topic];
    }else if (isUpdateFirst) {

                NSDictionary *model = [self.meteor.collections[METEORCOLLECTION_TOPICS] lastObject];
        
                if (![self doesModelAlreadyExist:model]) {
                    NSString* model_id = [model objectForKeyedSubscript:@"_id"];
                    [self.meteor addSubscription:METEORCOLLECTION_KNOTES withParameters:@[model_id]];
                    [self.meteor addSubscription:METEORCOLLECTION_KNOTE_TOPIC withParameters:@[model_id]];
                    [self.meteor addSubscription:METEORCOLLECTION_KNOTE_DATES withParameters:@[model_id]];
                    [self.meteor addSubscription:METEORCOLLECTION_KNOTE_PINNED withParameters:@[model_id]];
                    [self.meteor addSubscription:METEORCOLLECTION_KNOTE_REST withParameters:@[model_id]];
                    [self.meteor addSubscription:METEORCOLLECTION_KNOTE_ARCHIVED withParameters:@[model_id]];
                }
    }

    //Fetch first time
    NSInteger num = [self.meteor.collections[METEORCOLLECTION_TOPICS] count];

    NSLog(@"Updated %ld %ld",(long)numberTopic,(long)num );

    if (num == numberTopic) {
        isUpdateFirst = YES;
        numberTopic = 0;
        NSDictionary *models = self.meteor.collections[METEORCOLLECTION_TOPICS];
        dispatch_async( myCustomQueue, ^{
            
        BOOL todoExists = false;
        for(int t=0 ; t< [_meteor.collections[METEORCOLLECTION_TOPICS] count];t++){
            if([[_meteor.collections[METEORCOLLECTION_TOPICS][t] objectForKey:@"subject"] isEqualToString:kDefaultPadName]){
                todoExists = true;
                break;
            }
        }
        
        if(!todoExists){
//            CDIHUDView *hud = [[CDIHUDView alloc] initWithTitle:@"Creating To Do List..." loading:YES];
  //          [hud show];
            
            [[TNAPIClient sharedClient] sendInsertPadWithName:kDefaultPadName withUserId:[CDKUser currentUser].remoteID withBlock:^(NSDictionary *response, NSError *error){
                if (error) {
    //                [hud completeAndDismissWithTitle:[error.userInfo objectForKeyedSubscript:@"NSLocalizedDescription"]];
                }
                if (response) {
                    NSLog(@"response = %@",response);
      //              [hud completeAndDismissWithTitle:@"Done !"];
                 /*
                  response = {
                  id = 15;
                  msg = result;
                  result = 6tumHt2jrgBxkrbW9;
                  }
                  */
                    [self.managedObjectContext performBlockAndWait:^(){
                       
                    CDKList * list = [[CDKList alloc] init];
                    //   [[CDKList mainContext] performBlock:^{
                    int64_t remote_id = [[NSDate date] timeIntervalSince1970];
                    list.id = [response objectForKey:@"result"];
                    list.title = @"";
                    list.position = [NSNumber numberWithInt:0];
                    list.slug = @"";
                    list.archivedAt = nil;
                    list.updatedAt = nil;
                    list.isArchived = NO;
                    list.user = [CDKUser currentUser];
                    list.createdAt  = [NSDate date];
                    list.remoteID = [NSNumber numberWithInt:remote_id];
                    
                    [list save];
                    [savedLists addObject:list];
                    }];
                    NSLog(@"done posting");
                }
        
            }];
        }
        });
        
        
        NSLog(@"Got All Pads");
        
        for (NSString *objectId in models) {
            
            NSDictionary *model = [models objectForKey:objectId];
            
            NSString* model_id = [model objectForKeyedSubscript:@"_id"];
            
            if ([[model objectForKey:@"subject"] isEqualToString:kDefaultPadName] && ![self doesModelAlreadyExist:model]) {
                
                NSDictionary* taskFromIOS = [model copy];
                NSLog(@"current pad = %@",model);
                NSString* knoteAddedId =[taskFromIOS objectForKey:@"_id"];
                BOOL alreadyAdded = false;
                for(CDKList* savedList in savedLists){
                    if([knoteAddedId isEqualToString: savedList.id] ){
                        alreadyAdded=true;
                        _checkForOneList = NO;
                    }
                }
                if(!alreadyAdded)
                dispatch_async( myCustomQueue, ^{
                    CDKList *list = [[CDKList alloc] init];
                    int64_t remote_id = [[NSDate date] timeIntervalSince1970];
                    list.id = [taskFromIOS objectForKey:@"_id"];
                    list.title = [taskFromIOS objectForKey:@"subject"];
                    list.position = [[taskFromIOS objectForKey:@"order"] objectForKey:@"undefined"];

                    list.slug = @"";
                    list.archivedAt = nil;
                    list.updatedAt = nil;
                    list.isArchived = NO;
                    list.user = [CDKUser currentUser];
                    list.createdAt  = [NSDate date];
                    list.remoteID = [NSNumber numberWithInt:remote_id];
                    [list save];
                    [savedLists addObject:list];

            });
            }

            [self.meteor addSubscription:METEORCOLLECTION_KNOTES withParameters:@[model_id]];
            [self.meteor addSubscription:METEORCOLLECTION_KNOTE_TOPIC withParameters:@[model_id]];
            [self.meteor addSubscription:METEORCOLLECTION_KNOTE_DATES withParameters:@[model_id]];
            [self.meteor addSubscription:METEORCOLLECTION_KNOTE_PINNED withParameters:@[model_id]];
            [self.meteor addSubscription:METEORCOLLECTION_KNOTE_REST withParameters:@[model_id]];
            [self.meteor addSubscription:METEORCOLLECTION_KNOTE_ARCHIVED withParameters:@[model_id]];
        }

        // Update topic when offline.
        //[self updateOffline];

    }
}

/////////////////////////////////////////////////////////////////////
////////////////// KNOTES CALL BACKS/////////////////////////////////
/////////////////////////////////////////////////////////////////////


- (void)Ready_topic
{
}

- (void)Ready_pinnedKnotes
{

}

- (void)Ready_archivedKnotes
{

}

-(void)knotesAdded:(NSNotification *)note
{
    NSLog(@"Knote Added = %@",note.userInfo);
    NSLog(@"done added");
/*
{
 "_id" = dq3qfpSDB3WYc9GgZ;
 "account_id" = qs8PoCMD8kQebKt9p;
 archived = 0;
 "archived_by" =     {
    "account_id" = qs8PoCMD8kQebKt9p;
    date =         {
        "$date" = 1441216663862;
    };
 };
 cname = knotes;
 containerName = attachment;
 "created_time" =     {
    "$date" = 1440713662173;
 };
 date =     {
    "$date" = 1440975809000;
 };
 from = "sami_bahtti@hotmail.com";
 isMailgun = 0;
 "liked_contact_ids" =     (
 );
 "likes_count" = 0;
 "message_subject" = subject;
 name = "sami_bahtti_hotmail_com";
 options =     (
    {
        checked = 0;
        name = qwerty;
        num = 1;
        voters =             (
        );
    },
    {
        checked = 0;
        name = "";
        num = 2;
        voters =             (
        );
    },
    {
        checked = 0;
        name = pol;
        num = 3;
        voters =             (
        );
    }
 );
 order = "-1";
 status = ready;
 task = checklist;
 timestamp = 1440957809000;
 title = TaskNotes;
 "topic_id" = Hyt8bbtZWKgjp6Lwk;
 "topic_type" = 0;
 type = checklist;
 "updated_action" = "MARK_DONE";
 "updated_date" = 1441216663862;
 "viewed_by" =     (
    qs8PoCMD8kQebKt9p
 );
 }
 */
    
    
    NSDictionary * knoteAdded = note.userInfo;
    if(knoteAdded ){
        NSString* knoteType = [knoteAdded objectForKey:@"type"];
        if([knoteType isEqualToString:@"checklist"]){
            
            
            
            NSDictionary *models = self.meteor.collections[METEORCOLLECTION_TOPICS];
            dispatch_async( myCustomQueue, ^{
                
                if([[knoteAdded objectForKey:@"archived"] intValue]!=0){
                    return ;
                }
            for (NSString *objectId in models) {
            
                NSDictionary *model = [models objectForKey:objectId];
               
                CDKList *list = nil;
                if ([[model objectForKey:@"_id"] isEqualToString:[knoteAdded objectForKey:@"topic_id"]] && ![self doesModelAlreadyExist:model]) {
                    NSString* knoteAddedId =[knoteAdded objectForKey:@"topic_id"];
                    for(CDKList* savedList in savedLists){
                        if([knoteAddedId isEqualToString: savedList.id] ){
                            return;
                        }
                    }
                        NSLog(@"current pad = %@",model);
                    list = [[CDKList alloc] init];
                 //   [[CDKList mainContext] performBlock:^{
                        int64_t remote_id = [[NSDate date] timeIntervalSince1970];
                        list.id = [model objectForKey:@"_id"];
                        list.title = [model objectForKey:@"subject"];
                        list.position = [model objectForKey:@"uniqueNumber"];
                        list.slug = @"";
                        list.archivedAt = nil;
                        list.updatedAt = nil;
                        list.isArchived = NO;
                        list.user = [CDKUser currentUser];
                        list.createdAt  = [NSDate date];
                        list.remoteID = [NSNumber numberWithInt:remote_id];
                    
                        [list save];
                        [savedLists addObject:list];
                    
                   // }];
                    
                }
                
                NSArray* options = [knoteAdded objectForKey:@"options"];
                options = [options sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
                    NSNumber* positionA = [a objectForKey:@"num"]==[NSNull null]? [NSNumber numberWithInt:0]:[a objectForKey:@"num"];
                    NSNumber* positionB = [b objectForKey:@"num"]==[NSNull null]? [NSNumber numberWithInt:0]:[b objectForKey:@"num"];
                    if(positionA.integerValue < positionB.integerValue)
                        return NSOrderedAscending;
                    else if(positionA.integerValue > positionB.integerValue)
                        return NSOrderedDescending;
                    
                    return NSOrderedSame;
                }];
                
                if([[knoteAdded objectForKey:@"title"] isEqualToString:@"TaskNotes"] && [[model objectForKey:@"_id"] isEqualToString:[knoteAdded objectForKey:@"topic_id"]]&& [options count]>0 )
                {
                    // && ([self doesModelAlreadyExist:model]|| list)

                    if(!list){
                        list = [self findObject:[knoteAdded objectForKey:@"topic_id"]];
                    }
                    if(!list){
                        NSString* knoteAddedId =[knoteAdded objectForKey:@"topic_id"];
                        for(CDKList* savedList in savedLists){
                            if([knoteAddedId isEqualToString: savedList.id] ){
                                list = savedList;
                                break;
                            }
                        }
                        
                    }
                    
                    if(!list){
                        [[self managedObjectContext] save:nil];
                        return;
                    }

                    NSManagedObjectContext *moc = [self managedObjectContext];
                    
                    NSFetchRequest *request = [[NSFetchRequest alloc] init];
                    NSString* kNoteId=[knoteAdded objectForKey:@"_id"];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"list = %@ AND archivedAt = nil", list];
                    [request setEntity:[NSEntityDescription entityForName:[CDKTask entityName] inManagedObjectContext:moc]];
                    [request setPredicate:predicate];
                    [request setSortDescriptors:[CDKTask defaultSortDescriptors]];
                    
                    NSError *error = nil;
                    NSArray *results = [moc executeFetchRequest:request error:&error];
                    
                    
                    
                    if(results.count > 0){
                        CDKTask* task = results[0];
                        int64_t remote_id = [[NSDate date] timeIntervalSince1970];
                        task.id = kNoteId;
                        task.remoteID = [NSNumber numberWithInt:remote_id];
                        NSString* title =[knoteAdded objectForKey:@"title"];
                        title= [title isEqualToString:@""]?@" _ ":title;
                        //if([title isEqualToString:@""])title = @" _ ";
                        task.displayText = title;
                        task.text =title;
                        task.position = [NSNumber numberWithInt:0];
                        task.list = list;
                        [task setCheckList: [options copy]];

                        
                        //[[self managedObjectContext] performBlock:^{
                        
                        [task save];
                        //}];
                            
                    }else{
                        CDKTask* task = [[CDKTask alloc] init];
                        int64_t remote_id = [[NSDate date] timeIntervalSince1970];
                        task.id = kNoteId;
                        task.remoteID = [NSNumber numberWithInt:remote_id];
                        NSString* title =[knoteAdded objectForKey:@"title"];
                        title= [title isEqualToString:@""]?@" _ ":title;
                        //if([title isEqualToString:@""])title = @" _ ";
                        task.displayText = title;
                        task.text =title;
                        task.position = [NSNumber numberWithInt:0];
                        task.list = list;
                        [task setCheckList: [options copy]];

                        
                        //[[self managedObjectContext] performBlock:^{
                            
                        [task save];
                    
                        //}];
                    }
                    if([list.title isEqualToString:kDefaultPadName]){
//                        NSNumber *selectedList = [[NSUserDefaults standardUserDefaults] objectForKey:kCDISelectedListKey];
//                        //if (!selectedList) {
//                            
//                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//                        [userDefaults setObject:list.remoteID forKey:kCDISelectedListKey];
//                        [userDefaults synchronize];
//                        //}
                        _checkForOneList=YES;
                        
                    }
                    if(_selectedList)
                        if([list.id isEqualToString:_selectedList.id]){
                            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:options forKey:@"options"];
                            NSLog(@"options are : %@",options);
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:kTaskChangedNotification
                             object:self userInfo: userInfo];
                        }

                
                }
            }
            
            });
            

            
        }
    }
}

-(void)knotesRemoved:(NSNotification *)note
{
    NSLog(@"KNOTES REMOVED");
//    
//    NSDictionary* serverData = Nil;
//    
//    if (note.userInfo)
//    {
//        serverData = note.userInfo;
//    }
    
}

-(void)knotesChanged:(NSNotification *)note
{
    NSLog(@"KNOTES CHANGED");
    NSLog(@"Knote Edited = %@",note.userInfo);
    NSLog(@"done Edit");
    /*
     {
     "_id" = dq3qfpSDB3WYc9GgZ;
     "account_id" = qs8PoCMD8kQebKt9p;
     archived = 0;
     "archived_by" =     {
     "account_id" = qs8PoCMD8kQebKt9p;
     date =         {
     "$date" = 1441216663862;
     };
     };
     cname = knotes;
     containerName = attachment;
     "created_time" =     {
     "$date" = 1440713662173;
     };
     date =     {
     "$date" = 1440975809000;
     };
     from = "sami_bahtti@hotmail.com";
     isMailgun = 0;
     "liked_contact_ids" =     (
     );
     "likes_count" = 0;
     "message_subject" = subject;
     name = "sami_bahtti_hotmail_com";
     options =     (
     {
     checked = 1;
     name = qwerty;
     num = 1;
     voters =             (
     wiJck4ZMNnriE34ga
     );
     },
     {
     checked = 1;
     name = "";
     num = 2;
     voters =             (
     wiJck4ZMNnriE34ga
     );
     },
     {
     checked = 1;
     name = pol;
     num = 3;
     voters =             (
     wiJck4ZMNnriE34ga
     );
     },
     {
     checked = 0;
     name = u;
     num = 4;
     voters =             (
     );
     },
     {
     checked = 0;
     name = t;
     num = 5;
     voters =             (
     );
     },
     {
     checked = 0;
     name = l;
     num = 6;
     voters =             (
     );
     },
     {
     checked = 0;
     name = zx;
     num = 7;
     voters =             (
     );
     },
     {
     checked = 0;
     name = koi;
     num = 8;
     voters =             (
     );
     },
     {
     checked = 0;
     name = qsc;
     num = 9;
     voters =             (
     );
     },
     {
     checked = 0;
     name = kiu;
     num = 10;
     voters =             (
     );
     },
     {
     checked = 0;
     name = zse;
     num = 11;
     voters =             (
     );
     },
     {
     checked = 0;
     name = tre;
     num = 12;
     voters =             (
     );
     }
     );
     order = "-1";
     status = sent;
     task = checklist;
     timestamp = 1440957809000;
     title = TaskNotes;
     "topic_id" = Hyt8bbtZWKgjp6Lwk;
     "topic_type" = 0;
     type = checklist;
     "updated_date" = 1441328765108;
     "viewed_by" =     (
     qs8PoCMD8kQebKt9p
     );
     }
     */
    
    
    NSDictionary * knoteAdded = note.userInfo;
//    if(savingKnoteId)
//    {
//        if([savingKnoteId isEqualToString:[knoteAdded objectForKey:@"_id"]])
//        {
//            return;
//        }
//    }
        if(knoteAdded ){
            NSString* knoteType = [knoteAdded objectForKey:@"type"];
            if(knoteType == nil)return;
            
            if([knoteType isEqualToString:@"checklist"]){
                dispatch_async( myCustomQueue, ^{
                    savingKnoteId=[knoteAdded objectForKey:@"_id"];
                NSDictionary *models = self.meteor.collections[METEORCOLLECTION_TOPICS];
                for (NSString *objectId in models) {
                    
                    NSDictionary *model = [models objectForKey:objectId];
                    CDKList *list =nil;
                    if ([[model objectForKey:@"_id"] isEqualToString:[knoteAdded objectForKey:@"topic_id"]] && ![self doesModelAlreadyExist:model]) {
                        int64_t remote_id = [[NSDate date] timeIntervalSince1970];
                        list = [[CDKList alloc] init];
                        list.id = [model objectForKey:@"_id"];
                        list.title = [model objectForKey:@"subject"];
                        list.position = [model objectForKey:@"uniqueNumber"];
                        list.slug = @"";
                        list.archivedAt = nil;
                        list.updatedAt = nil;
                        list.isArchived = NO;
                        list.user = [CDKUser currentUser];
                        list.createdAt  = [NSDate date];
                        list.remoteID = [NSNumber numberWithInt:remote_id];
                        __weak NSManagedObjectContext *context = [CDKList mainContext];
                        [context performBlockAndWait:^{
                            [list save];
                        }];
                    }
                    
                    
                    
                    NSArray* options = [[knoteAdded objectForKey:@"options"] mutableCopy];
                    options = [options sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
                        NSNumber* positionA = [a objectForKey:@"num"]==[NSNull null]? [NSNumber numberWithInt:0]:[a objectForKey:@"num"];
                        NSNumber* positionB = [b objectForKey:@"num"]==[NSNull null]? [NSNumber numberWithInt:0]:[b objectForKey:@"num"];
                        if(positionA.integerValue < positionB.integerValue)
                            return NSOrderedAscending;
                        else if(positionA.integerValue > positionB.integerValue)
                            return NSOrderedDescending;
                        
                        return NSOrderedSame;
                    }];
                    
                    
                    if([[knoteAdded objectForKey:@"title"] isEqualToString:@"TaskNotes"] && [[model objectForKey:@"_id"] isEqualToString:[knoteAdded objectForKey:@"topic_id"]]&& [options count]>0 && [self doesModelAlreadyExist:model] )
                    {
                        
                        if(!list){
                            list = [self findObject:[knoteAdded objectForKey:@"topic_id"]];
                        }
                        
                        NSManagedObjectContext *moc = [self managedObjectContext];
                        
                        NSFetchRequest *request = [[NSFetchRequest alloc] init];
                        NSString* kNoteId=[knoteAdded objectForKey:@"_id"];
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"list = %@  AND archivedAt = nil", list];
                        [request setEntity:[NSEntityDescription entityForName:[CDKTask entityName] inManagedObjectContext:moc]];
                        [request setPredicate:predicate];
                        [request setSortDescriptors:[CDKTask defaultSortDescriptors]];
                        
                        NSError *error = nil;
                        NSArray *results = [moc executeFetchRequest:request error:&error];
                        
                        
                        
                        if(results.count > 0){
                            CDKTask* task = results[0];
                            int64_t remote_id = [[NSDate date] timeIntervalSince1970];
                            task.id = kNoteId;
                            task.remoteID = [NSNumber numberWithInt:remote_id];
                            NSString* title =[knoteAdded objectForKey:@"title"];
                            title= [title isEqualToString:@""]?@" _ ":title;
                            //if([title isEqualToString:@""])title = @" _ ";
                            task.displayText = title;
                            task.text =title;
                            task.position = [NSNumber numberWithInt:0];
                            task.list = list;
                            
                            [task setCheckList: options];
                            [[self managedObjectContext] performBlockAndWait:^{
                                
                                [task save];
                            }];
                        }else{
                            CDKTask* task = [[CDKTask alloc] init];
                            int64_t remote_id = [[NSDate date] timeIntervalSince1970];
                            task.id = kNoteId;
                            task.remoteID = [NSNumber numberWithInt:remote_id];
                            NSString* title =[knoteAdded objectForKey:@"title"];
                            title= [title isEqualToString:@""]?@" _ ":title;
                            //if([title isEqualToString:@""])title = @" _ ";
                            task.displayText = title;
                            task.text =title;
                            task.position = [NSNumber numberWithInt:0];
                            task.list = list;
                            [task setCheckList: options];
                            [[self managedObjectContext] performBlockAndWait:^{
                                
                                
                                [task save];
                            }];
                        }
                        if(_selectedList)
                            if([list.id isEqualToString:_selectedList.id]){
                                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[options mutableCopy] forKey:@"options"];
                                NSLog(@"options are : %@",options);
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:kTaskChangedNotification
                                 object:self userInfo: userInfo];
                            }
                    }
                }
                    savingKnoteId = nil;
                    
            });
                
        }
    }
    
    
}


/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
- (CDKList*)findObject:(NSString*)topicId{
    NSMutableArray *topics = [[NSMutableArray alloc] initWithArray:[self.fetchedResultsController fetchedObjects]];
    for (CDKList *topic in topics) {
        if ([topic.id isEqualToString:topicId]) {
            return topic;
        }
    }
    return nil;
}

- (void)updateOffline{
    NSMutableArray *topicLocation = [[NSMutableArray alloc] initWithArray:[self.fetchedResultsController fetchedObjects]];
    NSDictionary *topicServer = self.meteor.collections[METEORCOLLECTION_TOPICS];
    for (CDKList *topic in topicLocation) {
        int index = 0;
        for (NSDictionary *topicId in topicServer) {
            NSDictionary *model = [topicServer objectForKeyedSubscript:topicId];
            if ([[model objectForKeyedSubscript:@"_id"] isEqualToString:topic.id]) {
                continue;
            }
            if (index == topicServer.count - 1) {
                topic.archivedAt = [NSDate date];
                topic.isArchived = YES;
                [topic save];
                [topic update];
            }
            index ++;
        }
    }
}

- (void)topicsRemoved:(NSNotification *)note{
    NSLog(@"Topic Remove %@",@"");
    NSDictionary *value = [note userInfo];
    CDKList *list = [self findObject:[value objectForKeyedSubscript:@"_id"]];
    if (list) {
        list.archivedAt = [NSDate date];
        list.isArchived = YES;
        [list save];
        [list update];
    }
}

- (void)topicsChanged:(NSNotification *)note{
    NSLog(@"Topic Changed %@",note);
    
    /*
     userInfo = {
        "_id" = Hyt8bbtZWKgjp6Lwk;
        "account_id" = qs8PoCMD8kQebKt9p;
        addNewKnoteAt =     {
            "$date" = 1440957810017;
        };
        "alert_sent_time" =     (
                                );
        "changed_subject" = "Tasks1 from IOS";
        cname = topics;
        "created_time" =     {
            "$date" = 1440952447758;
            };
        "file_ids" =     (
                        );
        flagged = 0;
        isMailgun = 1;
        "liked_contact_ids" =     (
                                );
        "likes_count" = 0;
        new = 1;
        order =     {
            KBTtsRoXxQBa7XZgZ = "4.5";
            undefined = 4;
        };
        "original_subject" = "Tasks1 from IOS";
        "participator_account_ids" =     (
            KBTtsRoXxQBa7XZgZ,
            qs8PoCMD8kQebKt9p
            );
        permissions =     (
            read,
            write,
            upload
            );
        status = POSTED;
        subject = "Tasks1 from IOS";
        to =     (
            );
        "topic_type" = 0;
        type = topic;
        uniqueNumber = 22956;
        "updated_time" = 1440952447000;
        viewers =     (
            qs8PoCMD8kQebKt9p
        );
     }
     */
    NSDictionary* model = note.userInfo;
    
    NSMutableArray *topics = [[NSMutableArray alloc] initWithArray:[self.fetchedResultsController fetchedObjects]];
    NSString* _id = [model objectForKey:@"_id"];
    dispatch_async( myCustomQueue, ^{
        BOOL alreadyExists = false;
    for (CDKList *list in topics) {
        if([list.id isEqualToString:_id]){
            
            list.title = [model objectForKey:@"changed_subject"]?[model objectForKey:@"changed_subject"]:[model objectForKey:@"subject"];
            list.position = [model objectForKey:@"uniqueNumber"];
            list.slug = @"";
            list.archivedAt = [[model objectForKey:@"archived"] count]>0?[NSDate date]:nil;
            //list.updatedAt = [NSDate date];
            list.isArchived = NO;
            [self.managedObjectContext performBlockAndWait:^(){
                [list save];
            }];
            //[list update];
            alreadyExists=true;
            break;
        }
    }
    });
}

- (void)gotTopicCount:(NSNotification *)note{
    NSLog(@"Topic Count %@",[[note userInfo] objectForKey:@"count"]);
    numberTopic = [[[note userInfo] objectForKey:@"count"] integerValue];
    if(numberTopic == 0){
        dispatch_async( myCustomQueue, ^{
            [self removePreviousSavedLists];
        });
    }
}

- (void)gotArchivedTopicCount:(NSNotification *)note{
// NSLog(@"333333 %@",note);
}

- (void)contactsCountAdded:(NSNotification *)note{
// NSLog(@"444444 %@",note);
}

- (void)contactsAdded:(NSNotification *)note{
// NSLog(@"5555555 %@",note);
}

- (void)contactsChanged:(NSNotification *)note{
// NSLog(@"6666666 %@",note);
}

- (void)contactsRemoved:(NSNotification *)note{
// NSLog(@"7777777 %@",note);
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self _checkUser];
	}

	[SSRateLimit executeBlock:^{
		[self refresh:nil];
	} name:@"refresh-lists" limit:30.0];
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];

	if (editing) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleEditMode:)];
        [doneButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
        self.navigationItem.leftBarButtonItem = doneButton;

        UIBarButtonItem *settingButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(showSettings:)];
        [settingButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
        self.navigationItem.rightBarButtonItem = settingButton;
	} else {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleEditMode:)];
        [editButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
        self.navigationItem.leftBarButtonItem = editButton;

        UIBarButtonItem *settingButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(showSettings:)];
        [settingButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
        self.navigationItem.rightBarButtonItem = settingButton;
        
        /*UIBarButtonItem *createButton = [[UIBarButtonItem alloc] initWithTitle:@" ＋ " style:UIBarButtonItemStyleBordered target:self action:@selector(createList:)];
        [createButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];*/
//        self.navigationItem.rightBarButtonItem = createButton;

	}

	if (!editing && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.tableView selectRowAtIndexPath:[self.fetchedResultsController indexPathForObject:_selectedList] animated:YES scrollPosition:UITableViewScrollPositionNone];
	}
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return YES;
	}

	return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark - Gestures

- (BOOL)_shouldEditRowForGesture:(UIGestureRecognizer *)gestureRecognizer {
    BOOL didLongPressGestureSucceed = [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && gestureRecognizer.state == UIGestureRecognizerStateEnded;
    BOOL didTapGestureSucceed = [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && gestureRecognizer.state == UIGestureRecognizerStateBegan;
    return didTapGestureSucceed || didLongPressGestureSucceed;
}


- (void)_beginEditingWithGesture:(UIGestureRecognizer *)gestureRecognizer {
    if ([self _shouldEditRowForGesture:gestureRecognizer]) {
        if (![self isEditing]) {
            [self setEditing:YES animated:YES];
        }

        [self editRow:gestureRecognizer];
    }
}


#pragma mark - SSManagedViewController

- (Class)entityClass {
	return [CDKList class];
}


- (NSPredicate *)predicate {
    
    NSLog(@"current User is = %@  %@  %@",[CDKUser currentUser].firstName ,[CDKUser currentUser].username, [CDKUser currentUser].remoteID);
    
    return [NSPredicate predicateWithFormat:@"archivedAt = nil && user = %@", [CDKUser currentUser]];
    
}


#pragma mark - SSManagedTableViewController

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	CDKList *list = [self objectForViewIndexPath:indexPath];
	[(CDIListTableViewCell *)cell setList:list];
}


- (NSIndexPath *)viewIndexPathForFetchedIndexPath:(NSIndexPath *)fetchedIndexPath {
	if (_adding) {
		return [NSIndexPath indexPathForRow:fetchedIndexPath.row + 1 inSection:fetchedIndexPath.section];
	}

	return fetchedIndexPath;
}


- (NSIndexPath *)fetchedIndexPathForViewIndexPath:(NSIndexPath *)viewIndexPath {
	if (_adding) {
		return [NSIndexPath indexPathForRow:viewIndexPath.row - 1 inSection:viewIndexPath.section];
	}

	return viewIndexPath;
}


#pragma mark - CDIManagedTableViewController

- (void)coverViewTapped:(id)sender {
	[self _cancelAddingList:sender];
}


#pragma mark - Actions

- (void)refresh:(id)sender {
	if (self.loading || ![CDKUser currentUser]) {
		return;
	}
	self.loading = YES;

//	[[CDKHTTPClient sharedClient] getListsWithSuccess:^(AFJSONRequestOperation *operation, id responseObject) {
//		dispatch_async(dispatch_get_main_queue(), ^{
//			self.loading = NO;
//
//			[_archiveButton setTitle:@"19 Archived Lists" forState:UIControlStateNormal];
//			if (_archiveButton.alpha < 1.0f) {
//				[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
//					_archiveButton.alpha = 1.0f;
//				} completion:nil];
//			}
//		});
//	} failure:^(AFJSONRequestOperation *operation, NSError *error) {
//		dispatch_async(dispatch_get_main_queue(), ^{
//			[SSRateLimit resetLimitForName:@"refresh-lists"];
			self.loading = NO;
//            [_archiveButton setTitle:@"19 Archived Lists" forState:UIControlStateNormal];
//            if (_archiveButton.alpha < 1.0f) {
//                [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
//                    _archiveButton.alpha = 1.0f;
//                } completion:nil];
//            }
//        });
//	}];

	// Also update their user incase push for updates failed
	//[[CDKHTTPClient sharedClient] updateCurrentUserWithSuccess:nil failure:nil];
}


- (void)showSettings:(id)sender {
	CDISettingsViewController *viewController = [[CDISettingsViewController alloc] init];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
//	navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self toggleEditMode:self];
	[self.navigationController presentViewController:navigationController animated:YES completion:nil];
}


- (void)createList:(id)sender {
	/*if (self.fetchedResultsController.fetchedObjects.count >= 2 && [[CDKUser currentUser] hasPlus].boolValue == NO) {
		UIViewController *viewController = [[CDIUpgradeViewController alloc] init];
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self.navigationController presentViewController:navigationController animated:YES completion:nil];
		return;
	}*/

    
    NSLog(@"visibility of tableView = %hhd",self.tableView.hidden);
    NSLog(@"Frame of tableView : (%f,%f) , (%f,%f)",self.tableView.frame.origin.x,self.tableView.frame.origin.y,self.tableView.frame.size.width,self.tableView.frame.size.height);

    if([self.tableView isHidden]){
        self.tableView.hidden = false;
    }

	[self hideNoContentView:YES];
	UIView *coverView = self.coverView;
	coverView.frame = self.view.bounds;
	[self setEditing:NO animated:YES];

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(_cancelAddingList:)];
    [cancelButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = cancelButton;

    UIBarButtonItem *createButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStyleBordered target:self action:@selector(_createList:)];

    [createButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];

    self.navigationItem.rightBarButtonItem = createButton;

	[UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
		[self.tableView scrollToTopAnimated:NO]; // Not animated since the outer animation block will animate it
		coverView.alpha = 1.0f;

		_adding = YES;
		[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
		coverView.frame = CGRectMake(0.0f, [CDIListTableViewCell cellHeight], self.tableView.bounds.size.width, self.tableView.bounds.size.height - [CDIListTableViewCell cellHeight]);
        [self.tableView reloadData];
	} completion:nil];
	return;
}


#pragma mark - Private

- (void)_listUpdated:(NSNotification *)notification {
	if ([notification.object isEqual:_selectedList.remoteID] == NO) {
		return;
	}

	if (_selectedList.archivedAt != nil) {
		[CDISplitViewController sharedSplitViewController].listViewController.managedObject = nil;
		_selectedList = nil;
	}
}


- (void)_currentUserDidChange:(NSNotification *)notification {
	self.fetchedResultsController = nil;
	_checkForOneList = YES;
	[self.tableView reloadData];
}

- (void)__createList:(NSDictionary* )model {
    int64_t remote_id = [[NSDate date] timeIntervalSince1970];
    CDKList *list = [[CDKList alloc] init];
    list.id = [model objectForKey:@"_id"];
    list.title = [model objectForKey:@"subject"];
    list.position = [model objectForKey:@"uniqueNumber"];
    list.slug = @"";
    list.archivedAt = nil;
    list.updatedAt = nil;
    list.user = [CDKUser currentUser];
    list.createdAt  = [NSDate date];
    list.remoteID = [NSNumber numberWithInt:remote_id];

    [list createWithSuccess:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            isUpdateFirst = YES;
            [self _cancelAddingList:nil];
            int t =0;
            t=[self.fetchedResultsController fetchedObjects].count;
            NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:list];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self.view bringSubviewToFront:self.tableView];
            [self _selectListAtIndexPath:indexPath newList:YES];
        });
    } failure:^(AFJSONRequestOperation *remoteOperation, NSError *error) {

    }];
}

- (void)createPad:(NSDictionary* )model {
    int64_t remote_id = [[NSDate date] timeIntervalSince1970];
    CDKList *list = [[CDKList alloc] init];
    list.id = [model objectForKey:@"_id"];
    list.title = [model objectForKey:@"subject"];
    list.position = [model objectForKey:@"uniqueNumber"];
    list.slug = @"";
    list.archivedAt = nil;
    list.updatedAt = nil;
    list.user = [CDKUser currentUser];
    list.createdAt  = [NSDate date];
    list.remoteID = [NSNumber numberWithInt:remote_id];
    
    [list createWithSuccess:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    } failure:^(AFJSONRequestOperation *remoteOperation, NSError *error) {
        
    }];
}
- (void)_createList:(id)sender {

    	CDIAddListTableViewCell *cell = (CDIAddListTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	UITextField *textField = cell.textField;
	if (textField.text.length == 0) {
		[self _cancelAddingList:nil];
		return;
	}

    NSArray *participator_account_ids = @[[TNUserModel currentUser].user_email];
    NSDictionary *requiredTopicParams = @{
                                          @"userId":[TNUserModel currentUser].user_id,
                                          @"participator_account_ids":participator_account_ids,
                                          @"subject":textField.text,
                                          @"permissions":@[@"read", @"write", @"upload"],
                                          };

    NSDictionary *optionalTopicParams = @{
                                          @"file_ids":@[],
                                          @"order":@{[TNUserModel currentUser].user_id : @(999)},
                                          @"to":@"",
                                          };
    NSDictionary *additionalOptions = @{/*@"topicId":[topic.topic_id noPrefix:kKnoteIdPrefix]*/};

    NSArray *params = @[requiredTopicParams, optionalTopicParams, additionalOptions];

//	CDIHUDView *hud = [[CDIHUDView alloc] initWithTitle:@"Creating..." loading:YES];
//	[hud show];

    [[TNAPIClient sharedClient] insertTopicWithParam:@"create_topic" withPram:params withBlock:^(NSDictionary *model, NSError *error) {
        if (!error) {
//            [hud completeAndDismissWithTitle:@"Create!"];
            textField.text = nil;
            modelId = [model objectForKeyedSubscript:@"result"];
        }
    }];
//
//	CDKList *list = [[CDKList alloc] init];
//	list.title = textField.text;
//	list.position = [NSNumber numberWithInteger:INT32_MAX];
//	list.user = [CDKUser currentUser];
//	
//	[list createWithSuccess:^{
//		dispatch_async(dispatch_get_main_queue(), ^{
//			[hud completeAndDismissWithTitle:@"Created!"];
//			[self _cancelAddingList:nil];
//			textField.text = nil;
//            int t =0;
//            t=[self.fetchedResultsController fetchedObjects].count;
//            NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:list];
//			[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
//            [self.view bringSubviewToFront:self.tableView];
//            [self _selectListAtIndexPath:indexPath newList:YES];
//		});
//	} failure:^(AFJSONRequestOperation *remoteOperation, NSError *error) {
//		dispatch_async(dispatch_get_main_queue(), ^{
//			NSDictionary *responseObject = remoteOperation.responseJSON;
//			if ([responseObject isKindOfClass:[NSDictionary class]] && [[responseObject objectForKey:@"error"] isEqualToString:@"plus_required"]) {
//				[hud dismiss];
//				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Plus Required" message:@"You need Cheddar Plus to create more than 2 lists. Please upgrade to continue." delegate:self cancelButtonTitle:@"Later" otherButtonTitles:@"Upgrade", nil];
//				[alert show];
//			} else {
//				[hud failAndDismissWithTitle:@"Failed"];
//				[textField becomeFirstResponder];
//			}
//		});
//	}];
}


- (void)_cancelAddingList:(id)sender {
	if (!_adding) {
		return;
	}

	_adding = NO;

	CDIAddListTableViewCell *cell = (CDIAddListTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	if ([cell.textField isFirstResponder]) {
		[cell.textField resignFirstResponder];
	}

	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"+"] style:UIBarButtonItemStyleBordered target:self action:@selector(createList:)];
	[self setEditing:NO animated:NO];
	[self hideCoverView];
	[self updatePlaceholderViews:YES];
}


- (void)_selectListAtIndexPath:(NSIndexPath *)indexPath newList:(BOOL)newList {
	if (_adding) {
		return;
	}

	if ([[self.tableView indexPathForSelectedRow] isEqual:indexPath] == NO) {
		[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
	}
	
	CDKList *list = [self objectForViewIndexPath:indexPath];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:list.remoteID forKey:kCDISelectedListKey];
	[userDefaults synchronize];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[CDISplitViewController sharedSplitViewController].listViewController.managedObject = list;
		_selectedList = list;
	} else {
		CDITasksViewController *viewController = [[CDITasksViewController alloc] init];
        _selectedList = list;
        viewController.managedObject = list;
		viewController.focusKeyboard = newList;
        
		[self.navigationController pushViewController:viewController animated:YES];
	}

	_checkForOneList = NO;
}


- (void)_checkUser {
	if (![TNUserModel currentUser]) {
#ifdef CHEDDAR_USE_PASSWORD_FLOW
		UIViewController *viewController = [[CDISignInViewController alloc] init];
#else
		UIViewController *viewController = [[CDIWebSignInViewController alloc] init];
#endif
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			[self.splitViewController presentViewController:navigationController animated:YES completion:nil];
		} else {
			[self.navigationController presentViewController:navigationController animated:NO completion:nil];
		}
		return;
	}
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger rows = [super tableView:tableView numberOfRowsInSection:section];

	if (_adding) {
		return rows + 1;
	}
	
	return rows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *const cellIdentifier = @"cellIdentifier";
	static NSString *const addCellIdentifier = @"addCellIdentifier";

	if (_adding && indexPath.row == 0) {
		CDIAddListTableViewCell *cell = (CDIAddListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:addCellIdentifier];
		if (!cell) {
			cell = [[CDIAddListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addCellIdentifier];
			
			if (self.textExpander) {
				cell.textField.delegate = self.textExpander;
			} else {
				cell.textField.delegate = self;
			}
			
			[cell.closeButton addTarget:self action:@selector(_cancelAddingList:) forControlEvents:UIControlEventTouchUpInside];
		}

		return cell;
	}

	CDIListTableViewCell *cell = (CDIListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[CDIListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    	[cell setEditingAction:@selector(_beginEditingWithGesture:) forTarget:self];
	}
    CDKList* list= [self objectForViewIndexPath:indexPath];
	cell.list = list;

	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_adding) {
        return NO;
    }
    
    return YES;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self _selectListAtIndexPath:indexPath newList:NO];
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	if (sourceIndexPath.row == destinationIndexPath.row) {
		return;
	}

	self.ignoreChange = YES;
	NSMutableArray *lists = [self.fetchedResultsController.fetchedObjects mutableCopy];
	CDKList *list = [self objectForViewIndexPath:sourceIndexPath];
	[lists removeObject:list];
	[lists insertObject:list atIndex:destinationIndexPath.row];
	
	NSInteger i = 0;
	for (list in lists) {
		list.position = [NSNumber numberWithInteger:i++];
	}

	[self.managedObjectContext save:nil];
	self.ignoreChange = NO;
	
	[CDKList sortWithObjects:lists];
}


- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Archive";
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle != UITableViewCellEditingStyleDelete) {
		return;
	}
	
	CDKList *list = [self objectForViewIndexPath:indexPath];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		CDITasksViewController *listViewController = [CDISplitViewController sharedSplitViewController].listViewController;
		if ([listViewController.managedObject isEqual:list]) {
			listViewController.managedObject = nil;
		}
	}
    list.isArchived = YES;
	list.archivedAt = [NSDate date];
	[list save];
	[list update];
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([cell isKindOfClass:[CDIAddListTableViewCell class]]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[(CDIAddListTableViewCell *)cell textField] becomeFirstResponder];
		});
	}
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (_adding) {
		[self _cancelAddingList:scrollView];
	}
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (_adding) {
		[self _createList:textField];
		return NO;
	}

	CDKList *list = [self objectForViewIndexPath:self.editingIndexPath];
	list.title = textField.text;
	[list save];
	[list update];

	[self endCellTextEditing];
	return NO;
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (_adding) {
		[self _cancelAddingList:textField];
	}
}


#pragma mark - NSFetchedResultsController

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[super controllerDidChangeContent:controller];

	if (_checkForOneList) {
		if ([self.navigationController topViewController] == self ) {
			NSNumber *selectedList = [[NSUserDefaults standardUserDefaults] objectForKey:kCDISelectedListKey];
			if (selectedList) {
				CDKList *list = [CDKList objectWithRemoteID:selectedList];
				NSIndexPath *fIndexPath = [self.fetchedResultsController indexPathForObject:list];
				if (fIndexPath) {
					_checkForOneList = NO;
					//return;
				
				
				NSIndexPath *selectedIndexPath = [self viewIndexPathForFetchedIndexPath:fIndexPath];
                //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self _selectListAtIndexPath:selectedIndexPath newList:NO];
                //});
                return;
                }
			}

			if (self.fetchedResultsController.fetchedObjects.count > 0 ) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    if(!_selectedList){
                        
                        for(int t=0; t<[self.fetchedResultsController fetchedObjects].count;t++){
                            CDKList* list = [self objectForViewIndexPath:[NSIndexPath indexPathForRow:t inSection:0]];
                            if([list.title isEqualToString:kDefaultPadName]){
                                [self _selectListAtIndexPath:[NSIndexPath indexPathForRow:t inSection:0] newList:NO];
                                break;
                            }
                        }
                    }
                });
                
				return;
			}
		}
		_checkForOneList = NO;
	}
}


-(void)meteorConnectedNotification:(NSNotification *) notification{
    if(isUpdateNeeded)[self checkForUpdatesAndPush];
    
}


-(void)doUpdateNotification:(NSNotification *) notification{
    [self checkForUpdatesAndPush];
    
}


-(void)checkForUpdatesAndPush{
    
    NSArray* updates = [Update getAllUpdates];
    
    BOOL connected = [self.meteor connected];
    
    if(!connected){
        isUpdateNeeded = true;
        return;
    }
    if(updates && [updates count])
    dispatch_async( myCustomQueue, ^{
        
    for(Update* update in updates){
        //Updating Tasks here in background
        if([update.updated_entity intValue] == kCDKUpdateTask)
        {
            if([update.type intValue] == kCDKUpdatedItemTypeUpdated ){
                NSLog(@"updated Task %@",update.updated_ID);
                CDKTask* toUpdateTask= [CDKTask findObjectWithID:update.updated_ID];
                
                [[TNAPIClient sharedClient] sendRequestUpdateTaskList:update.updated_ID withOptionArray:toUpdateTask.checkList withCompleteBlock:^(WM_NetworkStatus success,NSError* error, id userDate){
                    if (error) {
                        NSLog(@"Error in update Task : %@",error);
                        NSLog(@"Error Posting update");
                        
                    }else{
                        NSLog(@"Received Data from update Task: %@",userDate);
                        NSLog(@"Done Posting update");
                        if(connected)
                        [update delete];
                    }
                }];

            }
            else if([update.type intValue] == kCDKUpdatedItemTypeAdded){
                NSLog(@"Added Task %@",update.updated_ID);
                CDKTask* toUpdateTask= [CDKTask findObjectWithID:update.updated_ID];
                TNTaskList *taskList = [[TNTaskList alloc]init];
                taskList.title = @"TaskNotes";
                NSDateFormatter * formater = [[NSDateFormatter alloc]init];
                [formater setDateFormat:kDateFormat1];
                taskList.date = [formater stringFromDate:[NSDate date]];
                taskList.subject = @"subject";
                taskList.name = [TNUserModel currentUser].user_username;
                taskList.options = toUpdateTask.checkList;
                taskList.from = [TNUserModel currentUser].user_email;
                
                taskList.topicId = toUpdateTask.list.id;
                taskList.taskType = @"checklist";
                taskList.sectionId = @"";
                taskList.order = [NSString stringWithFormat:@"%@", toUpdateTask.position];
                
                [[TNAPIClient sharedClient] sendInsertTaskList:taskList withUserId:[TNUserModel currentUser].user_id withUseData:nil withCompleteBlock:^(WM_NetworkStatus success, NSError* error, id userDate){
                    if (error) {
                   
                        NSLog(@"Error in Add Task : %@",error);
                        NSLog(@"Error Posting Add task");
                        
                    }else{
                        //    [hud completeAndDismissWithTitle:@"Inserted Successfully"];
                        /*
                         received data = {
                         id = 46;
                         msg = result;
                         result = hcLKL7FgfEfRMAf2H;
                         }

                         */
                        toUpdateTask.id = [userDate objectForKey:@"result"];
                        [toUpdateTask save];
                        NSLog(@"received data = %@",userDate);
                        if(connected)
                        [update delete];
                    }
                    NSLog(@"done posting");
                }];
            }
        }
        
    }
        isUpdateNeeded = false;
    });
    
}

@end
