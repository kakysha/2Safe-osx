//
//  FileLoader.m
//  2Safe
//
//  Created by Hip4yes on 10.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "FileLoader.h"
#import "ApiRequest.h"

@implementation FileLoader

+(void)checkout{    
    [self checkOutFolder:nil];
}

+(void)checkOutFolder:(NSString *)folderID{
    NSDictionary *dict = [NSDictionary dictionaryWithObject:folderID forKey:@"dir_id"];
    ApiRequest *req = [[ApiRequest alloc] initWithAction:@"list_dir" params:(folderID==nil)?nil:dict];
    [req performRequestWithBlock:^(NSDictionary *response, NSError *e){
        NSLog(@"---recieved response!");
        if(e!=nil) NSLog(@"---error:%@", [e localizedDescription]);
        for (NSString* key in response) {
            id value = [response objectForKey:key];
            NSLog(@"---Key:%@ value:%@", key, value);
        }
        
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        double lastUpdate = ([defs objectForKey:@"lastUpdate"]==nil)?0:[[defs objectForKey:@"lastUpdate"] doubleValue];
        if(e==nil){
            NSString *folder = [[[response objectForKey:@"response"] objectForKey:@"root"] objectForKey:@"tree"];
            NSDictionary *dirs = [[response objectForKey:@"response"] objectForKey:@"list_dirs"];
            for (NSDictionary *dir in dirs) {
                NSString *name = [dir objectForKey:@"name"];
                NSLog(@"---Dir name:%@", name);
                if([[dir objectForKey:@"mtime"] intValue]>lastUpdate){
                    //create folder
                    //[self checkOutFolder:[dir objectForKey:@"id"]];
                }
            }
            NSDictionary *files = [[response objectForKey:@"response"] objectForKey:@"list_files"];
            for (NSDictionary *file in files) {
                NSString *name = [file objectForKey:@"name"];
                NSLog(@"---file name:%@", name);
                if([[file objectForKey:@"mtime"] intValue]>lastUpdate){
                    [self loadFile:[file objectForKey:@"id"] inFolder:folder];
                }
            }
        }
        if(folderID==nil){
            //checkout is finished!
            [defs setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"lastUpdate"];
            [defs synchronize];
        }
    }];    
}

+(void)loadFile:(NSString *)fileID inFolder:(NSString *)folder{
    
}

+(void)getFileID:(NSString *)name atPath:(NSString *)path block:(void (^)(int, NSError *))block{
    //NSDictionary *dict = [NSDictionary dictionaryWithObject:folderID forKey:@"dir_id"];
    //ApiRequest *req = [[ApiRequest alloc] initWithAction:@"list_dir" params:(folderID==nil)?nil:dict];
    
}

@end
