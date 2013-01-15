//
//  Synchronization.m
//  2Safe
//
//  Created by Dan on 1/13/13.
//  Copyright (c) 2013 zaopark. All rights reserved.
//

#import "Synchronization.h"
#import "FileHandler.h"

@implementation Synchronization

-(void)getModificationDatesAtPath:(NSString*) folder {
	NSFileManager *fm = [NSFileManager defaultManager];
    FileHandler *fh = [[FileHandler alloc] init];
	NSArray* files = [fm directoryContentsAtPath:folder];
	//NSMutableArray *directoryList = [NSMutableArray arrayWithCapacity:10];
    NSString* mDate;
    
	for(NSString *file in files) {
		NSString *path = [folder stringByAppendingPathComponent:file];
		BOOL isDir = NO;
		[fm fileExistsAtPath:path isDirectory:(&isDir)];
		//if(isDir) {
		//	[directoryList addObject:file];
		//}
        if(isDir){
            [self getModificationDatesAtPath:path];
        }
        mDate = [fh getModificationDate:path];
        NSLog(@"Modification Date: %@ of %@", mDate, path);
	}
    
}

-(void)lookUp:(NSString*) folder {
    
}

@end
