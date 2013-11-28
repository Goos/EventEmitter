//
//  SomeObjectWithActions.h
//  EventEmitter
//
//  Created by Robin Goos on 28/11/13.
//  Copyright (c) 2013 Goos. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *kSomeObjectDoneEvent = @"done";
static NSString *kSomeObjectErrorEvent = @"error";

@interface SomeObjectWithEvents : NSObject

- (void)start;

@end
