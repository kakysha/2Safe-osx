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
#import "LoginController.h"



@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{   
    // Insert code here to initialize your application
    ApiRequest *api = [[ApiRequest alloc] initWithAction:@"get_disk_quota" params:@{} withToken:YES];
    [api performRequestWithBlock:^(NSDictionary *response, NSError *e) {
        if (!e) {
            for (NSString *key in response){
                NSLog(@"key:%@ value:%@\n", key, [response valueForKey:key]);
            }
        } else {
            NSLog(@"[%@] Error code:%ld description:%@",[api action], [e code],[e localizedDescription]);
        }
    }];
    
    //FileHandler *mainFileHandler = [[FileHandler alloc] init];
    //[mainFileHandler startTracking];
}

@end
