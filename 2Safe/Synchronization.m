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
}

-(NSMutableDictionary*) getClientQueue:(NSString*) folder {
    clientInsertionsQueue = [NSMutableArray arrayWithCapacity:20];
    clientDeletionsQueue = [NSMutableArray arrayWithCapacity:20];
    Database *db = [Database databaseForAccount:@"kakysha"];
    _stack = [NSMutableArray arrayWithCapacity:100];
    FSElement *firstElem = [[FSElement alloc] initWithPath:folder];
    firstElem.id = @"1";
    [_stack addObject:firstElem];
    while([_stack count] != 0){
        FSElement *stackElem = [_stack pop];
        NSArray* bdfiles = [db childElementsOfId:[stackElem id]];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *err;
        NSArray* files = [fm contentsOfDirectoryAtPath:stackElem.filePath error:&err];
        
        
        for(NSString *file in files) {
            NSString *path = [stackElem.filePath stringByAppendingPathComponent:file];
            BOOL isDir = NO;
            [fm fileExistsAtPath:path isDirectory:(&isDir)];
            FSElement *elementToAdd = [[FSElement alloc] initWithPath:path];
            if(isDir){
                [_stack push:elementToAdd];
            }
            NSUInteger foundIndex = [bdfiles indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([obj name] == elementToAdd.name){return YES;}else{return NO;}}];
            if (foundIndex == NSNotFound) {
                [clientInsertionsQueue addObject:elementToAdd];
            }
            else {
                if (elementToAdd.mdate == bdfiles[foundIndex])
            }

    }
    
}


@end
