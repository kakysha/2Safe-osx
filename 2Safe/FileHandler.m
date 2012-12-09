//
//  FileHandler.m
//  2Safe
//
//  Created by Dan on 12/9/12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "FileHandler.h"

static void callback(ConstFSEventStreamRef streamRef,void *clientCallBackInfo,size_t numEvents,
                     void *eventPaths,const FSEventStreamEventFlags eventFlags[],
                     const FSEventStreamEventId eventIds[])
{
    int i;
    
    char **paths = eventPaths;
    
    for (i=0; i<numEvents; i++) {
        int count;
        NSLog(@"Change %llu in %s, flags %u\n", eventIds[i],paths[i],eventFlags[i]);
    }
}

@implementation FileHandler

- (void) startTracking {
    CFStringRef thepath = CFSTR("/Users/Dan/Downloads");
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

@end
