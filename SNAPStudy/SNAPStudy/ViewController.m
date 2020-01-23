//
//  ViewController.m
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/2/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "ExperimentXMLLoader.h"
#import "NSTimer+Blocks.h"
#import "DropboxHandling.h"
#import "DropboxSDK/DropboxSDK.h"

@interface ViewController ()
@property (nonatomic) BOOL upgradeAlertVisible;
@property (nonatomic) AppDelegate* app;
@property (weak, nonatomic) IBOutlet UIButton *setupButton;
@property (weak, nonatomic) IBOutlet UILabel *nextRunLabel;
@property (strong) NSString* tappedCode;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.app = (AppDelegate*) [[UIApplication sharedApplication] delegate];
	// Do any additional setup after loading the view, typically from a nib.
    self.tappedCode = @"";
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    NSString *hide = [[NSUserDefaults standardUserDefaults] stringForKey:@"hideSetupScreen"];
    if (hide) {
        if ([hide isEqualToString:@"YES"])
        {
            self.setupButton.hidden = YES;
        }
    }
    self.nextRunLabel.text = [NSString stringWithFormat:@"%ld", 1+(long)self.app.lastRun];
}

- (IBAction)unhideButton1Tapped:(id)sender
{
    self.tappedCode = [self.tappedCode stringByAppendingString:@"1"];
}

- (IBAction)unhideButton2Tapped:(id)sender
{
    if ([self.tappedCode isEqualToString:@"111"]) {
        self.setupButton.hidden = NO;
        [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"hideSetupScreen"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    self.tappedCode = @"";
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self checkForNewVersionOnServer];
    [self checkIfNextRunExists];
}

- (void)checkIfNextRunExists
{
    UIAlertView* startingUp = [[UIAlertView alloc]
                          initWithTitle:@"Please wait."
                          message:@"Starting up..."
                          delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:nil];
    
    [startingUp show];
    

    // We want "starting up" to appear at least for half a second otherwise it might
    // look like a bug.
    [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
        ExperimentXMLLoader* loader = [[ExperimentXMLLoader alloc] initWithURL:self.app.xmlExperimentDataLocation];
        self.app.participantID = loader.participantID;
        
        [startingUp dismissWithClickedButtonIndex:0 animated:YES];
        
        if (loader.loadedOK) {
            NSInteger nextRunNumber = 1 + self.app.lastRun;
            NSLog(@"Attempting to load run number %ld to see if it exists.", (long)nextRunNumber);
            NSArray* experimentRun = [loader loadRun:nextRunNumber];
            if (experimentRun == nil) {
                UIAlertView* alert = [[UIAlertView alloc]
                                      initWithTitle:@"Thank you"
                                      message:@"You have completed the experiment.  Please contact the lab."
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
                
                [alert show];
            }
        }
    } repeats:NO];

}

- (void)checkForNewVersionOnServer
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSURL* url = [NSURL URLWithString:@"https://s3.amazonaws.com/snapstudy/manifest.plist"];
        NSString *latestPlist = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self compareVersions:latestPlist];
        });
    });
}

- (void)compareVersions:(NSString*)plistFileContents
{
    NSData* plistData = [plistFileContents dataUsingEncoding:NSUTF8StringEncoding];
    NSString* error;
    NSPropertyListFormat format;
    NSDictionary* plist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
    
    if (!plist) {
        NSLog(@"compareVersions: Could not get plist file to check version: %@", error);
    } else {
        NSString* versionString_ = plist[@"items"][0][@"metadata"][@"bundle-version"];
        NSString* versionString = [versionString_ componentsSeparatedByString:@" "][0];
        if ([versionString isEqualToString:self.app.version]) {
            NSLog(@"compareVersions: Found identical version, no need to upgrade.");
        } else {
            float theirVersion = [versionString floatValue];
            float ourVersion = [self.app.version floatValue];
            NSLog(@"Comparison: Our version %f, server version %f.", ourVersion, theirVersion);
            if (theirVersion > ourVersion) {
               // [self askUserIfUpgradeDesired];
            }
        }
    }
}

- (void)askUserIfUpgradeDesired
{
    if (!self.upgradeAlertVisible) {
        self.upgradeAlertVisible = YES;
        UIAlertView* alert = [[UIAlertView alloc]
             initWithTitle:@"Upgrade"
             message:@"A upgrade to this experiment is available. Get it now?"
             delegate:self
             cancelButtonTitle:@"Upgrade later"
             otherButtonTitles:@"Upgrade now", nil];
        
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString* selectedButton = [alertView buttonTitleAtIndex:buttonIndex];
    if ([selectedButton isEqualToString:@"Upgrade now"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-services://?action=download-manifest&url=https://s3.amazonaws.com/snapstudy/manifest.plist"]];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segueToQuestionnaire"])
    {
        // We have to check if the experiment XML asks us to force "first one of the day"
        
        self.app = [[UIApplication sharedApplication] delegate];
        NSInteger runNumber = 1 + self.app.lastRun;
        ExperimentXMLLoader* loader = [[ExperimentXMLLoader alloc] initWithURL:self.app.xmlExperimentDataLocation];
        [loader loadRun:runNumber];

        if (loader.forceFirstOneOfTheDay) {
            self.app.firstOneOfTheDay = YES;
            NSLog(@"FORCING FIRST RUN OF THE DAY AS PER XML FILE.");
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
