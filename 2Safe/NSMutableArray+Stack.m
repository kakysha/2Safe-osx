//
//  NSMutableArray+Stack.m
//  2Safe
//
//  Created by Dan on 1/15/13.
//  Copyright (c) 2013 zaopark. All rights reserved.
//

#import "NSMutableArray+Stack.h"

@implementation NSMutableArray (Stack)

- (id)pop
{
    id lastObject = [self lastObject];
    if (lastObject)
        [self removeLastObject];
    return lastObject;
}

- (void)push:(id)obj
{
    [self addObject: obj];
}

@end
