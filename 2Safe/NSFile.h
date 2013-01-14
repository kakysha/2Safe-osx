//
//  NSFile.h
//  2Safe
//
//  Created by Drunk on 14.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFile : NSObject

@property NSString *filePath;

- (id)initWithFileAtPath:(NSString *)path;

@end
