//
//  WPConfig.h
//  WeChatRedEnvelop
//
//  Created by 杨志超 on 2017/2/22.
//  Copyright © 2017年 swiftyper. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WPConfig : NSObject

+ (instancetype)sharedConfig;

@property (nonatomic, assign) BOOL serviceEnable;
@property (nonatomic, copy) NSString *serviceURL;
@property (nonatomic, assign) BOOL messageRevokeEnable;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
