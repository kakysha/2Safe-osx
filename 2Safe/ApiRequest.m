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
#import "NSFile.h"

@implementation ApiRequest {
    NSMutableData *receivedData;
    void (^responseBlock)(NSDictionary*, NSError *);
    void (^responseDataBlock)(NSData*, NSHTTPURLResponse*, NSError *);
    BOOL isWaiting;
    BOOL isDataRequest;
    BOOL isMultipart;
    NSMutableData *POSTBody;
    NSUInteger contentLength;
    PKMultipartInputStream *uploadFileStream;
}

NSString *POSTBoundary = @"0xKhTmLbOuNdArY";
NSString *url = @"https://api.2safe.com/";
static NSString *_token;

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
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!theConnection){
        self.error = [NSError errorWithDomain:@"2safe" code:02 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Can't create connection to %@", url], NSLocalizedDescriptionKey, nil]];
    }
}

// simple POST request section
- (void)prepareRequestBody {
    NSMutableString *b = [NSMutableString string];
    [b appendFormat:@"cmd=%@", self.action];
    b = [ApiRequest addQueryStringToUrlString:b withDictionary:self.requestparams];
    if (self.withToken) [b appendFormat:@"&token=%@", _token];
    POSTBody = [NSMutableData dataWithData:[b dataUsingEncoding:NSUTF8StringEncoding]];
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
    [self prepareRequestBody];
    
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
    [self prepareRequestBody];
    
    // send the request
    [self sendRequest];
    if (self.error) {
        block(nil, nil, self.error);
    }
}

// multipart POST request section
- (void)addMultipartParamToPOSTBody:(NSString *)name value:(id)value {
    if ([value isKindOfClass:[NSString class]])
        [uploadFileStream addPartWithName:name string:value];
    if ([value isKindOfClass:[NSData class]])
        [uploadFileStream addPartWithName:name data:value];
    if ([value isKindOfClass:[NSFile class]])
        [uploadFileStream addPartWithName:name path:[value filePath]];
}

- (void)prepareMultipartRequestBody {
    [self addMultipartParamToPOSTBody:@"cmd" value:self.action];
    for (id key in self.requestparams) {
            [self addMultipartParamToPOSTBody:key value:[self.requestparams objectForKey:key]];
    }
    if (self.withToken) [self addMultipartParamToPOSTBody:@"token" value:_token];
}

- (void) perfomFileUpload:(void (^)(NSDictionary *, NSError *))block{
    isMultipart = YES;
    
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
    [self prepareMultipartRequestBody];
    
    //send
    [self sendRequest];
    if (self.error) {
        block(nil, self.error);
    }
}


// events handling section
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    [receivedData setLength:0];
    self.responseHeaders = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // inform the user
    self.error = error;
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

@end
