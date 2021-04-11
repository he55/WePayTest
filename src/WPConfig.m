//
//  WPConfig.m
//  WeChatRedEnvelop
//
//  Created by 杨志超 on 2017/2/22.
//  Copyright © 2017年 swiftyper. All rights reserved.
//

#import "WPConfig.h"

static NSString * const kServiceEnableKey = @"ServiceEnable";
static NSString * const kServiceURLKey = @"ServiceURL";
static NSString * const kMessageRevokeEnableKey = @"MessageRevokeEnable";

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
        _serviceEnable = [_userDefaults boolForKey:kServiceEnableKey];
        _serviceURL = [_userDefaults stringForKey:kServiceURLKey];
        _messageRevokeEnable = [_userDefaults boolForKey:kMessageRevokeEnableKey];
    }
    return self;
}


- (void)setServiceEnable:(BOOL)serviceEnable {
    _serviceEnable = serviceEnable;
    [_userDefaults setBool:serviceEnable forKey:kServiceEnableKey];
    [_userDefaults synchronize];
}


- (void)setServiceURL:(NSString *)serviceURL {
    _serviceURL = serviceURL;
    [_userDefaults setObject:serviceURL forKey:kServiceURLKey];
    [_userDefaults synchronize];
}


- (void)setMessageRevokeEnable:(BOOL)messageRevokeEnable {
    _messageRevokeEnable = messageRevokeEnable;
    [_userDefaults setBool:messageRevokeEnable forKey:kMessageRevokeEnableKey];
    [_userDefaults synchronize];
}

@end
