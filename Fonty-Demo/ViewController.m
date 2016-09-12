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

@property (nonatomic, weak) UILabel *label;
@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[FYFontManager sharedManager] setFontURLStringArray:@[@"http://115.28.28.235:8080/xx.ttf",
                                                           @"http://www.zhaozi.cn/e/enews/?enews=DownSoft&classid=297&id=22785&pathid=0&pass=6a9c20be7abab75c8128ada2c271b041&p=:::"]];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 50.0f, 300.0f, 50.0f)];
    label.text = @"汉字";
    [self.view addSubview:label];
    self.label = label;
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    button1.tag = 1;
    button1.frame = CGRectMake(10.0f, 100.0f, 300.0f, 20.0f);
    [button1 setTitle:@"Fonty" forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.label setFont:[UIFont fy_mainFontOfSize:20.0f]];
}

- (void)buttonAction:(UIButton *)sender {
    FYSelectFontViewController *vc = [[FYSelectFontViewController alloc] init];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nc animated:YES completion:nil];
}

@end
