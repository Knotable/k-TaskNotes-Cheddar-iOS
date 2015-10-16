
//
//  CDITasksViewController.m
//  Cheddar for iOS
//
//  Created by Sam Soffes on 3/31/12.
//  Copyright (c) 2012 Nothing Magical. All rights reserved.
//

#import "CDITasksViewController.h"
#import "CDITaskTableViewCell.h"
#import "CDIAddTaskView.h"
#import "CDIAddTaskAnimationView.h"
#import "CDIAttributedLabel.h"
#import "CDICreateListViewController.h"
#import "CDITasksPlaceholderView.h"
#import "CDIEditTaskViewController.h"
#import "CDIWebViewController.h"
#import "CDISettingsTapPickerViewController.h"
#import "CDIHUDView.h"
#import "CDICheckboxButton.h"
#import "CDIKeyboardBar.h"
#import "UIColor+CheddariOSAdditions.h"
#import "UIFont+CheddariOSAdditions.h"
#import "Update.h"
#import "CDIWebPadButton.h"

@interface CDITasksViewController () <CDIAddTaskViewDelegate, TTTAttributedLabelDelegate, UITextFieldDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) CDIAddTaskView *addTaskView;
@property (nonatomic, strong) NSMutableArray *currentTags;
@property (nonatomic,strong) CDIWebPadButton* webPadButton;
- (void)_renameList:(id)sender;
- (void)_archiveTasks:(id)sender;
- (void)_archiveAllTasks:(id)sender;
- (void)_archiveCompletedTasks:(id)sender;
- (void)_toggleCompletion:(CDICheckboxButton *)sender;
- (void)_editTask:(CDKTask *)task;
@end

@implementation CDITasksViewController {
	NSIndexPath *_textEditingIndexPath;
	dispatch_semaphore_t _createTaskSemaphore;
    //NSMutableArray* options;
    dispatch_queue_t myCustomQueue;
    NSInteger selectedSection;
}

@synthesize addTaskView = _addTaskView;
@synthesize currentTags = _currentTags;
@synthesize focusKeyboard = _focusKeyboard;

- (void)setManagedObject:(SSManagedObject *)managedObject {
	CDKList *list = (CDKList *)self.managedObject;

	void *context = (__bridge void *)self;
	if (list) {
		[list removeObserver:self forKeyPath:@"title" context:context];
		[list removeObserver:self forKeyPath:@"archivedAt" context:context];
	}
	
	[super setManagedObject:managedObject];
	list = (CDKList *)self.managedObject;
	
//	self.title = @"Learn Tasknote";
    
    self.title = self.list.title;
    
	self.tableView.hidden = self.list == nil;
	
	if (list == nil) {
		return;
	}
	
	[list addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:context];
	[list addObserver:self forKeyPath:@"archivedAt" options:NSKeyValueObservingOptionNew context:context];

	self.ignoreChange = YES;
	[self closeTags];
	
	self.fetchedResultsController.fetchRequest.predicate = self.predicate;
	[self.fetchedResultsController performFetch:nil];
	[self.tableView reloadData];
	self.ignoreChange = NO;
	
	[self setEditing:NO animated:NO];
	[self setLoading:NO animated:NO];
	
	[SSRateLimit executeBlock:^{
		[self refresh:nil];
	} name:[NSString stringWithFormat:@"refresh-list-%@", self.list.remoteID] limit:30.0];
}


- (CDKList *)list {
	return (CDKList *)self.managedObject;
}


- (CDIAddTaskView *)addTaskView {
	if (!_addTaskView) {
		_addTaskView = [[CDIAddTaskView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, [CDIAddTaskView height])];
		_addTaskView.delegate = self;
		[_addTaskView.renameListButton addTarget:self action:@selector(_renameList:) forControlEvents:UIControlEventTouchUpInside];
		[_addTaskView.archiveTasksButton addTarget:self action:@selector(_archiveTasks:) forControlEvents:UIControlEventTouchUpInside];
		[_addTaskView.archiveAllTasksButton addTarget:self action:@selector(_archiveAllTasks:) forControlEvents:UIControlEventTouchUpInside];
		[_addTaskView.archiveCompletedTasksButton addTarget:self action:@selector(_archiveCompletedTasks:) forControlEvents:UIControlEventTouchUpInside];
	}
	return _addTaskView;
}


