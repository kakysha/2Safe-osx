//
//  Synchronization.m
//  2Safe
//
//  Created by Dan on 1/13/13.
//  Copyright (c) 2013 zaopark. All rights reserved.
//

#import "Synchronization.h"
#import "NSMutableArray+Stack.h"
#import "Database.h"
#import "FSElement.h"
#import "ApiRequest.h"
#import "AppDelegate.h"

@implementation Synchronization{
    NSMutableArray *_folderStack;
    NSMutableArray *_uploadFolderStack;
    NSMutableArray *_downloadFolderStack;
    NSFileManager *_fm;
    NSMutableDictionary *_serverMoves;
    Database *_db;
    NSMutableArray *_serverInsertionsQueue;
    NSMutableArray *_serverDeletionsQueue;
    NSMutableArray *_clientInsertionsQueue;
    NSMutableArray *_clientDeletionsQueue;
    NSMutableDictionary *_timeStamps;
    NSString *_folder;
    AppDelegate *_app;
}

- (id) init {
    if (self = [super init]) {
        _app = (AppDelegate *)[[NSApplication sharedApplication] delegate];
        _fm = [NSFileManager defaultManager];
        _db = [Database databaseForAccount:_app.account];
        _folderStack = [NSMutableArray arrayWithCapacity:100];
        _uploadFolderStack = [NSMutableArray arrayWithCapacity:50];
        _downloadFolderStack = [NSMutableArray arrayWithCapacity:50];
        _serverInsertionsQueue = [NSMutableArray arrayWithCapacity:50];
        _serverDeletionsQueue = [NSMutableArray arrayWithCapacity:50];
        _clientInsertionsQueue = [NSMutableArray arrayWithCapacity:50];
        _clientDeletionsQueue = [NSMutableArray arrayWithCapacity:50];
        _serverMoves = [NSMutableDictionary dictionaryWithCapacity:50];
        _folder = @"/Users/dan/Downloads/2safe/";
        return self;
    }
    return nil;
}

-(void) startSynchronization {
    
    [self getServerQueues];
    [self getClientQueues];
    [self resolveConflicts];
    
    [self performServerInsertionQueue];
    [self performServerDeletionQueue];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self performClientInsertionQueue]; });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self performClientDeletionQueue]; });
}

