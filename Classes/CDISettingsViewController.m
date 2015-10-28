//
//  CDISettingsViewController.m
//  Tasknotes for iOS
//
//  Created by Sam Soffes on 4/20/12.
//  Copyright (c) 2012 Nothing Magical. All rights reserved.
//

#import "CDISettingsViewController.h"
#import "CDIUpgradeViewController.h"
#import "CDIGroupedTableViewCell.h"
#import "CDIHUDView.h"
#import "UIColor+CheddariOSAdditions.h"
#import "UIButton+CheddariOSAdditions.h"
#import "UIFont+CheddariOSAdditions.h"
#import "CDIAppDelegate.h"
#import "CDISplitViewController.h"
#import "CDIListsViewController.h"
#import "CDISettingsTextSizePickerViewController.h"
#import "CDISettingsFontPickerViewController.h"
#import "CDISettingsTapPickerViewController.h"
#import "CDIWebViewController.h"

NSString *const kCDIFontDidChangeNotificationName = @"CDIFontDidChangeNotification";

@interface CDISettingsViewController ()
@property (nonatomic, strong) SSLabel *upgradeLabel;
@property (nonatomic, strong) UIButton *upgradeButton;
@end

@implementation CDISettingsViewController

@synthesize upgradeLabel = _upgradeLabel;

- (SSLabel *)upgradeLabel {
	if (!_upgradeLabel) {
		_upgradeLabel = [[SSLabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 60.0f)];
		_upgradeLabel.font = [UIFont cheddarInterfaceFontOfSize:14.0f];
		_upgradeLabel.backgroundColor = [UIColor clearColor];
		_upgradeLabel.textAlignment = NSTextAlignmentCenter;
		_upgradeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_upgradeLabel.numberOfLines = 2;
		_upgradeLabel.textEdgeInsets = UIEdgeInsetsMake(4.0f, 10.0f, 0.0f, 10.0f);
		_upgradeLabel.verticalTextAlignment = SSLabelVerticalTextAlignmentTop;
		_upgradeLabel.textColor = [UIColor cheddarOrangeColor];
		_upgradeLabel.userInteractionEnabled = YES;
	}
	return _upgradeLabel;
}


- (UIButton *)upgradeButton {
	if (!_upgradeButton) {
		_upgradeButton = [UIButton cheddarBigOrangeButton];
		_upgradeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		_upgradeButton.frame = CGRectMake(roundf((self.view.frame.size.width - 300.0f) / 2.0f), 6.0f, 300.0f, 42.0f);
		[_upgradeButton setTitle:@"Upgrade to Plus" forState:UIControlStateNormal];
		[_upgradeButton addTarget:self action:@selector(upgrade:) forControlEvents:UIControlEventTouchUpInside];
//		[self.upgradeLabel addSubview:_upgradeButton];
	}
	return _upgradeButton;
}


#pragma mark - NSObject

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    self.meteor = [CDIAppDelegate sharedAppDelegate].meteorClient;
	[super viewDidLoad];
	self.title = @"Settings";
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(close:)];
    [doneButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = doneButton;
	
	SSLabel *footer = [[SSLabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 33.0f)];
	footer.backgroundColor = [UIColor clearColor];
	footer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    footer.textAlignment = NSTextAlignmentCenter;
	footer.textColor = [UIColor cheddarLightTextColor];
	footer.font = [UIFont cheddarInterfaceFontOfSize:14.0f];
	footer.text = [NSString stringWithFormat:@"Version %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
	footer.shadowColor = [UIColor whiteColor];
	footer.shadowOffset = CGSizeMake(0.0f, 1.0f);
	footer.verticalTextAlignment = SSLabelVerticalTextAlignmentTop;
	self.tableView.tableFooterView = footer;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateUI) name:kCDKPlusDidChangeNotificationName object:nil];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self _updateUI];
	[self.tableView reloadData];
}


#pragma mark - Actions

- (void)close:(id)sender {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (void)upgrade:(id)sender {
	UIViewController *viewController = [[CDIUpgradeViewController alloc] init];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self.navigationController presentViewController:navigationController animated:YES completion:nil];
}


- (void)signOut:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sign Out" message:@"Are you sure you want to sign out of Tasknotes?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Sign Out", nil];
	[alert show];
}


#pragma mark - Private

- (void)_updateUI {
	CDKUser *user = [CDKUser currentUser];
	if (user.hasPlus.boolValue) {
		self.upgradeLabel.text = @"You have Tasknotes Plus and we really love you for that.";
		_upgradeButton.alpha = 0.0f;
	} else {
		self.upgradeLabel.text = @"";
		self.upgradeButton.alpha = 1.0f;
	}
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex != 1) {
		return;
	}
	// Sign out
    [TNUserModel setCurrentUser:nil];
    [self.meteor logout];
    [CDIAppDelegate sharedAppDelegate].isFirstLaunch = NO;
    //	[CDKUser setCurrentUser:nil];
