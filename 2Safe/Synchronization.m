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
        [self lookUp:[_stack pop]];
    }
    
}

-(NSMutableArray*) getFilesInFolder:(NSString*) folder {
    NSFileManager *fm = [NSFileManager defaultManager];
    
}

-(void)getModificationDatesAtPath:(NSString*) folder {
	_stack = [NSMutableArray arrayWithCapacity:100];
    [_stack addObject:folder];
    while([_stack count] != 0){
        [self lookUp:[_stack pop]];
    }
}

-(void)lookUp:(NSString*) folder {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err;
	NSArray* files = [fm contentsOfDirectoryAtPath:folder error:&err];
    NSString* mDate;
    
	for(NSString *file in files) {
		NSString *path = [folder stringByAppendingPathComponent:file];
		BOOL isDir = NO;
		[fm fileExistsAtPath:path isDirectory:(&isDir)];
        if(isDir){
            [_stack push:path];
        }
        
	}

}

@end
