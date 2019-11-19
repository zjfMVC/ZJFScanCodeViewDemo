//
//  ScanOnViewController.m
//  ZJFScanCodeViewDemo
//
//  Created by zhengworker on 2019/11/18.
//  Copyright © 2019 zhengworker. All rights reserved.
//

#import "ScanOnViewController.h"
#import "ZJFScanCodeView.h"

#define kScanContainerViewHeight   340

@interface ScanOnViewController ()

@property (nonatomic, strong) ZJFScanCodeView *scanCodeView;
@end

@implementation ScanOnViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
    __weak typeof(self) weakSelf = self;
    self.scanCodeView = [ZJFScanCodeView scanCodeViewWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, kScanContainerViewHeight) resultBlock:^(NSString * _Nonnull resultCode) {
        NSLog(@"我是你扫描得到的结果---------------------%@",resultCode);
        weakSelf.navigationItem.title = [NSString stringWithFormat:@"扫描结果:%@",resultCode];
        [weakSelf startScan];
    }];
//    [self.view addSubview:self.scanCodeView];
//    [self.scanCodeView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.center.equalTo(self.view);
//        make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH, kScanContainerViewHeight));
//    }];
//    [self.view.layer insertSublayer:self.scanCodeView.layer atIndex:0];
    self.view = self.scanCodeView;
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
@end