#pragma mark - NSObject

- (id)init {
	if ((self = [super init])) {
		_createTaskSemaphore = dispatch_semaphore_create(0);
		dispatch_semaphore_signal(_createTaskSemaphore);
		
		//self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Tasks" style:UIBarButtonItemStyleBordered target:nil action:nil];
	}
	return self;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.managedObject = nil;
	
	dispatch_semaphore_wait(_createTaskSemaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(_createTaskSemaphore);
}


#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    selectedSection = 0;
	[self setEditing:NO animated:NO];
	self.view.backgroundColor = [UIColor cheddarArchesColor];
	self.tableView.hidden = self.list == nil;
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake([CDIAddTaskView height], 0.0f, 0.0f, 0.0f);
	self.pullToRefreshView.bottomBorderColor = [UIColor colorWithWhite:0.8f alpha:1.0f];

	self.noContentView = [[CDITasksPlaceholderView alloc] initWithFrame:CGRectZero];
    
    
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 100.0f)];
    footer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIView *shadow = self.tableView.tableFooterView;
    
    self.tableView.tableFooterView = footer;
    shadow.frame = CGRectMake(0.0f, 0.0f, 320.0f, 3.0f);
    [footer addSubview:shadow];
    
    _webPadButton = [[CDIWebPadButton alloc] initWithFrame:CGRectMake(20.0f, 62.0f  , 280.0f, 32.0)];
    _webPadButton.alpha = 1.0f;
    [_webPadButton setTitle:@"View this Pad on Knotable.com" forState:UIControlStateNormal];
    [_webPadButton addTarget:self action:@selector(webPadButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [footer addSubview:_webPadButton];
    
    
    
    
    self.fetchedResultsController.fetchRequest.predicate = self.predicate;
    [self.fetchedResultsController performFetch:nil];
    
    myCustomQueue = dispatch_queue_create("com.kNotables.taskNotes", DISPATCH_QUEUE_SERIAL);
    [self.tableView beginUpdates];
    [self.tableView reloadData];
    [self.tableView endUpdates];
    
    
}


-(void)webPadButtonClick:(UIButton *) sender {
    
    NSString* text = [NSString stringWithFormat: @"http://staging.knotable.com/p/%@",self.list.id];
    NSURL*    url  = [[NSURL alloc] initWithString:text];
    
    if (url.scheme.length == 0)
    {
        text = [@"http://" stringByAppendingString:text];
        url  = [[NSURL alloc] initWithString:text];
    }
    
    [[UIApplication sharedApplication] openURL:url];
    
}



-(void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[SSRateLimit executeBlock:^{
		[self refresh:nil];
	} name:[NSString stringWithFormat:@"refresh-list-%@", self.list.remoteID] limit:30.0];

	if (_focusKeyboard) {
		[self.addTaskView.textField becomeFirstResponder];
		_focusKeyboard = NO;
	}
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskChangedNotification:)
                                                 name:kTaskChangedNotification
                                               object:nil];
}

-(void)taskChangedNotification:(NSNotification *) notification{
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //Your main thread code goes in here
        if ([[self.fetchedResultsController fetchedObjects] count]==0) {
            
            [self setFetchedResultsController:nil];
        }
//        self.fetchedResultsController.fetchRequest.predicate = self.predicate;
//        
//        [self.fetchedResultsController performFetch:nil];
//        
        
        if ([[[self fetchedResultsController] fetchedObjects] count]>0) {
            NSLog(@"hurray");
        }

        NSLog(@"Im on the main thread");
        NSDictionary* userInfo = notification.userInfo;
        //options = [userInfo objectForKey:@"options"];
        
        //[self.tableView endUpdates];
    
        self.ignoreChange = YES;
        
        [self setLoading:NO animated:NO];
        [self hideCoverView];

        self.tableView.hidden=false;
//        [SSRateLimit executeBlock:^{
//            [self refresh:nil];
//        } name:[NSString stringWithFormat:@"refresh-list-%@", self.list.remoteID] limit:30.0];
        self.loading = NO;
        [self updatePlaceholderViews:YES];
        [self.addTaskView.textField resignFirstResponder];
        //[self.tableView reloadData];
        //[self.tableView endUpdates];
        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    
        self.ignoreChange=NO;
        
        [self controllerDidChangeContent:self.fetchedResultsController];
//        [self hideNoContentView:YES];
//        [self hideLoadingView:YES];
    });

    
    
    
    
    
