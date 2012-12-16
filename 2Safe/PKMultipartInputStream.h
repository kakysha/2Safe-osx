//
//  PKMultipartInputStream.h
//  2Safe
//
//  Created by Drunk on 09.12.12.
//  Copyright (c) 2012 zaopark. All rights reserved.
//

@interface PKMultipartInputStream : NSInputStream
{
    @private
    NSMutableArray *parts;
    NSString       *boundary;
    NSData         *footer;
    NSUInteger     footerLength, currentPart, length, delivered, status;
}
- (void)addPartWithName:(NSString *)name string:(NSString *)string;
- (void)addPartWithName:(NSString *)name data:(NSData *)data;
- (void)addPartWithName:(NSString *)name path:(NSString *)path;
- (NSString *)boundary;
- (NSUInteger)length;
@end
