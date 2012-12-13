//
//  FileHandler.h
//  2Safe
//
//  Created by Dan on 12/9/12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreServices/CoreServices.h>	

@interface FileHandler : NSObject{
    FSEventStreamRef _stream;
    FSEventStreamContext *_context;
    BOOL _running;
    
    IBOutlet NSArrayController *ctrl;
    
//    NSObject<FolderEventDelegate> *delegate;
}

-(void)startTracking;
//-(void)setDelegate:(NSObject<FolderEventDelegate> *) del;

//TODO: implement functions
//-(void)createFolder:(NSString *)folderName atPath:(NSString *)relativePath;


@end
