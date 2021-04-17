#import "WeChat.h"
#import "WPConfig.h"
#import "HWZWeChatMessage.h"

NSString * const WPServiceURL = @"http://192.168.0.103:5000";

NSMutableArray *WPOrders;
int WPMode;
WCPayFacingReceiveContorlLogic *WCPayFacingReceive;


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
