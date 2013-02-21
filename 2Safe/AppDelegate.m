//
//  AppDelegate.m
//  2Safe
//
//  Created by Drunk on 29.11.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "AppDelegate.h"
#import "ApiRequest.h"
#import "FSElement.h"
#import "Database.h"
#import "Synchronization.h"
#import "ApiRequest.h"
#import "LoginController.h"

@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.account = [[NSUserDefaults standardUserDefaults] valueForKey:@"account"];
    self.token = [[NSUserDefaults standardUserDefaults] valueForKey:@"token"];
    if (self.account && self.token) {
        //new user on this computer
        if (![self loadConfigForAccount]) {
            self.rootFolderPath = @"/Users/Drunk/Downloads/2safe/";
            self.rootFolderId = nil;
            self.trashFolderId = nil;
            self.lastActionTimestamp = @"0";
            [Database databaseForAccount:self.account];
        }
    }
    
    //test sync
    Synchronization *sync = [[Synchronization alloc] init];
    [sync getClientQueues];
    //[sync getServerQueues];
    
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

@synthesize account = _account;
- (NSString *) account {
    if (_account) return _account;
    [LoginController auth];
    return _account;
}
- (void) setAccount:(NSString *)activeAccountName {
    _account = activeAccountName;
    //create DB
}
+ (NSString *) Account {
    return ((AppDelegate *)[[NSApplication sharedApplication] delegate]).account;
}

@synthesize rootFolderId = _rootFolderId;
- (NSString *) rootFolderId {
    if (_rootFolderId) return _rootFolderId;
    ApiRequest *r2 = [[ApiRequest alloc] initWithAction:@"get_props" params:@{@"url": @"/"} withToken:YES];
    [r2 performRequestWithBlock:^(NSDictionary *response, NSError *e) {
        _rootFolderId = [[response objectForKey:@"object"] objectForKey:@"id"];
    } synchronous:YES];
    return _rootFolderId;
}
- (void) setRootFolderId:(NSString *)rootFolderId {
    _rootFolderId = rootFolderId;
}
+ (NSString *) RootFolderId {
    return ((AppDelegate *)[[NSApplication sharedApplication] delegate]).rootFolderId;
}

@synthesize rootFolderPath = _rootFolderPath;
- (void) setRootFolderPath:(NSString *)rootFolderPath {
    //check if directory exists
    _rootFolderPath = rootFolderPath;
}

@synthesize trashFolderId = _trashFolderId;
- (NSString *) trashFolderId {
    if (_trashFolderId) return _trashFolderId;
    //make request
    return _trashFolderId;
}
- (void) setTrashFolderId:(NSString *)trashFolderId {
    _trashFolderId = trashFolderId;
}

@synthesize lastActionTimestamp = _lastActionTimestamp;

@synthesize token = _token;
- (NSString *) token {
    if (_token) return _token;
    [LoginController auth];
    return _token;
}
- (void) setToken:(NSString *)token {
    _token = token;
}
+ (NSString *) Token {
    return ((AppDelegate *)[[NSApplication sharedApplication] delegate]).token;
}

- (BOOL) loadConfigForAccount {
    NSDictionary *accountData = [[NSUserDefaults standardUserDefaults] valueForKey:_account];
    self.rootFolderPath = [accountData valueForKey:@"rootFolderPath"];
    self.rootFolderId = [accountData valueForKey:@"rootFolderId"];
    self.trashFolderId = [accountData valueForKey:@"trashFolderId"];
    self.lastActionTimestamp = [accountData valueForKey:@"lastActionTimestamp"];
    return _rootFolderPath && _rootFolderId && _trashFolderId && _lastActionTimestamp;
}

@end
