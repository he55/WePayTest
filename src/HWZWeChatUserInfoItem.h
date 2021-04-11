//
//  HWZWeChatUserInfoItem.h
//  WePay
//
//  Created by he55 on 5/20/20.
//  Copyright © 2020 he55. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HWZWeChatUserInfoItem : NSObject

@property (nonatomic, copy) NSString *wxid;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *sandboxPath;
@property (nonatomic, copy) NSString *dbPath;

@end

NS_ASSUME_NONNULL_END
