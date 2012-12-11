//
//  AppDelegate.m
//  2Safe
//
//  Created by Drunk on 29.11.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "AppDelegate.h"
#import "ApiRequest.h"
#import "FileHandler.h"
#import "FileTreeWrapper.h"


@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //test
//    [FileTreeWrapper clearTree];
//    [FileTreeWrapper addFolder:nil folderID:@"1" atPath:nil];
//    [FileTreeWrapper addFile:@"fname" fileID:@"2" atPath:nil];
//    NSLog(@"ok");
//    [FileTreeWrapper addFolder:@"f1" folderID:@"3" atPath:nil];
//    [FileTreeWrapper addFolder:@"f2" folderID:@"4" atPath:[FileTreeWrapper arrayForPath:@"f1"]];
//    [FileTreeWrapper addFolder:@"f3" folderID:@"5" atPath:[FileTreeWrapper arrayForPath:@"f1/f2"]];
//    [FileTreeWrapper addFile:@"file" fileID:@"6" atPath:[FileTreeWrapper arrayForPath:@"f1/f2/f3"]];
//    NSLog(@"File id:%@", [FileTreeWrapper getFileIDAtPath:[FileTreeWrapper arrayForPath:@"f1/f2/f3"] named:@"file"]);
    
    // Insert code here to initialize your application
    ApiRequest *api = [[ApiRequest alloc] initWithAction:@"chk_mail" params:@{@"email": @"awd@awd.awd"}];
    [api performRequestWithBlock:^(NSDictionary *response, NSError *e) {
        if (!e) {
            for (NSString *key in response){
                NSLog(@"key:%@ value:%@\n", key, [response valueForKey:key]);
            }
        } else {
            NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
        }
    }];
    
    FileHandler *mainFileHandler = [[FileHandler alloc] init];
    [mainFileHandler startTracking];
}

@end