//	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//	[userDefaults removeObjectForKey:kCDISelectedListKey];
//	[userDefaults synchronize];
	CDIAppDelegate *appDelegate = [CDIAppDelegate sharedAppDelegate];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		appDelegate.window.rootViewController = [[CDISplitViewController alloc] init];
	} else {
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[CDIListsViewController alloc] init]];
		appDelegate.window.rootViewController = navigationController;
	}
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 5;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Account
	if (section == 0) {
		return 1;
	}

    // Sign out
    else if (section == 1) {
        return 1;
    }
    
    
	// Display
	else if (section == 2) {
		return 2;
	}

	// Tasks
	else if (section == 3) {
		return 1;
	}

	// About and Support
	else if (section == 4) {
		return 2;
	}

	
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"None";
	NSUInteger numberOfRows = [tableView numberOfRowsInSection:indexPath.section];
	if (numberOfRows == 1) {
		cellIdentifier = @"Both";
	} else if (indexPath.row == 0) {
		cellIdentifier = @"Top";
	} else if (indexPath.row == numberOfRows - 1) {
		cellIdentifier = @"Bottom";
	}
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[CDIGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	// Account
	if (indexPath.section == 0) {
		cell.textLabel.text = @"Manage Account";
		cell.detailTextLabel.text = nil;
	}
    
    // Sign out
    else if (indexPath.section == 1) {
        cell.textLabel.text = @"Sign Out";
        cell.detailTextLabel.text = nil;
    }
    
	// Display
	else if (indexPath.section == 2) {
		if (indexPath.row == 0) {
			cell.textLabel.text = @"Text Size";
			cell.detailTextLabel.text = [CDISettingsTextSizePickerViewController textForSelectedKey];
		} else if (indexPath.row == 1) {
			cell.textLabel.text = @"Font";
			cell.detailTextLabel.text = [CDISettingsFontPickerViewController textForSelectedKey];
		}
	}
	
	// Tasks
	else if (indexPath.section == 3) {
		if (indexPath.row == 0) {
			cell.textLabel.text = @"Tap Action";
			cell.detailTextLabel.text = [CDISettingsTapPickerViewController textForSelectedKey];
		}
	}
	
	// About and Support
	else if (indexPath.section == 4) {
		if (indexPath.row == 0) {
			cell.textLabel.text = @"About";
			cell.detailTextLabel.text = nil;
		} else if (indexPath.row == 1) {
			cell.textLabel.text = @"Get Help";
			cell.detailTextLabel.text = nil;
		}
	}


	return cell;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if (section != 0) {
		return nil;
	}

	return self.upgradeLabel;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if (section != 0) {
		return 0.0f;
	}

	return 0.0f;//60
}


#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return @"Account";
	} else if (section == 2) {
		return @"Display";
	} else if (section == 3) {
		return @"Tasks";
	}
	return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController *viewController = nil;

	// Account
	if (indexPath.section == 0) {
		CDIWebViewController *viewController = [[CDIWebViewController alloc] init];
#if K_SERVER_DEV
        [viewController loadURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://dev.knotable.com/profile/%@",[CDKUser currentUser].remoteID ]]];
#elif K_SERVER_STAGING

        [viewController loadURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://staging.knotable.com/profile/%@",[CDKUser currentUser].remoteID ]]];

#elif K_SERVER_BETA
        [viewController loadURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://beta.knotable.com/profile/%@",[CDKUser currentUser].remoteID ]]];

#endif

		[self.navigationController pushViewController:viewController animated:YES];
		return;
	}
    
    
    // Sign out
    else if (indexPath.section == 1) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self signOut:nil];
        return;
    }
    

	// Display
	else if (indexPath.section == 2) {
		// Text Size
		if (indexPath.row == 0) {
			viewController = [[CDISettingsTextSizePickerViewController alloc] init];
		}
		
		// Font
		else if (indexPath.row == 1) {
			viewController = [[CDISettingsFontPickerViewController alloc] init];
		}
	}
	
	// Tasks
	else if (indexPath.section == 3) {
		// Tap Action
		if (indexPath.row == 0) {
			viewController = [[CDISettingsTapPickerViewController alloc] init];
		}
	}
	
	// Support and About
	else if (indexPath.section == 4) {
		// About
		if (indexPath.row == 0) {
			CDIWebViewController *viewController = [[CDIWebViewController alloc] init];
			[viewController loadURL:[[NSBundle mainBundle] URLForResource:@"About" withExtension:@"html"]];
			[self.navigationController pushViewController:viewController animated:YES];
			return;
		}

		// Support
		else if (indexPath.row == 1) {
			CDIWebViewController *viewController = [[CDIWebViewController alloc] init];
#if K_SERVER_DEV
            [viewController loadURL:[NSURL URLWithString:@"http://dev.knotable.com"]];
#elif K_SERVER_STAGING
            [viewController loadURL:[NSURL URLWithString:@"http://staging.knotable.com"]];
            
#elif K_SERVER_BETA
            [viewController loadURL:[NSURL URLWithString:@"http://beta.knotable.com"]];
            
#endif
      		[self.navigationController pushViewController:viewController animated:YES];
			return;
		}
	}

	

	if (viewController) {
		[self.navigationController pushViewController:viewController animated:YES];
	}
}

@end
