//
//  Synchronization.m
//  2Safe
//
//  Created by Dan on 1/13/13.
//  Copyright (c) 2013 zaopark. All rights reserved.
//

#import "Synchronization.h"
#import "FileHandler.h"
#import "NSMutableArray+Stack.h"
#import "Database.h"
#import "FSElement.h"
#import "ApiRequest.h"

@implementation Synchronization{
    NSMutableArray *_folderStack;
    NSMutableArray *_uploadFolderStack;
    NSFileManager *_fm;
    Database *_db;
    NSMutableArray *_clientInsertionsQueue;
    NSMutableArray *_clientDeletionsQueue;
    __block NSMutableArray *_serverInsertionsQueue;
    __block NSMutableArray *_serverDeletionsQueue;
}

- (id) init {
    if (self = [super init]) {
        _fm = [NSFileManager defaultManager];
        _db = [Database databaseForAccount:@"kakysha"];
        _folderStack = [NSMutableArray arrayWithCapacity:100];
        _uploadFolderStack = [NSMutableArray arrayWithCapacity:50];
        _clientInsertionsQueue = [NSMutableArray arrayWithCapacity:50];
        _clientDeletionsQueue = [NSMutableArray arrayWithCapacity:50];
        _serverInsertionsQueue = [NSMutableArray arrayWithCapacity:50];
        _serverDeletionsQueue = [NSMutableArray arrayWithCapacity:50];
        return self;
    }
    return nil;
}

-(void) getServerQueues:(NSString*) folder {
    ApiRequest *getEvents = [[ApiRequest alloc] initWithAction:@"get_events" params:@{@"after":@"1358514020446294"} withToken:YES];
    [getEvents performRequestWithBlock:^(NSDictionary *response, NSError *e) {
        if (!e) {
            NSString *elementPath;
            NSArray *reversedEvents = [[[response objectForKey:@"events"] reverseObjectEnumerator] allObjects];
            /*for (id key in response){
                NSLog(@"%@ = %@", key, [response objectForKey:key]);
            }*/
            for (NSDictionary *dict in reversedEvents) {
                /*for(id key in dict){
                    NSLog(@"%@ = %@", key, [dict objectForKey:key]);
                }*/
                    if([[dict objectForKey:@"event"] isEqualTo:@"file_uploaded"] ||
                       [[dict objectForKey:@"event"] isEqualTo:@"dir_created"]){
                        FSElement *parentElement = [_db getElementById:[dict objectForKey:@"parent_id"]];
                        if (parentElement) {
                            elementPath = [[_db getElementById:[dict objectForKey:@"parent_id"]].filePath stringByAppendingPathComponent:[dict objectForKey:@"name"]];
                        } else {
                            //parentElement = [_serverInsertionsQueue]
                        }
                        FSElement *elementToAdd = [[FSElement alloc] initWithPath:elementPath];
                        elementToAdd.id = [dict objectForKey:@"id"];
                        elementToAdd.pid = [dict objectForKey:@"parent_id"];
                        [_serverInsertionsQueue addObject:elementToAdd];
                    }
            }
        } else NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
    }];
}

-(void) getClientQueues:(NSString*) folder {
    FSElement *root = [[FSElement alloc] initWithPath:folder];
    root.id = @"1108986033540";
    [_folderStack push:root];
    while([_folderStack count] != 0){
        FSElement *stackElem = [_folderStack pop];
        NSMutableArray* bdfiles = [NSMutableArray arrayWithArray:[_db childElementsOfId:[stackElem id]]];
        NSArray* files = [_fm contentsOfDirectoryAtPath:stackElem.filePath error:nil];
        for(NSString *file in files) {
            NSString *path = [stackElem.filePath stringByAppendingPathComponent:file];
            FSElement *elementToAdd = [[FSElement alloc] initWithPath:path];
            BOOL isDir = NO;
            [_fm fileExistsAtPath:elementToAdd.filePath isDirectory:&isDir];
            NSUInteger foundIndex = [bdfiles indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj name] isEqualToString:elementToAdd.name]){*stop = YES;return YES;} return NO;}];
            if (foundIndex == NSNotFound) {
                elementToAdd.pid = stackElem.id;
                [_clientInsertionsQueue addObject:elementToAdd];
            }
            else {
                FSElement *dbElem = bdfiles[foundIndex];
                if(isDir){
                    dbElem.filePath = elementToAdd.filePath;
                    [_folderStack push:dbElem];
                } else
                if (![elementToAdd.mdate isEqualToString:dbElem.mdate]){
                    [_clientInsertionsQueue addObject:elementToAdd];
                }
                [bdfiles removeObjectAtIndex:foundIndex];
            }
        }
        if (bdfiles.count != 0)
            for(FSElement *fse in bdfiles) [_clientDeletionsQueue addObject:fse];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self performInsertionQueue]; });
}

