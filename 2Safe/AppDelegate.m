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
#import "Synchronization.h"
#import "FileTreeWrapper.h"
#import "NSFile.h"


@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    /*//example of tree wrapper
    [FileTreeWrapper clearTree];
    [FileTreeWrapper addFolder:nil folderID:@"1" atPath:nil];
    [FileTreeWrapper addFile:@"fname" fileID:@"2" atPath:nil];
    NSLog(@"ok");
    [FileTreeWrapper addFolder:@"f1" folderID:@"3" atPath:nil];
    [FileTreeWrapper addFolder:@"f2" folderID:@"4" atPath:[FileTreeWrapper arrayForPath:@"f1"]];
    [FileTreeWrapper addFolder:@"f3" folderID:@"5" atPath:[FileTreeWrapper arrayForPath:@"f1/f2"]];
    [FileTreeWrapper addFile:@"file" fileID:@"6" atPath:[FileTreeWrapper arrayForPath:@"f1/f2/f3"]];
    NSLog(@"File id:%@", [FileTreeWrapper getFileIDAtPath:[FileTreeWrapper arrayForPath:@"f1/f2/f3"] named:@"file"]);
    */
    
    //example of file downloading - INCORRECT!
    ApiRequest *r1 = [[ApiRequest alloc] initWithAction:@"get_file" params:@{@"id": @"1138179033539"} withToken:YES];
    [r1 performDataRequestWithBlock:^(NSData *response, NSHTTPURLResponse *h, NSError *e) {
        if (!e) {
            [response writeToFile:@"file_data.png" atomically:YES];
            NSLog(@"File saved to: file_data.png");
        } else {
            NSLog(@"Error code:%ld description:%@", [e code],[e localizedDescription]);
        }
        sleep(2);
        //example of sending JSON request with JSON response
        ApiRequest *r2 = [[ApiRequest alloc] initWithAction:@"get_disk_quota" params:@{} withToken:YES];
        [r2 performRequestWithBlock:^(NSDictionary *response, NSError *e) {
            if (!e) {
                for (id key in response) {
                    NSLog(@"%@ = %@", key, [response objectForKey:key]);
                }
            } else {
                NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
            }
            sleep(2);
            //example of sending multipart/form-data request for file uploading
            ApiRequest *r3 = [[ApiRequest alloc] initWithAction:@"put_file" params:@{@"dir_id" : @"1134748033540", @"file" : [[NSFile alloc] initWithFileAtPath:@"file_orig.png"], @"overwrite":@"1"} withToken:YES];
            [r3 performRequestWithBlock:^(NSDictionary *response, NSError *e) {
                if (!e) {
                    for (id key in response) {
                        NSLog(@"%@ = %@", key, [response objectForKey:key]);
                    }
                } else {
                    NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
                }
                sleep(2);
                //example of downloading files with NSOutputStream - OK!
                ApiRequest *r4 = [[ApiRequest alloc] initWithAction:@"get_file" params:@{@"id": @"1138179033539"} withToken:YES];
                [r4 performStreamRequest:[[NSOutputStream alloc] initToFileAtPath:@"file_stream.png" append:NO] withBlock:^(NSData *response, NSHTTPURLResponse *h, NSError *e) {
                    if (!e) {
                        NSLog(@"File saved to: file_stream.png");
                    } else {
                        NSLog(@"Error code:%ld description:%@", [e code],[e localizedDescription]);
                    }
                }];
            }];
        }];
    }];
    
    
    /*//example of file handler
    FileHandler *mainFileHandler = [[FileHandler alloc] init];
    [mainFileHandler startTracking];
    */
    
    Synchronization *sync = [[Synchronization alloc] init];
    [sync getModificationDatesAtPath:@"/Users/dan/Downloads"];
}

@end