//    NSDictionary* userInfo = notification.userInfo;
//    NSArray* newOptions = [userInfo objectForKey:@"options"];
//    
//    self.fetchedResultsController=nil;
//    [NSFetchedResultsController deleteCacheWithName:self.cacheName];
//    NSError* err;
//    [self.fetchedResultsController performFetch:&err];
//    //[SSRateLimit executeBlock:^{
//    
//    options =newOptions;
//    [self.tableView beginUpdates];
//        [self.tableView reloadData];
//    [self.tableView endUpdates];
//        self.loading = NO;
   // } name:[NSString stringWithFormat:@"refresh-list-%@", self.list.remoteID] limit:30.0];
    
}

- (void)addTaskButtonPressed:(id)sender {
    //[self setEditing:!self.editing animated:YES];
    selectedSection = [sender tag];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];

    [self.addTaskView.textField becomeFirstResponder];
    [self addTaskViewDidBeginEditing:_addTaskView];
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	
    [super setEditing:editing animated:animated];
    //[self.tableView setEditing:editing animated:animated];
    //self.navigationItem.hidesBackButton=YES;
    if (!self.navigationItem.rightBarButtonItem) {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleEditMode:)];
        [editButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
        self.navigationItem.rightBarButtonItem = editButton;
	}
    
	self.navigationItem.rightBarButtonItem.title = editing ? @"Done" : @"Edit";
	self.navigationItem.rightBarButtonItem.enabled = self.currentTags.count == 0 && self.list;
	//[self.addTaskView setEditing:editing animated:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return YES;
	}
	
	return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


#pragma mark - SSManagedViewController

+ (Class)fetchedResultsControllerClass {
	return [SSFilterableFetchedResultsController class];
}


- (Class)entityClass {
	return [CDKTask class];
}


- (NSPredicate *)predicate {
	return [NSPredicate predicateWithFormat:@"list = %@ AND archivedAt = nil", self.list];
}


#pragma mark - SSManagedTableViewController

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	CDITaskTableViewCell *taskCell = (CDITaskTableViewCell *)cell;
	//taskCell.task = [self objectForViewIndexPath:indexPath];
    CDKTask* currentTask=[[self fetchedResultsController]fetchedObjects][indexPath.section];
    
    NSArray* options= currentTask.checkList;
    if(indexPath.row >= [options count]) return;
    NSDictionary* task =options[indexPath.row];
    NSMutableDictionary* muTask = [task mutableCopy];
    NSString* name=[task objectForKey:@"name"] == [NSNull null]?@"-":[task objectForKey:@"name"];
    [muTask setValue:name forKey:@"name"];
    taskCell.task =muTask;
    
	taskCell.attributedLabel.tag = indexPath.row;
}


#pragma mark - CDIManagedTableViewController

- (void)editRow:(UIGestureRecognizer *)editingGestureRecognizer {
	NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)editingGestureRecognizer.view];
	if (!indexPath) {
		return;
	}

    CDKTask *task = [self.fetchedResultsController fetchedObjects][0]; //[self objectForViewIndexPath:indexPath];
	[self _editTask:task];
}


- (void)coverViewTapped:(id)sender {
	[self.addTaskView.textField resignFirstResponder];
}


#pragma mark - Actions

- (void)refresh:(id)sender {
	if (self.list == nil || self.loading) {
		return;
	}
	
//	self.loading = YES;
    

    self.loading = NO;
    
    
//	[[CDKHTTPClient sharedClient] getTasksWithList:list success:^(AFJSONRequestOperation *operation, id responseObject) {
//		dispatch_async(dispatch_get_main_queue(), ^{
//			self.loading = NO;
//		});
//	} failure:^(AFJSONRequestOperation *operation, NSError *error) {
//		dispatch_async(dispatch_get_main_queue(), ^{
//			//[SSRateLimit resetLimitForName:[NSString stringWithFormat:@"refresh-list-%@", self.list.remoteID]];
//			self.loading = NO;
//		});
//	}];
    //if(!self.tableView.tableHeaderView){
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, [CDITableViewCell cellHeight])];
    
        [headerView addSubview:self.addTaskView];
        self.tableView.tableHeaderView = headerView;
    //}
    if (_addTaskView.frame.size.width < self.tableView.frame.size.width) {
        self.addTaskView.frame=CGRectMake(0, 0, self.tableView.frame.size.width, [CDITableViewCell cellHeight]) ;
    }
    NSLog(@"size of add task view (%f,%f)",self.addTaskView.frame.size.width,self.addTaskView.frame.size.height);
    NSLog(@"Done");
}


