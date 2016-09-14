//
//  ViewController.m
//  Fonty-Demo
//
//  Created by 颜为晨 on 9/12/16.
//  Copyright © 2016 s2mh. All rights reserved.
//

#import "ViewController.h"
#import "FYSelectFontViewController.h"
#import "FYHeader.h"
#import "UIFont+FY_Fonty.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[FYFontManager sharedManager] setFontURLStringArray:@[@"http://115.28.28.235:8080/xx.ttf",
                                                           @"http://www.zhaozi.cn/e/enews/?enews=DownSoft&classid=297&id=22785&pathid=0&pass=6a9c20be7abab75c8128ada2c271b041&p=:::"]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.label setFont:[UIFont fy_mainFontOfSize:23.0f]];
}

- (IBAction)barButtonItemAction:(UIBarButtonItem *)sender {
    FYSelectFontViewController *vc = [[FYSelectFontViewController alloc] init];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nc animated:YES completion:nil];
}

@end
