//
//  HTTPApi.m
//  2Safe
//
//  Created by Drunk on 09.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "ApiRequest.h"
#import "LoginController.h"
#import "PKMultipartInputStream.h"
#import "FSElement.h"

typedef enum { TextRequest, DataRequest, StreamRequest } REQUESTTYPE;

@implementation ApiRequest {
    NSMutableData *receivedData;
    NSOutputStream *outputStream;
    void (^responseBlock)(NSDictionary*, NSError *);
    void (^responseDataBlock)(NSData*, NSHTTPURLResponse*, NSError *);
    BOOL isWaiting;
    REQUESTTYPE requestType;
    BOOL isMultipart;
    NSMutableData *POSTBody;
    NSUInteger contentLength;
    PKMultipartInputStream *uploadFileStream;
    BOOL sync;
}

NSString *POSTBoundary = @"0xKhTmLbOuNdArY";
NSString *url = @"https://api.2safe.com/";
NSString *_token;

- (id)initWithAction:(NSString *)action params:(NSDictionary *)params {
    if (self = [super init]) {
        uploadFileStream = [[PKMultipartInputStream alloc] init];
        POSTBody = [NSMutableData data];
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
        if (!(_token = [LoginController token])) {
            [LoginController requestTokenWithBlock:^(NSString *res){
                _token = res;
                if (isWaiting) {
                    if (responseBlock) [self performRequestWithBlock:responseBlock];
                    else [self performDataRequestWithBlock:responseDataBlock];
                    isWaiting = NO;
                }
            }];
        }
        return self;
    } else {
        return nil;
    }
}

//common methods section
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
        
        if ([urlWithQuerystring rangeOfString:@"="].location == NSNotFound) {
            [urlWithQuerystring appendFormat:@"%@=%@", [ApiRequest urlEscapeString:keyString], [ApiRequest urlEscapeString:valueString]];
        } else {
            [urlWithQuerystring appendFormat:@"&%@=%@", [ApiRequest urlEscapeString:keyString], [ApiRequest urlEscapeString:valueString]];
        }
    }
    return urlWithQuerystring;
}

