//
//  FileTreeWrapper.h
//  2Safe
//
//  Created by Hip4yes on 10.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileTreeWrapper : NSObject

+(void)clearTree;
+(void)addFolder:(NSString *)folderName folderID:(NSString *)folderID atPath:(NSMutableArray *)path;
+(void)addFile:(NSString *)fileName fileID:(NSString *)fileID atPath:(NSMutableArray *)path;

+(NSString *)getFolderIDAtPath:(NSMutableArray *)path;
+(NSString *)getFileIDAtPath:(NSMutableArray *)path named:(NSString *)name;

+(NSMutableArray *)arrayForPath:(NSString *)path;
@end
