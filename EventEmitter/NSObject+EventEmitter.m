//
//  NSObject+EventEmitter.m
//  Sandbox
//
//  Created by Robin Goos on 4/10/13.
//  Copyright (c) 2013 Goos. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+EventEmitter.h"

static NSString * const kEventTableIdentifier = @"EmitterEvents";
static NSString * const kListenerIdentifier = @"CallerListeners";
static NSMutableSet *emitterSwizzledClasses = nil;

/**
 * Helper function - gets / instantiates an associated object for
 * a listener object
 */
NSMutableArray * lazyListenerArray(id target) {
    id targetArray = objc_getAssociatedObject(target, &kListenerIdentifier);
    if (![targetArray isKindOfClass:[NSMutableArray class]]) {
        NSMutableArray *arr = [NSMutableArray array];
        objc_setAssociatedObject(target, &kListenerIdentifier, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return objc_getAssociatedObject(target, &kListenerIdentifier);
}

/**
 * Helper function - Returns an array of listeners on the emitter
 * and caller alike, in order to dereference the listeners.
 */
NSArray * objectListeners(id object) {
    NSMutableArray *listeners = [NSMutableArray array];
    
    NSMutableArray *cListeners = objc_getAssociatedObject(object, &kListenerIdentifier);
    NSMutableDictionary *eventTable = objc_getAssociatedObject(object, &kEventTableIdentifier);
    
    if (eventTable) {
        for (NSString *key in eventTable) {
            for (Listener *listener in eventTable[key]) {
                [listeners addObject:listener];
            }
        }
    }
    [listeners addObjectsFromArray:cListeners];
    
    return listeners;
    
}

@interface NSObject (_EventEmitter)

/**
 * Event list getter & setter
 */
- (NSMutableDictionary *)emitterEvents;
- (void)setEmitterEvents:(NSMutableDictionary *)events;

- (Listener *)addEventListener:(NSString *)eventType callback:(Callback)callback action:(SEL)selector target:(id)target;

- (void)swizzleObjectClass:(id)object;


@end

#pragma mark -
#pragma mark Listener Object
@implementation Listener

- (id)initWithCallback:(Callback)cb eventType:(NSString *)type target:(id)target
{
    self = [super init];
    if (self) {
        self.eventType = type;
        self.caller = target;
        self.cb = cb;
    }
    
    return self;
}

- (id)initWithSelector:(SEL)sel eventType:(NSString *)type target:(id)target;
{
    self = [super init];
    if (self) {
        self.eventType = type;
        self.caller = target;
        self.selector = sel;
    }
    
    return self;
}

- (void)off
{
    NSMutableArray *callerListeners, *emitterListeners;
    if (self.caller) {
        callerListeners = objc_getAssociatedObject(self.caller, &kListenerIdentifier);
        [callerListeners removeObject:self];
    }
    if (self.emitter) {
        emitterListeners = objc_getAssociatedObject(self.emitter, &kEventTableIdentifier)[self.eventType];
        [emitterListeners removeObject:self];
    }
}

@end

#pragma mark -
#pragma mark Category Implementation
@implementation NSObject (EventEmitter)

#pragma mark -
#pragma mark Static variable instantiation

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        emitterSwizzledClasses = [NSMutableSet set];
    });
}

#pragma mark -
#pragma mark Getters & Setters
- (NSMutableDictionary *)emitterEvents
{
    return objc_getAssociatedObject(self, &kEventTableIdentifier);
}

