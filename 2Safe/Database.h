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
#import "FSElement.h"

@interface Database : NSObject

+ (id)databaseForAccount:(NSString *)acc;
+ (BOOL) isDbExistsForAccount:(NSString *) acc;
- (id)initForAccount:(NSString *)acc;

- (BOOL)insertElement:(FSElement *)el;
- (FSElement *)getElementById:(NSString *)idx;
- (FSElement *)getElementById:(NSString *)idx withFullFilePath:(BOOL)ffp;
- (FSElement*)getElementByName:(NSString *)namex withPID:(NSString*)pidx;
- (FSElement*)getElementByName:(NSString *)namex withPID:(NSString*)pidx withFullFilePath:(BOOL)ffp;
- (BOOL)deleteElementById:(NSString *)idx;
- (BOOL)updateElementWithId:(NSString *)idx withValues:(FSElement *)val;
- (NSArray *)childElementsOfId:(NSString *)idx;

@end
