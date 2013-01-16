//
//  Database.m
//  2Safe
//
//  Created by Drunk on 14.01.13.
//  Copyright (c) 2013 zaopark. All rights reserved.
//

#import "Database.h"

@implementation Database {
    FMDatabaseQueue *_dbQueue;
}

+ (id)databaseForAccount:(NSString *)acc {
    return [[self alloc] initForAccount:acc];
}

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class Database. Use -initForAccount:"
                                 userInfo:nil];
    return nil;
}

-(id)initForAccount:(NSString *)acc {
    if (self = [super init]) {
        //check for Application Support directory existance
        NSString *as = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *appdirectory = [as stringByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:appdirectory isDirectory:nil])
            [[NSFileManager defaultManager] createDirectoryAtPath:appdirectory withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *_dbFile = [appdirectory stringByAppendingPathComponent:[acc stringByAppendingString:@".db"]];
        
        //check for db & table existance
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:_dbFile];
        [_dbQueue inDatabase:^(FMDatabase *db) {
            //TURN ON foreign_keys support (REQUIRED!)
            [db executeUpdate:@"PRAGMA foreign_keys=1"];

            FMResultSet *r = [db executeQuery:@"SELECT count(name) FROM sqlite_master WHERE type='table' AND name='elements'"];
            while ([r next])
                if ([r intForColumnIndex:0] == 0) {
                    [db executeUpdate:@"CREATE TABLE elements ("
                     "id PRIMARY KEY NOT NULL,"
                     "name TEXT NOT NULL,"
                     "hash TEXT,"
                     "mdate TEXT,"
                     "pid INTEGER REFERENCES elements(id) ON UPDATE CASCADE ON DELETE CASCADE)"
                     ];
                }
        }];
        
        return self;
    } else return nil;
}

- (BOOL)insertElement:(NSDictionary *)el {
    __block BOOL res = NO;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        res = [db executeUpdate:@"INSERT into elements(id,name,hash,mdate,pid) VALUES (:id, :name, :hash, :mdate, :pid)" withParameterDictionary:el];
        if ([db hadError]) NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }];
    return res;
}

- (NSDictionary *)getElementById:(NSString *)idx {
    __block NSDictionary *d;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *res = [db executeQuery:@"SELECT * from elements WHERE id=?", idx];
        if ([db hadError]) NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        while ([res next])
            d = [res resultDictionary];
    }];
    return d;
}

- (BOOL)deleteElementById:(NSString *)idx {
    __block BOOL res = NO;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        res = [db executeUpdate:@"DELETE from elements WHERE id=?", idx];
        if ([db hadError]) NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }];
    return res;
}

- (BOOL)updateElementWithId:(NSString *)idx withValues:(NSDictionary *)val{
    __block BOOL res = NO;
    NSMutableString *sql = [NSMutableString stringWithString:@"UPDATE elements SET name = name"];
    for (id key in val) {
        [sql appendFormat:@",%@ = :%@", key, key];
    }
    [sql appendFormat:@" WHERE id='%@'", idx];

    [_dbQueue inDatabase:^(FMDatabase *db) {
        res = [db executeUpdate:sql withParameterDictionary:val];
        if ([db hadError]) NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }];
    return res;
}

@end