- (void)setEmitterEvents:(NSMutableDictionary *)events
{
    objc_setAssociatedObject(self, &kEventTableIdentifier, events, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -
#pragma mark Event methods
- (void)emit:(NSString *)eventType, ...
{
    if (!self.emitterEvents) {
        self.emitterEvents = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableArray *objArgs = [NSMutableArray array];
    va_list args;
    
    id obj;
    
    va_start(args, eventType);
    while ((obj = va_arg(args, id)) != nil) {
        [objArgs addObject:obj];
    }
    va_end(args);
    
    id listeners = self.emitterEvents[eventType];
    
    if ([listeners isKindOfClass:[NSMutableArray class]]) {
        listeners = (NSMutableArray *)listeners;
        for (Listener *listener in listeners) {
            __weak typeof(self) this = self;
            if (listener.selector) {
                // Building the NSInvocation
                NSMethodSignature *sig = [listener.caller methodSignatureForSelector:listener.selector];
                NSAssert(sig != nil, @"Unknown selector %s sent to instance %@", sel_getName(listener.selector), listener.caller);
                NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
                [inv setTarget:listener.caller];
                [inv setSelector:listener.selector];
                id caller = self;
                if (sig.numberOfArguments > 2) {
                    [inv setArgument:&caller atIndex:2];
                }
                if (objArgs.count) {
                    for (int i = 3, argI = 0; i < sig.numberOfArguments && argI < objArgs.count; i++, argI++) {
                        id arg = objArgs[argI];
                        [inv setArgument:&arg atIndex:i];
                    }
                }
                [inv retainArguments];
                [inv invoke];
            } else if (listener.cb) {
                listener.cb(this, objArgs);
            }
        }
    }
}

- (Listener *)addEventListener:(NSString *)eventType callback:(Callback)callback action:(SEL)selector target:(id)target
{
    // Either a callback or action must be supplied, as well as target.
    if ((!callback && !selector) || !target) {
        return nil;
    }
    // Lazy initialization
    if (!self.emitterEvents) {
        self.emitterEvents = [[NSMutableDictionary alloc] init];
    }
    if (![self.emitterEvents[eventType] isKindOfClass:[NSArray class]]) {
        self.emitterEvents[eventType] = [NSMutableArray array];
    }
    
    NSMutableArray *listeners = self.emitterEvents[eventType];
    
    [self swizzleObjectClass:target];
    [self swizzleObjectClass:self];
    
    Listener *listener;
    if (callback) {
        listener = [[Listener alloc] initWithCallback:callback eventType:eventType target:target];
    } else {
        listener = [[Listener alloc] initWithSelector:selector eventType:eventType target:target];
    }
    listener.emitter = self;
    
    [listeners addObject:listener];
    
    NSMutableArray *arr = lazyListenerArray(target);
    [arr addObject:listener];
    
    return listener;
}

- (Listener *)on:(NSString *)eventType do:(Callback)callback target:(id)target
{
    return [self addEventListener:eventType callback:callback action:nil target:target];
}

- (Listener *)on:(NSString *)eventType call:(SEL)selector target:(id)target
{
    return [self addEventListener:eventType callback:nil action:selector target:target];
}

#pragma mark -
#pragma mark Method swizzling
- (void)swizzleObjectClass:(id)object
{
    if (!object)
        return;
    
    @synchronized (emitterSwizzledClasses) {
        Class cl = [object class];
        if ([emitterSwizzledClasses containsObject:cl])
            return;
        
        SEL ds = NSSelectorFromString(@"dealloc");
        Method dm = class_getInstanceMethod(cl, ds);
        IMP oi = method_getImplementation(dm),
            ni;
        
        // In order to stop xcode whining about casting block to pointer
        #if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0 || __MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_10_8
        ni = imp_implementationWithBlock(^(void *obj)
        #else
        ni = imp_implementationWithBlock((__bridge void *)^ (void *obj)
        #endif
        {
            @autoreleasepool {
                NSArray *listeners = objectListeners((__bridge id)obj);
                @synchronized(listeners) {
                    for (Listener *listener in listeners) {
                        [listener off];
                    }
                }
                ((void (*)(void *, SEL))oi)(obj, ds);
            }
        });
                                         
        class_replaceMethod(cl, ds, ni, method_getTypeEncoding(dm));
                                         
        [emitterSwizzledClasses addObject:cl];
    }
}


@end