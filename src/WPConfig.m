//
//  WPConfig.m
//  WeChatRedEnvelop
//
//  Created by 杨志超 on 2017/2/22.
//  Copyright © 2017年 swiftyper. All rights reserved.
//

#import "WPConfig.h"

static NSString * const kWPServiceEnableKey = @"WPServiceEnable";
static NSString * const kWPServiceURLKey = @"WPServiceURL";

@implementation WPConfig {
    NSUserDefaults *_userDefaults;
}

+ (instancetype)sharedConfig {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}


- (instancetype)init {
    if (self = [super init]) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _serviceEnable = [_userDefaults boolForKey:kWPServiceEnableKey];
        _serviceURL = [_userDefaults stringForKey:kWPServiceURLKey];
    }
    return self;
}


- (void)setServiceEnable:(BOOL)serviceEnable {
    _serviceEnable = serviceEnable;
    [_userDefaults setBool:serviceEnable forKey:kWPServiceEnableKey];
    [_userDefaults synchronize];
}


- (void)setServiceURL:(NSString *)serviceURL {
    _serviceURL = serviceURL;
    [_userDefaults setObject:serviceURL forKey:kWPServiceURLKey];
    [_userDefaults synchronize];
}

@end
