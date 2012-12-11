//
//  HTTPApi.m
//  2Safe
//
//  Created by Drunk on 09.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "ApiRequest.h"
#import "LoginController.h"

@implementation ApiRequest {
    NSMutableData *receivedData;
    NSMutableString *url;
    void (^responseBlock)(NSDictionary*, NSError *);
    void (^responseDataBlock)(NSData*, NSHTTPURLResponse*, NSError *);
    BOOL isWaiting;
    BOOL isDataRequest;
}

static NSString *_token;

- (id)initWithAction:(NSString *)action params:(NSDictionary *)params {
    if (self = [super init]) {
        url = [NSMutableString stringWithString:@"https://api.2safe.com/?cmd="];
        _action = action;
        _requestparams = params;
        receivedData = [NSMutableData data];
        return self;
    } else {
        return nil;
    }
}
- (id)initWithAction:(NSString *)action params:(NSDictionary *)params withToken:(BOOL)withToken {
    if (self = [self initWithAction:action params:params]) {
        _withToken = withToken;
        if (![LoginController token]) {
            [LoginController requestTokenWithBlock:^(NSString *res){
                _token = res;
                if (isWaiting) {
                    [self performRequestWithBlock:responseBlock];
                    isWaiting = NO;
                }
            }];
        } else {
            _token = [LoginController token];
        }
        return self;
    } else {
        return nil;
    }
}

- (void)checkRequestParams {
    self.error = nil;
    if ((self.action == nil) || (self.requestparams == nil)) {
        self.error = [NSError errorWithDomain:@"2safe" code:01 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"action -or- params not presented", NSLocalizedDescriptionKey, nil]];
    }
}

- (void)prepareRequestUrl{
    [url appendString:self.action];
    url = [ApiRequest addQueryStringToUrlString:url withDictionary:self.requestparams];
    if (self.withToken) {
        url = [ApiRequest addQueryStringToUrlString:url withDictionary:[[NSDictionary alloc] initWithObjectsAndKeys:_token,@"token", nil]];
    }
}

- (BOOL)isNeedWaitingForToken{
    if ((self.withToken)&&(!_token)) {
        //return and wait for block execution;
        isWaiting = YES;
        return YES;
    }
    return NO;
}

- (void)sendRequest {
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!theConnection){
        self.error = [NSError errorWithDomain:@"2safe" code:02 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Can't create connection to %@", url], NSLocalizedDescriptionKey, nil]];
    }
}

- (void)performRequestWithBlock:(void (^)(NSDictionary *, NSError *))block {
    [self checkRequestParams];
    if (self.error) {
        block(nil, self.error);
        return;
    }
    //save the callback as block
    responseBlock = block;
    
    //check for token awaiting
    if ([self isNeedWaitingForToken]) return;
    
    //create the request url
    [self prepareRequestUrl];

    //send
    [self sendRequest];
    if (self.error) {
        block(nil, self.error);
    }
}

- (void)performDataRequestWithBlock:(void (^)(NSData *, NSHTTPURLResponse*, NSError *))block {
    isDataRequest = YES;
    [self checkRequestParams];
    if (self.error) {
        block(nil, nil, self.error);
        return;
    }
    //save the callback as block
    responseDataBlock = block;
    
    //check for token awaiting
    if ([self isNeedWaitingForToken]) return;
    
    //create the request url
    [self prepareRequestUrl];
    
    // send the request
    [self sendRequest];
    if (self.error) {
        block(nil, nil, self.error);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    [receivedData setLength:0];
    self.responseHeaders = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // inform the user
    self.error = [NSError errorWithDomain:@"2safe" code:02 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Failed to connect to %@", url], NSLocalizedDescriptionKey, nil]];
    isDataRequest ? responseDataBlock(nil,nil, self.error) : responseBlock(nil, self.error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (isDataRequest){
        responseDataBlock(receivedData, self.responseHeaders, nil);
    }
    else {
        NSDictionary *r = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableLeaves error:nil];
        if ([r valueForKey:@"error_code"]) {
            self.error = [NSError errorWithDomain:@"2safe" code:[[r valueForKey:@"error_code"] intValue] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[r valueForKey:@"error_msg"], NSLocalizedDescriptionKey, nil]];
            responseBlock(nil, self.error);
        } else
            responseBlock([r valueForKey:@"response"], nil); // API always returns the response in "response" key
    }
}

+(NSString*)urlEscapeString:(NSString *)unencodedString
{
    CFStringRef originalStringRef = (__bridge_retained CFStringRef)unencodedString;
    NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,originalStringRef, NULL, NULL,kCFStringEncodingUTF8);
    CFRelease(originalStringRef);
    return s;
}


+(NSMutableString*)addQueryStringToUrlString:(NSString *)urlString withDictionary:(NSDictionary *)dictionary
{
    NSMutableString *urlWithQuerystring = [[NSMutableString alloc] initWithString:urlString];
    
    for (id key in dictionary) {
        NSString *keyString = [key description];
        NSString *valueString = [[dictionary objectForKey:key] description];
        
        if ([urlWithQuerystring rangeOfString:@"?"].location == NSNotFound) {
            [urlWithQuerystring appendFormat:@"?%@=%@", [ApiRequest urlEscapeString:keyString], [ApiRequest urlEscapeString:valueString]];
        } else {
            [urlWithQuerystring appendFormat:@"&%@=%@", [ApiRequest urlEscapeString:keyString], [ApiRequest urlEscapeString:valueString]];
        }
    }
    return urlWithQuerystring;
}

@end
