//
//  OSAppDelegate.m
//  OneScreen
//
//  Created by Xiaoxue Han on 9/25/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSAppDelegate.h"
#import "OSServerManager.h"
#import <Crashlytics/Crashlytics.h>

@implementation OSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [TestFlight takeOff:@"dfba855e-fe1a-4a76-97bc-ef5306809bb3"];
    
    // crashlytics
    [Crashlytics startWithAPIKey:@"02eaa877844435ac8f0e7707e5087c6a937afdd5"];
    
    NSString *storyboardName = @"Main_iPhone";
    if ([[UIScreen mainScreen] bounds].size.height == 480 || [[UIScreen mainScreen] bounds].size.width == 480) {
        storyboardName = @"Main_iPhone3.5";
    }
    
    //[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
#if 1
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    UITabBarController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"rootNav"];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
#else
    // test Reset Password view
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[KNStoryboardManager getMainStoryboardName] bundle:nil];
    UIViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"passwordResetNavController"];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
#endif

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    //Customize Of Navigation Controller for All page
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"NavigationBar_BgImage"] forBarMetrics:UIBarMetricsDefault];
    
    // navigation bar text color
    [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                            NSForegroundColorAttributeName: [UIColor colorWithRed:248/255.0 green:248/255.0 blue:248/255.0 alpha:1.0],
                                                            NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f]
                                                            }];
    
    // orientation is portrate first
    self.allowRotateToLandscape = NO;
    
    return YES;
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
    
    [[OSServerManager sharedInstance] logout];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[OSServerManager sharedInstance] loginWithUserName:kGlobalUserName password:kGlobalUserPass];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - orientation
- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if (self.allowRotateToLandscape)
        return UIInterfaceOrientationMaskLandscape;
    else
        return UIInterfaceOrientationMaskPortrait;
}

@end
