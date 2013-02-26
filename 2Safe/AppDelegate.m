//
//  AppDelegate.m
//  2Safe
//
//  Created by Drunk on 29.11.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "AppDelegate.h"
#import "FSElement.h"
#import "Database.h"
#import "Synchronization.h"
#import "ApiRequest.h"
#import "LoginController.h"

@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize account;
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
@synthesize rootFolderPath = _rootFolderPath;
- (NSString *) rootFolderPath {
    return _rootFolderPath;
}
- (void) setRootFolderPath:(NSString *)rootFolderPath {
    _rootFolderPath = rootFolderPath;
    [self saveConfigForAccount];
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
@synthesize lastActionTimestamp = _lastActionTimestamp;
- (NSString *) lastActionTimestamp {
    if (_lastActionTimestamp) return _lastActionTimestamp;
    return [NSString stringWithFormat:@"%.f", [[NSDate date] timeIntervalSince1970] * 1000.0];
}
- (void) setLastActionTimestamp:(NSString *)lastActionTimestamp {
    _lastActionTimestamp = lastActionTimestamp;
    [self saveConfigForAccount];
}
@synthesize token;
@synthesize used_bytes;
@synthesize total_bytes;
@synthesize used_space = _used_space;
- (NSString *) used_space {
    _used_space = self.total_bytes > 0 ? [NSString stringWithFormat:@"%.f%% of %.fGB used", (float)(self.used_bytes / self.total_bytes) * 100, (float)(self.total_bytes/1024/1024/1024)] : nil;
    return _used_space;
}
- (void) setUsed_space:(NSString *)used_space {
    _used_space = used_space;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self start];
}

- (void) applicationWillTerminate:(NSNotification *)notification {
    [self saveConfigForAccount];
}

- (void) start {    
    if (!self.account) self.account = [[NSUserDefaults standardUserDefaults] valueForKey:@"account"];
    if (!self.token) self.token = [[NSUserDefaults standardUserDefaults] valueForKey:@"token"];
    if (self.account && self.token) {
        //execute API request to check token here
        ApiRequest *r2 = [[ApiRequest alloc] initWithAction:@"get_disk_quota" params:@{} withToken:YES];
        [r2 performRequestWithBlock:^(NSDictionary *response, NSError *e) {
            if (!e) {
                self.total_bytes = [[response objectForKey:@"quotas"] objectForKey:@"total_bytes"];
                self.used_bytes =  [[response objectForKey:@"quotas"] objectForKey:@"used_bytes"];
                self.used_space = @"a"; //reload the value
            } else {
                NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
            }
        } synchronous:YES];
        NSLog(@"Token: %@", self.token);
        
        //new user on this computer or some information is lost
        if (![self loadConfigForAccount]) {
            NSLog(@"New user %@", self.account);
            [[NSFileManager defaultManager] removeItemAtPath:[Database dbFileForAccount:self.account] error:nil];
            [Database databaseForAccount:self.account];
            self.rootFolderId = nil;
            self.trashFolderId = nil;
            self.lastActionTimestamp = nil;
            [self chooseRootFolderAndDownloadFiles:YES];
        } else {
            Synchronization *sync = [[Synchronization alloc] init];
            [sync getClientQueues];
            [sync getServerQueues];
            //[sync startSynchronization];
        }
    } else [LoginController auth];
}

- (void) chooseRootFolderAndDownloadFiles:(BOOL)_downloadFiles {
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setCanCreateDirectories:YES];
    if ([openDlg runModal] == NSOKButton )
    {
        NSArray *dir = [openDlg URLs];
        NSURL *durl = [dir objectAtIndex:0];
        if (!_downloadFiles) {
            if (self.rootFolderPath) {
                NSError *e;
                [[NSFileManager defaultManager] removeItemAtPath:[durl path] error:nil];
                [[NSFileManager defaultManager] moveItemAtPath:self.rootFolderPath toPath:[durl path] error:&e];
                if (e) NSLog(@"%@", [e localizedDescription]);
            }
        }
        else {
            self.rootFolderPath = [durl path];
            [self downloadAllFiles];
        }
        self.rootFolderPath = [durl path];
    }
}

- (void) downloadAllFiles {
    //TODO: download all files here
}

- (BOOL) loadConfigForAccount {
    NSDictionary *accountData = [[NSUserDefaults standardUserDefaults] valueForKey:self.account];
    _rootFolderPath = [accountData valueForKey:@"rootFolderPath"];
    self.rootFolderId = [accountData valueForKey:@"rootFolderId"];
    self.trashFolderId = [accountData valueForKey:@"trashFolderId"];
    _lastActionTimestamp = [accountData valueForKey:@"lastActionTimestamp"];
    return _rootFolderPath && [[NSFileManager defaultManager] fileExistsAtPath:_rootFolderPath] && _rootFolderId && _trashFolderId && _lastActionTimestamp && [Database isDbExistsForAccount:self.account];
}
- (void) saveConfigForAccount {
    [[NSUserDefaults standardUserDefaults] setObject:self.account forKey:@"account"];
    [[NSUserDefaults standardUserDefaults] setObject:self.token forKey:@"token"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:6];
    [dict setObject:self.rootFolderPath forKey:@"rootFolderPath"];
    [dict setObject:self.rootFolderId forKey:@"rootFolderId"];
    [dict setObject:self.trashFolderId forKey:@"trashFolderId"];
    [dict setObject:self.lastActionTimestamp forKey:@"lastActionTimestamp"];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:self.account];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
