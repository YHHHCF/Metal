/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of our iOS application delegate
*/

#import "AAPLAppDelegate.h"

@implementation AAPLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // this only runs in iOS devices
    NSLog(@"debug didFinishLaunchingWithOptions\n");
    return YES;
}

@end
