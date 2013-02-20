//
//  Settings.m
//  2Safe
//
//  Created by Drunk on 20.02.13.
//  Copyright (c) 2013 zaopark. All rights reserved.
//

#import "Settings.h"

@implementation Settings

- (id) init {
    if (self = [super init]) {
        self.activeAccountName = [[NSUserDefaults standardUserDefaults] valueForKey:@"activeAccountName"];
        self.rootFolderId = [[NSUserDefaults standardUserDefaults] valueForKey:@"rootFolderId"];
        self.trashFolderId = [[NSUserDefaults standardUserDefaults] valueForKey:@"trashFolderId"];
        self.lastActionTimestamp = [[NSUserDefaults standardUserDefaults] valueForKey:@"lastActionTimestamp"];
        return self;
    }
    return nil;
}

- (NSString *) rootFolderId {
    if (_rootFolderId) return _rootFolderId;
    /*ApiRequest *r2 = [[ApiRequest alloc] initWithAction:@"get_disk_quota" params:@{} withToken:YES];
    [r2 performRequestWithBlock:^(NSDictionary *response, NSError *e) {
        
    }];*/
}

@end
