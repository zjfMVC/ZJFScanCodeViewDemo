//
//  ZJFScanCodeView.m
//  szjyhkdriver
//
//  Created by zhengworker on 2019/5/7.
//  Copyright © 2019 zhengworker. All rights reserved.
//

#import "ZJFScanCodeView.h"
#import "Masonry.h"

#define SCAN_CODE_TYPE_AVAILABLE        @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeCode93Code]

// 控制面板高度
#define kControlPanelHeight   60

@interface ZJFScanCodeView ()<AVCaptureMetadataOutputObjectsDelegate>

/** 设备 */
@property (nonatomic, strong) AVCaptureDevice * device;

/** 输入输出的中间桥梁 */
@property (nonatomic, strong) AVCaptureSession * session;

/** 相机图层 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;

/** 扫描支持的编码格式的数组 */
@property (nonatomic, strong) NSMutableArray * metadataObjectTypes;
@property (nonatomic, strong) NSArray * originalMetadataObjectTypes;

@property(nonatomic,strong) AVCaptureMetadataOutput * output ;//输出流

@property(nonatomic,strong) AVCaptureDeviceInput * input;//创建输入流

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *scanArea;
@property (strong, nonatomic) UILabel *tipsLbl;
// 控制面板菜单按钮
@property (nonatomic, strong) UIView *controlPanelView;
@property (nonatomic, strong) UIButton *onOffTorchBtn; // 开关补光灯
@property (nonatomic, strong) UIButton *switchBarOrQRCodeBtn; // 切换二维码和条形码扫描

@property (strong, nonatomic) UIImageView *boundLeftTop;
@property (strong, nonatomic) UIImageView *boundRightTop;
@property (strong, nonatomic) UIImageView *boundLeftBottom;
@property (strong, nonatomic) UIImageView *boundRightBottom;
@property (strong, nonatomic) UIImageView *seperator;

@property (nonatomic, assign) CGFloat scanAreaWidth;
@property (nonatomic, assign) CGFloat scanAreaHeight;
@end

@implementation ZJFScanCodeView {
    BOOL isSetScan;
    SystemSoundID _beepSound;
    SystemSoundID _failureBeepSound;
    SystemSoundID _repeatBeepSound;
    NSTimer *timer;
}



#pragma mark - 实例化类方法
+ (instancetype)scanCodeViewWithFrame:(CGRect)frame resultBlock:(void(^)(NSString *resultCode))resultBlock {
    return [ZJFScanCodeView scanCodeViewWithFrame:frame metadataObjectTypes:SCAN_CODE_TYPE_AVAILABLE resultBlock:resultBlock];
}

+ (instancetype)scanCodeViewWithFrame:(CGRect)frame metadataObjectTypes:(NSArray <AVMetadataObjectType>*)metadataObjectTypes resultBlock:(void(^)(NSString *resultCode))resultBlock {
    ZJFScanCodeView *view = [[self alloc] initWithFrame:frame];
    [view.metadataObjectTypes addObjectsFromArray:metadataObjectTypes !=nil ? (metadataObjectTypes.count > 0 ? metadataObjectTypes : SCAN_CODE_TYPE_AVAILABLE) : SCAN_CODE_TYPE_AVAILABLE];
    view.originalMetadataObjectTypes = metadataObjectTypes !=nil ? (metadataObjectTypes.count > 0 ? metadataObjectTypes : SCAN_CODE_TYPE_AVAILABLE) : SCAN_CODE_TYPE_AVAILABLE;
    view.resultBlock = resultBlock;
    return view;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initData];
        [self initView];
    }
    return self;
}



#pragma mark - 配置初始化一些数据资源
- (void)initData {
    isSetScan = NO;
    self.scanAreaWidth = self.frame.size.width - 10;
    self.scanAreaHeight = 200;
}


