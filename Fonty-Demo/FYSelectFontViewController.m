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

@property (copy, nonatomic) NSArray<FYFontFile *> *fontFiles;

@end

@implementation FYSelectFontViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (!self) {
        return nil;
    }
    self.navigationItem.title = @"Fonty";
    [self setupBarItems];
    self.fontFiles = [FYFontManager fontFiles];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[FYSelectFontTableViewCell class] forCellReuseIdentifier:@"FYSelectFontTableViewCell"];
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fontFiles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    FYFontFile *file = self.fontFiles[section];
    return (file.registered) ? file.fontModels.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FYSelectFontTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FYSelectFontTableViewCell" forIndexPath:indexPath];
    FYFontFile *file = self.fontFiles[indexPath.section];
    if (file.registered) {
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
        [self.tableView reloadData];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    FYFontFile *file = self.fontFiles[section];
    return file.downloadURLString;
}

#pragma mark UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontFile *file = self.fontFiles[indexPath.section];
    switch (file.downloadStatus) {
        case FYFontFileDownloadStatusToBeDownloaded: {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Download Font File From"
                                                                                     message:file.downloadURLString
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                                style:UIAlertActionStyleCancel
                                                              handler:nil]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Start"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  [FYFontManager downloadFontFile:file];
                                                              }]];
            [self presentViewController:alertController animated:YES completion:nil];
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
            if (file.registered) {
                FYFontModel *model = file.fontModels[indexPath.row];
                UIFont *font = model.font;
                if ([font.fontName isEqualToString:[FYFontManager mainFont].fontName]) {
                    [FYFontManager setMainFont:nil];
                    FYSelectFontTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                } else {
                    [FYFontManager setMainFont:font];
                    return indexPath;
                }
            } else {
                if (![FYFontManager registerFontFile:file]) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Can not register this font file!"
                                                                                             message:nil
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:nil]];
                    [self presentViewController:alertController animated:YES completion:nil];
                } else {
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }
        }
            break;
            
        default:
            break;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FYSelectFontTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    FYSelectFontTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
}

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

#pragma mark - Notification

- (void)noticeDownload:(NSNotification *)notification {
    FYFontFile *file = [notification.userInfo objectForKey:FYFontStatusNotificationKey];
    NSInteger targetSection = [self.fontFiles indexOfObject:file];
    if (file.registered) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:targetSection]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
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
}

#pragma mark - Action 

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)setupBarItems {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(backAction)];
}

- (void)assembleCell:(FYSelectFontTableViewCell *)cell withModel:(FYFontModel *)model {
    UIFont *font = [UIFont fy_fontOfModel:model withSize:12.0f];
    cell.textLabel.text = model.postScriptName;
    cell.textLabel.font = font;
    cell.detailTextLabel.text = nil;
    if ([font.fontName isEqualToString:[FYFontManager mainFont].fontName]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.downloadProgress = 1.0;
}

- (void)assembleCell:(FYSelectFontTableViewCell *)cell withFile:(FYFontFile *)file {
    UIFont *font = [UIFont systemFontOfSize:12.0f weight:10.0];
    cell.textLabel.text = file.downloadURLString;
    cell.textLabel.font = font;
    cell.detailTextLabel.text = nil;
    cell.selected = NO;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.downloadProgress = file.downloadProgress;
    cell.striped = NO;
    cell.pauseStripes = NO;
    
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

@end
