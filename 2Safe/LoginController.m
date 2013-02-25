//
//  LoginController.m
//  2Safe
//
//  Created by Drunk on 10.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "LoginController.h"
#import "ApiRequest.h"
#import "AppDelegate.h"

@implementation LoginController {
}

NSDictionary *credentials = nil;
BOOL isCaptchaNeeded = NO;
NSString *captchaId;
NSError *_error;
BOOL restart = NO;
@synthesize window;
@synthesize captchaView;
@synthesize login;
@synthesize password;
@synthesize captchaImage;
@synthesize captchaText;
@synthesize errorMessage;
@synthesize enterButton;

- (IBAction)enter:(id)sender {
    credentials = [[NSDictionary alloc] initWithObjectsAndKeys:[login stringValue], @"login", [password stringValue], @"password", [captchaText stringValue], @"captcha", captchaId, @"captcha_id", nil];
    [LoginController auth];
    [enterButton setEnabled:NO];
}

- (void)updateWindow{
    [window makeKeyAndOrderFront:nil];
    [enterButton setEnabled:YES];
    if (isCaptchaNeeded) {
        [captchaView setHidden:NO];
        ApiRequest *cr = [[ApiRequest alloc] initWithAction:@"get_captcha" params:@{}];
        [cr performDataRequestWithBlock:^(NSData *r, NSHTTPURLResponse *h, NSError *e) {
            NSImage *img = [[NSImage alloc] initWithData:r];
            [captchaImage setImage:img];
            captchaId = [LoginController getCpatchaIdFromResponseHeaders:h];
            isCaptchaNeeded = NO;
        }];
    }
    if ([LoginController error]) {
        [errorMessage setStringValue:[[LoginController error] localizedDescription]];
    }
}

+ (void)showLoginWindowWithCaptcha:(BOOL)wc{
    isCaptchaNeeded = wc;
    NSLog(@"Asking user for login/password");
    [[[[NSApplication sharedApplication] windows][0] delegate] updateWindow]; // DIRTY SLUTTY CODE HERE, BEWARE!
}

+ (NSError *)error{
    return _error;
}

+ (void) authAndRestart{
    restart = true;
    [LoginController auth];
}
+ (void) auth{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"token"]; //purge old token
    ((AppDelegate *)[[NSApplication sharedApplication] delegate]).account = nil;
    _error = nil;
    if (!credentials && !(credentials = [LoginController getCredentialsFromKeychain])) {
        [LoginController showLoginWindowWithCaptcha:NO];
        return;
    }
    
    ApiRequest *api = [[ApiRequest alloc] initWithAction:@"auth" params:credentials];
    [api performRequestWithBlock:^(NSDictionary *response, NSError *e) {
        if (e) _error = e;
        if (!e) {
            ((AppDelegate *)[[NSApplication sharedApplication] delegate]).account = [credentials valueForKey:@"login"];
            ((AppDelegate *)[[NSApplication sharedApplication] delegate]).token = [response valueForKey:@"token"];
            NSLog(@"New token obtained for %@: %@", [credentials valueForKey:@"login"],[response valueForKey:@"token"]);
            [SSKeychain setPassword:[credentials valueForKey:@"password"] forService:@"2safe" account:[credentials valueForKey:@"login"] error:&e];
            [[[NSApplication sharedApplication] windows][0] close]; // DIRTY SLUTTY CODE HERE, BEWARE!
            if (restart) {[((AppDelegate *)[[NSApplication sharedApplication] delegate]) start]; restart = false;}
        } else if ([e code] == 85){ //captcha requirement
            NSLog(@"Error: Captcha is required!\n[code:%ld description:%@]",[e code],[e localizedDescription]);
            [LoginController showLoginWindowWithCaptcha:YES];
        } else if ([e code] == 53){ //invalid captcha
            NSLog(@"Error: Captcha is invalid!\n[code:%ld description:%@]",[e code],[e localizedDescription]);
            [LoginController showLoginWindowWithCaptcha:YES];
        } else {
            NSLog(@"Error: incorrect username or password\n[code:%ld description:%@]",[e code],[e localizedDescription]);
            [LoginController showLoginWindowWithCaptcha:NO];
        }
    } synchronous:YES];
}

+ (NSDictionary *)getCredentialsFromKeychain {
    NSError *e = nil;
    
    NSArray *accounts = [SSKeychain accountsForService:@"2safe" error:&e];
    
    if ((accounts != nil)&&(e == nil)) {
        NSString *login = [[accounts lastObject] valueForKey:kSSKeychainAccountKey];
        NSString *password = [SSKeychain passwordForService:@"2safe" account:login error:&e];
        if (e) return nil;
        else NSLog(@"Obtaining login(%@) & password from keychain", login);
        return [[NSDictionary alloc] initWithObjectsAndKeys:login, @"login", password, @"password", nil];
    }
    NSLog(@"No logins in keychain");
    return nil;
}

+ (NSString *)getCpatchaIdFromResponseHeaders:(NSHTTPURLResponse *)h {
    NSString *cookieString = [[h allHeaderFields] valueForKey:@"Set-Cookie"];
    NSUInteger start = [cookieString rangeOfString:@"="].location + 1;
    NSUInteger end = [cookieString rangeOfString:@";"].location;
    return [cookieString substringWithRange:NSMakeRange(start, end-start)];
}

@end
