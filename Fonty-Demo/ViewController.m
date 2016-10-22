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

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[FYFontManager sharedManager] setFontURLStringArray:@[@"http://115.28.28.235:8088/SizeKnownFont.ttf",
                                                           @"http://115.28.28.235:8088/SizeUnknownFont.ttf"]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.label setFont:[UIFont fy_mainFontOfSize:24.0f]];
    [self.textField setFont:[UIFont fy_mainFontOfSize:24.0f]];
    [self.textField becomeFirstResponder];
}

- (IBAction)barButtonItemAction:(UIBarButtonItem *)sender {
    FYSelectFontViewController *vc = [[FYSelectFontViewController alloc] init];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nc animated:YES completion:nil];
}

@end
