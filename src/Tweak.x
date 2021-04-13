#import "WeChat.h"
#import "WPConfig.h"
#import "HWZWeChatMessage.h"

static NSString * const WePayServiceURL = @"http://192.168.0.103:5000";

static WCPayFacingReceiveContorlLogic *s_wcPayFacingReceiveContorlLogic;
static int s_tweakMode;
static NSString *s_lastFixedAmountQRCode;
static BOOL s_isMakeQRCodeFlag;

static NSMutableArray<NSMutableDictionary *> *s_orderTasks;
static NSMutableDictionary *s_orderTask;
static NSInteger s_lastTimestamp = NSIntegerMax;


void makeQRCode(void) {
    if (s_isMakeQRCodeFlag || !s_orderTasks.count) {
        return;
    }

    s_isMakeQRCodeFlag = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        while (s_orderTasks.count) {
            s_orderTask = s_orderTasks[0];
            [s_orderTasks removeObject:s_orderTask];

            s_tweakMode = 2;
            [s_wcPayFacingReceiveContorlLogic WCPayFacingReceiveFixedAmountViewControllerNext:s_orderTask[@"orderAmount"] Description:s_orderTask[@"orderId"]];
        }
        s_isMakeQRCodeFlag = NO;
    });
}

void getOrderTask(void) {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/getOrderTask", WePayServiceURL]];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            NSMutableArray *arr = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            [s_orderTasks addObjectsFromArray:arr];
            makeQRCode();
        }
    }];
    [dataTask resume];
}

void postOrderTask(NSDictionary *orderTask) {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/postOrderTask", WePayServiceURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:orderTask options:kNilOptions error:nil];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
        }
    }];
    [dataTask resume];
}

void postMessage(NSArray *messages) {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/postMessage", WePayServiceURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:messages options:kNilOptions error:nil];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSInteger lastTimestamp = [content integerValue];
            if (lastTimestamp) {
                s_lastTimestamp = lastTimestamp;
            }
        }
    }];
    [dataTask resume];
}

void sendMessage(void) {
    NSArray *messages = [HWZWeChatMessage messagesWithTimestamp:s_lastTimestamp];
    postMessage(messages);
}

void saveOrderTaskLog(NSDictionary *orderTask) {
    static NSString *logPath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        logPath = [cachesDirectory stringByAppendingPathComponent:@"wepay_order.log"];
    });

    NSOutputStream *outputStream = [[NSOutputStream alloc] initToFileAtPath:logPath append:YES];
    [outputStream open];

    NSData *data = [[NSString stringWithFormat:@"%@\n\n", orderTask] dataUsingEncoding:NSUTF8StringEncoding];
    [outputStream write:(const uint8_t *)data.bytes maxLength:data.length];
    [outputStream close];
}


%hook WCPayFacingReceiveContorlLogic

- (id)initWithData:(id)arg1 {
    if (!s_wcPayFacingReceiveContorlLogic) {
        s_wcPayFacingReceiveContorlLogic = self;
    }
    return %orig;
}


- (void)OnGetFixedAmountQRCode:(WCPayTransferGetFixedAmountQRCodeResponse *)arg1 Error:(id)arg2 {
    if (s_tweakMode == 0) {
        %orig;
        return;
    } else if ([self onError:arg2] || [s_lastFixedAmountQRCode isEqualToString:arg1.m_nsFixedAmountQRCode]) {
        return;
    }

    s_lastFixedAmountQRCode = arg1.m_nsFixedAmountQRCode;

    if (s_tweakMode == 1) {
        s_tweakMode = 0;
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
        s_tweakMode = 0;
        s_orderTask[@"orderCode"] = s_lastFixedAmountQRCode;
        saveOrderTaskLog(s_orderTask);
        postOrderTask(s_orderTask);
        [self stopLoading];
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
