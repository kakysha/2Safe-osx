//
//  LoginController.m
//  2Safe
//
//  Created by Drunk on 10.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "LoginController.h"
#import "ApiRequest.h"

@implementation LoginController

NSString *_token;
NSDictionary *credentials = nil;
void (^_completionHandler)(NSString *res);
BOOL isCaptchaNeeded = NO;
NSString *captchaId;

@synthesize window;
@synthesize captchaView;
@synthesize login;
@synthesize password;
@synthesize captchaImage;
@synthesize captchaText;

- (IBAction)enter:(id)sender {
    credentials = [[NSDictionary alloc] initWithObjectsAndKeys:[login stringValue], @"login", [password stringValue], @"password", [captchaText stringValue], @"captcha", captchaId, @"captcha_id", nil];
    [[self window] close];
    [LoginController auth];
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
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
}

+ (void)showLoginWindowWithCaptcha:(BOOL)wc{
    isCaptchaNeeded = wc;
    NSLog(@"Asking user for login/password");
    [[[NSApplication sharedApplication] windows][0] makeKeyAndOrderFront:nil]; // DIRTY SLUTTY CODE HERE, BEWARE!
}

+ (NSString *)token{
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"token"]; //purge old token
    if (_token != nil) {
        NSLog(@"Getting token from Static Variable");
        return _token;
    }

    _token = [[NSUserDefaults standardUserDefaults] valueForKey:@"token"];
    if (_token == nil) {
        [LoginController auth];
    } else NSLog(@"Getting token from UserDefaults");
    return _token;
}

+ (void)requestTokenWithBlock:(void(^)(NSString *))responseBlock {
    _completionHandler = responseBlock;
}

+ (void)auth{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"token"]; //purge old token
    
    if (!credentials && !(credentials = [LoginController getCredentialsFromKeychain])) {
        [LoginController showLoginWindowWithCaptcha:NO];
        return;
    }
    
    ApiRequest *api = [[ApiRequest alloc] initWithAction:@"auth" params:credentials];
    [api performRequestWithBlock:^(NSDictionary *response, NSError *e) {
        if (!e) {
            [[NSUserDefaults standardUserDefaults] setObject:[response valueForKey:@"token"] forKey:@"token"];
            
            NSLog(@"New token obtained for %@: %@", [credentials valueForKey:@"login"],[response valueForKey:@"token"]);
            
            //call the callback
            _completionHandler([response valueForKey:@"token"]);
            _completionHandler = nil;

            if ([SSKeychain setPassword:[credentials valueForKey:@"password"] forService:@"2safe" account:[credentials valueForKey:@"login"] error:&e]) NSLog(@"Password for %@ is stored in keychain", [credentials valueForKey:@"login"]);
            else NSLog(@"Can't store the password in keychain, error:%@", [e localizedDescription]);
            
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
    }];
}

+ (NSDictionary *)getCredentialsFromKeychain {
    NSError *e = nil;
    
    NSArray *accounts = [SSKeychain accountsForService:@"2safe" error:&e];
    
    if ((accounts != nil)&&(e == nil)) {
        NSString *login = [[accounts lastObject] valueForKey:kSSKeychainAccountKey];
        NSString *password = [SSKeychain passwordForService:@"2safe" account:login error:&e];
        if (e) return nil;
        else NSLog(@"Obtaining login(%@) & password(%@) from keychain", login, password);
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
