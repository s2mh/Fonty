//
//  FYSelectFontViewController.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import "FYSelectFontViewController.h"

#import "FYSelectFontTableViewCell.h"

#import "FYFontManager.h"
#import "UIFont+FY_Fonty.h"

@interface FYSelectFontViewController ()

//@property (nonatomic, strong) NSArray<NSArray *> *fontArrayContainer;
//@property (nonatomic, strong) NSArray<NSString *> *sectionHeaderTitleArray;
//@property (nonatomic, assign) NSInteger maxArrayCount;

@property (copy, nonatomic) NSArray<FYFontFile *> *fontFiles;

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
    
    self.fontFiles = [FYFontManager fontFiles];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.navigationController.toolbarHidden = NO;
//    self.tableView.allowsMultipleSelectionDuringEditing = YES;
//    self.tableView.allowsMultipleSelection = YES;
    [self.tableView registerClass:[FYSelectFontTableViewCell class] forCellReuseIdentifier:@"FYSelectFontTableViewCell"];
//    [self setupSelection];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noticeDownload:)
                                                 name:FYFontStatusNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [FYFontManager saveSettins];
}

//- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
//    [super setEditing:editing animated:animated];
//    [self setupSelection];
//}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.fontFiles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    FYFontFile *file = self.fontFiles[section];
    return file.fontModels.count ? file.fontModels.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FYSelectFontTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FYSelectFontTableViewCell" forIndexPath:indexPath];
    FYFontFile *file = self.fontFiles[indexPath.section];
    if (file.fontModels.count) {
        FYFontModel *model = file.fontModels[indexPath.row];
        [self assembleCell:cell withModel:model];
    } else {
        [self assembleCell:cell withFile:file];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FYFontFile *file = self.fontFiles[indexPath.section];
    return (file.downloadStatus == FYFontFileDownloadStatusDownloaded);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        FYFontFile *file = self.fontFiles[indexPath.section];
        [FYFontManager deleteFontFile:file];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    FYFontFile *file = self.fontFiles[section];
    return file.downloadURL.absoluteString;
}

#pragma mark UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontFile *file = self.fontFiles[indexPath.section];

    switch (file.downloadStatus) {
        case FYFontFileDownloadStatusToBeDownloaded: {
            UIAlertView *AV = [[UIAlertView alloc] initWithTitle:@"Download Font File From"
                                                         message:file.downloadURL.absoluteString
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Start", nil];
            AV.tag = indexPath.section;
            [AV show];
        }
            break;
            
        case FYFontFileDownloadStatusDownloading: {
            [FYFontManager pauseDownloadingFile:file];
        }
            break;
            
        case FYFontFileDownloadStatusSuspending: {
            [FYFontManager downloadFontFile:file];
        }
            break;
            
        case FYFontFileDownloadStatusDownloaded: {
            if (file.fontModels.count) {
                FYFontModel *model = file.fontModels[indexPath.row];
                [FYFontManager setMainFontModel:model];
//                [self deselectRowsInSection:indexPath.section];
                return indexPath;
            }
        }
            break;
            
        default:
            break;
    }
    
    return nil;
}

//- (nullable NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
//    FYFontModel *model = self.fontArrayContainer[indexPath.section][indexPath.row];
//    if (model.status == FYFontModelDownloadStatusDownloaded) {
//        switch (indexPath.section) {
//            case 0: if (FYFontManager.mainFontIndex == indexPath.row)       return nil;
//            case 1: if (FYFontManager.mainBoldFontIndex == indexPath.row)   return nil;
//            case 2: if (FYFontManager.mainItalicFontIndex == indexPath.row) return nil;
//        }
//    }
//    return indexPath;
//}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Clear";
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontFile *file = self.fontFiles[indexPath.section];
    if (file.downloadStatus == FYFontFileDownloadStatusDownloaded) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSInteger section = alertView.tag;
        FYFontFile *file = self.fontFiles[section];
        [FYFontManager downloadFontFile:file];
    }
}

#pragma mark - Notification

- (void)noticeDownload:(NSNotification *)notification {
    FYFontFile *file = [notification.userInfo objectForKey:FYFontStatusNotificationKey];
    NSInteger targetSection = [self.fontFiles indexOfObject:file];
    NSLog(@"%ld %f", (long)targetSection, file.downloadProgress);
//    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:targetSection] withRowAnimation:UITableViewRowAnimationAutomatic];
    
//    NSMutableArray *cellIndexPaths = [NSMutableArray arrayWithCapacity:self.fontFiles.count];
    
    if (file.downloadProgress == 1.0) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:targetSection] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        for (NSInteger row = 0; row < self.fontFiles.count; row++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:targetSection];
            if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                FYSelectFontTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                [self assembleCell:cell withFile:file];
                [cell setNeedsLayout];
                break;
            }
        }
    }
    
    
//    if (file.status == FYFontFileDownloadStatusToBeDownloaded) {
//        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:targetRow inSection:targetSection]]
//                              withRowAnimation:UITableViewRowAnimationNone];
//        [self setupSelection];
//    } else {
//        // "Reloading a row causes the table view to ask its data source for a new cell for that row. " --> upset the downloading animation
//        for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
//            if (indexPath.section == targetSection && indexPath.row == targetRow) {
//                FYSelectFontTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//                [self assembleCell:cell withModel:newModel];
//                [cell setNeedsLayout];
//                break;
//            }
//        }
//    }
}

