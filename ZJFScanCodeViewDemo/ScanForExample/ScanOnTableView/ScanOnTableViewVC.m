//
//  ScanOnTableViewVC.m
//  ZJFScanCodeViewDemo
//
//  Created by zhengworker on 2019/11/19.
//  Copyright © 2019 zhengworker. All rights reserved.
//

#import "ScanOnTableViewVC.h"
#import "ZJFScanCodeView.h"

#define kScanContainerViewHeight   340
@interface ScanOnTableViewVC ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) ZJFScanCodeView *scanCodeView;
@property (strong, nonatomic) NSArray *dataSource;
@end

@implementation ScanOnTableViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initData];
    [self initView];
}

#pragma mark - 初始化基础数据
- (void)initData {
    self.dataSource = @[@"在",@"吗？",@"不在",@"有",@"什么事吗",@"没事我就在了",@"有事我就不在"];
}


#pragma mark -- 设置UI
- (void)initView {
    
    NSString *navigatiomTitle = @"扫描列表";
    [self.navigationItem setTitle:NSLocalizedString(navigatiomTitle, nil)];

    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
    
    __weak typeof(self) weakSelf = self;
    self.scanCodeView = [ZJFScanCodeView scanCodeViewWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, kScanContainerViewHeight) resultBlock:^(NSString * _Nonnull resultCode) {
        NSLog(@"我是你扫描得到的结果---------------------%@",resultCode);
        weakSelf.navigationItem.title = [NSString stringWithFormat:@"扫描结果:%@",resultCode];
        [weakSelf startScan];
    }];
    self.tableView.tableHeaderView = self.scanCodeView;
    self.tableView.tableHeaderView.frame = CGRectMake(0, 0, SCREEN_WIDTH, kScanContainerViewHeight);
}


// 更新好约束后调用
- (void)viewDidLayoutSubviews {
    if (self.view.frame.size.width == SCREEN_WIDTH) {
        [self.scanCodeView setScanConfig];
        [self startScan];
    }
}

- (void)startScan {
    [self.scanCodeView startScan];
}

- (void)stopScan {
    [self.scanCodeView stopScan];
}


- (void)dealloc {
    if (self.scanCodeView) {
        [self.scanCodeView stopScan];
    }
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
}

@end
