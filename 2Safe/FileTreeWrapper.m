//
//  FileTreeWrapper.m
//  2Safe
//
//  Created by Hip4yes on 10.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "FileTreeWrapper.h"

@implementation FileTreeWrapper

+(void)clearTree{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setObject:nil forKey:@"tree"];
    [defs synchronize];
}

+(void)addFile:(NSString *)fileName fileID:(NSString *)fileID atPath:(NSMutableArray *)path{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *folder = [defs objectForKey:@"tree"];
    if(path!=nil){
        for(NSString *f in path)
            folder = (NSMutableDictionary *)[folder objectForKey:f];
    }
    NSLog(@"folder: %@, files:%@", folder, [folder objectForKey:@"files"]);
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[folder objectForKey:@"files"]];
    NSLog(@"1");
    [dict setObject:fileID forKey:fileName];
    NSLog(@"2");
    [folder setObject:nil forKey:@"files"];
    NSLog(@"3");
    [folder setObject:dict forKey:@"files"];
    NSLog(@"4");
    [defs synchronize];
}

+(void)addFolder:(NSString *)folderName folderID:(NSString *)folderID atPath:(NSMutableArray *)path{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    if(folderName==nil){
        NSMutableDictionary *newFolder = [NSMutableDictionary dictionary];
        [newFolder setObject:[NSMutableDictionary dictionary] forKey:@"folders"];
        [newFolder setObject:[NSMutableDictionary dictionary] forKey:@"files"];
        [newFolder setObject:folderID forKey:@"id"];
        [defs setObject:newFolder forKey:@"tree"];
        [defs synchronize];
        return;
    }
    NSMutableDictionary *folder = [defs objectForKey:@"tree"];
    if(path!=nil){
        for(NSString *f in path)
            folder = [folder objectForKey:f];
    }
    NSMutableDictionary *newFolder = [NSMutableDictionary dictionary];
    [newFolder setObject:[NSMutableDictionary dictionary] forKey:@"folders"];
    [newFolder setObject:[NSMutableDictionary dictionary] forKey:@"files"];
    [newFolder setObject:folderID forKey:@"id"];
    [[folder objectForKey:@"folders"] setObject:newFolder forKey:folderName];
    [defs synchronize];
}

+(NSString *)getFolderIDAtPath:(NSMutableArray *)path{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *folder = [defs objectForKey:@"tree"];
    if(path!=nil){
        for(NSString *f in path)
            folder = [folder objectForKey:f];
    }
    return [folder objectForKey:@"id"];
}

+(NSString *)getFileIDAtPath:(NSMutableArray *)path named:(NSString *)name{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *folder = [defs objectForKey:@"tree"];
    if(path!=nil){
        for(NSString *f in path)
            folder = [folder objectForKey:f];
    }
    return [[folder objectForKey:@"files"] objectForKey:name];
}

+(NSMutableArray *)arrayForPath:(NSString *)path{
    //path = [NSString stringWithFormat:@"root/%@",path];
    return [NSMutableArray arrayWithArray:[path componentsSeparatedByString:@"/"]];
}

@end
