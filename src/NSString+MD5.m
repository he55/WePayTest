//
//  NSString+MD5.m
//  WePay
//
//  Created by he55 on 5/20/20.
//  Copyright © 2020 he55. All rights reserved.
//

#import "NSString+MD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (MD5)

- (NSString *)MD5String {
    const char * pointer = [self UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];

#pragma clang diagnostic push
#pragma clang diagnostic warning "-Wdeprecated-declarations"
    CC_MD5(pointer, (CC_LONG)strlen(pointer), md5Buffer);
#pragma clang diagnostic pop

    NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x",md5Buffer[i]];
    }

    return md5String;
}

@end
