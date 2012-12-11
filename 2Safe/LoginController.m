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

static NSString *_token;
static NSDictionary *credentials = nil;
void (^_completionHandler)(NSString *res);

@synthesize window;
@synthesize login;
@synthesize password;

- (IBAction)enter:(id)sender {
    credentials = [[NSDictionary alloc] initWithObjectsAndKeys:[login stringValue], @"login", [password stringValue], @"password", nil];
    [[self window] close];
    [LoginController auth];
}

+ (void)showLoginWindow {
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
        [LoginController showLoginWindow];
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
        } else {
            NSLog(@"Error: incorrect username or password\n[code:%ld description:%@]",[e code],[e localizedDescription]);
            [LoginController showLoginWindow];
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

@end
