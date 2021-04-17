#import "WeChat.h"
#import "WPConfig.h"
#import "HWZWeChatMessage.h"

NSString * const WPServiceURL = @"http://192.168.0.103:5000";

static NSMutableArray *WPOrders;
static int WPMode;
static WCPayFacingReceiveContorlLogic *WCPayFacingReceive;

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
    WPLog([NSString stringWithFormat:@"%@", order]);

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


%hook WCPayFacingReceiveContorlLogic

- (id)initWithData:(id)arg1 {
    WCPayFacingReceive = self;
    return %orig;
}

- (void)OnGetFixedAmountQRCode:(WCPayTransferGetFixedAmountQRCodeResponse *)arg1 Error:(id)arg2 {
    if (WPMode == 0) {
        %orig;
        return;
    }

    static NSString *lastFixedAmountQRCode;
    if (![self onError:arg2] && ![lastFixedAmountQRCode isEqualToString:arg1.m_nsFixedAmountQRCode]) {
        lastFixedAmountQRCode = arg1.m_nsFixedAmountQRCode;
        WCPayControlData *m_data = [self valueForKey:@"m_data"];
        m_data.m_nsFixedAmountReceiveMoneyQRCode = arg1.m_nsFixedAmountQRCode;
        m_data.fixed_qrcode_level = arg1.qrcode_level;
        m_data.m_enWCPayFacingReceiveMoneyScene = 2;

        [self stopLoading];

        if (WPMode == 1) {
            id viewController = [[%c(CAppViewControllerManager) getAppViewControllerManager] getTopViewController];
            if ([viewController isKindOfClass:%c(WCPayFacingReceiveQRCodeViewController)]) {
                [(WCPayFacingReceiveQRCodeViewController *)viewController refreshViewWithData:m_data];
            }
        } else if (WPMode == 2) {
            for (int i = 0; i < [WPOrders count]; i++) {
                NSMutableDictionary *order = WPOrders[i];
                if ([order[@"orderId"] isEqualToString:m_data.m_nsFixedAmountReceiveMoneyDesc]) {
                    order[@"orderCode"] = lastFixedAmountQRCode;
                    [WPOrders removeObject:order];
                    WPPostOrder(order);
                    break;
                }
            }
        }
    }
}

%end


// 接收消息
%hook CMessageMgr

- (void)onNewSyncAddMessage:(id)arg1 {
    %orig;
    // WPPostMessage();
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
    WPMode = 1;
    NSString *amount = [NSString stringWithFormat:@"%d", arc4random_uniform(100)];
    [WCPayFacingReceive WCPayFacingReceiveFixedAmountViewControllerNext:amount Description:@"我是备注"];
}

%end


// 二维码收款 > 设置金额
%hook WCPayFacingReceiveFixedAmountViewController

- (void)onNext {
    WPMode = 0;
    %orig;
}

%end


// 微信
%hook NewMainFrameViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    if (!WCPayFacingReceive) {
        [%c(WCUIAlertView) showAlertWithTitle:@"WePay" message:@"WePay 需要打开二维码收款" btnTitle:@"打开二维码收款" target:self sel:@selector(handleOpenFace2FaceReceiveMoney)];
    }
}

%new
- (void)handleOpenFace2FaceReceiveMoney {
    [self openFace2FaceReceiveMoney];
    WPOrders = [NSMutableArray array];

    [NSTimer scheduledTimerWithTimeInterval:2.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
        // WPPostOrder(nil);
    }];
}

%end
