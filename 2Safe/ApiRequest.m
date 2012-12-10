//
//  HTTPApi.m
//  2Safe
//
//  Created by Drunk on 09.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import "ApiRequest.h"

@implementation ApiRequest

NSMutableData *receivedData;
NSMutableString *url;
void (^responseBlock)(NSDictionary*, NSError *);

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

- (void)performRequestWithBlock:(void (^)(NSDictionary *, NSError *))block {
    if ((self.action == nil) || (self.requestparams == nil)) {
        self.error = [NSError errorWithDomain:@"2safe" code:01 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"action -or- params not presented", NSLocalizedDescriptionKey, nil]];
        block(nil, self.error);
    }
    //save the callback as block
    responseBlock = block;
    //create the request url
    [url appendString:self.action];
    url = [ApiRequest addQueryStringToUrlString:url withDictionary:self.requestparams];
    // Create the request.
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    // create the connection with the request
    // and start loading the data
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!theConnection){
        self.error = [NSError errorWithDomain:@"2safe" code:02 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Can't create connection to %@", url], NSLocalizedDescriptionKey, nil]];
        block(nil, self.error);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // inform the user
    self.error = [NSError errorWithDomain:@"2safe" code:02 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Failed to connect to %@", url], NSLocalizedDescriptionKey, nil]];
    responseBlock(nil, self.error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // do something with the data
    // receivedData is declared as a method instance elsewhere
    NSDictionary *r = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableLeaves error:nil];
    if ([r valueForKey:@"error_code"]) {
        self.error = [NSError errorWithDomain:@"2safe" code:[[r valueForKey:@"error_code"] intValue] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[r valueForKey:@"error_msg"], NSLocalizedDescriptionKey, nil]];
        responseBlock(nil, self.error);
    } else
    responseBlock([r valueForKey:@"response"], nil); // API always returns the response in "response" key
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
