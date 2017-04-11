//
//  ViewController.m
//  Fonty-Demo
//
//  Created by 颜为晨 on 9/12/16.
//  Copyright © 2016 s2mh. All rights reserved.
//

#import <objc/message.h>

#import "ViewController.h"
#import "FYSelectFontViewController.h"

#import "Fonty.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *exampleTextView;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.exampleTextView.font = [UIFont fy_mainFontWithSize:11.0f];
}

#pragma mark - Action

- (IBAction)barButtonItemAction:(UIBarButtonItem *)sender {
    FYSelectFontViewController *vc = [[FYSelectFontViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nc animated:YES completion:nil];
}

@end
