//
//  WPChatMessage.m
//  WePay
//
//  Created by he55 on 5/19/20.
//  Copyright © 2020 he55. All rights reserved.
//

#import "WPChatMessage.h"
#import "fmdb/FMDB.h"

    NSString *_tableName=@"Chat_c156d1a38aa55c427b37494e8f31104c";

@implementation WPChatMessage {
    NSString *_dbPath;
}

- (instancetype)initWithDbPath:(NSString *)dbPath {
    if (self = [super init]) {
        _dbPath = dbPath;
    }
    return self;
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
    
    FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"SELECT CreateTime, MesSvrID, Message FROM %@ WHERE Des = 1 AND Type = 49 AND CreateTime > ? ORDER BY CreateTime", _tableName], @(timestamp)];
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
