//
//  ScanTypeListVC.m
//  ZJFScanCodeViewDemo
//
//  Created by zhengworker on 2019/11/18.
//  Copyright © 2019 zhengworker. All rights reserved.
//

#import "ScanTypeListVC.h"
#import "ScanOnViewController.h"
#import "ScanOnTableViewVC.h"

@interface ScanTypeListVC ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *dataSource;

@end

@implementation ScanTypeListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initData];
    [self initView];
}


#pragma mark - 初始化基础数据
- (void)initData {
    self.dataSource = @[@"放置在tableView头部视图上"];
}


#pragma mark -- 设置UI
- (void)initView {
    
    NSString *navigatiomTitle = @"扫描类型列表";
    [self.navigationItem setTitle:NSLocalizedString(navigatiomTitle, nil)];

    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
}



#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    rows = self.dataSource.count;
    return rows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    if (indexPath.row < self.dataSource.count) {
        cell.textLabel.text = self.dataSource[indexPath.row];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0001;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0001;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 在手指离开的那一刻进行反选中
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    if (indexPath.row == 0) {
//        ScanOnViewController *vc = [ScanOnViewController new];
//        [self.navigationController pushViewController:vc animated:YES];
//    } else if (indexPath.row == 1) {
//        ScanOnTableViewVC *vc = [ScanOnTableViewVC new];
//        [self.navigationController pushViewController:vc animated:YES];
//    }
    ScanOnTableViewVC *vc = [ScanOnTableViewVC new];
    [self.navigationController pushViewController:vc animated:YES];
}
@end
