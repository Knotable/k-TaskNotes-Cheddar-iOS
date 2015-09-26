//
//  CDIFirstLaunchViewController.m
//  Cheddar for iOS
//
//  Created by MAC OS on 9/25/15.
//  Copyright (c) 2015 Nothing Magical. All rights reserved.
//

#import "CDIFirstLaunchViewController.h"
#import "CDIListsViewController.h"
@interface CDIFirstLaunchViewController ()<UIGestureRecognizerDelegate>{
    BOOL isLandscape;
}
@property (nonatomic, strong) UILabel* wellcome,*signUpGo;
@property (nonatomic, strong) UIImageView *k_image;
@end

@implementation CDIFirstLaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"firstlauch"]]];
    [self initUI];
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft || [[UIDevice currentDevice] orientation ]== UIDeviceOrientationLandscapeRight)
    {
        NSLog(@"Lanscapse");
        isLandscape = YES;
    }
    if([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait || [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown )
    {
        NSLog(@"UIDeviceOrientationPortrait");
        isLandscape = NO;
        
    }
    [_k_image removeFromSuperview];
    [_wellcome removeFromSuperview];
    [_signUpGo removeFromSuperview];
    [self initUI];
}

-(void)initUI{
    _k_image = [[UIImageView alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2 - 100, isLandscape?30:50, 200, 200)];
    _k_image.image = [UIImage imageNamed:@"k_image"];
    [self.view addSubview:_k_image];
    
    _wellcome = [[UILabel alloc]initWithFrame:CGRectMake(5, _k_image.frame.size.height+_k_image.frame.origin.y - 15, self.view.frame.size.width - 10, 120)];
    [_wellcome setText:@"This app lets you manage some tasks and sync them with Knotable."];
    [_wellcome setFont:[UIFont fontWithName:@"Avenir" size:20]];
    [_wellcome setTextColor:[UIColor whiteColor]];
    _wellcome.lineBreakMode = NSLineBreakByWordWrapping;
    _wellcome.numberOfLines = 0;
    _wellcome.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_wellcome];
    
    _signUpGo = [[UILabel alloc]initWithFrame:CGRectMake(5, self.view.frame.size.height - 30, self.view.frame.size.width - 10, 30)];
    [_signUpGo setText:@"Tap the screen to go Sign Up"];
    [_signUpGo setFont:[UIFont fontWithName:@"Avenir" size:17]];
    [_signUpGo setTextColor:[UIColor whiteColor]];
    _signUpGo.lineBreakMode = NSLineBreakByWordWrapping;
    _signUpGo.numberOfLines = 0;
    _signUpGo.textAlignment = NSTextAlignmentCenter;
    
//    [self.view addSubview:_signUpGo];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FIRST_LAUNCH"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    CDIListsViewController *controller = [[CDIListsViewController alloc]init];
    [self.navigationController pushViewController:controller animated:YES];
    
    
}
@end
