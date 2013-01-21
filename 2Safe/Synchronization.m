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
    NSMutableArray *_serverInsertionsQueue;
    NSMutableArray *_serverDeletionsQueue;
    NSMutableArray *_clientInsertionsQueue;
    NSMutableArray *_clientDeletionsQueue;
    
}

- (id) init {
    if (self = [super init]) {
        _fm = [NSFileManager defaultManager];
        _db = [Database databaseForAccount:@"kakysha"];
        _folderStack = [NSMutableArray arrayWithCapacity:100];
        _uploadFolderStack = [NSMutableArray arrayWithCapacity:50];
        _serverInsertionsQueue = [NSMutableArray arrayWithCapacity:50];
        _serverDeletionsQueue = [NSMutableArray arrayWithCapacity:50];
        _clientInsertionsQueue = [NSMutableArray arrayWithCapacity:50];
        _clientDeletionsQueue = [NSMutableArray arrayWithCapacity:50];
        return self;
    }
    return nil;
}

-(void) getServerQueues:(NSString*) folder {
    ApiRequest *getEvents = [[ApiRequest alloc] initWithAction:@"get_events" params:@{@"after":@"1358760165599963"} withToken:YES];
    [getEvents performRequestWithBlock:^(NSDictionary *response, NSError *e) {
        if (!e) {
            NSString *elementPath;
            /*for(id key in response){
                NSLog(@"%@ = %@",key,[response objectForKey:key]);
            }*/
            for (NSDictionary *dict in [response objectForKey:@"events"]) {
                /* for(id key in dict){
                    NSLog(@"%@ = %@", key, [dict objectForKey:key]);
                } */
                if([[dict objectForKey:@"event"] isEqualTo:@"file_uploaded"] ||
                   [[dict objectForKey:@"event"] isEqualTo:@"dir_created"]){
                    
                    //trying to locate element's parent
                    FSElement *parentElement = [_db getElementById:[dict objectForKey:@"parent_id"] withFullFilePath:YES];
                    if (parentElement)
                        //db returns full path only starting from the application folder root
                        elementPath = [[folder stringByAppendingPathComponent:parentElement.filePath] stringByAppendingPathComponent:[dict objectForKey:@"name"]];
                    else {
                        NSUInteger ind = [_serverInsertionsQueue indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj id] isEqualToString:[dict objectForKey:@"parent_id"]]){*stop = YES;return YES;} return NO;}];
                        if (ind != NSNotFound) {
                            //in _serverInsertionsQueue we already have elements with absolute file paths
                            elementPath = [[[_serverInsertionsQueue objectAtIndex:ind] filePath] stringByAppendingPathComponent:[dict objectForKey:@"name"]];
                        }
                    }
                    if (!elementPath) continue; //nothing found neither in db nor in serverQueue - that innormal, but we must do with it anyway
                    FSElement *elementToAdd = [[FSElement alloc] init];
                    elementToAdd.filePath = elementPath;
                    elementToAdd.name = [dict objectForKey:@"name"];
                    elementToAdd.id = [dict objectForKey:@"id"];
                    elementToAdd.pid = [dict objectForKey:@"parent_id"];
                    if ([[dict objectForKey:@"event"] isEqualTo:@"dir_created"]) elementToAdd.hash = @"NULL";
                    [_serverInsertionsQueue addObject:elementToAdd];
                }	
                if ([[dict objectForKey:@"event"] isEqualTo:@"file_moved"] ||
                         [[dict objectForKey:@"event"] isEqualTo:@"dir_moved"]){
                    FSElement *elementToDel = [_db getElementByName:[dict objectForKey:@"old_name"] withPID:[dict objectForKey:@"old_parent_id"] withFullFilePath:YES];
                    if (!elementToDel) {
                        NSUInteger ind = [_serverInsertionsQueue indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj name] isEqualToString:[dict objectForKey:@"old_name"]] && [[obj pid] isEqualToString:[dict objectForKey:@"old_parent_id"]]){*stop = YES;return YES;} return NO;}];
                        if (ind == NSNotFound) continue; //nothing found, return
                        FSElement *elem = [_serverInsertionsQueue objectAtIndex:ind];
                        //move or rename
                        if ([[dict objectForKey:@"new_parent_id"] isNotEqualTo:@"1108987033540"]){ //TODO: Trash ID HERE!
                            FSElement *elementToAdd = [[FSElement alloc] init];
                            FSElement *parentElement = [_db getElementById:[dict objectForKey:@"new_parent_id"]];
                            if(!parentElement){
                                NSUInteger pind = [_serverInsertionsQueue indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj id] isEqualToString:[dict objectForKey:@"new_parent_id"]]){*stop = YES;return YES;} return NO;}];
                                parentElement = [_serverInsertionsQueue objectAtIndex:pind];
                            }
                            elementToAdd.filePath = [[folder stringByAppendingPathComponent:parentElement.filePath] stringByAppendingPathComponent:[dict objectForKey:@"new_name"]];
                            elementToAdd.name = [dict objectForKey:@"new_name"];
                            elementToAdd.pid = [dict objectForKey:@"new_parent_id"];
                            elementToAdd.id = elem.id;
                            elementToAdd.hash = elem.hash;
                            elementToAdd.mdate = elem.mdate;
                            [_serverInsertionsQueue addObject:elementToAdd];
                        }
                        [_serverInsertionsQueue removeObjectAtIndex:ind];
                    }
                    else {
                        elementToDel.filePath = [folder stringByAppendingPathComponent:elementToDel.filePath];
                        [_serverDeletionsQueue addObject:elementToDel];
                        //move -or- rename
                        if ([[dict objectForKey:@"new_parent_id"] isNotEqualTo:@"1108987033540"]){ //TODO: Trash ID HERE!
                            elementToDel.pid = [dict objectForKey:@"new_parent_id"];
                            FSElement *parentElement = [_db getElementById:[dict objectForKey:@"new_parent_id"]];
                            if(!parentElement){
                                NSUInteger pind = [_serverInsertionsQueue indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj id] isEqualToString:[dict objectForKey:@"new_parent_id"]]){*stop = YES;return YES;} return NO;}];
                                parentElement = [_serverInsertionsQueue objectAtIndex:pind];
                            }
                            elementToDel.filePath = [[folder stringByAppendingPathComponent:parentElement.filePath] stringByAppendingPathComponent:[dict objectForKey:@"new_name"]];
                            elementToDel.name = [dict objectForKey:@"new_name"];
                            [_serverInsertionsQueue addObject:elementToDel];
                        }
                    }
                }
            }
            for (FSElement *el in _serverInsertionsQueue) {
                NSLog(@"+%@ %@ %@", el.id, el.filePath, el.pid);
            }
            for (FSElement *el in _serverDeletionsQueue) {
                NSLog(@"-%@ %@ %@", el.id, el.filePath, el.pid);
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
            elementToAdd.pid = stackElem.id;
            BOOL isDir = NO;
            [_fm fileExistsAtPath:elementToAdd.filePath isDirectory:&isDir];
            NSUInteger foundIndex = [bdfiles indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj name] isEqualToString:elementToAdd.name]){*stop = YES;return YES;} return NO;}];
            if (foundIndex == NSNotFound) {
                [_clientInsertionsQueue addObject:elementToAdd];
            }
            else {
                FSElement *dbElem = bdfiles[foundIndex];
                if(isDir){
                    dbElem.filePath = elementToAdd.filePath;
                    [_folderStack push:dbElem];
                } else
                if (![elementToAdd.mdate isEqualToString:dbElem.mdate]){
                    elementToAdd.id = dbElem.id;
                    [_clientInsertionsQueue addObject:elementToAdd];
                }
                [bdfiles removeObjectAtIndex:foundIndex];
            }
        }
        if (bdfiles.count != 0)
            for(FSElement *fse in bdfiles) [_clientDeletionsQueue addObject:fse];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self performInsertionQueue]; });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self performDeletionQueue]; });
}

