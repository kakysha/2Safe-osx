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
#import "FSElement.h"
#import "Database.h"
#import "Synchronization.h"

@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //testing FSElement
    /*FSElement *e1 = [[FSElement alloc] initWithPath:@"/Users/Drunk/Downloads/3module.pdf"];
    NSLog(@"name:%@ hash:%@ mdate:%@", e1.name, e1.hash, e1.mdate);
    e1.id = @"2";
    e1.pid = @"1";
    
    //testing db
    Database *db = [Database databaseForAccount:@"kakysha"];
    FSElement *e2 = [db getElementById:@"2"];
    NSLog(@"id:%@ name:%@ hash:%@ mdate:%@ pid:%@", e2.id, e2.name, e2.hash, e2.mdate, e2.pid);
    [db updateElementWithId:@"2" withValues:e1];
    NSArray *child = [db childElementsOfId:@"1"];
    
    for (int i = 0; i < child.count; i++)
        NSLog(@"%@", [child[i] name]);
    */
    
    //test sync
    Synchronization *sync = [[Synchronization alloc] init];
    [sync getClientQueues:@"/Users/Drunk/Downloads/2safe/"];
    
    //example of file downloading - INCORRECT!
    /*ApiRequest *r1 = [[ApiRequest alloc] initWithAction:@"get_file" params:@{@"id": @"121928033048"} withToken:YES];
    [r1 performDataRequestWithBlock:^(NSData *response, NSHTTPURLResponse *h, NSError *e) {
        if (!e) {
            [response writeToFile:@"file_data.txt" atomically:YES];
            NSLog(@"File saved to: file_data.txt");
        } else {
            NSLog(@"Error code:%ld description:%@", [e code],[e localizedDescription]);
        }
        //sleep(2);
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
            //sleep(2);
            //example of sending multipart/form-data request for file uploading
            ApiRequest *r3 = [[ApiRequest alloc] initWithAction:@"put_file" params:@{@"dir_id" : @"1134748033540", @"file" : [[FSElement alloc] initWithPath:@"file_orig.png"], @"overwrite":@"1"} withToken:YES];
            [r3 performRequestWithBlock:^(NSDictionary *response, NSError *e) {
                if (!e) {
                    for (id key in response) {
                        NSLog(@"%@ = %@", key, [response objectForKey:key]);
                    }
                } else {
                    NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
                }
                //sleep(2);
                //example of downloading files with NSOutputStream - OK!
                ApiRequest *r4 = [[ApiRequest alloc] initWithAction:@"get_file" params:@{@"id": @"121928033048"} withToken:YES];
                [r4 performStreamRequest:[[NSOutputStream alloc] initToFileAtPath:@"file_stream.txt" append:NO] withBlock:^(NSData *response, NSHTTPURLResponse *h, NSError *e) {
                    if (!e) {
                        NSLog(@"File saved to: file_stream.txt");
                    } else {
                        NSLog(@"Error code:%ld description:%@", [e code],[e localizedDescription]);
                    }
                }];
            }];
        }];
    }];*/
     
}

@end
