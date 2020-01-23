//
//  AppDelegate.m
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/2/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import "AppDelegate.h"
#import "DropboxSDK/DropboxSDK.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    self.version = @"0.23";

    NSString* dataSourceURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"dataSourceURL"];
    
    if (dataSourceURL == nil || [dataSourceURL isEqualToString:@""]) {
        self.xmlExperimentDataLocation = @"http://pakl.net/p001.txt";
    } else {
        self.xmlExperimentDataLocation = dataSourceURL;
    }
    self.dropBoxHandling = [[DropboxHandling alloc] init];
    
    NSString* lastRunNumber = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastRunCompletedNumber"];
    if (lastRunNumber == nil || [lastRunNumber isEqualToString:@""])
    {
        self.lastRun = 0;
    } else {
        self.lastRun = [lastRunNumber intValue];
    }
    
    NSDate* today = [NSDate date];
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YYYYMMdd"];
    NSString* todayAsString = [dateFormat stringFromDate:today];
    NSString* lastRunDate = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastRunCompletedDate"];
    if (lastRunDate == nil || [lastRunDate isEqualToString:@""]) {
        self.firstOneOfTheDay = YES;
    } else {
        if ([lastRunDate isEqualToString:todayAsString])
        {
            self.firstOneOfTheDay = NO;
        } else {
            self.firstOneOfTheDay = YES;
        }
    }
    
    self.startupCount = [[[NSUserDefaults standardUserDefaults] stringForKey:@"startupCount"] integerValue];
    if (self.startupCount == 0) {
        self.startupCount = 1;
    } else {
        self.startupCount = self.startupCount + 1;
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld", (long)self.startupCount] forKey:@"startupCount"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    DBSession *dbSession = [[DBSession alloc]
                            initWithAppKey:@"plqhx6l8vbbmc15"
                            appSecret:@"hli5oj1cj6rkmy3"
                            root:kDBRootAppFolder]; // either kDBRootAppFolder or kDBRootDropbox
    [DBSession setSharedSession:dbSession];
    //[[DBAccountManager alloc] initWithAppKey:@"plqhx6l8vbbmc15" secret:@"hli5oj1cj6rkmy3"]; // ADAM
    // My keys for testing:
    //[[DBAccountManager alloc] initWithAppKey:@"ndnl5r1o7lywsjy" secret:@"rcat7xoya3nt25t"]; // PAKL

    
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
  sourceApplication:(NSString *)source annotation:(id)annotation {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}


//- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
//  sourceApplication:(NSString *)source annotation:(id)annotation {
//    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
//    if (account) {
//        NSLog(@"App linked successfully!");
//        return YES;
//    }
//    return NO;
//}

- (void)setXMLDataLocation:(NSString*)xmlDataLocation
{
    [[NSUserDefaults standardUserDefaults] setObject:xmlDataLocation forKey:@"dataSourceURL"];
    self.xmlExperimentDataLocation = xmlDataLocation;
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)recordRunCompleted:(NSInteger)runNumber
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld", (long)runNumber] forKey:@"lastRunCompletedNumber"];
    
    NSDate* today = [NSDate date];
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YYYYMMdd"];
    NSString* todayAsString = [dateFormat stringFromDate:today];
    [[NSUserDefaults standardUserDefaults] setObject:todayAsString forKey:@"lastRunCompletedDate"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString*)participantID
{
    if (!_participantID) {
        _participantID = [[NSUserDefaults standardUserDefaults] stringForKey:@"participantID"];
        if (!_participantID) {
            _participantID = @"unassigned";
        }
    }
    return _participantID;
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
