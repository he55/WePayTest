//
//  HWZWeChatMessage.m
//  WePay
//
//  Created by he55 on 5/19/20.
//  Copyright © 2020 he55. All rights reserved.
//

#import "HWZWeChatMessage.h"
#import "HWZSettings.h"
#import "fmdb/FMDB.h"

@implementation HWZWeChatMessage

+ (NSDictionary<NSString *, id> *)messageWithMessageId:(NSString *)messageId {
    FMDatabase *db = [FMDatabase databaseWithPath:HWZDbPath];
    if (![db open]) {
        return nil;
    }

    static NSString * sql = @"SELECT CreateTime, MesSvrID, Message FROM %@ WHERE MesSvrID = ?";
    FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:sql, HWZTableName], messageId];

    if (!resultSet) {
        return nil;
    }

    if (![resultSet next]) {
        return nil;
    }

    NSDictionary *message = @{
        @"createTime": @([resultSet intForColumnIndex:0]),
        @"messageId": [resultSet stringForColumnIndex:1],
        @"message": [resultSet stringForColumnIndex:2]
    };

    [db close];

    return message;
}


+ (NSArray<NSDictionary<NSString *, id> *> *)messagesWithTimestamp:(NSInteger)timestamp {
    FMDatabase *db = [FMDatabase databaseWithPath:HWZDbPath];
    if (![db open]) {
        return nil;
    }

    static NSString * sql = @"SELECT CreateTime, MesSvrID, Message FROM %@ WHERE Des = 1 AND Type = 49 AND CreateTime > ? AND Message LIKE '%%<![CDATA[we/_%%' ESCAPE '/' ORDER BY CreateTime";
    FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:sql, HWZTableName], @(timestamp)];

    if (!resultSet) {
        return nil;
    }

    NSMutableArray *messages = [NSMutableArray array];
    while ([resultSet next]) {
        NSDictionary *message = @{
            @"createTime": @([resultSet intForColumnIndex:0]),
            @"messageId": [resultSet stringForColumnIndex:1],
            @"message": [resultSet stringForColumnIndex:2]
        };
        [messages addObject:message];
    }

    [db close];

    return messages;
}

@end
