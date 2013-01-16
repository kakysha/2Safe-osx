//
//  NSFile.h
//  2Safe
//
//  Created by Drunk on 14.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSElement : NSObject

@property NSString *filePath;
@property NSString *id;
@property NSString *name;
@property(nonatomic) NSString *hash;
@property NSString *mdate;
@property NSString *pid;

- (id)initWithPath:(NSString *)path;
+ (NSString *)getMD5HashForFile:(NSString *)filePath;
+ (NSString *)getModificationDateForFile:(NSString *)filePath;


@end