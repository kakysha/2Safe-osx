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
        NSLog(@"Token: %@", self.token);
        //new user on this computer
        if (![self loadConfigForAccount]) {
            [[NSFileManager defaultManager] removeItemAtPath:[Database dbFileForAccount:self.account] error:nil];
            self.rootFolderPath = @"/Users/Drunk/Downloads/2safe/";
            self.rootFolderId = nil;
            self.trashFolderId = nil;
            self.lastActionTimestamp = nil;
        }
        Synchronization *sync = [[Synchronization alloc] init];
        [sync getClientQueues];
        //[sync getServerQueues];
    }
    
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

- (void) applicationWillTerminate:(NSNotification *)notification {
    [self saveConfigForAccount];
}

@synthesize account = _account;
- (NSString *) account {
    if (_account) return _account;
    [LoginController auth];
    return _account;
}
- (void) setAccount:(NSString *)activeAccountName {
    _account = activeAccountName;
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

@synthesize rootFolderPath;
+ (NSString *) RootFolderPath {
    return ((AppDelegate *)[[NSApplication sharedApplication] delegate]).rootFolderPath;
}

@synthesize trashFolderId = _trashFolderId;
- (NSString *) trashFolderId {
    if (_trashFolderId) return _trashFolderId;
    ApiRequest *r2 = [[ApiRequest alloc] initWithAction:@"list_dir" params:@{} withToken:YES];
    [r2 performRequestWithBlock:^(NSDictionary *response, NSError *e) {
        NSArray *dirs = [response objectForKey:@"list_dirs"];
        for (NSDictionary *d in dirs) {
            if ([[d objectForKey:@"special_dir"] isEqualToString:@"trash"]) {
                _trashFolderId = [d objectForKey:@"id"];
                break;
            }
        }
    } synchronous:YES];
    return _trashFolderId;
}
- (void) setTrashFolderId:(NSString *)trashFolderId {
    _trashFolderId = trashFolderId;
}
+ (NSString *) TrashFolderId {
    return ((AppDelegate *)[[NSApplication sharedApplication] delegate]).trashFolderId;
}

@synthesize lastActionTimestamp = _lastActionTimestamp;
- (NSString *) lastActionTimestamp {
    if (_lastActionTimestamp) return _lastActionTimestamp;
    return [NSString stringWithFormat:@"%.f", [[NSDate date] timeIntervalSince1970] * 1000.0];
}
- (void) setLastActionTimestamp:(NSString *)lastActionTimestamp {
    _lastActionTimestamp = lastActionTimestamp;
}

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
    NSDictionary *accountData = [[NSUserDefaults standardUserDefaults] valueForKey:self.account];
    self.rootFolderPath = [accountData valueForKey:@"rootFolderPath"];
    self.rootFolderId = [accountData valueForKey:@"rootFolderId"];
    self.trashFolderId = [accountData valueForKey:@"trashFolderId"];
    self.lastActionTimestamp = [accountData valueForKey:@"lastActionTimestamp"];
    return rootFolderPath && [[NSFileManager defaultManager] fileExistsAtPath:rootFolderPath] && _rootFolderId && _trashFolderId && _lastActionTimestamp && [Database isDbExistsForAccount:self.account];
}
- (void) saveConfigForAccount {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:6];
    [dict setObject:self.rootFolderPath forKey:@"rootFolderPath"];
    [dict setObject:self.rootFolderId forKey:@"rootFolderId"];
    [dict setObject:self.trashFolderId forKey:@"trashFolderId"];
    [dict setObject:self.lastActionTimestamp forKey:@"lastActionTimestamp"];
    [[NSUserDefaults standardUserDefaults] setObject:self.account forKey:@"account"];
    [[NSUserDefaults standardUserDefaults] setObject:self.token forKey:@"token"];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:self.account];
    //debug
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey:self.account];
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"token"];
}

@end
