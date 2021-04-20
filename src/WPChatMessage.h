//
//  WPChatMessage.h
//  WePay
//
//  Created by he55 on 5/19/20.
//  Copyright © 2020 he55. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WPChatMessage : NSObject

- (instancetype)initWithDbPath:(NSString *)dbPath;

- (NSDictionary *)messageWithMessageId:(NSString *)messageId;
- (NSArray *)messagesWithTimestamp:(NSInteger)timestamp;

@end

NS_ASSUME_NONNULL_END
