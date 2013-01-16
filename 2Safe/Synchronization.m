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

@implementation Synchronization{
    NSMutableArray *_stack;
}

-(NSMutableDictionary*) getClientQueue:(NSString*) folder {
    NSMutableDictionary *clientQueue = [NSMutableDictionary dictionaryWithCapacity:20];
    _stack = [NSMutableArray arrayWithCapacity:100];
    [_stack addObject:folder];
    while([_stack count] != 0){
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *err;
        NSArray* files = [fm contentsOfDirectoryAtPath:[_stack pop] error:&err];
        
        for(NSString *file in files) {
            NSString *path = [[_stack pop] stringByAppendingPathComponent:file];
            BOOL isDir = NO;
            [fm fileExistsAtPath:path isDirectory:(&isDir)];
            if(isDir){
                [_stack push:path];
            }
            //!!!!
        }

    }
    
}


@end