- (void)checkRequestParams {
    self.error = nil;
    if ((self.action == nil) || (self.requestparams == nil)) {
        self.error = [NSError errorWithDomain:@"2safe" code:01 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"action -or- params not presented", NSLocalizedDescriptionKey, nil]];
    }
    for (id key in self.requestparams) {
        if (![[self.requestparams objectForKey:key] isKindOfClass:[NSString class]]) {
            isMultipart = YES;
            break;
        }
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
    NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [theRequest setHTTPMethod:@"POST"];
    if (isMultipart)
        [theRequest addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", POSTBoundary] forHTTPHeaderField:@"Content-Type"];
    else
        [theRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [theRequest setHTTPBody:POSTBody];
    if (isMultipart) [theRequest setHTTPBodyStream:uploadFileStream];
    NSURLConnection *theConnection;
    if (!sync) {
        theConnection =[[NSURLConnection alloc] initWithRequest:theRequest delegate:self startImmediately:NO];
        [theConnection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [theConnection start];
        if (!theConnection)
            self.error = [NSError errorWithDomain:@"2safe" code:02 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Can't create connection to %@", url], NSLocalizedDescriptionKey, nil]];
        else
            NSLog(@"Start: %@ (%@)", self.action, [[self.requestparams valueForKey:@"file"] name]);
    } else {
        NSURLResponse *resp;
        NSError *er;
        NSLog(@"Synchronous request \"%@\" started", self.action);
        NSData *syncData = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&resp error:&er];
        [self connection:nil didReceiveResponse:(NSHTTPURLResponse *)resp];
        if (er) [self connection:nil didFailWithError:er];
        else {
            [self connection:nil didReceiveData:syncData];
            [self connectionDidFinishLoading:nil];
        }
    }
}

// POST BODY generators
- (void)prepareRequestBody {
    NSMutableString *b = [NSMutableString string];
    [b appendFormat:@"cmd=%@", self.action];
    b = [ApiRequest addQueryStringToUrlString:b withDictionary:self.requestparams];
    if (self.withToken) [b appendFormat:@"&token=%@", _token];
    POSTBody = [NSMutableData dataWithData:[b dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)prepareMultipartRequestBody {
    [self addMultipartParamToPOSTBody:@"cmd" value:self.action];
    for (id key in self.requestparams) {
        [self addMultipartParamToPOSTBody:key value:[self.requestparams objectForKey:key]];
    }
    if (self.withToken) [self addMultipartParamToPOSTBody:@"token" value:_token];
}

- (void)addMultipartParamToPOSTBody:(NSString *)name value:(id)value {
    if ([value isKindOfClass:[NSString class]])
        [uploadFileStream addPartWithName:name string:value];
    if ([value isKindOfClass:[NSData class]])
        [uploadFileStream addPartWithName:name data:value];
    if ([value isKindOfClass:[FSElement class]])
        [uploadFileStream addPartWithName:name path:[value filePath]];
}

// public methods
- (void)performRequestWithBlock:(void (^)(NSDictionary *, NSError *))block synchronous:(BOOL)synced{
    sync = synced;
    requestType = TextRequest;
    [self checkRequestParams];
    if (self.error) {
        block(nil, self.error);
        return;
    }
    responseBlock = block;
    if ([self isNeedWaitingForToken]) return;
    isMultipart ? [self prepareMultipartRequestBody] : [self prepareRequestBody];
    [self sendRequest];
}

- (void)performDataRequestWithBlock:(void (^)(NSData *, NSHTTPURLResponse*, NSError *))block synchronous:(BOOL)synced {
    sync = synced;
    requestType = DataRequest;
    [self checkRequestParams];
    if (self.error) {
        block(nil, nil, self.error);
        return;
    }
    responseDataBlock = block;
    if ([self isNeedWaitingForToken]) return;
    isMultipart ? [self prepareMultipartRequestBody] : [self prepareRequestBody];
    [self sendRequest];
}

- (void)performStreamRequest:(NSOutputStream *)stream withBlock:(void (^)(NSData *, NSHTTPURLResponse *, NSError *))block synchronous:(BOOL)synced {
    sync = synced;
    outputStream = stream;
    requestType = StreamRequest;
    [self checkRequestParams];
    if (self.error) {
        block(nil, nil, self.error);
        return;
    }
    responseDataBlock = block;
    if ([self isNeedWaitingForToken]) return;
    isMultipart ? [self prepareMultipartRequestBody] : [self prepareRequestBody];
    [self sendRequest];
}
- (void)performRequestWithBlock:(void (^)(NSDictionary *, NSError *))block {
    [self performRequestWithBlock:block synchronous:NO];
}
- (void)performDataRequestWithBlock:(void (^)(NSData *, NSHTTPURLResponse *, NSError *))block {
    [self performDataRequestWithBlock:block synchronous:NO];
}
- (void)performStreamRequest:(NSOutputStream *)stream withBlock:(void (^)(NSData *, NSHTTPURLResponse *, NSError *))block {
    [self performStreamRequest:stream withBlock:block synchronous:NO];
}

// events handling section
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    [receivedData setLength:0];
    if ([response statusCode] == 200) {
        if (outputStream) [outputStream open];
    } else {
        NSLog(@"%li", response.statusCode);
        outputStream = nil; //set to null to prevent writing error information to file
    }
    self.responseHeaders = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    switch (requestType) {
        case TextRequest:
        case DataRequest:
            [receivedData appendData:data];
            break;
        case StreamRequest: {
            if (outputStream) {
                NSUInteger left = [data length];
                NSUInteger nwr = 0;
                do {
                    nwr = [outputStream write:[data bytes] maxLength:left];
                    if (-1 == nwr) break;
                    left -= nwr;
                } while (left > 0);
                if (left) {
                    self.error = [outputStream streamError];
                    responseDataBlock(nil, nil, self.error);
                }
            } else {
                [receivedData appendData:data]; //error (statusCode != 200), write it to data
            }
        }
            break;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // inform the user
    self.error = error;
    switch (requestType) {
        case TextRequest:
            responseBlock(nil, self.error);
            break;
        case DataRequest:
        case StreamRequest:
            if (outputStream) [outputStream close];
            responseDataBlock(nil,nil, self.error);
            break;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //check for error
    NSDictionary *r = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableLeaves error:nil];
    if ([r valueForKey:@"error_code"]) {
        self.error = [NSError errorWithDomain:@"2safe" code:[[r valueForKey:@"error_code"] intValue] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[r valueForKey:@"error_msg"], NSLocalizedDescriptionKey, nil]];
        
        //if authentication error - try to reauthenticate and resend the request
        if (([self.error code] == 1)|| //not authorized
            ([self.error code] == 15)) { //incorrect token
            NSLog(@"Incorrect token, reauth. (error: %li)", [self.error code]);
            [LoginController requestTokenWithBlock:^(NSString *res){
                _token = res;
                if (responseBlock) [self performRequestWithBlock:responseBlock];
                else [self performDataRequestWithBlock:responseDataBlock];
            }];
        } else {
            if (requestType == TextRequest) responseBlock(nil, self.error);
            else responseDataBlock(nil, nil, self.error);
        }
        return;
    }
    //ok - return the result
    NSLog(@"Finish: %@ (%@)", self.action, [[self.requestparams valueForKey:@"file"] name]);
    switch (requestType) {
        case TextRequest: {
                responseBlock([r valueForKey:@"response"], nil); // API always returns the response in "response" key
        }
            break;
        case DataRequest:
        case StreamRequest:
            if (outputStream) [outputStream close];
            responseDataBlock(receivedData, self.responseHeaders, nil);
            break;
    }
}

@end
