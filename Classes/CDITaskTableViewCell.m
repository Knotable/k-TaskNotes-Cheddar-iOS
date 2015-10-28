//
//  CDITaskTableViewCell.m
//  Cheddar for iOS
//
//  Created by Sam Soffes on 4/5/12.
//  Copyright (c) 2012 Nothing Magical. All rights reserved.
//

#import "CDITaskTableViewCell.h"
#import "CDIAttributedLabel.h"
#import "CDICheckboxButton.h"
#import "UIColor+CheddariOSAdditions.h"
#import "UIFont+CheddariOSAdditions.h"
#import "CDKTask+CheddariOSAdditions.h"
#import "CDISettingsTextSizePickerViewController.h"

@interface CDITaskTableViewCell ()
- (void)_updateAttributedText;
@end

@implementation CDITaskTableViewCell {
	UIImageView *_checkmark;
}

@synthesize task = _task;
@synthesize attributedLabel = _attributedLabel;
@synthesize checkboxButton = _checkboxButton;


- (void)setTask:(NSDictionary *)task {
	_task = task;
	/*
     {
        checked = 0;
        name = pol;
        num = 3;
        voters =             (
     );
     }
     */
    
	if ([[_task objectForKey:@"checked"]boolValue]) {
		_attributedLabel.textColor = [UIColor cheddarLightTextColor];
		_checkmark.hidden = NO;
		_attributedLabel.linkAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
										   (id)[UIColor colorWithWhite:0.45f alpha:1.0f].CGColor, (NSString *)kCTForegroundColorAttributeName,
										   nil];
	} else {
		_attributedLabel.textColor = [UIColor cheddarTextColor];
		_checkmark.hidden = YES;
		_attributedLabel.linkAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
										   (id)[UIColor cheddarBlueColor].CGColor, (NSString *)kCTForegroundColorAttributeName,
										   nil];
	}

	[self _updateAttributedText];
}


#pragma mark - Class Methods

+ (CGFloat)cellHeightForTask:(NSDictionary *)task width:(CGFloat)width {
	static TTTAttributedLabel *label = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
		label.numberOfLines = 0;
	});
	label.font = [UIFont cheddarFontOfSize:18.0f];
	label.text = [task objectForKey:@"name"] == [NSNull null]?@"-":[task objectForKey:@"name"];
	
    
    
    CGSize size = CGSizeMake(width - 60.0f, 2000.0f);
	
//    if (self.editing){
//        size = CGSizeMake(width - 60.0f, 2000.0f);
//        
//    }else{
//        size = CGSizeMake(width - 60.0f, 2000.0f);
//        
//    }
    CGSize maximumLabelSize = size;
    if (SYSTEM_VERSION_LESS_THAN(iOS7_0)) {
        //version < 7.0
        
        maximumLabelSize= [label.text sizeWithFont:label.font
                            constrainedToSize:CGSizeMake(size.width, MAXFLOAT)
                                lineBreakMode:NSLineBreakByWordWrapping];
    }
    else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(iOS7_0)) {
        //version >= 7.0
        
        //Return the calculated size of the Label
        maximumLabelSize= [label.text boundingRectWithSize:CGSizeMake(size.width, MAXFLOAT)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{
                                                        NSFontAttributeName : label.font
                                                        }
                                              context:nil].size;
        
    }
    else{
        maximumLabelSize= [label bounds].size;
    }
    
    
    
    
    
    
    
	CGFloat offset = ([CDISettingsTextSizePickerViewController fontSizeAdjustment] * 2.0f) - 1.0f;
    return (maximumLabelSize.height + 27.0f );//- offset);
}