#pragma mark - Tags

- (void)addTag:(CDKTag *)tag {
	if (!tag || [_currentTags containsObject:tag]) {
		return;
	}
	
	if (!_currentTags) {
		_currentTags = [[NSMutableArray alloc] init];
	}
	
	[_currentTags addObject:tag];
	
	SSFilterableFetchedResultsController *controller = (SSFilterableFetchedResultsController *)self.fetchedResultsController;
	
	NSString *filterName = [_currentTags componentsJoinedByString:@","];
	[self.addTaskView showTags:_currentTags];
	[controller addFilterPredicate:^BOOL(id obj) {
		return [(CDKTask *)obj hasTags:_currentTags];
	} forKey:filterName];
	[controller setActiveFilterByKey:filterName];
	
	self.navigationItem.rightBarButtonItem.enabled = NO;
	[self setEditing:NO animated:YES];
}


- (void)closeTags {
	[self.addTaskView closeTags];
	
	SSFilterableFetchedResultsController *controller = (SSFilterableFetchedResultsController *)self.fetchedResultsController;
	[controller removeCurrentFilter];
	
	[_currentTags removeAllObjects];
	
	self.navigationItem.rightBarButtonItem.enabled = YES;
}


#pragma mark - Private

- (void)updateTableViewOffsets {
	CGFloat offset = self.tableView.contentOffset.y;
	CGFloat top = [CDIAddTaskView height] - fminf(0.0f, offset);
	CGFloat bottom = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? self.keyboardRect.size.height : 0.0f;
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(top, 0.0f, bottom, 0.0f);
	self.pullToRefreshView.defaultContentInset = UIEdgeInsetsMake(0.0f, 0.0f, bottom, 0.0f);
	self.addTaskView.shadowView.alpha = fmaxf(0.0f, fminf(offset / 24.0f, 1.0f));
}


- (void)_renameList:(id)sender {
	CDICreateListViewController *viewController = [[CDICreateListViewController alloc] init];
	viewController.list = self.list;
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self.navigationController presentModalViewController:navigationController animated:YES];
}


- (void)_archiveTasks:(id)sender {
	// TODO: This is super ugly
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Archive Completed", @"Archive All", nil];
		[actionSheet showFromRect:[sender frame] inView:self.view animated:YES];
	} else {
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Archive Completed", @"Archive All", nil];
		actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
		[actionSheet showInView:self.navigationController.view];
	}
}


- (void)_archiveAllTasks:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Archive All Tasks" message:@"Do you want to archive all of the tasks in this list?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Archive", nil];
	alert.tag = 1;
	[alert show];
}


- (void)_archiveCompletedTasks:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Archive Completed Tasks" message:@"Do you want to archive all of the completed tasks in this list?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Archive", nil];
	alert.tag = 2;
	[alert show];
}


- (void)_toggleCompletion:(CDICheckboxButton *)sender {
	NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender.tableViewCell];
	if (!indexPath) {
		return;
	}
    CDKTask* task=[[self fetchedResultsController]fetchedObjects][indexPath.section];
    
    NSMutableArray* options= [task.checkList mutableCopy];
    
    NSMutableDictionary* checkListItem = [options[indexPath.row] mutableCopy];
    if([[checkListItem objectForKey:@"checked"]intValue] == 0)
        [checkListItem setValue:[NSNumber numberWithInt:1] forKey:@"checked"];
    else
        [checkListItem setValue:[NSNumber numberWithInt:0] forKey:@"checked"];
    options[indexPath.row]=checkListItem;
    //CDKTask* task=[[self fetchedResultsController]fetchedObjects][0];
    task.checkList = options;
    [task save];
    
    Update* update = [[Update alloc] init];
    update.updated_entity = [NSNumber numberWithInt:kCDKUpdateTask];
    update.updated_ID = task.id;
    update.type=[NSNumber numberWithInt:kCDKUpdatedItemTypeUpdated];
    [update save];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kDoUpdateNotification
     object:self userInfo: nil];
    [self.tableView reloadData];
