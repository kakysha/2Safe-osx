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
- (id)initForAccount:(NSString *)acc;

- (BOOL)insertElement:(FSElement *)el;
- (FSElement *)getElementById:(NSString *)idx;
- (FSElement*)getElementByName:(NSString *)namex withPID:(NSString*)pidx;
- (BOOL)deleteElementById:(NSString *)idx;
- (BOOL)updateElementWithId:(NSString *)idx withValues:(FSElement *)val;
- (NSArray *)childElementsOfId:(NSString *)idx;

@end
