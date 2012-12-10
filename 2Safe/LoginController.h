//
//  LoginController.h
//  2Safe
//
//  Created by Drunk on 10.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSKeychain.h"

@interface LoginController : NSObject

@property (assign) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSSecureTextField *password;
@property (weak) IBOutlet NSTextField *login;

- (IBAction)enter:(id)sender;

+ (NSString *)token;

@end
