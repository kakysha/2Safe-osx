//
//  LoginController.h
//  2Safe
//
//  Created by Drunk on 10.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSKeychain.h"

@interface LoginController : NSObject <NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSView *captchaView;

@property (weak) IBOutlet NSSecureTextField *password;
@property (weak) IBOutlet NSTextField *login;
@property (weak) IBOutlet NSImageView *captchaImage;
@property (weak) IBOutlet NSTextFieldCell *captchaText;

- (IBAction)enter:(id)sender;
- (void)windowDidBecomeKey:(NSNotification *)notification;

+ (NSString *)token;
+ (void)requestTokenWithBlock:(void(^)(NSString *))responseBlock;

@end
