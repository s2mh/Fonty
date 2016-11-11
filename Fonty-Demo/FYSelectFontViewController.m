//
//  FYSelectFontViewController.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import "FYSelectFontViewController.h"

#import "FYSelectFontTableViewCell.h"

#import "FYHeader.h"
#import "UIFont+FY_Fonty.h"

@interface FYSelectFontViewController ()

@property (nonatomic, strong) NSArray<NSArray *> *fontArrayContainer;
@property (nonatomic, strong) NSArray<NSString *> *sectionHeaderTitleArray;
@property (nonatomic, assign) NSInteger maxArrayCount;

@end

@implementation FYSelectFontViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (!self) {
        return nil;
    }
    self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.title = @"Fonty";
    [self setupBarItems];
    
    _fontArrayContainer = @[FYFontManager.fontModelArray,
                            FYFontManager.boldFontModelArray,
                            FYFontManager.italicFontModelArray];
    _sectionHeaderTitleArray = @[@"FONT",
                                 @"BOLD FONT",
                                 @"ITALIC FONT"];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.toolbarHidden = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelection = YES;
    [self.tableView registerClass:[FYSelectFontTableViewCell class] forCellReuseIdentifier:@"FYSelectFontTableViewCell"];
    [self setupSelection];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noticeDownload:)
                                                 name:FYFontStatusNotification
                                               object:nil];
    
    self.maxArrayCount = MAX(FYFontManager.fontModelArray.count,
                             MAX(FYFontManager.boldFontModelArray.count,
                                 FYFontManager.italicFontModelArray.count));
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [FYFontManager saveSettins];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self setupSelection];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fontArrayContainer.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fontArrayContainer[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = self.fontArrayContainer[indexPath.section][indexPath.row];
    FYSelectFontTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FYSelectFontTableViewCell" forIndexPath:indexPath];
    [self assembleCell:cell withModel:model];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = self.fontArrayContainer[indexPath.section][indexPath.row];
    return (model.status == FYFontModelDownloadStatusDownloaded);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        FYFontModel *model = self.fontArrayContainer[indexPath.section][indexPath.row];
        [FYFontManager deleteFontWithURL:model.downloadURL];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionHeaderTitleArray[section];
}

#pragma mark UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = self.fontArrayContainer[indexPath.section][indexPath.row];
    if (model.status == FYFontModelDownloadStatusDownloaded) {
        switch (indexPath.section) {
            case 0:
                FYFontManager.mainFontIndex = indexPath.row;
                break;
            case 1:
                FYFontManager.mainBoldFontIndex = indexPath.row;
                break;
            case 2:
                FYFontManager.mainItalicFontIndex = indexPath.row;
                break;
        }
        [self deselectRowsInSection:indexPath.section];
        return indexPath;
    } else if (model.status == FYFontModelDownloadStatusDownloading) {
        [FYFontManager pauseDownloadingWithURL:model.downloadURL];
    } else if (model.status == FYFontModelDownloadStatusSuspending) {
        [FYFontManager downloadFontWithURL:model.downloadURL];
    } else if (model.status == FYFontModelDownloadStatusToBeDownloaded) {
        UIAlertView *AV = [[UIAlertView alloc] initWithTitle:@"Download Font File From"
                                                     message:model.downloadURL.absoluteString
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Start", nil];
        AV.tag = ((indexPath.section * self.maxArrayCount) + indexPath.row);
        [AV show];
    }
    return nil;
}

- (nullable NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = self.fontArrayContainer[indexPath.section][indexPath.row];
    if (model.status == FYFontModelDownloadStatusDownloaded) {
        switch (indexPath.section) {
            case 0: if (FYFontManager.mainFontIndex == indexPath.row)       return nil;
            case 1: if (FYFontManager.mainBoldFontIndex == indexPath.row)   return nil;
            case 2: if (FYFontManager.mainItalicFontIndex == indexPath.row) return nil;
        }
    }
    return indexPath;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Clear";
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = self.fontArrayContainer[indexPath.section][indexPath.row];
    if (model.status == FYFontModelDownloadStatusDownloaded) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSInteger section = alertView.tag / self.maxArrayCount;
        NSInteger row = alertView.tag % self.maxArrayCount;
        FYFontModel *model = self.fontArrayContainer[section][row];
        [FYFontManager downloadFontWithURL:model.downloadURL];
    }
}

