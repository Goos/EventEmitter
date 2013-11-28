//
//  SomeObjectWithActions.m
//  EventEmitter
//
//  Created by Robin Goos on 28/11/13.
//  Copyright (c) 2013 Goos. All rights reserved.
//

#import "SomeObjectWithEvents.h"
#import "NSObject+EventEmitter.h"

@implementation SomeObjectWithEvents

- (void)start
{
    int r = arc4random_uniform(2);
    if (r) {
        [self emit:kSomeObjectDoneEvent, nil];
    } else {
        NSError *err = [NSError errorWithDomain:@"com.eventemitter.randomerror" code:4 userInfo:@{NSLocalizedDescriptionKey: @"Random error."}];
        [self emit:kSomeObjectErrorEvent, err, nil];
    }
}

@end
