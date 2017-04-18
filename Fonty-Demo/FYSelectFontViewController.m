//
//  FYSelectFontViewController.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import "FYSelectFontViewController.h"

#import "FYSelectFontTableViewCell.h"

#import "Fonty.h"

@interface FYSelectFontViewController ()

@property (weak, nonatomic) NSArray<FYFontFile *> *fontFiles;

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
                                             selector:@selector(layoutCellWithNotification:)
                                                 name:FYFontFileDownloadingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(layoutCellWithNotification:)
                                                 name:FYFontFileDownloadStateDidChangeNotification                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadRowWithNotification:)
                                                 name:FYFontFileRegisteringDidCompleteNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadRowWithNotification:)
                                                 name:FYFontFileDeletingDidCompleteNotification
                                               object:nil];
    [self setupSelection];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [FYFontManager archive];
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
    return (file.downloadStatus == FYFontFileDownloadStateDownloaded);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        FYFontFile *file = self.fontFiles[indexPath.section];
        [FYFontManager deleteFontFile:file];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"Font file %ld", (long)section + 1];
}

#pragma mark UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontFile *file = self.fontFiles[indexPath.section];
    switch (file.downloadStatus) {
        case FYFontFileDownloadStateToBeDownloaded: {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Download Font File From"
                                                                                     message:file.sourceURLString
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
            
        case FYFontFileDownloadStateDownloading: {
            [FYFontManager pauseDownloadingFile:file];
        }
            break;
            
        case FYFontFileDownloadStateSuspended: {
            [FYFontManager downloadFontFile:file];
        }
            break;
            
        case FYFontFileDownloadStateDownloaded: {
            if (file.registered) {
                FYFontModel *model = file.fontModels[indexPath.row];
                UIFont *font = model.font;
                if ([font.fontName isEqualToString:[FYFontManager mainFont].fontName]) {
                    [FYFontManager setMainFont:nil];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Clear";
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontFile *file = self.fontFiles[indexPath.section];
    if (file.downloadStatus == FYFontFileDownloadStateDownloaded) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

#pragma mark - Action 

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Notification

- (void)layoutCellWithNotification:(NSNotification *)notification {
    FYFontFile *file = [notification.userInfo objectForKey:FYFontFileNotificationUserInfoKey];
    NSInteger targetSection = [self.fontFiles indexOfObject:file];
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

- (void)reloadRowWithNotification:(NSNotification *)notification {
    FYFontFile *file = [notification.userInfo objectForKey:FYFontFileNotificationUserInfoKey];
    NSInteger targetSection = [self.fontFiles indexOfObject:file];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:targetSection]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Private

- (void)setupBarItems {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(backAction)];
}

- (void)setupSelection {
    NSInteger section = -1;
    NSInteger row     = -1;
    UIFont *mainFont = [FYFontManager mainFont];
    
    for (NSInteger i = 0; i < self.fontFiles.count; i++) {
        FYFontFile *file = self.fontFiles[i];
        for (NSInteger j = 0; j < file.fontModels.count; j++) {
            FYFontModel *model = file.fontModels[j];
            if ([model.font.fontName isEqualToString:mainFont.fontName]) {
                section = i;
                row     = j;
                goto foundSelection;
            }
        }
    }
    
foundSelection:
    if (section > -1) {
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
}

- (void)assembleCell:(FYSelectFontTableViewCell *)cell withModel:(FYFontModel *)model {
    UIFont *font = [UIFont fy_fontOfModel:model withSize:12.0f];
    cell.textLabel.text = model.postScriptName;
    cell.textLabel.font = font;
    cell.detailTextLabel.text = nil;
    cell.downloadProgress = 1.0;
}

- (void)assembleCell:(FYSelectFontTableViewCell *)cell withFile:(FYFontFile *)file {
    UIFont *font = [UIFont systemFontOfSize:12.0f weight:10.0];
    cell.textLabel.text = file.sourceURLString;
    cell.textLabel.font = font;
    cell.detailTextLabel.text = nil;
    cell.downloadProgress = file.downloadProgress;
    cell.striped = NO;
    cell.pauseStripes = NO;
    
    switch (file.downloadStatus) {
        case FYFontFileDownloadStateToBeDownloaded: {
            if (file.downloadError) {
                cell.detailTextLabel.text = file.downloadError.localizedDescription;
            }
        }
            break;
            
        case FYFontFileDownloadStateDownloading: {
            cell.striped = file.fileSizeUnknown;
        }
            break;
            
        case FYFontFileDownloadStateSuspended: {
            cell.striped = file.fileSizeUnknown;
            cell.pauseStripes = YES;
        }
            break;
            
        default:
            break;
    }
    if (file.fileSize > 0.0f) {
        if (file.fileSizeUnknown) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2fM / ?", file.fileDownloadedSize / 1000000.0f];
        } else {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2fM / %.2fM", file.fileDownloadedSize / 1000000.0f, file.fileSize / 1000000.0f];
        }
    }
}

@end
