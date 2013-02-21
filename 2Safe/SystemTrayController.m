//
//  SystemTrayController.m
//  2Safe
//
//  Created by Alex Puchkovskiy on 31.01.13.
//  Copyright (c) 2013 zaopark. All rights reserved.
//

#import "SystemTrayController.h"
#import "ApiRequest.h"

@implementation SystemTrayController

- (void) awakeFromNib{
    
    //Create the NSStatusBar and set its length
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:60] init];
    
    //Load image
    NSBundle *bundle = [NSBundle mainBundle];
    statusImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"tray_ico" ofType: @"ico"]];
    
    //Sets the images and text in NSStatusItem
    [statusItem setTitle:@"2Safe"];
    [statusItem setImage:statusImage];
    [statusItem setHighlightMode:YES];
    
    //Tells the NSStatusItem what menu to load
    [statusItem setMenu:statusMenu];
    
    //Sets the tooptip for our item
    [statusItem setToolTip:@"2Safe"];
    
    //Create request. return disk quota
    ApiRequest *r2 = [[ApiRequest alloc] initWithAction:@"get_disk_quota" params:@{} withToken:YES];
    //send request
    /*[r2 performRequestWithBlock:^(NSDictionary *response, NSError *e) {
        if (!e) {
            for (id key in response) {
                //NSLog(@"%@ = %@", key, [response objectForKey:key]);
            }
        } else NSLog(@"Error code:%ld description:%@",[e code],[e localizedDescription]);
    }];*/
}


//Open 2Safe folder
- (IBAction)openFolder:(id)sender {
    NSString* stringContainingPath = @"/Users/Puchok/Desktop/1";
    NSURL *fileURL = [NSURL fileURLWithPath: stringContainingPath];
    NSURL *folderURL = [fileURL URLByDeletingLastPathComponent];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ folderURL ]];
}

//Open 2Safe's web site
- (IBAction)openWebSite:(id)sender {
    NSURL *url = [[NSURL alloc] initWithString: @"https://www.2safe.com/"];
    [[NSWorkspace sharedWorkspace] openURL: url];
}

//Open preferences window
- (IBAction)openPreferences:(id)sender {
    
}

//Open help window
- (IBAction)openHelp:(id)sender {
}

//QUIT Application
- (IBAction)quit:(id)sender {
    [[NSApplication sharedApplication] terminate: nil];
}
@end
