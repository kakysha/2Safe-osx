//
//  SystemTrayController.m
//  2Safe
//
//  Created by Alex Puchkovskiy on 31.01.13.
//  Copyright (c) 2013 zaopark. All rights reserved.
//

#import "SystemTrayController.h"
#import "AppDelegate.h"

@implementation SystemTrayController {
    AppDelegate *_app;
}

- (void) awakeFromNib{
    _app = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    
    //Create the NSStatusBar and set its length
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:25] init];
    
    //Load image
    NSBundle *bundle = [NSBundle mainBundle];
    statusImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"tray_ico" ofType: @"ico"]];
    
    //Sets the images and text in NSStatusItem
    [statusItem setImage:statusImage];
    [statusItem setHighlightMode:YES];
    
    //Tells the NSStatusItem what menu to load
    [statusItem setMenu:statusMenu];
    
    //Sets the tooptip for our item
    [statusItem setToolTip:@"2Safe"];
}


//Open 2Safe folder
- (IBAction)openFolder:(id)sender {
    if (_app.rootFolderPath) {
        NSURL *folderURL = [NSURL URLWithString:_app.rootFolderPath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ folderURL ]];
    }
}

//Open 2Safe's web site
- (IBAction)openWebSite:(id)sender {
    NSURL *url = [[NSURL alloc] initWithString: @"https://www.2safe.com/"];
    [[NSWorkspace sharedWorkspace] openURL: url];
}

//Open preferences window
- (IBAction)openPreferences:(id)sender {
    [_app chooseRootFolderAndDownloadFiles:NO];
}

//Open help window
- (IBAction)login_logout:(id)sender {
    if (_app.account) {
        [_app logout];
    } else [_app start];
}

//QUIT Application
- (IBAction)quit:(id)sender {
    [[NSApplication sharedApplication] terminate: nil];
}
@end
