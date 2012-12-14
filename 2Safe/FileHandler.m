//
//  FileHandler.m
//  2Safe
//
//  Created by Dan on 12/9/12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "FileHandler.h"
#import "FileUploader.h"

static void callback(ConstFSEventStreamRef streamRef,void *clientCallBackInfo,size_t numEvents,
                     void *eventPaths,const FSEventStreamEventFlags eventFlags[],
                     const FSEventStreamEventId eventIds[])
{
    int i;
    
    char **paths = eventPaths;
    
    for (i=0; i<numEvents; i++) {
        NSLog(@"Change %llu in %s, flags %u\n", eventIds[i],paths[i],eventFlags[i]);
        //TODO: delegate file events to FileUploader
        //[FileUploader file:<#(NSString *)#> atPath:<#(NSString *)#> triggeredEvent:<#(FileEvent)#>];
    }
}

@implementation FileHandler

//-(id)init{
//    self = [super init];
//    if(self) delegate = nil;
//    return self;
//}

- (void) startTracking {
    CFStringRef thepath = CFSTR("/Users/");
    CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&thepath, 1, NULL);
    
    /* Use context only to simply pass the array controller */
    _context = (FSEventStreamContext*)malloc(sizeof(FSEventStreamContext));
    _context->version = 0;
    _context->info = (__bridge void*)ctrl;
    _context->retain = NULL;
    _context->release = NULL;
    _context->copyDescription = NULL;
    
    _stream = FSEventStreamCreate(NULL,
                                  &callback,
                                  _context,
                                  pathsToWatch,
                                  kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
                                  1.0, /* Latency in seconds */
                                  kFSEventStreamCreateFlagFileEvents
                                  );
    
    _running = NO;
    NSLog(@"Tracking started.");
    FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    
    FSEventStreamStart(_stream);
}

//-(void)setDelegate:(NSObject<FolderEventDelegate> *)del{
//    delegate = del;
//}

@end
