#import "WeChat.h"
#import "WPConfig.h"
#import "WPChatMessage.h"

NSString *WePayServiceURL;

static WCPayFacingReceiveContorlLogic *s_wcPayFacingReceiveContorlLogic;
static int s_tweakMode;
static NSString *s_lastFixedAmountQRCode;

static NSMutableArray<NSMutableDictionary *> *s_orderTasks;
static NSMutableArray<NSMutableDictionary *> *s_orderTasks2;
static NSMutableDictionary *s_orderTask;
static NSInteger s_lastTimestamp = NSIntegerMax;
WPChatMessage *chatMessage;


static void makeQRCode() {
    static BOOL isMake;
    if(!isMake){
        isMake = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            while (s_orderTasks.count) {
                NSMutableDictionary * orderTask = s_orderTasks[0];
                [s_orderTasks removeObject:orderTask];
                [s_wcPayFacingReceiveContorlLogic WCPayFacingReceiveFixedAmountViewControllerNext:orderTask[@"orderAmount"] Description:orderTask[@"orderId"]];
            }
            isMake = NO;
        });
    }
}


static void getOrderTask() {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/getOrderTask", WePayServiceURL]];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            NSMutableArray *arr = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            [s_orderTasks addObjectsFromArray:arr];
            if(s_orderTasks.count){
                makeQRCode();
            }
        }
    }];
    [dataTask resume];
}


static void postOrderTask(NSDictionary *orderTask) {
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


static void postMessage(NSArray *messages) {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/postMessage", WePayServiceURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:messages options:kNilOptions error:nil];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            s_lastTimestamp = [content integerValue];
        }
    }];
    [dataTask resume];
}


static void saveOrderTaskLog(NSDictionary *orderTask) {
    static NSString *logPath = nil;
    if (!logPath) {
        NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        logPath = [cachesDirectory stringByAppendingPathComponent:@"WePay.log"];
    }

    NSOutputStream *outputStream = [[NSOutputStream alloc] initToFileAtPath:logPath append:YES];
    [outputStream open];

    NSData *data = [[NSString stringWithFormat:@"%@\n\n", orderTask] dataUsingEncoding:NSUTF8StringEncoding];
    [outputStream write:data.bytes maxLength:data.length];
    [outputStream close];
}


%hook WCPayFacingReceiveContorlLogic

- (id)initWithData:(id)arg1 {
    s_wcPayFacingReceiveContorlLogic = self;
    return %orig;
}

- (void)continueOnSuccessfullyGetShortTermQrcodeResp:(int)arg1 hasDesc:(bool)arg2 {
    if(s_tweakMode==1){
        WCPayControlData *m_data = [self valueForKey:@"m_data"];
        NSString *desc=m_data.fixedAmountCollectionData.desc;
        for (int i=0; i<s_orderTasks2.count; i++) {
            NSMutableDictionary *orderTask=s_orderTasks2[i];
            if([orderTask[@"orderId"] isEqualToString:desc]){
                orderTask[@"orderCode"]=m_data.fixedAmountCollectionData.QRCodeURL;
                [s_orderTasks2 removeObject:orderTask];
                saveOrderTaskLog(orderTask);
                postOrderTask(orderTask);
                return;
            }
        }
    }else{
        %orig;
    }
}

- (void)OnGetFixedAmountQRCode:(WCPayTransferGetFixedAmountQRCodeResponse *)arg1 Error:(id)arg2 {
    if ([self onError:arg2] || [s_lastFixedAmountQRCode isEqualToString:arg1.m_nsFixedAmountQRCode]) {
        return;
    }

    s_lastFixedAmountQRCode = arg1.m_nsFixedAmountQRCode;

    if (s_tweakMode == 0) {
        s_orderTask[@"orderCode"] = s_lastFixedAmountQRCode;
        saveOrderTaskLog(s_orderTask);
        postOrderTask(s_orderTask);
        [self stopLoading];
    } else if (s_tweakMode == 1) {
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
        %orig;
    }
}

%end


// 接收消息
%hook CMessageMgr

- (void)onNewSyncAddMessage:(id)arg1 {
    %orig;

    if([[arg1 valueForKey:@"m_nsFromUsr"] isEqualToString:@"gh_3dfda90e39d6"]){
    NSArray *messages = [chatMessage messagesWithTimestamp:s_lastTimestamp];
    postMessage(messages);
    }
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
    NSString *amount = [NSString stringWithFormat:@"%d", arc4random_uniform(100) + 1];
    [s_wcPayFacingReceiveContorlLogic WCPayFacingReceiveFixedAmountViewControllerNext:amount Description:@"我是备注"];
}

%end


// 二维码收款 > 设置金额
%hook WCPayFacingReceiveFixedAmountViewController

- (void)onNext {
    s_tweakMode = 2;
    %orig;
}

%end


// 微信
%hook NewMainFrameViewController

- (void)viewDidLoad {
    %orig;
    WePayServiceURL = [WPConfig sharedConfig].serviceURL;
    s_orderTasks = [NSMutableArray array];
    s_orderTasks2 = [NSMutableArray array];

    NSString *currentUserDocumentPath = [%c(MMContext) currentUserDocumentPath];
    NSString *brandMsgDbPath = [currentUserDocumentPath stringByAppendingPathComponent:@"Brand/BrandMsg.db"];
    chatMessage = [[WPChatMessage alloc] initWithDbPath:brandMsgDbPath];

    if ([WPConfig sharedConfig].serviceEnable) {
        [%c(WCUIAlertView) showAlertWithTitle:@"WePay" message:@"WePay 需要打开二维码收款" btnTitle:@"打开二维码收款" target:self sel:@selector(handleOpenFace2FaceReceiveMoney)];
    }
}

%new
- (void)handleOpenFace2FaceReceiveMoney {
    [self openFace2FaceReceiveMoney];

    [NSTimer scheduledTimerWithTimeInterval:2.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
        getOrderTask();
    }];
}

%end
