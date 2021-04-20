//
//  HWZWeChatMessage.m
//  WePay
//
//  Created by he55 on 5/19/20.
//  Copyright © 2020 he55. All rights reserved.
//

#import "HWZWeChatMessage.h"
#import "fmdb/FMDB.h"

@implementation HWZWeChatMessage {
    NSString *_dbPath;
    NSString *_tableName;
}

- (instancetype)initWithDbPath:(NSString *)dbPath {
    if (self = [super init]) {
        _dbPath = dbPath;
    }
    return self;
}


- (NSString *)chatTableName {
    FMDatabase *db = [FMDatabase databaseWithPath:_dbPath];
    if (![db open]) {
        return nil;
    }
    
    FMResultSet *resultSet = [db executeQuery:@"SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'chat/_%' ESCAPE '/' ORDER BY name"];
    if (!resultSet) {
        return nil;
    }
    
    NSMutableArray *arr = [NSMutableArray array];
    while ([resultSet next]) {
        [arr addObject:[resultSet stringForColumnIndex:0]];
    }
    
    for (NSString *name in arr) {
        resultSet = [db executeQuery:[NSString stringWithFormat:@"SELECT Message FROM %@ WHERE Des = 0 AND Type = 1 ORDER BY CreateTime DESC LIMIT 1", name]];
        if ([resultSet next] && [[resultSet stringForColumnIndex:0] isEqualToString:@"123qwe"]) {
            [db close];
            return name;
        }
    }
    
    [db close];
    return nil;
}


- (NSDictionary *)messageWithMessageId:(NSString *)messageId {
    FMDatabase *db = [FMDatabase databaseWithPath:_dbPath];
    if (![db open]) {
        return nil;
    }
    
    FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"SELECT CreateTime, MesSvrID, Message FROM %@ WHERE MesSvrID = ?", _tableName], messageId];
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


- (NSArray *)messagesWithTimestamp:(NSInteger)timestamp {
    FMDatabase *db = [FMDatabase databaseWithPath:_dbPath];
    if (![db open]) {
        return nil;
    }
    
    FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"SELECT CreateTime, MesSvrID, Message FROM %@ WHERE Des = 1 AND Type = 49 AND CreateTime > ? AND Message LIKE '%%<![CDATA[we/_%%' ESCAPE '/' ORDER BY CreateTime", _tableName], @(timestamp)];
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