//    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:task.checkList forKey:@"options"];
//    NSLog(@"options are : %@",task.checkList);
//    [[NSNotificationCenter defaultCenter]
//     postNotificationName:kTaskChangedNotification
//     object:self userInfo: userInfo];
//    
}


- (void)_editTask:(CDKTask *)task {
//	CDIEditTaskViewController *viewController = [[CDIEditTaskViewController alloc] init];
//	viewController.task = task;
//	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
//	navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
//	[self.navigationController presentModalViewController:navigationController animated:YES];
}


#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if([self.fetchedResultsController fetchedObjects]){
        return [[self.fetchedResultsController fetchedObjects] count];
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray* tasks= [self.fetchedResultsController fetchedObjects];
    CDKTask* task=nil;
    NSArray* options = nil;
    if(tasks.count >0)
    {
        task= tasks[section];
        //if(options != nil)
        options=task.checkList;
        
    }else return 0;

    CGRect rect = _webPadButton.frame;
    
    if([options count]>0){
        if(rect.origin.y > 50){
            rect.origin.y-=50;
        }
    }else{
        
        if(rect.origin.y < 50){
            rect.origin.y+=50;
        }
    }
    [_webPadButton setFrame:rect];
    
    return [options count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *const cellIdentifier = @"cellIdentifier";
	
	CDITaskTableViewCell *cell = (CDITaskTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[CDITaskTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.attributedLabel.delegate = self;
    	[cell setEditingAction:@selector(editRow:) forTarget:self];
		[cell.checkboxButton addTarget:self action:@selector(_toggleCompletion:) forControlEvents:UIControlEventTouchUpInside];
	}
	[self configureCell:cell atIndexPath:indexPath];
	
	return cell;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CDKTask* task = [self.fetchedResultsController fetchedObjects][section];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 24)];
    [view setBackgroundColor:[UIColor colorWithRed:0.890f green:0.890f blue:0.890f alpha:1.0f]];
    
    /* Create custom view to display section header... */
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
    [label setFont:[UIFont boldCheddarFontOfSize:16]];
    [label setTextColor:[UIColor cheddarTextColor]];
    NSString *string =task.text;
    /* Section header Label*/
    [label setText:string];
    
    /*Section Header Add task Button*/
    UIButton* addButton = [[UIButton alloc]initWithFrame:CGRectMake(tableView.frame.size.width-38, 3, 30, 18)];
    [addButton setTag:section];
    [addButton setTitle:@"+" forState:UIControlStateNormal];
    [addButton setBackgroundColor:[UIColor whiteColor]];
    [addButton setTitleColor:[UIColor cheddarLightTextColor] forState:UIControlStateNormal];
    addButton.layer.cornerRadius = 8;
    addButton.clipsToBounds = YES;
    [addButton addTarget:self action:@selector(addTaskButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:addButton];
    [view addSubview:label];
    return view;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.addTaskView.textField isFirstResponder]) {
        return NO;
    }
 
    return YES;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *action = [CDISettingsTapPickerViewController selectedKey];
    
    //For now return without doing anything
    return;
    
    
	// Nothing
	if ([action isEqualToString:kCDITapActionNothingKey]) {
		return;
	}
	
	//CDKTask *task = [self objectForViewIndexPath:indexPath];
	// Complete
	if ([action isEqualToString:kCDITapActionCompleteKey]) {
		//[task toggleCompleted];
                return;
	}
	
	// Edit
	if ([action isEqualToString:kCDITapActionEditKey]) {
		//[self _editTask:task];
        return;
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Archive";
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle != UITableViewCellEditingStyleDelete) {
		return;
	}
	
    CDKTask* task=[[self fetchedResultsController]fetchedObjects][indexPath.section];
    NSMutableArray* options=[task.checkList mutableCopy];
    
    [options removeObjectAtIndex:indexPath.row];
    task.checkList = options;
    [task save];
    
    Update* update = [[Update alloc] init];
    update.updated_entity = [NSNumber numberWithInt:kCDKUpdateTask];
    update.updated_ID = task.id;
    update.type=[NSNumber numberWithInt:kCDKUpdatedItemTypeUpdated];
    [update save];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kDoUpdateNotification
     object:self userInfo: nil];
