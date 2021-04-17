#import "WeChat.h"
#import "WPConfig.h"
#import "HWZWeChatMessage.h"

static NSString * const WePayServiceURL = @"http://192.168.0.103:5000";

static WCPayFacingReceiveContorlLogic *s_wcPayFacingReceiveContorlLogic;
static int s_tweakMode;
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
