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

@synthesize filePath = _filePath;
- (NSString *) filePath {
    return _filePath;
}
- (void) setFilePath:(NSString *)filePath {
    _filePath = filePath;
    _name = _name = [filePath lastPathComponent];
}
@synthesize id;
@synthesize name = _name;
- (NSString *)name {
    if (_name) return _name;
    _name = [self.filePath lastPathComponent];
    return _name;
}
@synthesize mdate = _mdate;
- (NSString *)mdate {
    if (_mdate) return _mdate;
    _mdate = [FSElement getModificationDateForFile:self.filePath];
    return _mdate;
}
@synthesize pid;
@synthesize hash = _hash;
- (NSString *)hash {
    if (_hash) return _hash;
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:&isDir];
    if (isDir) return @"NULL";
    _hash = [FSElement getMD5HashForFile:self.filePath];
    return _hash;
}

- (id)initWithPath:(NSString *)path {
    if (![[NSFileManager defaultManager] isReadableFileAtPath:path]) {
        NSLog(@"File %@ is not readable", path);
        return nil;
    }
    self.filePath = path;
    _mdate = [FSElement getModificationDateForFile:path];
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
    int t = (int)ti;
    NSString *result = [NSString stringWithFormat: @"%i", t];
    return result;
}

@end