//    [self.tableView reloadData];

}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	if (sourceIndexPath.row != destinationIndexPath.row && sourceIndexPath.section == destinationIndexPath.section ) {
        self.ignoreChange = YES;
        CDKTask* task=[[self fetchedResultsController]fetchedObjects][destinationIndexPath.section];
        NSMutableArray* options = [task.checkList mutableCopy];
        
        NSMutableDictionary* sourceCheckListItem = [options[sourceIndexPath.row] mutableCopy];
        NSMutableDictionary* destinationCheckListItem = [options[destinationIndexPath.row] mutableCopy];
//        if([[checkListItem objectForKey:@"checked"]intValue] == 0)
//            [checkListItem setValue:[NSNumber numberWithInt:1] forKey:@"checked"];
//        else
//            [checkListItem setValue:[NSNumber numberWithInt:0] forKey:@"checked"];
        
        NSNumber* temp = [sourceCheckListItem objectForKey:@"num"];
        [sourceCheckListItem setValue:[destinationCheckListItem objectForKey:@"num"] forKey:@"num"];
        [destinationCheckListItem setValue:temp forKey:@"num"];
        options[destinationIndexPath.row]=sourceCheckListItem;
        options[sourceIndexPath.row]=destinationCheckListItem;
//        NSArray* newOptions = [options sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
//            NSNumber* positionA = [a objectForKey:@"num"]==[NSNull null]? [NSNumber numberWithInt:0]:[a objectForKey:@"num"];
//            NSNumber* positionB = [b objectForKey:@"num"]==[NSNull null]? [NSNumber numberWithInt:0]:[b objectForKey:@"num"];
//            if(positionA.integerValue < positionB.integerValue)
//                return NSOrderedAscending;
//            else if(positionA.integerValue > positionB.integerValue)
//                return NSOrderedDescending;
//            
//            return NSOrderedSame;
//        }];
//        options = [newOptions mutableCopy];
        task.checkList = options;
        [task save];
        
        self.ignoreChange = NO;
        
        Update* update = [[Update alloc] init];
        update.updated_entity = [NSNumber numberWithInt:kCDKUpdateTask];
        update.updated_ID = task.id;
        update.type=[NSNumber numberWithInt:kCDKUpdatedItemTypeUpdated];
        [update save];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kDoUpdateNotification
         object:self userInfo: nil];
        
    }

    [self.tableView reloadData];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 24;//[CDIAddTaskView height];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDKTask* currentTask=[[self fetchedResultsController]fetchedObjects][indexPath.section];
    NSArray* options = currentTask.checkList;
    
    NSDictionary *task = options[indexPath.row];//[self objectForViewIndexPath:indexPath];
    NSMutableDictionary* muTask = [task mutableCopy];
    NSString* name=[task objectForKey:@"name"] == [NSNull null]?@"-":[task objectForKey:@"name"];
    [muTask setValue:name forKey:@"name"];
	return [CDITaskTableViewCell cellHeightForTask:muTask width:tableView.frame.size.width];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if ([self showingCoverView]) {
		[self.addTaskView.textField resignFirstResponder];
	}
	
	[super scrollViewDidScroll:scrollView];
}


#pragma mark - CDIAddTaskViewDelegate

