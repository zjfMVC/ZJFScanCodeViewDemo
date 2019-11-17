//
//  ZJFScanCodeView.h
//  szjyhkdriver
//
//  Created by zhengworker on 2019/5/7.
//  Copyright © 2019 zhengworker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 扫描二维码或条形码的控件
 */
@interface ZJFScanCodeView : UIView

@property (nonatomic, assign) BOOL isQRCode;

/**
 结果回调
 */
@property (nonatomic, copy) void (^resultBlock)(NSString *resultCode);

/**
 初始化实例
 @param frame 坐标
 @param resultBlock 结果回调
 @return 实例
 */
+ (instancetype)scanCodeViewWithFrame:(CGRect)frame resultBlock:(void(^)(NSString *resultCode))resultBlock;

/**
 初始化实例

 @param frame 坐标
 @param metadataObjectTypes 扫描支持的编码格式
 @param resultBlock 结果回调
 @return 实例
 */
+ (instancetype)scanCodeViewWithFrame:(CGRect)frame metadataObjectTypes:(NSArray <AVMetadataObjectType>*)metadataObjectTypes resultBlock:(void(^)(NSString *resultCode))resultBlock;

/**
 设计扫描相关配置(在布局约束完成后再调用)
 */
- (void)setScanConfig;

- (void)startScan;

- (void)stopScan;
@end

NS_ASSUME_NONNULL_END
