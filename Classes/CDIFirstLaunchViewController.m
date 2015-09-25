//
//  CDIFirstLaunchViewController.m
//  Cheddar for iOS
//
//  Created by MAC OS on 9/25/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import "CDIFirstLaunchViewController.h"
#import "CDIListsViewController.h"
@interface CDIFirstLaunchViewController ()<UIGestureRecognizerDelegate>

@end

@implementation CDIFirstLaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"firstlauch"]]];
    UIImageView *k_image = [[UIImageView alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2 - 100, 100, 200, 200)];
    k_image.image = [UIImage imageNamed:@"k_image"];
    [self.view addSubview:k_image];
    
    UILabel *wellcome = [[UILabel alloc]initWithFrame:CGRectMake(5, k_image.frame.size.height+k_image.frame.origin.y + 5, self.view.frame.size.width - 10, 120)];
    [wellcome setText:@"This app lets you manage some tasks and sync them with Knotable."];
    [wellcome setFont:[UIFont fontWithName:@"Avenir" size:20]];
    [wellcome setTextColor:[UIColor whiteColor]];
    wellcome.lineBreakMode = NSLineBreakByWordWrapping;
    wellcome.numberOfLines = 0;
    wellcome.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:wellcome];
    
    UILabel *signUpGo = [[UILabel alloc]initWithFrame:CGRectMake(5, self.view.frame.size.height - 30, self.view.frame.size.width - 10, 30)];
    [signUpGo setText:@"Tap the screen to go Sign Up"];
    [signUpGo setFont:[UIFont fontWithName:@"Avenir" size:17]];
    [signUpGo setTextColor:[UIColor whiteColor]];
    signUpGo.lineBreakMode = NSLineBreakByWordWrapping;
    signUpGo.numberOfLines = 0;
    signUpGo.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:signUpGo];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(signUpview:)];
    [tap setDelegate:self];
    tap.cancelsTouchesInView = NO;
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)signUpview:(UITapGestureRecognizer *)sender
{
    CDIListsViewController *controller = [[CDIListsViewController alloc]init];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