- (void)addTaskView:(CDIAddTaskView *)addTaskView didReturnWithTitle:(NSString *)title {
	        //CDIHUDView *hud = [[CDIHUDView alloc] initWithTitle:@"Inserting Task..." loading:YES];
            //[hud show];
            CDIAddTaskAnimationView *animation = [[CDIAddTaskAnimationView alloc] initWithFrame:self.view.bounds];
			animation.title = title;
			[self.view addSubview:animation];
			
			self.ignoreChange = YES;
			
			NSInteger numberOfRows = [self.tableView numberOfRowsInSection:selectedSection];
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:numberOfRows inSection:selectedSection];
			
			NSNumber* position = [NSNumber numberWithInteger:self.list.highestPosition + 1];
			

            TNTaskList *taskList = [[TNTaskList alloc]init];
            taskList.title = @"TaskNotes";
            NSDateFormatter * formater = [[NSDateFormatter alloc]init];
            [formater setDateFormat:kDateFormat1];
            taskList.date = [formater stringFromDate:[NSDate date]];
            taskList.subject = @"subject";
            taskList.name = [TNUserModel currentUser].user_username;
            taskList.options = @[[NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:false], @"checked",
                                  title, @"name",
                                  [NSNumber numberWithInteger:self.list.highestPosition + 1], @"num",
                                  @[], @"voters",
                                  nil],@""];
            taskList.from = [TNUserModel currentUser].user_email;
            taskList.topicId = self.list.id;
            taskList.taskType = @"checklist";
            taskList.sectionId = @"";
            taskList.order = [NSString stringWithFormat:@"%@", position];
            
			CGPoint point = CGPointZero;
			if (numberOfRows > 0) {
				CGRect rect = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows - 1 inSection:0]];
				point = rect.origin;
				point.y += rect.size.height;
			} else {
				point.y = [CDIAddTaskView height];
			}
    
    NSArray* tasks =[self.fetchedResultsController fetchedObjects];
    NSArray* options = nil;
    if([tasks count] == 0){
        
                CDKTask* task = [[CDKTask alloc] init];
                int64_t remote_id = [[NSDate date] timeIntervalSince1970];
                task.id = [NSString stringWithFormat:@"%@%lli",kCDKUpdatedItemOfflineIDPrefix,remote_id];
                task.remoteID = [NSNumber numberWithInt:remote_id];
                task.displayText = @"TaskNotes";
                task.text =@"TaskNotes";
                task.position = [NSNumber numberWithInt:0];
                task.list = self.list;
                [task setCheckList: @[[NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithBool:false], @"checked",
                                       title, @"name",
                                       [NSNumber numberWithInteger:self.list.highestPosition + 1], @"num",
                                       @[], @"voters",
                                       nil],[NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithBool:false], @"checked",
                                             [NSNull null], @"name",
                                             [NSNumber numberWithInteger:0], @"num",
                                             @[], @"voters",
                                             nil]]];
                [task save];
                
                Update* update = [[Update alloc] init];
                
                update.updated_entity = [NSNumber numberWithInt: kCDKUpdateTask];
                update.updated_ID = task.id;
                update.type= [NSNumber numberWithInt: kCDKUpdatedItemTypeAdded];
                [update save];
                
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:kDoUpdateNotification
                 object:self userInfo: nil];
                
                [animation animationToPoint:point height:self.tableView.bounds.size.height insertTask:^{
                    //self.ignoreChange = NO;
                } completion:^{
                    [animation removeFromSuperview];
                    
                    [self hideCoverView];
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:task.checkList forKey:@"options"];
                    NSLog(@"options are : %@",task.checkList);
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kTaskChangedNotification
                     object:self userInfo: userInfo];
                    
                }];
            }
            else{
                CDKTask * task = [[self fetchedResultsController]fetchedObjects][selectedSection];
                
                options = [task checkList];
                NSDictionary* lastOption = [options lastObject];
                
                if(lastOption){
                    position = [lastOption objectForKey:@"num"];
                    position = [NSNumber numberWithInt:position.intValue + 1];
                }
                
                NSMutableArray* oldOptions = [options mutableCopy];
                Boolean alreadyAdded = false;
                if(oldOptions){
                    //oldOptions = [oldOptions mutableCopy];
                    for(int k=0; k < oldOptions.count ; k++){
                        NSDictionary* option = oldOptions[k];
                        if([option objectForKey:@"name"] == [NSNull null]){
                            alreadyAdded = true;
                            oldOptions[k] = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithBool:false], @"checked", title, @"name",position, @"num",@[], @"voters",nil];
                            break;
                        }
                    }
                }
                NSArray* options=nil;
                if(!alreadyAdded){
                    if(oldOptions){
                        options = [oldOptions arrayByAddingObjectsFromArray:@[[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:false], @"checked", title, @"name",position, @"num",@[], @"voters",nil]]];
                    }else{
                        options =@[[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:false], @"checked" ,title, @"name",position, @"num",@[], @"voters",nil],@{}];
                                
                    }
                }
                else{
                    options = oldOptions;
                }
                task.checkList = [options copy];
                [task save];
                
                Update* update = [[Update alloc] init];
                update.updated_entity = [NSNumber numberWithInt:kCDKUpdateTask];
                update.updated_ID = task.id;
                update.type=[NSNumber numberWithInt:kCDKUpdatedItemTypeUpdated];
                [update save];
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:kDoUpdateNotification
                 object:self userInfo: nil];
                
                [animation animationToPoint:point height:self.tableView.bounds.size.height insertTask:^{
                    //self.ignoreChange = NO;
                } completion:^{
                    [animation removeFromSuperview];
                    [self hideCoverView];
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:task.checkList forKey:@"options"];
                    NSLog(@"options are : %@",task.checkList);
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kTaskChangedNotification
                     object:self userInfo: userInfo];
                    
                }];
                
            }
    
}