#pragma mark - 设置UI
- (void)initView {
    self.backgroundColor = [UIColor blackColor];
    
    self.containerView = [UIView new];
    [self addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.bottom.equalTo(self).offset(-kControlPanelHeight);
        make.left.and.right.equalTo(self);
    }];
    self.containerView.layer.borderColor = [UIColor whiteColor].CGColor;
    
    
    self.scanArea = [UIView new];
    [self.containerView addSubview:self.scanArea];
    [self.scanArea mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.containerView);
        make.size.mas_equalTo(CGSizeMake(self.scanAreaWidth, self.scanAreaHeight));
    }];
    self.scanArea.layer.borderColor = [UIColor whiteColor].CGColor;
    self.scanArea.layer.borderWidth = 1.5;
    self.scanArea.clipsToBounds = YES;
    
    self.seperator = [UIImageView new];
    [self.scanArea addSubview:self.seperator];
    self.seperator.image = [UIImage imageNamed:@"fengexian"];
    self.seperator.frame = CGRectMake(1 , 0, self.scanAreaWidth - 2, 1.5);
    
    self.boundLeftTop = [UIImageView new];
    self.boundLeftTop.image = [UIImage imageNamed:@"biankuang1"];
    [self.containerView addSubview:self.boundLeftTop];
    [self.boundLeftTop mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(16, 16));
        make.top.equalTo(self.scanArea).offset(0);
        make.left.equalTo(self.scanArea).offset(0);
    }];
    
    self.boundRightTop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"biankuang2"]];
    [self.containerView addSubview:self.boundRightTop];
    [self.boundRightTop mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(self.boundLeftTop);
        make.top.equalTo(self.boundLeftTop);
        make.right.equalTo(self.scanArea).offset(0);
    }];
    
    self.boundLeftBottom = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"biankuang4"]];
    [self.containerView addSubview:self.boundLeftBottom];
    [self.boundLeftBottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(self.boundLeftTop);
        make.left.equalTo(self.boundLeftTop);
        make.bottom.equalTo(self.scanArea).offset(0);
    }];
    
    self.boundRightBottom = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"biankuang3"]];
    [self.containerView addSubview:self.boundRightBottom];
    [self.boundRightBottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(self.boundLeftTop);
        make.right.equalTo(self.boundRightTop);
        make.bottom.equalTo(self.boundLeftBottom);
    }];
    
    self.tipsLbl = ({
        UILabel *lbl = [UILabel new];
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [UIFont systemFontOfSize:12];
        lbl.numberOfLines = 0;
        lbl.textAlignment = NSTextAlignmentCenter;
        [self.containerView addSubview:lbl];
        lbl;
    });
    [self.tipsLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.containerView);
        make.top.equalTo(self.scanArea.mas_bottom).offset(5);
    }];
    self.tipsLbl.text = NSLocalizedString(@"將條形碼放入框內，\n即可自動掃描", nil);
    
    UIView *topView = [UIView new];
    topView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.36];
    [self.containerView addSubview:topView];
    [topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.and.left.and.right.equalTo(self.containerView);
        make.bottom.equalTo(self.scanArea.mas_top);
    }];
    
    UIView *bottomView  = [UIView new];
    bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.36];
    [self.containerView addSubview:bottomView];
    [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.and.left.and.right.equalTo(self.containerView);
        make.top.equalTo(self.scanArea.mas_bottom);
    }];
    
    UIView *leftView = [UIView new];
    leftView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.36];
    [self.containerView addSubview:leftView];
    [leftView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.containerView);
        make.right.equalTo(self.scanArea.mas_left);
        make.top.equalTo(topView.mas_bottom);
        make.bottom.equalTo(bottomView.mas_top);
    }];
    
    UIView *rightView = [UIView new];
    rightView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.36];
    [self.containerView addSubview:rightView];
    [rightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.containerView);
        make.left.equalTo(self.scanArea.mas_right);
        make.top.equalTo(topView.mas_bottom);
        make.bottom.equalTo(bottomView.mas_top);
    }];
    
    
    
    self.controlPanelView = [UIView new];
    [self addSubview:self.controlPanelView];
    [self.controlPanelView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self);
        make.left.and.right.equalTo(self);
        make.height.mas_equalTo(kControlPanelHeight);
    }];
    
    self.onOffTorchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.onOffTorchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.onOffTorchBtn setTitle:NSLocalizedString(@"開啟補光燈", nil) forState:UIControlStateNormal];
    self.onOffTorchBtn.titleLabel.numberOfLines = 2;
    [self.onOffTorchBtn addTarget:self action:@selector(onOffTorchBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.controlPanelView addSubview:self.onOffTorchBtn];
    [self.onOffTorchBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.and.bottom.equalTo(self.controlPanelView);
        make.left.equalTo(self.controlPanelView).offset(16);
        make.right.equalTo(self.controlPanelView.mas_centerX).offset(-5);
    }];
    
    self.switchBarOrQRCodeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.switchBarOrQRCodeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.switchBarOrQRCodeBtn setTitle:NSLocalizedString(@"二維碼", nil) forState:UIControlStateNormal];
    [self.switchBarOrQRCodeBtn addTarget:self action:@selector(switchBarOrQRCodeAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.controlPanelView addSubview:self.switchBarOrQRCodeBtn];
    [self.switchBarOrQRCodeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.and.bottom.equalTo(self.controlPanelView);
        make.left.equalTo(self.controlPanelView.mas_centerX).offset(5);
        make.right.equalTo(self.controlPanelView).offset(-16);
    }];
    
    [self bringSubviewToFront:self.tipsLbl];
}


