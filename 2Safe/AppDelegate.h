//
//  AppDelegate.h
//  2Safe
//
//  Created by Drunk on 29.11.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    FSEventStreamRef _stream;
    FSEventStreamContext *_context;
    BOOL _running;
    
    IBOutlet NSArrayController *ctrl;
}

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
