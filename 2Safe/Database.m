//
//  Database.m
//  2Safe
//
//  Created by Drunk on 14.01.13.
//  Copyright (c) 2013 zaopark. All rights reserved.
//

#import "Database.h"
#import "AppDelegate.h"

@implementation Database {
    FMDatabaseQueue *_dbQueue;
}

+ (id)databaseForAccount:(NSString *)acc {
    return [[self alloc] initForAccount:acc];
}

+ (NSString *) dbFileForAccount:(NSString *)acc {
    NSString *as = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *appdirectory = [as stringByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appdirectory isDirectory:nil])
        [[NSFileManager defaultManager] createDirectoryAtPath:appdirectory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *_dbFile = [appdirectory stringByAppendingPathComponent:[acc stringByAppendingString:@".db"]];
    return _dbFile;
}

+ (BOOL) isDbExistsForAccount:(NSString *)acc {
    __block BOOL res = false;
    NSString *_dbFile = [Database dbFileForAccount:acc];
    if ([[NSFileManager defaultManager] fileExistsAtPath:_dbFile]) {
        //check for db & table existance
        FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:_dbFile];
        [dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *r = [db executeQuery:@"SELECT count(name) FROM sqlite_master WHERE type='table' AND name='elements'"];
            while ([r next])
                if ([r intForColumnIndex:0] > 0) {
                    res = true;
                }
        }];
    }
    return res;
}

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class Database. Use -initForAccount:"
                                 userInfo:nil];
    return nil;
}

-(id)initForAccount:(NSString *)acc {
    if (self = [super init]) {
        NSString *_dbFile = [Database dbFileForAccount:acc];
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:_dbFile];
        if (![Database isDbExistsForAccount:acc]) {
            [_dbQueue inDatabase:^(FMDatabase *db) {
                [db executeUpdate:@"CREATE TABLE elements ("
                 "id PRIMARY KEY NOT NULL,"
                 "name TEXT NOT NULL,"
                 "hash TEXT,"
                 "mdate TEXT,"
                 "pid INTEGER REFERENCES elements(id) ON UPDATE CASCADE ON DELETE CASCADE)"
                 ];
                [db executeUpdate:@"INSERT INTO elements VALUES (?, ?, NULL, NULL, NULL)",
                 AppDelegate.RootFolderId, @"root"];
            }];
        }
        [_dbQueue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"PRAGMA foreign_keys=1"];
        }];
        return self;
    } else return nil;
}

+ (FSElement *) elementFromDict:(NSDictionary *)d {
    FSElement *e = [[FSElement alloc] init];
    e.id = [NSString stringWithFormat:@"%@",[d objectForKey:@"id"]];
    e.name = [d objectForKey:@"name"];
    e.hash = [d objectForKey:@"hash"];
    e.mdate = [NSString stringWithFormat:@"%@",[d objectForKey:@"mdate"]];
    e.pid = [NSString stringWithFormat:@"%@",[d objectForKey:@"pid"]];
    return e;
}
+ (NSDictionary *) dictionaryFromEl:(FSElement *)el {
    return [NSDictionary dictionaryWithObjectsAndKeys:el.id,@"id",el.name,@"name",el.hash,@"hash",el.mdate,@"mdate",el.pid,@"pid", nil];
}

- (BOOL)insertElement:(FSElement *)el {
    __block BOOL res = NO;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        res = [db executeUpdate:@"INSERT into elements(id,name,hash,mdate,pid) VALUES (:id, :name, :hash, :mdate, :pid)" withParameterDictionary:[Database dictionaryFromEl:el]];
        if ([db hadError]) NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }];
    return res;
}

- (FSElement *)getElementById:(NSString *)idx withFullFilePath:(BOOL)ffp{
    __block FSElement *e;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *res = [db executeQuery:@"SELECT * from elements WHERE id=?", idx];
        if ([db hadError]) NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        NSDictionary *d;
        while ([res next])
            d = [res resultDictionary];
        if (!d) e = nil;
        else {
            e = [Database elementFromDict:d];
        }
    }];
    if (e && ffp) {
        e.filePath = [self getFullFilePathForEl:e];
    }
    return e;
}

- (FSElement *) getElementById:(NSString *)idx {
    return [self getElementById:idx withFullFilePath:NO];
}

- (NSString *) getFullFilePathForEl:(FSElement *)e {
    FSElement *p = e;
    while ([p.pid isNotEqualTo:@"<null>"]) {
        e.filePath = [p.name stringByAppendingPathComponent:e.filePath];
        p = [self getElementById:p.pid];
    }
    return e.filePath;
}

-(FSElement *) getElementByName:(NSString *)namex withPID:(NSString*)pidx withFullFilePath:(BOOL)ffp{
    __block FSElement *e;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT * from elements WHERE name=? AND pid=?";
        if ((pidx == nil)||([pidx isEqualTo:@"NULL"])) sql = @"SELECT * from elements WHERE name=? AND pid ISNULL";
        FMResultSet *res = [db executeQuery:sql, namex, pidx];
        if ([db hadError]) NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        NSDictionary *d;
        while ([res next])
            d = [res resultDictionary];
        if (!d) e = nil;
        else e = [Database elementFromDict:d];
    }];
    if (e && ffp) {
        e.filePath = [self getFullFilePathForEl:e];
    }
    return e;
}
-(FSElement *) getElementByName:(NSString *)namex withPID:(NSString*)pidx {
    return [self getElementByName:namex withPID:pidx withFullFilePath:NO];
}

- (BOOL)deleteElementById:(NSString *)idx {
    __block BOOL res = NO;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        res = [db executeUpdate:@"DELETE from elements WHERE id=?", idx];
        if ([db hadError]) NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }];
    return res;
}

- (BOOL)updateElementWithId:(NSString *)idx withValues:(FSElement *)el{
    __block BOOL res = NO;
    NSDictionary *val = [Database dictionaryFromEl:el];
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
- (NSArray *)childElementsOfId:(NSString *)idx {
    __block NSMutableArray *childs = [NSMutableArray arrayWithCapacity:30];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *res = [db executeQuery:@"SELECT * from elements WHERE pid=?", idx];
        if ([db hadError]) NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        NSDictionary *d;
        while ([res next]) {
            d = [res resultDictionary];
            [childs addObject:[Database elementFromDict:d]];
        }
    }];
    return childs;
}

@end
