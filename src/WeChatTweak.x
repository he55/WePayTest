#import "WeChat.h"
#import "WPConfig.h"
#import "HWZWeChatMessage.h"

NSString * const WPServiceURL = @"http://192.168.0.103:5000";

NSMutableArray *WPOrders;
int WPMode;
WCPayFacingReceiveContorlLogic *WCPayFacingReceive;

void WPMakeQRCode(void) {
    static BOOL flag;
    if (!flag && WPOrders.count) {
        flag = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *order = WPOrders[0];
            WPMode = 2;
            [WCPayFacingReceive WCPayFacingReceiveFixedAmountViewControllerNext:order[@"orderAmount"] Description:order[@"orderId"]];
            flag = NO;
        });
    }
}

void WPPostOrder(NSDictionary *order) {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/postOrder", WPServiceURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:order options:kNilOptions error:nil];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([obj isKindOfClass:[NSArray class]] && [obj count]) {
                [WPOrders addObjectsFromArray:obj];
                WPMakeQRCode();
            }
        }
    }];
    [dataTask resume];
}

void WPPostMessage(void) {
    static NSInteger lastTimestamp = NSIntegerMax;
    NSArray *messages = [HWZWeChatMessage messagesWithTimestamp:lastTimestamp];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/postMessage", WPServiceURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:messages options:kNilOptions error:nil];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSInteger timestamp = [content integerValue];
            if (timestamp) {
                lastTimestamp = timestamp;
            }
        }
    }];
    [dataTask resume];
}

void WPLog(NSString *log) {
    static NSString *logPath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        logPath = [cachesDirectory stringByAppendingPathComponent:@"wepay.log"];
    });

    NSOutputStream *outputStream = [[NSOutputStream alloc] initToFileAtPath:logPath append:YES];
    [outputStream open];

    NSData *data = [[NSString stringWithFormat:@"%@\n\n", log] dataUsingEncoding:NSUTF8StringEncoding];
    [outputStream write:(const uint8_t *)data.bytes maxLength:data.length];
    [outputStream close];
}



%hook WCPayFacingReceiveContorlLogic

- (id)initWithData:(id)arg1 {
    s_wcPayFacingReceiveContorlLogic = self;
    return %orig;
}


- (void)OnGetFixedAmountQRCode:(WCPayTransferGetFixedAmountQRCodeResponse *)arg1 Error:(id)arg2 {
    if (s_tweakMode == 0) {
        %orig;
        return;
    }

    static NSString *lastFixedAmountQRCode;

    if (![self onError:arg2] && ![lastFixedAmountQRCode isEqualToString:arg1.m_nsFixedAmountQRCode]) {
        lastFixedAmountQRCode = arg1.m_nsFixedAmountQRCode;

        if (s_tweakMode == 1) {
            WCPayControlData *m_data = [self valueForKey:@"m_data"];
            m_data.m_nsFixedAmountReceiveMoneyQRCode = arg1.m_nsFixedAmountQRCode;
            m_data.fixed_qrcode_level = arg1.qrcode_level;
            m_data.m_enWCPayFacingReceiveMoneyScene = 2;

            [self stopLoading];
            id viewController = [[%c(CAppViewControllerManager) getAppViewControllerManager] getTopViewController];
            if ([viewController isKindOfClass:%c(WCPayFacingReceiveQRCodeViewController)]) {
                [(WCPayFacingReceiveQRCodeViewController *)viewController refreshViewWithData:m_data];
            }
        } else if (s_tweakMode == 2) {
            s_orderTask[@"orderCode"] = lastFixedAmountQRCode;
            saveOrderTaskLog(s_orderTask);
            postOrderTask(s_orderTask);
            [self stopLoading];
        }
    }
}

%end


// 接收消息
%hook CMessageMgr

- (void)onNewSyncAddMessage:(id)arg1 {
    %orig;
    // sendMessage();
}

%end


// 二维码收款
%hook WCPayFacingReceiveQRCodeViewController

- (void)viewDidLoad {
    %orig;

    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"测试" style:UIBarButtonItemStylePlain target:self action:@selector(handleCodeTest)];
    [barButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.8]} forState:UIControlStateNormal];
    [barButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.8]} forState:UIControlStateHighlighted];

    self.navigationItem.rightBarButtonItem = barButtonItem;
}

%new
- (void)handleCodeTest {
    s_tweakMode = 1;
    NSString *amount = [NSString stringWithFormat:@"%d", arc4random_uniform(100)];
    [s_wcPayFacingReceiveContorlLogic WCPayFacingReceiveFixedAmountViewControllerNext:amount Description:@"我是备注"];
}

%end


// 二维码收款 > 设置金额
%hook WCPayFacingReceiveFixedAmountViewController

- (void)onNext {
    s_tweakMode = 0;
    %orig;
}

%end


// 微信
%hook NewMainFrameViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    if (!s_wcPayFacingReceiveContorlLogic) {
        [%c(WCUIAlertView) showAlertWithTitle:@"WePay" message:@"WePay 需要打开二维码收款" btnTitle:@"打开二维码收款" target:self sel:@selector(handleOpenFace2FaceReceiveMoney)];
    }
}

%new
- (void)handleOpenFace2FaceReceiveMoney {
    [self openFace2FaceReceiveMoney];
    s_orderTasks = [NSMutableArray array];

    [NSTimer scheduledTimerWithTimeInterval:2.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
        getOrderTask();
    }];
}

%end
