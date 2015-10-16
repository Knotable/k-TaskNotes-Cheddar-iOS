//
//  SSTextField.m
//  SSToolkit
//
//  Created by Sam Soffes on 3/11/10.
//  Copyright 2010-2011 Sam Soffes. All rights reserved.
//

#import "SSTextField.h"
#import "SSDrawingUtilities.h"

@interface SSTextField ()
- (void)_initialize;
@end

@implementation SSTextField

#pragma mark - Accessors

@synthesize textEdgeInsets = _textEdgeInsets;
@synthesize clearButtonEdgeInsets = _clearButtonEdgeInsets;
@synthesize placeholderTextColor = _placeholderTextColor;

- (void)setPlaceholderTextColor:(UIColor *)placeholderTextColor {
	_placeholderTextColor = placeholderTextColor;
	
	if (!self.text && self.placeholder) {
		[self setNeedsDisplay];
	}
}


#pragma mark - UIView

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self _initialize];
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self _initialize];
    }
    return self;
}


#pragma mark - UITextField

- (CGRect)textRectForBounds:(CGRect)bounds {
	return UIEdgeInsetsInsetRect([super textRectForBounds:bounds], _textEdgeInsets);
}


- (CGRect)editingRectForBounds:(CGRect)bounds {
	return [self textRectForBounds:bounds];
}


- (CGRect)clearButtonRectForBounds:(CGRect)bounds {
	CGRect rect = [super clearButtonRectForBounds:bounds];
	rect = CGRectSetY(rect, rect.origin.y + _clearButtonEdgeInsets.top);
	return CGRectSetX(rect, rect.origin.x + _clearButtonEdgeInsets.right);
}


- (void)drawPlaceholderInRect:(CGRect)rect {
	if (!_placeholderTextColor) {
		[super drawPlaceholderInRect:rect];
		return;
	}
	
    [_placeholderTextColor setFill];
    
    NSLog(@"%@", NSStringFromCGRect(rect));
    
    CGRect customRect = rect;
    
    NSLog(@"%@", self.placeholder);
    
//    if (customRect.size.height > self.placeholder)
//    {
//        customRect.origin.y = 11;
//    }
//    else if (customRect.size.height == 41)
//    {
//        customRect.origin.y = 9;
//    }

    customRect.origin.y = rect.origin.y + ((rect.size.height - self.font.pointSize) / 2) ;
    
    NSLog(@"%f",self.font.pointSize);
    
    [self.placeholder drawInRect:customRect withFont:self.font lineBreakMode:UILineBreakModeTailTruncation alignment:self.textAlignment];
}


#pragma mark - Private

- (void)_initialize {
	_textEdgeInsets = UIEdgeInsetsZero;
	_clearButtonEdgeInsets = UIEdgeInsetsZero;
}

@end
