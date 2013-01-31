//
//  SystemTrayController.h
//  2Safe
//
//  Created by Alex Puchkovskiy on 31.01.13.
//  Copyright (c) 2013 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SystemTrayController : NSObject {
    /* Our outlets which allow us to access the interface */
    IBOutlet NSMenu *statusMenu;
    
    /* The other stuff :P */
    NSStatusItem *statusItem;
    NSImage *statusImage;
    NSImage *statusHighlightImage;
}

//
//Actions
//
- (IBAction)openFolder:(id)sender;
- (IBAction)openWebSite:(id)sender;
- (IBAction)openPreferences:(id)sender;
- (IBAction)openHelp:(id)sender;
- (IBAction)quit:(id)sender;

@end
