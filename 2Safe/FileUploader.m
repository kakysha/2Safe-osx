//
//  FileUploader.m
//  2Safe
//
//  Created by Hip4yes on 10.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "FileUploader.h"
#import "ApiRequest.h"
#import "FileLoader.h"

@implementation FileUploader

+(void)file:(NSString *)fileName atPath:(NSString *)path triggeredEvent:(FileEvent)event{
    if(event==FILE_IS_DELETED)
    {
//        FileLoader getFileID:fileName atPath: path block:<#^(int, NSError *)block#>
//        ApiRequest *api = [[ApiRequest alloc] initWithAction:@"remove_file" params:@{@"email": @"awd@awd.awd"}];
//        [api performRequestWithBlock:^(NSDictionary *response, NSError *e) {
//            if (!e) {
//                for (NSString *key in response){
//                    NSLog(@"key:%@ value:%@\n", key, [response valueForKey:key]);
//                }
//            } else {
//                NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
//            }
//        }];
//        
    }
    //NSData *file = [[NSFileManager defaultManager] contentsAtPath:file];
}



@end
