//
//  CDITableViewCell.h
//  Cheddar for iOS
//
//  Created by Sam Soffes on 3/31/12.
//  Copyright (c) 2012 Nothing Magical. All rights reserved.
//

@interface CDITableViewCell : UITableViewCell
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
#define iOS7_0 @"7.0"

@property (nonatomic, strong, readonly) SSTextField *textField;
@property (nonatomic, assign) BOOL editingText;

+ (CGFloat)cellHeight;

- (void)setEditingAction:(SEL)editAction forTarget:(id)target;
- (void)updateFonts;

@end
