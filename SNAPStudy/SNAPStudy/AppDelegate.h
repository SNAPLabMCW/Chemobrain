//
//  AppDelegate.h
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/2/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DropboxHandling.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) NSString* version;
@property (nonatomic) NSString* xmlExperimentDataLocation;
@property (nonatomic) NSString* participantID;
@property (nonatomic) NSInteger lastRun;
@property (nonatomic) NSInteger startupCount;
@property (nonatomic,strong) DropboxHandling* dropBoxHandling;

@property (nonatomic) BOOL firstOneOfTheDay;
- (void)setXMLDataLocation:(NSString*)xmlDataLocation;
-(void)recordRunCompleted:(NSInteger)runNumber;


@end
