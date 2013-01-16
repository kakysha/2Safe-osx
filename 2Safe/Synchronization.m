//
//  Synchronization.m
//  2Safe
//
//  Created by Dan on 1/13/13.
//  Copyright (c) 2013 zaopark. All rights reserved.
//

#import "Synchronization.h"
#import "FileHandler.h"
#import "NSMutableArray+Stack.h"
#import "Database.h"
#import "FSElement.h"

@implementation Synchronization{
    NSMutableArray *_stack;
    NSMutableArray *clientInsertionsQueue;
    NSMutableArray *clientDeletionsQueue;
    NSFileManager *fm;
}

- (id) init {
    if (self = [super init]) {
        fm = [NSFileManager defaultManager];
        return self;
    }
    return nil;
}

-(void) getClientQueues:(NSString*) folder {
    clientInsertionsQueue = [NSMutableArray arrayWithCapacity:20];
    clientDeletionsQueue = [NSMutableArray arrayWithCapacity:20];
    Database *db = [Database databaseForAccount:@"kakysha"];
    _stack = [NSMutableArray arrayWithCapacity:100];
    FSElement *firstElem = [[FSElement alloc] initWithPath:folder];
    firstElem.id = @"1";
    [_stack addObject:firstElem];
    while([_stack count] != 0){
        FSElement *stackElem = [_stack pop];
        NSMutableArray* bdfiles = [NSMutableArray arrayWithArray:[db childElementsOfId:[stackElem id]]];
        NSError *err;
        NSArray* files = [fm contentsOfDirectoryAtPath:stackElem.filePath error:&err];
        for(NSString *file in files) {
            NSString *path = [stackElem.filePath stringByAppendingPathComponent:file];
            BOOL isDir = NO;
            [fm fileExistsAtPath:path isDirectory:&isDir];
            FSElement *elementToAdd = [[FSElement alloc] initWithPath:path];
            NSUInteger foundIndex = [bdfiles indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj name] isEqualToString:elementToAdd.name]){*stop = YES;return YES;} return NO;}];
            if (foundIndex == NSNotFound) {
                [clientInsertionsQueue addObject:elementToAdd];
            }
            else {
                FSElement *dbDir = bdfiles[foundIndex];
                if(isDir){
                    dbDir.filePath = elementToAdd.filePath;
                    [_stack push:dbDir];
                } else
                if (![elementToAdd.mdate isEqualToString:dbDir.mdate]){
                    [clientInsertionsQueue addObject:elementToAdd];
                }
                [bdfiles removeObjectAtIndex:foundIndex];
            }
        }
        
        if (bdfiles.count != 0) {
            for(FSElement *fse in bdfiles){
                [clientDeletionsQueue addObject:fse];
            }
        }
    }
    for (int i = 0; i < clientInsertionsQueue.count; i++) NSLog(@"%@", [clientInsertionsQueue[i] filePath]);
}


@end
