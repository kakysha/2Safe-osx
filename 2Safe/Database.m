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

+ (FSElement *) elementFromDict:(NSDictionary *)d {
    FSElement *e = [[FSElement alloc] init];
    e.id = [d objectForKey:@"id"];
    e.name = [d objectForKey:@"name"];
    e.hash = [d objectForKey:@"hash"];
    e.mdate = [d objectForKey:@"mdate"];
    e.pid = [d objectForKey:@"pid"];
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

- (FSElement *)getElementById:(NSString *)idx {
    __block FSElement *e;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *res = [db executeQuery:@"SELECT * from elements WHERE id=?", idx];
        if ([db hadError]) NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        NSDictionary *d;
        while ([res next])
            d = [res resultDictionary];
        if (!d) e = nil;
        else e = [Database elementFromDict:d];
    }];
    return e;
}

-(FSElement*)getElementByName:(NSString *)namex withPID:(NSString*)pidx {
    __block FSElement *e;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *res = [db executeQuery:@"SELECT * from elements WHERE name=? AND pid=?", namex, pidx];
        if ([db hadError]) NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        NSDictionary *d;
        while ([res next])
            d = [res resultDictionary];
        if (!d) e = nil;
        else e = [Database elementFromDict:d];
    }];
    return e;
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
