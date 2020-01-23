//
//  ConfigurationViewController.m
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/6/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import "ConfigurationViewController.h"
#import "AppDelegate.h"
#import "ExperimentXMLLoader.h"
#import "DropboxSDK/DropboxSDK.h"
#import "DropboxHandling.h"

@interface ConfigurationViewController ()
@property (weak, nonatomic) IBOutlet UILabel* participantIDLabel;
@property (weak, nonatomic) IBOutlet UITextField *dataSourceLocationURL;
@property (weak, nonatomic) IBOutlet UILabel* nextRunLabel;
@property (weak, nonatomic) IBOutlet UILabel* startupTimesLabel;
@property (weak, nonatomic) IBOutlet UILabel *linkedStatusMessage;
@property (weak, nonatomic) IBOutlet UITextField *experimentURL;
@property (weak, nonatomic) IBOutlet UILabel* firstOneOfDayLabel;
@property (strong) NSTimer* checkLinkTimer;
@property (strong) DropboxHandling* dropbox;
@end

@implementation ConfigurationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate* app = [[UIApplication sharedApplication] delegate];
    self.startupTimesLabel.text = [NSString stringWithFormat:@"%ld", (long)app.startupCount];
    self.nextRunLabel.text = [NSString stringWithFormat:@"%ld", 1+(long)app.lastRun];
    self.firstOneOfDayLabel.text = app.firstOneOfTheDay ? @"YES" : @"NO";
    self.dataSourceLocationURL.text = app.xmlExperimentDataLocation;
    self.participantIDLabel.text = app.participantID;
    
    self.dropbox = [[DropboxHandling alloc] init];
    [self checkIfDropBoxIsLinked];
    self.checkLinkTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkIfDropBoxIsLinked) userInfo:nil repeats:YES];
                           
}

- (IBAction)resetSessionToZero:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"lastRunCompletedNumber"];
    // Pakl
    [[NSUserDefaults standardUserDefaults] synchronize];
    UIAlertView* alert = [[UIAlertView alloc]
                          initWithTitle:@"Session Counter Reset"
                          message:@"The session counter has been reset.  Press the home button.  When you next load the app, the session counter will restart at 1."
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.checkLinkTimer invalidate];
    self.checkLinkTimer = nil;
}

- (void)checkIfDropBoxIsLinked
{
    if ([self.dropbox isLinked]) {
        self.linkedStatusMessage.text = @"(Linked)";
    } else {
        self.linkedStatusMessage.text = @"(Not Linked)";
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    AppDelegate* app = [[UIApplication sharedApplication] delegate];

    [app setXMLDataLocation:textField.text];
}

- (IBAction)sendAllSurveys:(id)sender
{
    [self.list sendAllSurveys];
}

- (IBAction)sendAllExperimentData:(id)sender
{
    [self.list sendAllExperimentData];
}

- (IBAction)authenticateToDropbox:(id)sender
{
//    UIViewController* root = [self.navigationController.viewControllers objectAtIndex:0];
//    [[DBAccountManager sharedManager] linkFromController:root];
    
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self]; // try root if this doesn't work
    }
    
}

-(IBAction)unlinkFromDropbox:(id)sender
{
    [[DBSession sharedSession] unlinkAll];   
}

- (IBAction)writeTestFile:(id)sender
{
    AppDelegate* app = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    DropboxHandling* dropbox = app.dropBoxHandling;
    [dropbox write:self.startupTimesLabel.text toFile:@"test_startup_times_count.txt" alsoWriteLocally:YES];
}

- (IBAction)validateXMLFile:(id)sender
{
    [self.experimentURL resignFirstResponder];
    NSString* url = self.experimentURL.text;
    ExperimentXMLLoader* loader = [[ExperimentXMLLoader alloc] initWithURL:url];
    NSString* msg = [NSString
                     stringWithFormat:@"We detected the experiment has %ld runs.  If this is different from what you expected, there is probably a problem with the XML file.  Please recheck it and re-upload it.",
                     (long)loader.numRuns];
    UIAlertView* alert = [[UIAlertView alloc]
                          initWithTitle:@"Validating Experiment"
                          message:msg
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    
    [alert show];
    
}

- (IBAction)hideSetupScreen:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"hideSetupScreen"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
