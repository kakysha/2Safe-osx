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
    NSMutableArray *stack;
}

-(void)getModificationDatesAtPath:(NSString*) folder {
	stack = [NSMutableArray arrayWithCapacity:100];
    [stack addObject:folder];
    while([stack count] != 0){
        [self lookUp:[stack pop]];
    }
}

-(void)lookUp:(NSString*) folder {
    NSFileManager *fm = [NSFileManager defaultManager];
    FileHandler *fh = [[FileHandler alloc] init];
	NSArray* files = [fm directoryContentsAtPath:folder];
    NSString* mDate;
    
	for(NSString *file in files) {
		NSString *path = [folder stringByAppendingPathComponent:file];
		BOOL isDir = NO;
		[fm fileExistsAtPath:path isDirectory:(&isDir)];
		//if(isDir) {
		//	[directoryList addObject:file];
		//}
        if(isDir){
            [stack push:path];
        }
        mDate = [fh getModificationDate:path];
        NSLog(@"Modification Date: %@ of %@", mDate, path);
	}

}

@end
