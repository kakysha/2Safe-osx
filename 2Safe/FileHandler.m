//
//  FileHandler.m
//  2Safe
//
//  Created by Dan on 12/9/12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "FileHandler.h"
#import "FileUploader.h"

#include <CoreFoundation/CoreFoundation.h>
#include <CommonCrypto/CommonDigest.h>
#define FileHashDefaultChunkSizeForReadingData 4096

static void callback(ConstFSEventStreamRef streamRef,void *clientCallBackInfo,size_t numEvents,
                     void *eventPaths,const FSEventStreamEventFlags eventFlags[],
                     const FSEventStreamEventId eventIds[])
{
    int i;
    char **paths = eventPaths;
    
    for (i=0; i<numEvents; i++) {
        NSLog(@"Change %llu in %s, flags %u\n", eventIds[i],paths[i],eventFlags[i]);
        FileEvent trigEvent;
        NSString *s = [[NSString alloc] initWithCString:paths[i] encoding:NSASCIIStringEncoding];
        NSString* pathName = [s stringByDeletingLastPathComponent];
        NSString* fileName = [s lastPathComponent];
        if(eventFlags[i] == kFSEventStreamEventFlagItemCreated) trigEvent = FILE_IS_CREATED;
        else if(eventFlags[i] == kFSEventStreamEventFlagItemModified) trigEvent = FILE_IS_MODIFIED;
        else if(eventFlags[i] == kFSEventStreamEventFlagItemRemoved) trigEvent = FILE_IS_DELETED;
        else if(eventFlags[i] == kFSEventStreamEventFlagItemRenamed) trigEvent = FILE_IS_RENAMED;
        //delegate file events to FileUploader
        //[FileUploader file: fileName atPath:pathName triggeredEvent:trigEvent];
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

NSString* getFileMD5hash(NSString* filePath) {
    
    // Declare needed variables
    CFStringRef result = NULL;
    NSString *ns_result = NULL;
    CFReadStreamRef readStream = NULL;
    
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) return NULL;
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) {
        CFRelease(fileURL);
        return NULL;
    }
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
        CFRelease(fileURL);
        return NULL;
    }
    
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[FileHashDefaultChunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,
                      (const void *)buffer,
                      (CC_LONG)readBytesCount);
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    
    // Abort if the read operation failed
    if (!didSucceed) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
        CFRelease(fileURL);
        return NULL;
    }
    
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,
                                       (const char *)hash,
                                       kCFStringEncodingUTF8);
    
    CFReadStreamClose(readStream);
    CFRelease(readStream);
    CFRelease(fileURL);
    return ns_result = (__bridge NSString*) result;
}

- (NSString*) getModificationDate: (NSString*) path {
    NSDictionary* fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    NSDate *date = [fileAttribs fileModificationDate];
    NSTimeInterval ti = [date timeIntervalSince1970];
    NSString *result = [NSString stringWithFormat: @"%f", ti];
    return result;
}

@end