#pragma mark - Notification

- (void)noticeDownload:(NSNotification *)notification {
    FYFontModel *newModel = [notification.userInfo objectForKey:FYFontStatusNotificationKey];
    NSInteger targetSection = 0;
    switch (newModel.type) {
        case FYFontTypeFont:        targetSection = 0; break;
        case FYFontTypeBoldFont:    targetSection = 1; break;
        case FYFontTypeItalicFont:  targetSection = 2; break;
    }
    NSArray<FYFontModel *> *targetFontArray = self.fontArrayContainer[targetSection];
    NSInteger targetRow = [targetFontArray indexOfObject:newModel];
    
    if (newModel.status == FYFontModelDownloadStatusToBeDownloaded) {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:targetRow inSection:targetSection]]
                              withRowAnimation:UITableViewRowAnimationNone];
        [self setupSelection];
    } else {
        // "Reloading a row causes the table view to ask its data source for a new cell for that row. " --> upset the downloading animation
        for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
            if (indexPath.section == targetSection && indexPath.row == targetRow) {
                FYSelectFontTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                [self assembleCell:cell withModel:newModel];
                [cell setNeedsLayout];
                break;
            }
        }
    }
}

#pragma mark - Action 

- (void)switchChangeValue:(UISwitch *)sw {
    FYFontManager.usingFontyStyle = sw.isOn;
}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)setupBarItems {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(backAction)];
    
    UISwitch *styleSwitch = [[UISwitch alloc] init];
    [styleSwitch setOn:FYFontManager.isUsingFontyStyle];
    [styleSwitch addTarget:self action:@selector(switchChangeValue:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithCustomView:styleSwitch];
    [bbi setPossibleTitles:[NSSet setWithObject:@"possibleTitles"]];
    self.toolbarItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
                          [[UIBarButtonItem alloc] initWithTitle:@"Use Fonty Style ->"
                                                           style:UIBarButtonItemStylePlain
                                                          target:nil
                                                          action:NULL],
                          [[UIBarButtonItem alloc] initWithCustomView:styleSwitch]];
}

- (void)setupSelection {
    if (FYFontManager.fontModelArray.count) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:FYFontManager.mainFontIndex inSection:0]
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
    }
    if (FYFontManager.boldFontModelArray.count) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:FYFontManager.mainBoldFontIndex inSection:1]
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
    }
    if (FYFontManager.italicFontModelArray.count) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:FYFontManager.mainItalicFontIndex inSection:2]
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)assembleCell:(FYSelectFontTableViewCell *)cell withModel:(FYFontModel *)model {
    cell.textLabel.text = model.description;
    cell.textLabel.font = [UIFont fy_fontWithURL:model.downloadURL size:16.0f];
    cell.detailTextLabel.text = nil;
    
    cell.downloadProgress = model.downloadProgress;
    cell.striped = NO;
    cell.pauseStripes = NO;
    
    if (model.status == FYFontModelDownloadStatusToBeDownloaded) {
        if (model.downloadError) {
            cell.detailTextLabel.text = model.downloadError.localizedDescription;
        }
    } else if (model.status == FYFontModelDownloadStatusDownloading) {
        cell.striped = model.fileSizeUnknown;
    } else if (model.status == FYFontModelDownloadStatusSuspending) {
        cell.striped = model.fileSizeUnknown;
        cell.pauseStripes = YES;
    }
    if (model.fileSize > 0.0f) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"size: %.2fM", model.fileSize / 1000000.0f];
    }
}

- (void)deselectRowsInSection:(NSInteger)section {
    for (NSIndexPath *selectedIndexPath in [self.tableView indexPathsForSelectedRows]) {
        if (section == selectedIndexPath.section) {
            [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
            break;
        }
    }
}

@end
