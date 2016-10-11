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

@interface FYSelectFontViewController () <UIAlertViewDelegate>

@property (nonatomic, weak) FYFontManager *fontManager;
@property (nonatomic, weak) NSArray *fontModelArray;

@end

@implementation FYSelectFontViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Fonty";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(backAction)];
    
    self.fontManager = [FYFontManager sharedManager];
    self.fontModelArray = self.fontManager.fontModelArray;
    
    [self.tableView registerClass:[FYSelectFontTableViewCell class] forCellReuseIdentifier:@"FYSelectFontTableViewCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noticeDownload:)
                                                 name:FYNewFontDownloadNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fontModelArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = [self.fontModelArray objectAtIndex:indexPath.row];
    FYSelectFontTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FYSelectFontTableViewCell" forIndexPath:indexPath];
    
    cell.textLabel.text = model.description;
    cell.textLabel.font = [UIFont fy_fontWithURL:model.URL size:17.0f];
    
    cell.downloadProgress = model.downloadProgress;
    cell.striped = (model.status == FYFontModelDownloadStatusDownloaded) ? NO : model.fileSizeUnknown;
    cell.stripedPause = (model.status == FYFontModelDownloadStatusSuspending);
    
    if (indexPath.row == self.fontManager.mainFontIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = [self.fontModelArray objectAtIndex:indexPath.row];
    return model.status == FYFontModelDownloadStatusDownloaded;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        FYFontModel *model = [self.fontModelArray objectAtIndex:indexPath.row];
        [tableView reloadData];
        
        [self.fontManager deleteFontWithURL:model.URL];
    }
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = [self.fontModelArray objectAtIndex:indexPath.row];
    if (model.status == FYFontModelDownloadStatusDownloaded) {
        self.fontManager.mainFontIndex = indexPath.row;
        [tableView reloadData];
    } else if (model.status == FYFontModelDownloadStatusDownloading) {
        [self.fontManager pauseDownloadingWithURL:model.URL];
    } else if (model.status == FYFontModelDownloadStatusSuspending) {
        [self.fontManager downloadFontWithURL:model.URL];
    } else if (model.status == FYFontModelDownloadStatusToBeDownloaded) {
        UIAlertView *AV = [[UIAlertView alloc] initWithTitle:@"Download Font File from"
                                                     message:model.URL.absoluteString
                                                    delegate:self
                                           cancelButtonTitle:@"cancel"
                                           otherButtonTitles:@"start", nil];
        AV.tag = indexPath.row;
        [AV show];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"clear";
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = [self.fontModelArray objectAtIndex:indexPath.row];
    if ((model.status == FYFontModelDownloadStatusDownloaded ||
         model.status == FYFontModelDownloadStatusDownloading ||
         model.status == FYFontModelDownloadStatusSuspending) && model.URL) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        FYFontModel *model = [self.fontModelArray objectAtIndex:alertView.tag];
        [self.fontManager downloadFontWithURL:model.URL];
    }
}

#pragma mark - Notification

- (void)noticeDownload:(NSNotification *)notification {
    [self.tableView reloadData];
}

#pragma mark - Action 

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
