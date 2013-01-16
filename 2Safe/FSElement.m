//
//  NSFile.m
//  2Safe
//
//  Created by Drunk on 14.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "FSElement.h"
#include <CoreFoundation/CoreFoundation.h>
#include <CommonCrypto/CommonDigest.h>
#define FileHashDefaultChunkSizeForReadingData 4096

@implementation FSElement

@synthesize filePath;
@synthesize id_;
@synthesize name;
@synthesize mdate;
@synthesize pid;
@synthesize hash = _hash;
- (NSString *)hash {
    if (_hash) return _hash;
    _hash = [FSElement getMD5HashForFile:filePath];
    return _hash;
}

- (id)initWithPath:(NSString *)path {
    if (![[NSFileManager defaultManager] isReadableFileAtPath:path]) {
        NSLog(@"File %@ is not readable", path);
        return nil;
    }
    filePath = path;
    name = [path lastPathComponent];
    mdate = [FSElement getModificationDateForFile:path];
    return self;
}

+ (NSString *) getMD5HashForFile:(NSString *)filePath {
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
+ (NSString *)getModificationDateForFile:(NSString *)filePath{
    NSDictionary* fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    NSDate *date = [fileAttribs fileModificationDate];
    NSTimeInterval ti = [date timeIntervalSince1970];
    NSString *result = [NSString stringWithFormat: @"%f", ti];
    return result;
}

@end
