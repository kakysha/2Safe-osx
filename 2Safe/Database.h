//
//  Database.h
//  2Safe
//
//  Created by Drunk on 14.01.13.
//  Copyright (c) 2013 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

@interface Database : NSObject

+ (id)databaseForAccount:(NSString *)acc;
- (id)initForAccount:(NSString *)acc;

- (BOOL)insertElement:(NSDictionary *)el;
- (NSDictionary *)getElementById:(NSString *)idx;
- (BOOL)deleteElementById:(NSString *)idx;
- (BOOL)updateElementWithId:(NSString *)idx withValues:(NSDictionary *)val;

@end
