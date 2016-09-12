//
//  FYSelectFontViewController.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import "FYSelectFontViewController.h"
#import "FYHeader.h"

static NSString *const UITableViewCellIdentifier = @"UITableViewCellIdentifier";

@interface FYSelectFontViewController () <UIAlertViewDelegate>

@property (nonatomic, weak) FYFontManager *fontManager;
@property (nonatomic, weak) NSArray *fontModelArray;

@end

@implementation FYSelectFontViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Fonty";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(backAction)];
    
    self.fontManager = [FYFontManager sharedManager];
    self.fontModelArray = self.fontManager.fontModelArray;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:UITableViewCellIdentifier];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fontModelArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = [self.fontModelArray objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:UITableViewCellIdentifier forIndexPath:indexPath];
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.text = model.description;
    cell.accessoryView = nil;
    
    if (model.status == FYFontModelDownloadStatusDownloaded) {
        if (indexPath.row == self.fontManager.mainFontIndex) {
            cell.selected = YES;
        }
    } else if (model.status == FYFontModelDownloadStatusDeleting || model.status == FYFontModelDownloadStatusDownloading) {
        UIActivityIndicatorView *AIV = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [AIV startAnimating];
        cell.accessoryView = AIV;
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
        model.status = FYFontModelDownloadStatusDeleting;
        [tableView reloadData];
        
        [self.fontManager deleteFontWithURL:model.URL completeBlock:^{
            model.status = FYFontModelDownloadStatusToBeDownloaded;
            self.fontManager.mainFontIndex = 0;
            [tableView reloadData];
        }];
    }
}

#pragma mark UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = [self.fontModelArray objectAtIndex:indexPath.row];
    if (model.status == FYFontModelDownloadStatusDownloaded) {
        self.fontManager.mainFontIndex = indexPath.row;
        [tableView reloadData];
        return indexPath;
    } else {
        UIAlertView *AV = [[UIAlertView alloc] initWithTitle:@"Download Font File from"
                                                     message:model.URL.absoluteString
                                                    delegate:self
                                           cancelButtonTitle:@"cancel"
                                           otherButtonTitles:@"start", nil];
        AV.tag = indexPath.row;
        [AV show];
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"clear";
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    FYFontModel *model = [self.fontModelArray objectAtIndex:indexPath.row];
    if (model.status == FYFontModelDownloadStatusDownloaded || model.URL) {
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

#pragma mark - Action 

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