#pragma mark - 设计扫描相关配置
- (void)setScanConfig {
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        //判断相机是否能够使用
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if(status == AVAuthorizationStatusDenied){
            UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"%@%@%@", NSLocalizedString(@"請在iPhone的“設置-隱私-相機”選項中，允許", nil), NSLocalizedString(@"神州集運司機", nil), NSLocalizedString(@"訪問妳的相機。", nil)] delegate:nil cancelButtonTitle:NSLocalizedString(@"我知道了", nil) otherButtonTitles:nil];
            [alter show];
            return;
        }
    }
    
    timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(scanAnimate) userInfo:nil repeats:YES];
    [timer fire];
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    
    if (error) {
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"註意", nil) message:NSLocalizedString(@"該設備沒有攝像頭", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"確認", nil) otherButtonTitles:nil];
        [alter show];
        return;
    }
    
    self.output = [[AVCaptureMetadataOutput alloc] init];
    
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    _session = [[AVCaptureSession alloc] init];
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    
    if ([_session canAddInput:self.input]) {
        [_session addInput:self.input];
    }
    if ([_session canAddOutput:self.output]) {
        [_session addOutput:self.output];
    }
    
    self.output.metadataObjectTypes = self.metadataObjectTypes !=nil ? (self.metadataObjectTypes.count > 0 ? self.metadataObjectTypes : SCAN_CODE_TYPE_AVAILABLE) : SCAN_CODE_TYPE_AVAILABLE;
    
    self.output.rectOfInterest = CGRectMake(self.scanArea.frame.origin.y / (self.frame.size.height), self.scanArea.frame.origin.x / SCREEN_WIDTH, self.scanAreaWidth / self.frame.size.height, self.scanAreaWidth / self.frame.size.width);
    [self coverToMetadataOutputRectOfInterestForRect:self.scanArea.frame];
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    self.previewLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, self.frame.size.height - kControlPanelHeight);
    
    [self.containerView.layer insertSublayer:self.previewLayer atIndex:0];
    
    [_session startRunning];
}


/**
 设置自动对焦

 @param device <#device description#>
 @param point <#point description#>
 */
- (void)setFocusForDevice:(AVCaptureDevice *)device atPoint:(CGPoint)point {
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        if ([device lockForConfiguration:nil]) {
            [device setFocusPointOfInterest:point];
            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [device unlockForConfiguration];
        }
    }
}

/**
 设置平衡光

 @param device <#device description#>
 */
