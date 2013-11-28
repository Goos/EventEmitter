//
//  AppDelegate.m
//  EventEmitter
//
//  Created by Robin Goos on 28/11/13.
//  Copyright (c) 2013 Goos. All rights reserved.
//

#import "AppDelegate.h"
#import "SomeObjectWithEvents.h"
#import "NSObject+EventEmitter.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    SomeObjectWithEvents *obj = [SomeObjectWithEvents new];
    
    // Adding eventlisteners with selectors. Will always attempt to set the
    // emitter as the first argument, and then any further arguments
    // in the order they are provided.
    [obj on:kSomeObjectDoneEvent call:@selector(someObjectReceivedDoneEvent:) target:self];
    [obj on:kSomeObjectErrorEvent call:@selector(someObject:receivedError:) target:self];
    
    // Adding eventlisteners with blocks. Sends the emitter as the first argument,
    // and the rest of the arguments as an array, in the order provided.
    [obj on:kSomeObjectDoneEvent do:^(SomeObjectWithEvents *obj, NSArray *args) {
        NSLog(@"Done-event block listener fired!");
    } target:self];
    
    [obj on:kSomeObjectErrorEvent do:^(SomeObjectWithEvents *obj, NSArray *args) {
        NSLog(@"Error-event block listener fired with error: %@", args[0]);
    } target:self];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (int i = 0; i < 10; i++) {
            sleep(2);
            [obj start];
        }
    });
    
    return YES;
}

- (void)someObjectReceivedDoneEvent:(SomeObjectWithEvents *)obj
{
    NSLog(@"Done-event selector listener fired!");
}

- (void)someObject:(SomeObjectWithEvents *)obj receivedError:(NSError *)err
{
    NSLog(@"Error-event selector listener fired with error: %@", err);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
