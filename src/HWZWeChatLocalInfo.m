//
//  HWZWeChatLocalInfo.m
//  WePay
//
//  Created by he55 on 5/20/20.
//  Copyright © 2020 he55. All rights reserved.
//

#import "HWZWeChatLocalInfo.h"
#import "HWZWeChatUserInfoItem.h"
#import "NSString+MD5.h"

@implementation HWZWeChatLocalInfo

+ (HWZWeChatUserInfoItem *)userInfo {
    NSString *sandboxPath = [self sandboxPath];
    if (!sandboxPath) {
        return nil;
    }

    HWZWeChatUserInfoItem *userInfo = [[HWZWeChatUserInfoItem alloc] init];
    userInfo.sandboxPath = sandboxPath;

    NSString *localInfoFilePath = [sandboxPath stringByAppendingPathComponent:@"Documents/LocalInfo.lst"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:localInfoFilePath]) {
        return userInfo;
    }

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:localInfoFilePath];
    NSArray *objects = dict[@"$objects"];
    if (!objects) {
        return userInfo;
    }

    userInfo.wxid = objects[2];
    userInfo.userId = objects[3];
    userInfo.userName = objects[4];
    userInfo.dbPath = [NSString stringWithFormat:@"%@/Documents/%@/%@", sandboxPath, [userInfo.wxid MD5String], @"Brand/BrandMsg.db"];

    return userInfo;
}


+ (NSString *)sandboxPath {
    NSString *applicationPath = @"/var/mobile/Containers/Data/Application";

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directories = [fileManager contentsOfDirectoryAtPath:applicationPath error:nil];

    for (NSString *directory in directories) {
        NSString *sandboxPath = [applicationPath stringByAppendingPathComponent:directory];
        NSString *plistPath = [sandboxPath stringByAppendingPathComponent:@".com.apple.mobile_container_manager.metadata.plist"];

        if (![fileManager fileExistsAtPath:plistPath]) {
            continue;
        }

        NSDictionary *metadata = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        if ([metadata[@"MCMMetadataIdentifier"] isEqualToString:@"com.tencent.xin"]) {
            return sandboxPath;
        }
    }
    return nil;
}

@end
