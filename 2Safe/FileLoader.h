//
//  FileLoader.h
//  2Safe
//
//  Created by Hip4yes on 10.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileLoader : NSObject

+(void)checkout;

+(void)checkOutFolder:(NSString *)folderID;
+(void)loadFile:(NSString *)fileID inFolder:(NSString *)folder;

+(void)getFileID:(NSString *)name atPath:(NSString *)path block:(void (^)(int , NSError *))block;

@end
