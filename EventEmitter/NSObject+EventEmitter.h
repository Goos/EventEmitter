//
//  NSObject+EventEmitter.h
//  Sandbox
//
//  Created by Robin Goos on 4/10/13.
//  Copyright (c) 2013 Goos. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^Callback)(__weak id slf, NSArray *args);

@interface Listener : NSObject

@property (nonatomic) SEL selector;
@property (nonatomic, copy) Callback cb;
@property (nonatomic, strong) NSString *eventType;
@property (nonatomic, weak) id caller;
@property (nonatomic, weak) id emitter;

- (id)initWithCallback:(Callback)cb eventType:(NSString *)type target:(id)target;

/**
 * off:
 * @POST:
    Stops the listener from continuing to listen to events.
 */
- (void)off;

@end

@interface NSObject (EventEmitter)

/*! Sends out an event that other objects can listen to with on:do:target:.
 * Expects the variable arguments to be (non-primitive) foundation objects.
 * Expects the vaList to be terminated with nil.
 * @param eventType   The event type identifier (e.g: "error")
 * @param ...         An optional amount of parameters to be passed with the event (must be terminated with nil).
*/
- (void)emit:(NSString *)eventType, ...;

/*! Adds a listener to the NSObject, calling the block every time the receiver calls emit:.
 * The listener is removed either if the listener or the receiver gets deallocated.
 * @param eventType   The event-identifier which determines what event to listen to.
 * @param callback    The block to be called when the event is emitted. See block definition above.
 * @param target      The observer-object that should be the other part of maintaining the responsibility of listening.
 *
 * @return    An instance of a Listener, in order to stop listening (by calling [listener off];).
*/
- (Listener *)on:(NSString *)eventType do:(Callback)callback target:(id)target;

/// Same as on:do:with, except that a selector is supplied instead of a callback-block.
- (Listener *)on:(NSString *)eventType call:(SEL)selector target:(id)target;

@end