#pragma mark - Action 

//- (void)switchChangeValue:(UISwitch *)sw {
//    FYFontManager.usingMainStyle = sw.isOn;
//}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)setupBarItems {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(backAction)];
    
//    UISwitch *styleSwitch = [[UISwitch alloc] init];
//    [styleSwitch setOn:FYFontManager.isUsingMainStyle];
//    [styleSwitch addTarget:self action:@selector(switchChangeValue:) forControlEvents:UIControlEventValueChanged];
//    UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithCustomView:styleSwitch];
//    [bbi setPossibleTitles:[NSSet setWithObject:@"possibleTitles"]];
//    self.toolbarItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
//                          [[UIBarButtonItem alloc] initWithTitle:@"Fonty Style Switch ->"
//                                                           style:UIBarButtonItemStylePlain
//                                                          target:nil
//                                                          action:NULL],
//                          [[UIBarButtonItem alloc] initWithCustomView:styleSwitch]];
}

//- (void)setupSelection {
//    if (FYFontManager.fontModelArray.count) {
//        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:FYFontManager.mainFontIndex inSection:0]
//                                    animated:NO
//                              scrollPosition:UITableViewScrollPositionNone];
//    }
//    if (FYFontManager.boldFontModelArray.count) {
//        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:FYFontManager.mainBoldFontIndex inSection:1]
//                                    animated:NO
//                              scrollPosition:UITableViewScrollPositionNone];
//    }
//    if (FYFontManager.italicFontModelArray.count) {
//        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:FYFontManager.mainItalicFontIndex inSection:2]
//                                    animated:NO
//                              scrollPosition:UITableViewScrollPositionNone];
//    }
//}

- (void)assembleCell:(FYSelectFontTableViewCell *)cell withModel:(FYFontModel *)model {
    
    UIFont *font = [UIFont fy_fontOfModel:model withSize:12.0f];
    cell.textLabel.text = model.postScriptName;
    cell.textLabel.font = font;
    cell.detailTextLabel.text = nil;
    
    cell.downloadProgress = 1.0;
}

- (void)assembleCell:(FYSelectFontTableViewCell *)cell withFile:(FYFontFile *)file {
    UIFont *font = [UIFont systemFontOfSize:12.0f weight:10.0];
    cell.textLabel.text = file.downloadURL.absoluteString;
    cell.textLabel.font = font;
    cell.detailTextLabel.text = nil;
    
    cell.downloadProgress = file.downloadProgress;
    cell.striped = NO;
    cell.pauseStripes = NO;
//    NSLog(@"cccelll %f %d", file.downloadProgress, file.fileSizeUnknown);
    switch (file.downloadStatus) {
        case FYFontFileDownloadStatusToBeDownloaded: {
            if (file.downloadError) {
                cell.detailTextLabel.text = file.downloadError.localizedDescription;
            }
        }
            break;
            
        case FYFontFileDownloadStatusDownloading: {
            cell.striped = file.fileSizeUnknown;
        }
            break;
            
        case FYFontFileDownloadStatusSuspending: {
            cell.striped = file.fileSizeUnknown;
            cell.pauseStripes = YES;
        }
            break;
            
        default:
            break;
    }
    if (file.fileSize > 0.0f) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"size: %.2fM", file.fileSize / 1000000.0f];
    }
}

//- (void)assembleCell:(FYSelectFontTableViewCell *)cell withModel:(FYFontModel *)model {
//    UIFont *font = [UIFont fy_fontWithURL:model.downloadURL size:16.0f];
//    cell.textLabel.text = (model.downloadProgress == 1.0f) ? font.fontDescriptor.postscriptName : model.description;
//    cell.textLabel.font = font;
//    cell.detailTextLabel.text = nil;
//    
//    cell.downloadProgress = model.downloadProgress;
//    cell.striped = NO;
//    cell.pauseStripes = NO;
//
//    if (model.status == FYFontModelDownloadStatusToBeDownloaded) {
//        if (model.downloadError) {
//            cell.detailTextLabel.text = model.downloadError.localizedDescription;
//        }
//    } else if (model.status == FYFontModelDownloadStatusDownloading) {
//        cell.striped = model.fileSizeUnknown;
//    } else if (model.status == FYFontModelDownloadStatusSuspending) {
//        cell.striped = model.fileSizeUnknown;
//        cell.pauseStripes = YES;
//    }
//    if (model.fileSize > 0.0f) {
//        cell.detailTextLabel.text = [NSString stringWithFormat:@"size: %.2fM", model.fileSize / 1000000.0f];
//    }
//}

//- (void)deselectRowsInSection:(NSInteger)section {
//    for (NSIndexPath *selectedIndexPath in [self.tableView indexPathsForSelectedRows]) {
//        if (section == selectedIndexPath.section) {
//            [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
//            break;
//        }
//    }
//}

@end