-(void) getServerQueues {
    ApiRequest *getEvents = [[ApiRequest alloc] initWithAction:@"get_events" params:@{@"after":_app.lastActionTimestamp} withToken:YES];
    [getEvents performRequestWithBlock:^(NSDictionary *response, NSError *e) {
        if (!e) {
            for (NSDictionary *dict in [response objectForKey:@"events"]) {
                if(([[dict objectForKey:@"event"] isEqualTo:@"file_uploaded"] && [dict objectForKey:@"size"]) ||
                   [[dict objectForKey:@"event"] isEqualTo:@"dir_created"]){
                    NSUInteger objId = [_serverInsertionsQueue indexOfObjectPassingTest:^(id obj, NSUInteger objId, BOOL *stop){if ([[obj id] isEqualToString:[dict objectForKey:@"id"]]){*stop = YES;return YES;} return NO;}];
                    if (objId == NSNotFound){
                        FSElement *elementToAdd = [[FSElement alloc] init];
                        elementToAdd.name = [dict objectForKey:@"name"];
                        elementToAdd.id = [dict objectForKey:@"id"];
                        elementToAdd.pid = [dict objectForKey:@"parent_id"];
                        if ([[dict objectForKey:@"event"] isEqualTo:@"dir_created"]) elementToAdd.hash = @"NULL";
                        [_serverInsertionsQueue addObject:elementToAdd];
                    }
                }
                /** the principle on which the algorithm relies when moving files/fodlers:
                 move = deletion (from the old location) + creation (at the new location)
                 three queues are created: deletion queue, creation queue and move queue
                 deletion queue stores the elements that were moved out
                 creation queue stores the elements which will be created at the destination location
                 move queue matches the elements from deletion queue to insertion queue. If found the match then the file is moved, 
                    elsewere two actions are accomplished separately - one element is deleted and the other element is created
                 **/
                if ([[dict objectForKey:@"event"] isEqualTo:@"file_moved"] ||
                         [[dict objectForKey:@"event"] isEqualTo:@"dir_moved"]){
                    NSString *oldId = [[dict objectForKey:@"event"] isEqualTo:@"file_moved"] ? [dict objectForKey:@"old_id"] : [dict objectForKey:@"id"];
                    NSString *newId = [[dict objectForKey:@"event"] isEqualTo:@"file_moved"] ? [dict objectForKey:@"new_id"] : [dict objectForKey:@"id"];
                    FSElement *elementToDel = [_db getElementById:oldId withFullFilePath:YES];
                    NSInteger ind;
                    if (!elementToDel) {
                        ind = [_serverInsertionsQueue indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj id] isEqualToString:oldId]){*stop = YES;return YES;} return NO;}];
                        if (ind == NSNotFound) continue; //nothing found, return
                        elementToDel = [_serverInsertionsQueue objectAtIndex:ind];
                        [_serverInsertionsQueue removeObjectAtIndex:ind];
                    } else {
                        [_serverDeletionsQueue addObject:elementToDel];
                        [_serverMoves setObject:elementToDel.id forKey:elementToDel.id];
                    }
                    //move or rename
                    if ([[dict objectForKey:@"new_parent_id"] isNotEqualTo:_app.trashFolderId]){
                        FSElement *elementToAdd = [[FSElement alloc] init];
                        elementToAdd.name = [dict objectForKey:@"new_name"];
                        elementToAdd.id = newId;
                        elementToAdd.pid = [dict objectForKey:@"new_parent_id"];
                        if ([[dict objectForKey:@"event"] isEqualTo:@"dir_moved"]) elementToAdd.hash = @"NULL";
                        ind > -1 ? [_serverInsertionsQueue insertObject:elementToAdd atIndex:ind] : [_serverInsertionsQueue addObject:elementToAdd];
                        //find the deletion id corresponding to the moving file:
                        NSString *delId = [_serverMoves objectForKey:elementToDel.id];
                        if (delId) {
                            [_serverMoves removeObjectForKey:elementToDel.id];
                            [_serverMoves setObject:delId forKey:elementToAdd.id];
                        }
                    //delete
                    } else {
                        //remove element's childs from insertionQueue, if there are some.
                        [self removeChildrenFromQueueForElement:elementToDel];
                    }
                }
                //save timestamps
                NSString *tsid = [dict objectForKey:@"id"] ? [dict objectForKey:@"id"] : [dict objectForKey:@"new_id"];
                [_timeStamps setObject:[dict objectForKey:@"timestamp"] forKey:tsid];
            }
            for (FSElement *el in _serverInsertionsQueue) {
                NSLog(@"+%@ %@ %@", el.id, el.name, el.pid);
            }
            for (FSElement *el in _serverDeletionsQueue) {
                NSLog(@"-%@ %@ %@", el.id, el.name, el.pid);
            }
            for (id key in [_serverMoves allKeys]) {
                NSLog(@"move:%@ %@", key, [_serverMoves objectForKey:key]);
            }
            
            //[self performServerInsertionQueue];
            //[self performServerDeletionQueue];
            
        } else NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
    }];
}

-(void) removeChildrenFromQueueForElement:(FSElement *)el {
    for (int i = 0; i < _serverInsertionsQueue.count; i++){
        FSElement *obj = [_serverInsertionsQueue objectAtIndex:i];
        if ([obj.pid isEqualToString:el.id]) {
            [self removeChildrenFromQueueForElement:obj];
            [_serverInsertionsQueue removeObject:obj];
        }
    }
}

-(void) getClientQueues {
    FSElement *root = [[FSElement alloc] initWithPath:_folder];
    root.id = _app.rootFolderId;
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
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self performClientInsertionQueue]; });
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self performClientDeletionQueue]; });
}