-(void) performInsertionQueue{
    for(FSElement *fse in _clientInsertionsQueue) {
        if ([fse.hash isEqualToString:@"NULL"]) { // directory, recursively hop in it and it's contents, concurrently in other thread
            
            [_uploadFolderStack push:fse];
            while ([_uploadFolderStack count] > 0) {
                __block FSElement *curDirEl = [_uploadFolderStack pop];
                //firstly, create a dir on the server to get it's id [respectively block thread to wait for execution of request]
                ApiRequest *folderUploadRequest = [[ApiRequest alloc] initWithAction:@"make_dir" params:@{@"dir_id":curDirEl.pid, @"dir_name":curDirEl.name} withToken:YES];
                [folderUploadRequest performRequestWithBlock:^(NSDictionary *response, NSError *e){
                    if (!e) {
                        curDirEl.id = [response valueForKey:@"dir_id"];
                        [_db insertElement:curDirEl];
                        NSArray* files = [_fm contentsOfDirectoryAtPath:curDirEl.filePath error:nil];
                        for(NSString *file in files) {
                            NSString *path = [curDirEl.filePath stringByAppendingPathComponent:file];
                            FSElement *childEl = [[FSElement alloc] initWithPath:path];
                            childEl.pid = curDirEl.id;
                            BOOL isDir = NO;
                            [_fm fileExistsAtPath:childEl.filePath isDirectory:&isDir];
                            if (isDir) { //directory - just push it into stack for upload
                                [_uploadFolderStack push:childEl];
                            } else { //file - upload ad store it in db
                                ApiRequest *fileUploadRequest2 = [[ApiRequest alloc] initWithAction:@"put_file" params:@{@"dir_id" : childEl.pid , @"file" : childEl, @"overwrite":@"1"} withToken:YES];
                                [fileUploadRequest2 performRequestWithBlock:^(NSDictionary *response, NSError *e) {
                                    if (!e) {
                                        childEl.id = [[response valueForKey:@"file"] valueForKey:@"id"];
                                        [_db insertElement:childEl];
                                    } else NSLog(@"%ld: %@",[e code],[e localizedDescription]);
                                }];
                            }
                        }
                    } else NSLog(@"%ld: %@",[e code],[e localizedDescription]);
                } synchronous:YES];
            }
        } else {
            ApiRequest *fileUploadRequest = [[ApiRequest alloc] initWithAction:@"put_file" params:@{@"dir_id" : fse.pid , @"file" : fse, @"overwrite":@"1"} withToken:YES];
            [fileUploadRequest performRequestWithBlock:^(NSDictionary *response, NSError *e) {
                if (!e) {
                    fse.id = [[response valueForKey:@"file"] valueForKey:@"id"];
                    [_db insertElement:fse];
                } else NSLog(@"%ld: %@",[e code],[e localizedDescription]);
            }];
        }
        
        //TODO: firstly, create the folders, after than - upload files!
        /*ApiRequest *r3 = [[ApiRequest alloc] initWithAction:@"put_file" params:@{@"dir_id" : fse.pid , @"file" : fse, @"overwrite":@"1"} withToken:YES];
        [r3 performRequestWithBlock:^(NSDictionary *response, NSError *e) {
            if (!e) {
                for (id key in response) {
                    NSLog(@"%@ = %@", key, [response objectForKey:key]);
                }
            } else {
                NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
            }
         }
        ];*/
        
    }
    
    /*//DELETING FILES!
    for(FSElement *fse in _clientDeletionsQueue) {
        ApiRequest *r4 = [[ApiRequest alloc] initWithAction:@"remove_file" params:@{@"id" : fse.id, @"remove_now":@"1"} withToken:YES];
        [r4 performRequestWithBlock:^(NSDictionary *response, NSError *e) {
            if (!e) {
                for (id key in response) {
                    NSLog(@"%@ = %@", key, [response objectForKey:key]);
                }
            } else {
                NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
            }
            sleep(2);
        }
         ];
    }*/
}


@end
