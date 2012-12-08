//
//  HTTPApi.h
//  2Safe
//
//  Created by Drunk on 09.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTTPApi : NSObject
{
    NSMutableData *receivedData;
}

- (void)testApi;

@end
