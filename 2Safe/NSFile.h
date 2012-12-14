//
//  NSFile.h
//  2Safe
//
//  Created by Drunk on 14.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFile : NSObject

- (id)initWithFileAtPath:(NSString *)path;

@property NSString *filePath;

@end
