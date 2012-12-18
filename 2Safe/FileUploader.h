//
//  FileUploader.h
//  2Safe
//
//  Created by Hip4yes on 10.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum fileEventTypes{
    FILE_IS_CREATED,
    FILE_IS_MODIFIED,
    FILE_IS_DELETED,
    FILE_IS_RENAMED
} FileEvent;

@interface FileUploader : NSObject



+(void)file:(NSString *)fileName atPath:(NSString *)path triggeredEvent:(FileEvent)event;


@end