-(void)resolveConflicts{
    for(FSElement *clientInsertionElement in _clientInsertionsQueue){
        NSUInteger foundIndex = [_serverInsertionsQueue indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj name] isEqualToString:clientInsertionElement.name] && [[obj pid] isEqualToString:clientInsertionElement.pid]){*stop = YES;return YES;} return NO;}];
        [_folderStack removeAllObjects];
        if(foundIndex != NSNotFound && [clientInsertionElement.hash isEqualToString:@"NULL"]){
            //TODO: Delete folder from serverInsertions when conflict appears or not?
            [_serverInsertionsQueue removeObjectAtIndex:foundIndex];
            [_folderStack push: clientInsertionElement];
            while([_folderStack count] != 0){
                FSElement *stackElem = [_folderStack pop];
                [_db insertElement:stackElem];
                NSArray* files = [_fm contentsOfDirectoryAtPath:stackElem.filePath error:nil];
                for(NSString *file in files) {
                    NSString *path = [stackElem.filePath stringByAppendingPathComponent:file];
                    FSElement *elementToAdd = [[FSElement alloc] initWithPath:path];
                    elementToAdd.pid = stackElem.id;
                    BOOL isDir = NO;
                    [_fm fileExistsAtPath:elementToAdd.filePath isDirectory:&isDir];
                    NSUInteger nextFoundIndex = [_serverInsertionsQueue indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj name] isEqualToString:elementToAdd.name] && [[obj pid] isEqualTo:[[_serverInsertionsQueue objectAtIndex:foundIndex] id]]){*stop = YES;return YES;} return NO;}];
                    if (nextFoundIndex != NSNotFound) {
                        FSElement *serverInsertionElement = [_serverInsertionsQueue objectAtIndex:nextFoundIndex];
                        if(isDir){
                            [_serverInsertionsQueue removeObject:serverInsertionElement];
                            [_clientInsertionsQueue removeObject:elementToAdd];
                            elementToAdd.id = serverInsertionElement.id;
                            [_folderStack push:elementToAdd];
                        } else {
                            __block NSString *sInsHash;
                            ApiRequest *getHashRequest = [[ApiRequest alloc] initWithAction:@"get_props" params:@{@"id":serverInsertionElement.id} withToken:YES];
                            [getHashRequest performRequestWithBlock:^(NSDictionary *response, NSError *e){
                                if (!e) {
                                    for(id obj in [response objectForKey:@"object"]){
                                        if([[obj key] isEqualToString:@"chksum"]){
                                            sInsHash = [obj value];
                                        }else continue;
                                    }
                                    serverInsertionElement.hash = sInsHash;
                                    if([elementToAdd.hash isEqualTo:sInsHash]){
                                        [_serverInsertionsQueue removeObject:serverInsertionElement];
                                        [_clientInsertionsQueue removeObject:elementToAdd];
                                        elementToAdd.id = serverInsertionElement.id;
                                        [_db insertElement:elementToAdd];
                                    }
                                    
                                    
                                }else NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
                            }];
                        }
                            
                    }
                }

            }
        }
        else if (foundIndex != NSNotFound){
            FSElement *serverInsertionElement = [_serverInsertionsQueue objectAtIndex:foundIndex];
            __block NSString *sInsHash;
            ApiRequest *getHashRequest = [[ApiRequest alloc] initWithAction:@"get_props" params:@{@"id":serverInsertionElement.id} withToken:YES];
            [getHashRequest performRequestWithBlock:^(NSDictionary *response, NSError *e){
                if (!e) {
                    for(id obj in [response objectForKey:@"object"]){
                        if([[obj key] isEqualToString:@"chksum"]){
                            sInsHash = [obj value];
                        }else continue;
                    }
                    serverInsertionElement.hash = sInsHash;
                    if([clientInsertionElement.hash isEqualTo:sInsHash]){
                        [_serverInsertionsQueue removeObject:serverInsertionElement];
                        clientInsertionElement.id = serverInsertionElement.id;
                        [_db insertElement:clientInsertionElement];
                        [_clientInsertionsQueue removeObject:clientInsertionElement];
                    }
                }else NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
            }];
        }
    }

    NSMutableArray *nonDeletableIds = [NSMutableArray arrayWithCapacity:50];
    for(FSElement *serverInsertionElement in _serverInsertionsQueue){
        FSElement *p = serverInsertionElement;
        [nonDeletableIds addObject:p.id];
        while([p.pid isNotEqualTo:@"<null>"]){
            NSUInteger foundIndex = [nonDeletableIds indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([obj isEqualToString:p.pid]){*stop = YES;return YES;} return NO;}];
            if(foundIndex == NSNotFound){
                [nonDeletableIds addObject:p.pid];
            }
            foundIndex = [_serverInsertionsQueue indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj id] isEqualToString:p.pid]){*stop = YES;return YES;} return NO;}];
            if(foundIndex != NSNotFound){
                p = [_serverInsertionsQueue objectAtIndex:foundIndex];
            }else {
                p = [_db getElementById:p.pid];
            }
        }
    }
    if([nonDeletableIds count] != 0){
        for (FSElement *clientDeletionElement in _clientDeletionsQueue){
            NSUInteger foundIndex = [nonDeletableIds indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([obj isEqualToString:clientDeletionElement.id]){*stop = YES;return YES;} return NO;}];
            if (foundIndex != NSNotFound && [clientDeletionElement.hash isEqualToString:@"NULL"]){
                [_clientDeletionsQueue removeObject:clientDeletionElement];
                [_folderStack removeAllObjects];
                    [_folderStack push: clientDeletionElement];
                    while([_folderStack count] != 0){
                        FSElement *stackElem = [_folderStack pop];
                        NSArray* files = [_fm contentsOfDirectoryAtPath:stackElem.filePath error:nil];
                        for(NSString *file in files) {
                            //NSString *path = [stackElem.filePath stringByAppendingPathComponent:file];
                            FSElement *elementToAdd = [_db getElementByName:file withPID:stackElem.id withFullFilePath:YES];
                            BOOL isDir = NO;
                            [_fm fileExistsAtPath:elementToAdd.filePath isDirectory:&isDir];
                            NSUInteger nextFoundIndex = [nonDeletableIds indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([obj isEqualToString:elementToAdd.id]){*stop = YES;return YES;} return NO;}];
                            if (nextFoundIndex != NSNotFound) {
                                if(isDir){
                                    [_folderStack push:elementToAdd];
                                }
                            }
                            else{
                                [_clientDeletionsQueue addObject:elementToAdd];
                            }
                        }
                        
                    }
            }
        }
    }
    [nonDeletableIds removeAllObjects];
    NSMutableArray *nonDeletableObjects = [[NSMutableArray alloc] initWithCapacity:50];
    for(FSElement *clientInsertionElement in _clientInsertionsQueue){
        FSElement *p = clientInsertionElement;
        //[nonDeletableObjects addObject:p];
        while([p.id isNotEqualTo:@"<null>"]){
            NSUInteger foundIndex = [nonDeletableObjects indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj id] isEqualToString:p.pid]){*stop = YES;return YES;} return NO;}];
            if(foundIndex == NSNotFound){
                [nonDeletableObjects addObject:p];
            }
            p = [_db getElementById:p.pid];
        }
    }
    if ([nonDeletableObjects count] != 0){
        for (FSElement *serverDeletionElement in _serverDeletionsQueue){
            NSUInteger foundIndex = [nonDeletableObjects indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj pid] isEqualToString:serverDeletionElement.pid] && [[obj name] isEqualToString:serverDeletionElement.name]){*stop = YES;return YES;} return NO;}];
            if (foundIndex != NSNotFound && [serverDeletionElement.hash isEqualToString:@"NULL"]){
                [_serverDeletionsQueue removeObject:serverDeletionElement];
                [_folderStack removeAllObjects];
                [_folderStack push: serverDeletionElement];
                while([_folderStack count] != 0){
                    FSElement *stackElem = [_folderStack pop];
                    NSArray* files = [_fm contentsOfDirectoryAtPath:stackElem.filePath error:nil];
                    for(NSString *file in files) {
                        //NSString *path = [stackElem.filePath stringByAppendingPathComponent:file];
                        FSElement *elementToAdd = [_db getElementByName:file withPID:stackElem.id withFullFilePath:YES];
                        BOOL isDir = NO;
                        [_fm fileExistsAtPath:elementToAdd.filePath isDirectory:&isDir];
                        NSUInteger nextFoundIndex = [nonDeletableIds indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([obj isEqualToString:elementToAdd.id]){*stop = YES;return YES;} return NO;}];
                        if (nextFoundIndex != NSNotFound) {
                            if(isDir){
                                [_folderStack push:elementToAdd];
                            }
                        }
                        else{
                            [_serverDeletionsQueue addObject:elementToAdd];
                        }
                    }
                    
                }
            }
        }
    }
}