-(void) performInsertionQueue{
    for(FSElement *fse in _clientInsertionsQueue) {
        if ([fse.hash isEqualToString:@"NULL"]) { // directory, recursively hop in it and it's contents
            [_uploadFolderStack push:fse];
            
            while ([_uploadFolderStack count] > 0) {
                __block FSElement *curDirEl = [_uploadFolderStack pop];
                
                //firstly, create a dir on the server to get it's id [respectively block thread to wait for execution of request]
                ApiRequest *folderUploadRequest = [[ApiRequest alloc] initWithAction:@"make_dir" params:@{@"dir_id":curDirEl.pid, @"dir_name":curDirEl.name} withToken:YES];
                [folderUploadRequest performRequestWithBlock:^(NSDictionary *response, NSError *e){
                    
                    if (!e) {
                        curDirEl.id = [response valueForKey:@"dir_id"];
                        [_db insertElement:curDirEl];
                        
                        //iterate through files
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
                                ApiRequest *fileUploadRequest2 = [[ApiRequest alloc] initWithAction:@"put_file" params:@{@"dir_id" : childEl.pid , @"file" : childEl, @"versioned":@"1"} withToken:YES];
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
                    if (fse.id) [_db updateElementWithId:fse.id withValues:fse];
                    else {
                        fse.id = [[response valueForKey:@"file"] valueForKey:@"id"];
                        [_db insertElement:fse];
                    }
                } else NSLog(@"%ld: %@",[e code],[e localizedDescription]);
            }];
        }
    }
}

- (void) performDeletionQueue {
    for(FSElement *fse in _clientDeletionsQueue) {
        if ([fse.hash isEqualToString:@"NULL"]) { // directory, delete it recursively
            ApiRequest *delDirectory = [[ApiRequest alloc] initWithAction:@"remove_dir" params:@{@"dir_id" : fse.id, @"recursive":@"1"} withToken:YES];
            [delDirectory performRequestWithBlock:^(NSDictionary *response, NSError *e) {
                if (!e) {
                    [_db deleteElementById:fse.id];
                } else NSLog(@"%ld: %@",[e code],[e localizedDescription]);
            }];
        } else { // file
            ApiRequest *delFile = [[ApiRequest alloc] initWithAction:@"remove_file" params:@{@"id" : fse.id} withToken:YES];
            [delFile performRequestWithBlock:^(NSDictionary *response, NSError *e) {
                if (!e) {
                    [_db deleteElementById:fse.id];
                } else NSLog(@"%ld: %@",[e code],[e localizedDescription]);
            }];
        }
    }
}


@end
