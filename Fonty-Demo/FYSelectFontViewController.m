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

@implementation FYSelectFontViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Fonty";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(backAction)];
    
    [self.tableView registerClass:[FYSelectFontTableViewCell class] forCellReuseIdentifier:@"FYSelectFontTableViewCell"];
    
//    UITableViewCell *targetCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.fontManager.mainFontIndex inSection:0]];
//    [targetCell setSelected:YES animated:YES];
//    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.fontManager.mainFontIndex inSection:0]
//                                animated:NO
//                          scrollPosition:UITableViewScrollPositionNone];
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
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return FYFontManager.fontModelArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = [FYFontManager.fontModelArray objectAtIndex:indexPath.row];
    FYSelectFontTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FYSelectFontTableViewCell" forIndexPath:indexPath];
    NSLog(@"%li", (long)indexPath.row);
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
    } else if (model.status == FYFontModelDownloadStatusDownloaded) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"size: %.2fM", model.fileSize / 1000000.0f];
    }
   
    [cell setSelected:(indexPath.row == FYFontManager.mainFontIndex) animated:NO];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = [FYFontManager.fontModelArray objectAtIndex:indexPath.row];
    return model.status == FYFontModelDownloadStatusDownloaded;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        FYFontModel *model = [FYFontManager.fontModelArray objectAtIndex:indexPath.row];
        [tableView reloadData];
        
        [FYFontManager deleteFontWithURL:model.downloadURL];
    }
}

#pragma mark UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = [FYFontManager.fontModelArray objectAtIndex:indexPath.row];
    if (model.status == FYFontModelDownloadStatusDownloaded) {
        FYFontManager.mainFontIndex = indexPath.row;
        return indexPath;
    } else if (model.status == FYFontModelDownloadStatusDownloading) {
        [FYFontManager pauseDownloadingWithURL:model.downloadURL];
    } else if (model.status == FYFontModelDownloadStatusSuspending) {
        [FYFontManager downloadFontWithURL:model.downloadURL];
    } else if (model.status == FYFontModelDownloadStatusToBeDownloaded) {
        UIAlertView *AV = [[UIAlertView alloc] initWithTitle:@"Download Font File from"
                                                     message:model.downloadURL.absoluteString
                                                    delegate:self
                                           cancelButtonTitle:@"cancel"
                                           otherButtonTitles:@"start", nil];
        AV.tag = indexPath.row;
        [AV show];
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"clear";
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = [FYFontManager.fontModelArray objectAtIndex:indexPath.row];
    if ((model.status == FYFontModelDownloadStatusDownloaded ||
         model.status == FYFontModelDownloadStatusDownloading ||
         model.status == FYFontModelDownloadStatusSuspending) && model.downloadURL) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        FYFontModel *model = [FYFontManager.fontModelArray objectAtIndex:alertView.tag];
        [FYFontManager downloadFontWithURL:model.downloadURL];
    }
}

#pragma mark - Notification

- (void)noticeDownload:(NSNotification *)notification {
    FYFontModel *newModel = [notification.userInfo objectForKey:FYFontStatusNotificationKey];
    NSInteger targetRow = [FYFontManager.fontModelArray indexOfObjectPassingTest:^BOOL(FYFontModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.downloadURL.absoluteString isEqualToString:newModel.downloadURL.absoluteString];
    }];
    NSIndexPath *targetIndexPath = [NSIndexPath indexPathForRow:targetRow inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[targetIndexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Action 

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