- (void)setWhiteBalanceModeForDevice:(AVCaptureDevice *)device {
    if ([device isAdjustingWhiteBalance] && [device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
        if ([device lockForConfiguration:nil]) {
            [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            [device unlockForConfiguration];
        }
    }
}

/**
 设置曝光

 @param device <#device description#>
 @param point <#point description#>
 */
- (void)setExposureForDevice:(AVCaptureDevice *)device atPoint:(CGPoint)point {
    if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        if ([device lockForConfiguration:nil]) {
            [device setExposurePointOfInterest:point];
            [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
                [device addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(device)];
            }
            [device unlockForConfiguration];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"adjustingExposure"]) {
        AVCaptureDevice *device = (__bridge AVCaptureDevice *)(context);
        if (![device isAdjustingExposure] && [device isExposureModeSupported:AVCaptureExposureModeLocked]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([device lockForConfiguration:nil]) {
                    [device setExposureMode:AVCaptureExposureModeLocked];
                    [device unlockForConfiguration];
                }
            });
        }
    }
}


#pragma mark - 设置扫描区域
- (CGRect)rectOfInterestByScanViewRect:(CGRect)rect {
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    
    CGFloat x = (height - CGRectGetHeight(rect)) / 2 / height;
    CGFloat y = (width - CGRectGetWidth(rect)) / 2 / width;
    
    CGFloat w = CGRectGetHeight(rect) / height;
    CGFloat h = CGRectGetWidth(rect) / width;
    
    return CGRectMake(x, y, w, h);
}

- (void)coverToMetadataOutputRectOfInterestForRect:(CGRect)cropRect {
    CGSize size = _previewLayer.bounds.size;
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 0.0;
    
    if ([_session.sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        p2 = 1920./1080.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPreset352x288]) {
        p2 = 352./288.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        p2 = 1280./720.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetiFrame960x540]) {
        p2 = 960./540.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetiFrame1280x720]) {
        p2 = 1280./720.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetHigh]) {
        p2 = 1920./1080.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetMedium]) {
        p2 = 480./360.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetLow]) {
        p2 = 192./144.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetPhoto]) { // 暂时未查到具体分辨率，但是可以推导出分辨率的比例为4/3
        p2 = 4./3.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetInputPriority]) {
        p2 = 1920./1080.;
    }
    else if (@available(iOS 9.0, *)) {
        if ([_session.sessionPreset isEqualToString:AVCaptureSessionPreset3840x2160]) {
            p2 = 3840./2160.;
        }
    } else {
        
    }
    if ([_previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResize]) {
        _output.rectOfInterest = CGRectMake((cropRect.origin.y)/size.height,(size.width-(cropRect.size.width+cropRect.origin.x))/size.width, cropRect.size.height/size.height,cropRect.size.width/size.width);
    } else if ([_previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (p1 < p2) {
            CGFloat fixHeight = size.width * p2;
            CGFloat fixPadding = (fixHeight - size.height)/2;
            _output.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                        (size.width-(cropRect.size.width+cropRect.origin.x))/size.width,
                                                        cropRect.size.height/fixHeight,
                                                        cropRect.size.width/size.width);
        } else {
            CGFloat fixWidth = size.height * (1/p2);
            CGFloat fixPadding = (fixWidth - size.width)/2;
            _output.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                                        (size.width-(cropRect.size.width+cropRect.origin.x)+fixPadding)/fixWidth,
                                                        cropRect.size.height/size.height,
                                                        cropRect.size.width/fixWidth);
        }
    } else if ([_previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (p1 > p2) {
            CGFloat fixHeight = size.width * p2;
            CGFloat fixPadding = (fixHeight - size.height)/2;
            _output.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                        (size.width-(cropRect.size.width+cropRect.origin.x))/size.width,
                                                        cropRect.size.height/fixHeight,
                                                        cropRect.size.width/size.width);
        } else {
            CGFloat fixWidth = size.height * (1/p2);
            CGFloat fixPadding = (fixWidth - size.width)/2;
            _output.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                                        (size.width-(cropRect.size.width+cropRect.origin.x)+fixPadding)/fixWidth,
                                                        cropRect.size.height/size.height,
                                                        cropRect.size.width/fixWidth);
        }
    }
}