- (void)addTaskViewDidBeginEditing:(CDIAddTaskView *)addTaskView {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[self showCoverView];
	}
}


- (void)addTaskViewDidEndEditing:(CDIAddTaskView *)addTaskView {
    
    [self hideCoverView];
    if(selectedSection != 0){
        NSInteger numberOfRows = [self.tableView numberOfRowsInSection:selectedSection] - 1;
        if(numberOfRows <0)numberOfRows = 0;
        
        NSIndexPath *rowIndexPath = [NSIndexPath indexPathForRow:numberOfRows inSection:selectedSection];
    
        [self.tableView scrollToRowAtIndexPath:rowIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        selectedSection = 0;
    }

}


- (void)addTaskViewShouldCloseTags:(CDIAddTaskView *)addTaskView; {
	[self closeTags];
}


#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
	// Open tag
	if ([url.scheme isEqualToString:@"x-cheddar-tag"]) {
		CDKTag *tag = [CDKTag existingTagWithName:url.host];
		[self addTag:tag];
		return;
	}
	
	// Open browser
	if ([url.scheme.lowercaseString isEqualToString:@"http"] || [url.scheme.lowercaseString isEqualToString:@"https"]) {
		CDIWebViewController *viewController = [[CDIWebViewController alloc] init];
		[viewController loadURL:url];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
			[self.splitViewController presentViewController:navigationController animated:YES completion:nil];
		} else {
			[self.navigationController pushViewController:viewController animated:YES];
		}
		return;
	}
	
	// Open other URLs
	[[UIApplication sharedApplication] openURL:url];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		[self setEditing:NO animated:YES];
		[self.list archiveCompletedTasks];
	} else if (buttonIndex == 1) {
		[self setEditing:NO animated:YES];
		[self.list archiveAllTasks];
	}
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		return;
	}

	[self setEditing:NO animated:YES];

	if (alertView.tag == 1) {
		[self.list archiveAllTasks];
		[self setEditing:NO animated:YES];
	} else if (alertView.tag == 2) {
		[self.list archiveCompletedTasks];
	}
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	CDKTask *task = [self objectForViewIndexPath:self.editingIndexPath];
	task.text = textField.text;
	task.displayText = textField.text;
	task.entities = nil;
	[task save];
	[task update];
	
	[self endCellTextEditing];
	return NO;
}


#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context != (__bridge void *)self) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		return;
	}

	if ([keyPath isEqualToString:@"title"])
    {
//		self.title = @"Learn Tasknote";//[change objectForKey:NSKeyValueChangeNewKey];
        
        self.title = [change objectForKey:NSKeyValueChangeNewKey];
        
	} else if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad && [keyPath isEqualToString:@"archivedAt"]) {
		if ([change objectForKey:NSKeyValueChangeNewKey] != [NSNull null]) {
			[self.navigationController popToRootViewControllerAnimated:YES];
		}
	}
}

#pragma mark - NSFetchedResultsController

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [super controllerDidChangeContent:controller];
   }

-(BOOL)hasContent{
    NSArray* tasks = [self.fetchedResultsController fetchedObjects];
    return [super hasContent] ? true : [tasks count];
}

@end
