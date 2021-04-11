//
//  HWZSettings.h
//  WePay
//
//  Created by he55 on 6/14/20.
//  Copyright © 2020 he55. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * _Nullable HWZDbPath;
extern NSString * _Nullable HWZTableName;
extern NSString * _Nullable HWZOrderServiceCallbackURL;

NS_ASSUME_NONNULL_BEGIN

@interface HWZSettings : NSObject

+ (BOOL)loadSettings;

@end

NS_ASSUME_NONNULL_END