#pragma mark - UITableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier])) {
		self.textLabel.hidden = YES;
		
		_checkboxButton = [[CDICheckboxButton alloc] initWithFrame:CGRectZero];
		_checkboxButton.tableViewCell = self;
		[self.contentView addSubview:_checkboxButton];
		
		_checkmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"small-check"]];
		_checkmark.hidden = YES;
		[self.contentView addSubview:_checkmark];
		
		_attributedLabel = [[CDIAttributedLabel alloc] initWithFrame:CGRectZero];
		_attributedLabel.textColor = [UIColor cheddarTextColor];
		_attributedLabel.backgroundColor = [UIColor clearColor];
		_attributedLabel.numberOfLines = 0;
		_attributedLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
		[self updateFonts];
		[self.contentView addSubview:_attributedLabel];
		
		self.contentView.clipsToBounds = YES;
	}
	return self;
}


- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGSize size = self.contentView.bounds.size;
	CGFloat offset = ([CDISettingsTextSizePickerViewController fontSizeAdjustment] * 2.0f) - 1.0f;
	CGFloat textYOffset = roundf(offset / 2.0f);

	if (self.editing) { // TODO: Only match reordering and not swipe to delete
		_checkboxButton.frame = CGRectMake(-34.0f, (size.height/2 - 24/2)/* 13.0f + offset*/, 24.0f, 24.0f);
		_checkmark.frame = CGRectMake(-30.0f,(size.height/2 - 18/2)/* 16.0f + offset*/, 22.0f, 18.0f);
		_attributedLabel.frame = CGRectMake(12.0f,(size.height/2 - (size.height  -24 )/2)/* 13.0f + textYOffset*/, size.width - 20.0f, size.height  -20 );
	} else {
		_checkboxButton.frame = CGRectMake(10.0f, (size.height/2 - 24/2)/* 13.0f + offset*/, 24.0f, 24.0f);
		_checkmark.frame = CGRectMake(12.0f, (size.height/2 - 18/2)/* 16.0f + offset*/, 22.0f, 18.0f);
		_attributedLabel.frame = CGRectMake(44.0f, (size.height/2 - (size.height  -24)/2)/* 13.0f + textYOffset*/, size.width - 54.0f, size.height  -20);
	}
}


#pragma mark - UITableViewCell

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	
	void (^change)(void) = ^{
		_checkboxButton.alpha = editing ? 0.0f : 1.0f;
		_checkmark.alpha = _checkboxButton.alpha;
	};
	
	if (animated) {
		[UIView animateWithDuration:0.18 delay:0.0 options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction animations:change completion:nil];
	} else {
		change();
	}
}


- (void)prepareForReuse {
	[super prepareForReuse];
	self.task = nil;
}


#pragma mark - CDITableViewCell

- (void)updateFonts {
	[super updateFonts];
	_attributedLabel.font = [UIFont cheddarFontOfSize:18.0f];
	[self _updateAttributedText];
}


#pragma Private

- (void)_updateAttributedText {
	__weak NSDictionary *task = _task;
	[_attributedLabel setText:[task objectForKey:@"name"] afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
		//[task addEntitiesToAttributedString:mutableAttributedString];
		return mutableAttributedString;
	}];

	// Add links
//	for (NSDictionary *entity in _task.entities) {
//		NSArray *indices = [entity objectForKey:@"display_indices"];
//		NSRange range = NSMakeRange([[indices objectAtIndex:0] unsignedIntegerValue], 0);
//		range.length = [[indices objectAtIndex:1] unsignedIntegerValue] - range.location;
//		range = [_attributedLabel.text composedRangeWithRange:range];
//
//		NSString *type = [entity objectForKey:@"type"];
//
//		// Tag
//		if ([type isEqualToString:@"tag"]) {
//			NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"x-cheddar-tag://%@", [entity objectForKey:@"tag_name"]]];
//			[_attributedLabel addLinkToURL:url withRange:range];
//		}
//
//		// Link
//		else if ([type isEqualToString:@"link"]) {
//			NSURL *url = [NSURL URLWithString:[entity objectForKey:@"url"]];
//			[_attributedLabel addLinkToURL:url withRange:range];
//		}
//	}
}

@end