#pragma mark - 扫描辅助设置
- (void)switchBarOrQRCodeAction:(UIButton *)btn {
    [self stopScan];
    btn.selected = !btn.selected;
    if (btn.selected) {
        [self.switchBarOrQRCodeBtn setTitle:NSLocalizedString(@"條形碼", nil) forState:UIControlStateNormal];
        self.tipsLbl.text = NSLocalizedString(@"將二維碼放入框內，\n即可自動掃描", nil);
        [self.metadataObjectTypes removeAllObjects];
        [self.metadataObjectTypes addObject:AVMetadataObjectTypeQRCode];
        
    } else {
        [self.switchBarOrQRCodeBtn setTitle:NSLocalizedString(@"二維碼", nil) forState:UIControlStateNormal];
        self.tipsLbl.text = NSLocalizedString(@"將條形碼放入框內，\n即可自動掃描", nil);
        [self.metadataObjectTypes removeAllObjects];
        [self.metadataObjectTypes addObjectsFromArray:self.originalMetadataObjectTypes];
    }
    self.output.metadataObjectTypes = self.metadataObjectTypes !=nil ? (self.metadataObjectTypes.count > 0 ? self.metadataObjectTypes : SCAN_CODE_TYPE_AVAILABLE) : SCAN_CODE_TYPE_AVAILABLE;
    [self startScan];
}

- (void)onOffTorchBtnAction:(UIButton *)btn {
    btn.selected = !btn.selected;
    [self openOrCloseTorch:btn.selected];
}

- (void)openOrCloseTorch:(BOOL)torch {
    if (torch) { //打开闪光灯
        NSError *error = nil;
        if ([self.device hasTorch]) {
            [self.onOffTorchBtn setTitle:NSLocalizedString(@"關閉補光燈", nil) forState:UIControlStateNormal];
            BOOL locked = [self.device lockForConfiguration:&error];
            if (locked) {
                self.device.torchMode = AVCaptureTorchModeOn;
                [self.device unlockForConfiguration];
            }
        }
    } else {//关闭闪光灯
        if ([self.device hasTorch]) {
            [self.onOffTorchBtn setTitle:NSLocalizedString(@"開啟補光燈", nil) forState:UIControlStateNormal];
            [self.device lockForConfiguration:nil];
            [self.device setTorchMode: AVCaptureTorchModeOff];
            [self.device unlockForConfiguration];
        }
    }
}



#pragma mark - 开启和停止扫描
- (void)startScan {
    timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(scanAnimate) userInfo:nil repeats:YES];
    [timer fire];
    self.seperator.hidden = NO;
    [_session startRunning];
    [self openOrCloseTorch:self.onOffTorchBtn.selected];
}

- (void)stopScan {
    [_session stopRunning];
    [self stopTimer];
    self.seperator.hidden = YES;
    self.isQRCode = NO;
}

- (void)scanAnimate {
    self.seperator.frame = CGRectMake(1 , 0, self.scanAreaWidth - 2, 1.5);
    
    [UIView animateWithDuration:3 animations:^{
        self.seperator.frame = CGRectMake(1 , self.scanAreaHeight, self.scanAreaWidth - 2, 1.5);
    }];
}




#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    [self stopScan];
    if ([metadataObjects[0] isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
        self.isQRCode = [((AVMetadataMachineReadableCodeObject *)metadataObjects[0]).type isEqualToString:AVMetadataObjectTypeQRCode];
    }
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        NSString *content = obj.stringValue;
        if (self.resultBlock) {
            self.resultBlock(content);
        }
    } else {
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"注意" message:@"條碼可能太模糊或者有褶皺掃描失敗了，請更換清晰條碼或者整理好褶皺再重新掃描！" delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles:nil];
        [alter show];
    }
}



#pragma mark - 懒加载
- (NSMutableArray *)metadataObjectTypes {
    if (!_metadataObjectTypes) {
        _metadataObjectTypes = [NSMutableArray array];
    }
    return _metadataObjectTypes;
}

- (void)dealloc {
    [timer invalidate];
    timer = nil;
}

- (void)stopTimer {
    [timer invalidate];
    timer = nil;
}
@end
