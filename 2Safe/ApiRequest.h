//
//  HTTPApi.h
//  2Safe
//
//  Created by Drunk on 09.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApiRequest : NSObject

//request
@property NSString *action;
@property NSDictionary *requestparams;
//response
@property NSString *rawresponse;
@property NSDictionary *response;
@property NSError *error;

- (id)initWithAction:(NSString *)action params:(NSDictionary *)params;
- (void) performRequestWithBlock:(void (^)(NSDictionary *r, NSError *e))block;

@end
