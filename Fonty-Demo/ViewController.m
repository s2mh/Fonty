//
//  ViewController.m
//  Fonty-Demo
//
//  Created by 颜为晨 on 9/12/16.
//  Copyright © 2016 s2mh. All rights reserved.
//

#import "ViewController.h"
#import <objc/message.h>
#import "FYSelectFontViewController.h"
#import "FYFontManager.h"

static const CGFloat FontSize = 17.0f;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray<NSString *> *sectionHeaderTitleArray;

@property (strong, nonatomic) NSArray<NSString *> *UIFontSelectorStringArray;
@property (strong, nonatomic) NSArray<NSString *> *UIFontCategorySelectorStringArray;
@property (strong, nonatomic) NSArray<NSString *> *FYFontManagerSelectorStringArray;

@property (strong, nonatomic) NSArray<NSArray *> *arrayContainer;

@end

@implementation ViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    self.arrayContainer = @[self.UIFontSelectorStringArray = @[@"systemFontOfSize:",
                                                               @"boldSystemFontOfSize:",
                                                               @"italicSystemFontOfSize:"],
                            self.UIFontCategorySelectorStringArray = @[@"fy_mainFontOfSize:",
                                                                       @"fy_mainBoldFontOfSize:",
                                                                       @"fy_mainItalicFontOfSize:"],
                            self.FYFontManagerSelectorStringArray = @[@"mainFontOfSize:",
                                                                      @"mainBoldFontOfSize:",
                                                                      @"mainItalicFontOfSize:",
                                                                      @"UIFontSystemFontOfSize:",
                                                                      @"UIFontBoldSystemFontOfSize:",
                                                                      @"UIFontItalicSystemFontOfSize:"]];
    
    self.sectionHeaderTitleArray = @[@"UIFont Selectors",
                                     @"UIFont (FY_Fonty) Selectors",
                                     @"FYFontManager Selectors"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.arrayContainer.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrayContainer[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray<NSString *> *selectStringArray = self.arrayContainer[indexPath.section];
    NSString *selectorString = selectStringArray[indexPath.row];
    SEL selector = NSSelectorFromString(selectorString);
    id reciever = nil;
    if (selectStringArray == self.FYFontManagerSelectorStringArray) {
        reciever = [FYFontManager class];
    } else {
        reciever = [UIFont class];
    }
    UIFont *font = ((UIFont *(*)(id, SEL, CGFloat)) objc_msgSend)(reciever, selector, FontSize);
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.font = font;
    cell.textLabel.text = [NSString stringWithFormat:@"%@ 是这样的", selectorString];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionHeaderTitleArray[section];
}

#pragma mark - Action

- (IBAction)barButtonItemAction:(UIBarButtonItem *)sender {
    FYSelectFontViewController *vc = [[FYSelectFontViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nc animated:YES completion:nil];
}

@end