-(void) performClientInsertionQueue{
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

- (void) performClientDeletionQueue {
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

- (NSString *) getFullFilePathForElement:(FSElement *)el {
    NSString *filePath;
    FSElement *parentElement = [_db getElementById:el.pid withFullFilePath:YES];
    if (parentElement)
        filePath = [[_folder stringByAppendingPathComponent:parentElement.filePath] stringByAppendingPathComponent:el.name];
    else {
        NSUInteger ind = [_serverInsertionsQueue indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){if ([[obj id] isEqualToString:el.pid]){*stop = YES;return YES;} return NO;}];
        if (ind != NSNotFound) {
            parentElement = [_serverInsertionsQueue objectAtIndex:ind];
            if (parentElement.filePath)
                filePath = [parentElement.filePath stringByAppendingPathComponent:el.name];
            else
                filePath = [[self getFullFilePathForElement:parentElement] stringByAppendingPathComponent:el.name];
        }
    }
    return filePath;
}

-(void) performServerInsertionQueue{
    for(FSElement *fse in _serverInsertionsQueue) {
        fse.filePath = [self getFullFilePathForElement:fse];
        NSString *delId = [_serverMoves objectForKey:fse.id];
        //move file
        if (delId) {
            NSInteger delInd = [_serverDeletionsQueue indexOfObjectPassingTest:^(FSElement *obj, NSUInteger idx, BOOL *stop){if ([obj.id isEqualToString:delId]){*stop = YES;return YES;} return NO;}];
            FSElement *delEl = [_serverDeletionsQueue objectAtIndex:delInd];
            delEl.filePath = [self getFullFilePathForElement:delEl];
            [_fm moveItemAtPath:delEl.filePath toPath:fse.filePath error:nil];
            [_serverDeletionsQueue removeObjectAtIndex:delInd];
            [_serverMoves removeObjectForKey:fse.id];
            [_db updateElementWithId:delId withValues:fse];
        //insert file
        } else {
            if ([fse.hash isEqualToString:@"NULL"]) {
                //create dir
                [_fm createDirectoryAtPath:fse.filePath withIntermediateDirectories:NO attributes:nil error:nil];
                [_db insertElement:fse];
            } else {
                ApiRequest *fileDownloadRequest = [[ApiRequest alloc] initWithAction:@"get_file" params:@{@"id" : fse.id} withToken:YES];
                [fileDownloadRequest performStreamRequest:[[NSOutputStream alloc] initToFileAtPath:fse.filePath append:NO] withBlock:^(NSData *response, NSHTTPURLResponse *h, NSError *e) {
                    if (!e) {
                        if ([_db getElementById:fse.id]) {
                            [_db updateElementWithId:fse.id withValues:fse];
                        } else
                            [_db insertElement:fse];
                    } else NSLog(@"%ld: %@",[e code],[e localizedDescription]);
                }];
            }
        }
        if ([_timeStamps objectForKey:fse.id])
            _app.lastActionTimestamp = [NSString stringWithFormat:@"%@",[_timeStamps objectForKey:fse.id]];
    }
}

-(void) performServerDeletionQueue{
    for(FSElement *fse in _serverDeletionsQueue) {
        fse.filePath = [self getFullFilePathForElement:fse];
        [_fm removeItemAtPath:fse.filePath error:nil];
        [_db deleteElementById:fse.id];
        if ([_timeStamps objectForKey:fse.id])
            _app.lastActionTimestamp = [_timeStamps objectForKey:fse.id];
    }
}

@end
