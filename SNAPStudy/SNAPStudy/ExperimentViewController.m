//
//  ExperimentViewController.m
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/3/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import "ExperimentViewController.h"
#import "ExperimentTrial.h"
#import "NSTimer+Blocks.h"
#import "ExperimentXMLLoader.h"
#import "AppDelegate.h"
#import "DropboxHandling.h"
#import "CalibrationScreenViewController.h"

#define ARC4RANDOM_MAX      0x100000000

@interface ExperimentViewController ()
@property (weak, nonatomic) IBOutlet UILabel *fixationCross;
@property (weak, nonatomic) IBOutlet UILabel *stimulusTop;
@property (weak, nonatomic) IBOutlet UILabel *stimulusBottom;
@property (weak, nonatomic) IBOutlet UILabel *cueTop;
@property (weak, nonatomic) IBOutlet UILabel *cueCenter;
@property (weak, nonatomic) IBOutlet UILabel *cueBottom;

@property (weak, nonatomic) UILabel *target;

@property (nonatomic) BOOL fixationCrossWasHidden;
@property (nonatomic) BOOL stimulusTopWasHidden;
@property (nonatomic) BOOL stimulusBottomWasHidden;
@property (nonatomic) BOOL cueTopWasHidden;
@property (nonatomic) BOOL cueCenterWasHidden;
@property (nonatomic) BOOL cueBottomWasHidden;

@property (nonatomic) NSMutableArray* eventTimings;

@property (nonatomic) NSInteger cumulativeTime;
@property (nonatomic) NSArray* experiment;
@property (nonatomic) NSArray* experimentRunBreaks;
@property (nonatomic) ExperimentTrial* currentTrial;
@property (nonatomic) NSInteger currentTrialNumber;
@property (nonatomic) NSInteger frameCount;

@property (nonatomic) CFTimeInterval lastTime;
@property (nonatomic) CADisplayLink* dl;
@property (nonatomic) NSDate* timeTrialStarted;
@property (nonatomic) NSDateFormatter* dateFormat;

@property (nonatomic) NSInteger runNumber;
@property (nonatomic) AppDelegate* app;
@property (nonatomic) BOOL experimentIsRunning;
@end

@implementation ExperimentViewController

- (void)runNextTrial
{

    NSLog(@"Run next trial, %ld", (long)self.currentTrialNumber);
    if (self.currentTrialNumber < [self.experiment count]) {
        float breakDurationIfTakingBreak = 0.0;
        if ([self shouldTakeABreakAfter:self.currentTrialNumber])
        {
            breakDurationIfTakingBreak = [self takeABreakFor:self.currentTrialNumber];
            NSLog(@"shouldTakeABreakAfter -- duration %f", breakDurationIfTakingBreak);
        }

        [NSTimer scheduledTimerWithTimeInterval:breakDurationIfTakingBreak block:^{
            if (breakDurationIfTakingBreak > 0) {
                
                NSLog(@"Taking the break -- duration %f", breakDurationIfTakingBreak);
                // Show calibration screen.  When we return, resume.
                CalibrationScreenViewController* calibration = [self.storyboard instantiateViewControllerWithIdentifier:@"calibrationScreenViewControllerID"];

                [calibration whenDone:^{
                        self.stimulusTop.text = @"GET READY!";
                        [NSTimer scheduledTimerWithTimeInterval:5.0 block:^{
                            NSLog(@"Waiting 5 seconds to hide stimulusTop (get ready) and proceed.");
                            self.stimulusTop.hidden = YES;
                            [self proceedWithNextTrial];
                        } repeats:NO];
                }];
                [self.navigationController pushViewController:calibration animated:NO];
                
            } else {
                [self proceedWithNextTrial];
            }
        } repeats:NO];
        
    } else {
        [self saveReport];
        [self endExperiment];
    }
}

- (void)proceedWithNextTrial
{
    ExperimentTrial* trial = [self.experiment objectAtIndex:self.currentTrialNumber];
    self.currentTrialNumber = self.currentTrialNumber + 1;
    self.frameCount = 0;
    self.timeTrialStarted = [NSDate date];
    [trial log:@"Base time for trial %@", [self.dateFormat stringFromDate:self.timeTrialStarted]];
    
    [self.eventTimings addObject:[NSString stringWithFormat:
                                  @"%f 0 trialStart", [self.timeTrialStarted timeIntervalSinceNow] * -1000.0]];
    [self doTrial:trial];
}

- (BOOL)shouldTakeABreakAfter:(NSInteger)trialNumber
{
    for (NSDictionary* plannedBreak in self.experimentRunBreaks)
    {
        int afterTrial = [plannedBreak[@"_after_trial"] intValue];
        if (trialNumber == afterTrial) return YES;
    }
    return NO;
}

- (float)takeABreakFor:(NSInteger)trialNumber
{
    NSDictionary* thisBreak = nil;
    for (NSDictionary* plannedBreak in self.experimentRunBreaks)
    {
        int afterTrial = [plannedBreak[@"_after_trial"] intValue];
        if (trialNumber == afterTrial) thisBreak = plannedBreak;
    }
    float duration = 0.0;
    if (thisBreak != nil) {
        self.stimulusTop.hidden = NO;
        duration = [thisBreak[@"_duration"] floatValue];
        NSString* msg = [NSString stringWithFormat:@"Please take a break for %d seconds.", (int)duration];
        self.stimulusTop.text = msg;
        NSLog(@"Taking a break for %d seconds.", (int)duration);

    }
    return duration;
}


- (void)doTrial:(ExperimentTrial*)trial
{
    self.cumulativeTime = 0;
    self.currentTrial = trial;
    NSArray* cuesToShow = @[];
    self.target = nil;
    UILabel* nonTarget = nil;
    
    switch (trial.cueCondition) {
        case CueConditionNone:
            cuesToShow = @[self.fixationCross];
            break;
        case CueConditionCenter:
            cuesToShow = @[self.cueCenter];
            break;
        case CueConditionSpatialUp:
            cuesToShow = @[self.cueTop, self.fixationCross];
            break;
        case CueConditionSpatialDown:
            cuesToShow = @[self.cueBottom, self.fixationCross];
            break;
        case CueConditionDouble:
            cuesToShow = @[self.cueBottom, self.cueTop, self.fixationCross];
            break;
    }
    
    switch (trial.targetLocation) {
        case TargetLocationUp:
            self.target = self.stimulusTop;
            nonTarget = self.stimulusBottom;
            break;
        case TargetLocationDown:
            nonTarget = self.stimulusTop;
            self.target = self.stimulusBottom;
            break;
    }
    NSArray* targetsToShow = @[self.target];
    nonTarget.text = @"";
    switch (trial.stimulus) {
        case StimulusCongruentLeft:
            self.target.text = @"< < < < <";
            break;
        case StimulusCongruentRight:
            self.target.text = @"> > > > >";
            break;
        case StimulusIncongruentLeft:
            self.target.text = @"> > < > >";
            break;
        case StimulusIncongruentRight:
            self.target.text = @"< < > < <";
            break;
        case StimulusNeutralLeft:
            self.target.text = @"- - < - -";
            break;
        case StimulusNeutralRight:
            self.target.text = @"- - > - -";
            break;
    }
    
    [trial start:self.currentTrialNumber];
    // ------------------------------------------------------
    // ENQUEUE THE TRIAL EVENTS
    // ------------------------------------------------------
    [self hide:@[nonTarget]          after:0                             andShow:@[self.fixationCross]];
    [self hide:@[self.fixationCross] after:trial.initialFixationDuration andShow:cuesToShow];
    [self hide:cuesToShow            after:trial.cueDuration             andShow:@[self.fixationCross]];
    [self hide:@[]                   after:trial.postCueDelayDuration    andShow:targetsToShow];
    [self hide:targetsToShow         after:trial.maxTargetDuration       andShow:@[]];
    [self hide:@[self.fixationCross] at:4000 andThen:^{[self runNextTrial];}];
}

- (void)endExperiment
{
    self.experimentIsRunning = NO;
    [self.app recordRunCompleted:self.runNumber];
}

- (void)saveReport
{
    // Show Report if we are debugging
    NSString* report = @"";
    report = [report stringByAppendingString:@"Trial Summary\n\n"];
    report = [report stringByAppendingString:((ExperimentTrial*)self.experiment[0]).header];
    for (int i = 0; i < [self.experiment count]; i++) {
        ExperimentTrial* trial = [self.experiment objectAtIndex:i];
        report = [report stringByAppendingString:[trial summary]];
    }
    if (self.dl != nil) {
        report = [report stringByAppendingString:@"Onset-Offset Frame Events (Diagnostics)\n\n"];
        report = [report stringByAppendingString:@"time\tframe\tobject\tevent\n"];
        for (int i = 0; i < [self.eventTimings count]; i++) {
            report = [report stringByAppendingString:[self.eventTimings objectAtIndex:i]];
            report = [report stringByAppendingString:@"\n"];
        }
    }
    report = [report stringByAppendingString:@"\n\n"];
    report = [report stringByAppendingString:@"Trial-by-Trial Detailed Events\n\n"];
    for (int i = 0; i < [self.experiment count]; i++) {
        ExperimentTrial* trial = [self.experiment objectAtIndex:i];
        report = [report stringByAppendingString:[NSString stringWithFormat:@"%@", trial.eventLog]];
    }
    
    BOOL SHOW_LOG_ONSCREEN = NO;
    BOOL SAVE_LOG_TO_FILE = YES;
    if (SHOW_LOG_ONSCREEN) {
        UITextView* tv = [[UITextView alloc] initWithFrame:CGRectMake(100, 100, 700, 300)];
        tv.backgroundColor = [UIColor lightGrayColor];
        tv.font = [UIFont systemFontOfSize:12.0];
        [self.view addSubview:tv];
        tv.text = report;
    } else {
        UILabel* thankYou = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 700, 300)];
        thankYou.font = [UIFont boldSystemFontOfSize:22.0];
        thankYou.textColor = [UIColor whiteColor];
        thankYou.text = @"Thank you.  Please come back when you receive the next message from our lab.";
        thankYou.numberOfLines = 3;
        thankYou.lineBreakMode = NSLineBreakByWordWrapping;
        [self.view addSubview:thankYou];
    }
    
    if (SAVE_LOG_TO_FILE) {
        NSString* docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];

        int runNumber = (int) (1 + self.app.lastRun);
        NSString* twoDigit = [NSString stringWithFormat:@"%02d", runNumber];

        NSString* filename = [@[@"log",
                                twoDigit,
                                @"-",
                                self.app.participantID,
                                @"-",
                              [self.dateFormat stringFromDate:self.timeTrialStarted],
                               @".csv"] componentsJoinedByString:@""];
        NSString *filepath = [docsDir stringByAppendingPathComponent:filename];
        [report writeToFile:filepath atomically:YES encoding:NSUTF8StringEncoding error:nil];

        AppDelegate* app = (AppDelegate*) [[UIApplication sharedApplication] delegate];
        DropboxHandling* dropbox = app.dropBoxHandling;
        [dropbox write:report toFile:filename alsoWriteLocally:NO];
    }
}

- (NSArray*)prepareRandomDemoExperiment
{
    NSMutableArray* experimentRun = [[NSMutableArray alloc] init];
    int numTrials = 5;
    for (int i = 0; i < numTrials; i++) {
        int cue = ((int)((float)arc4random()/ARC4RANDOM_MAX*5.0));
        int target = ((int)((float)arc4random()/ARC4RANDOM_MAX*2.0));
        if (cue == CueConditionSpatialDown) target = TargetLocationDown; // Must force these to comply with valid cues.
        if (cue == CueConditionSpatialUp) target = TargetLocationUp;
        
        ExperimentTrial* trial = [[ExperimentTrial alloc]
                                  initWithInitialFixationDuration:400+((int)((float)arc4random()/ARC4RANDOM_MAX*1200.0))
                                  cueCondition:cue
                                  stimulus:((int)((float)arc4random()/ARC4RANDOM_MAX*6.0))
                                  targetLocation:target];
        [experimentRun addObject:trial];
    }
    return experimentRun;
}

- (NSArray*)loadRunFromXML:(NSInteger)runNumber
{
    ExperimentXMLLoader* loader = [[ExperimentXMLLoader alloc] initWithURL:self.app.xmlExperimentDataLocation];
    
    NSArray* experimentRun = [loader loadRun:runNumber];
    return experimentRun;
}

- (NSArray*)loadRunBreaksFromXML:(NSInteger)runNumber
{
    ExperimentXMLLoader* loader = [[ExperimentXMLLoader alloc] initWithURL:self.app.xmlExperimentDataLocation];
    
    NSArray* experimentRunBreaks = [loader loadRunBreaks:runNumber];
    return experimentRunBreaks;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.experimentIsRunning) return;
    self.experimentIsRunning = YES;
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.app = [[UIApplication sharedApplication] delegate];
    self.runNumber = 1 + self.app.lastRun;
    self.experiment = [self loadRunFromXML:self.runNumber];
    self.experimentRunBreaks = [self loadRunBreaksFromXML:self.runNumber];
    if (self.experiment == nil) {
        UIAlertView* alert = [[UIAlertView alloc]
                              initWithTitle:@"Thank you"
                              message:@"This experiment is complete.  Please contact the lab."
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        
        [alert show];
    } else {
        NSLog(@"Loaded %lu trials in this run", (unsigned long)[self.experiment count]);
        self.currentTrialNumber = 0;
        [self runNextTrial];
    }
}

- (IBAction)userChoseLeft:(id)sender
{
    [self.currentTrial respondLeft];
    [self hide:@[self.stimulusBottom, self.stimulusTop] at:0 andThen:^{}];
}

- (IBAction)userChoseRight:(id)sender
{
    [self.currentTrial respondRight];
    [self hide:@[self.stimulusBottom, self.stimulusTop] at:0 andThen:^{}];
}

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
    self.eventTimings = [[NSMutableArray alloc] initWithCapacity:10000];
    self.dateFormat = [[NSDateFormatter alloc] init];
    [self.dateFormat setDateFormat:@"YYYYMMdd_HHmmss"];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.experimentIsRunning) return;
    self.fixationCross.hidden = YES;
    self.stimulusTop.hidden = YES;
    self.stimulusBottom.hidden = YES;
    self.cueTop.hidden = YES;
    self.cueCenter.hidden = YES;
    self.cueBottom.hidden = YES;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    BOOL refreshFrameDiagnositcs = NO;
    if (refreshFrameDiagnositcs) {
        self.dl = [CADisplayLink displayLinkWithTarget: self selector:@selector(refreshFrame)];
        [self.dl addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [self.dl setPaused:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.experimentIsRunning) return;
    if (self.dl != nil) {
        [self.dl setPaused:YES];
        self.dl = nil;
    }
}

- (void)hide:(NSArray*)viewsToHide after:(long)delay andShow:(NSArray*)viewsToShow
{
    const float delayEvent = ((float) self.cumulativeTime + (float)delay) / 1000.0;
    [NSTimer scheduledTimerWithTimeInterval:delayEvent block:^{
        for (UILabel* view in viewsToHide) {
            if (!view.hidden) {
                view.hidden = YES;
                [self.currentTrial log:@"Hid: %@", view.text];
            }
        }
        for (UILabel* view in viewsToShow) {
            if (view.hidden) {
                view.hidden = NO;
                [self.currentTrial log:@"Showed: %@", view.text];
                if ([view.text isEqualToString:self.target.text]) {
                    self.currentTrial.absoluteTargetShowTime = CACurrentMediaTime();
                }
            }
        }
    } repeats:NO];
    self.cumulativeTime += delay;
}

- (void)hide:(NSArray*)viewsToHide at:(long)delay andThen:(void(^)(void))doThisNext
{
    const float delayEvent = (float)delay/1000.0;
    [NSTimer scheduledTimerWithTimeInterval:delayEvent block:^{
        for (UILabel* view in viewsToHide) {
            if (!view.hidden) {
                view.hidden = YES;
                [self.currentTrial log:@"Hid: %@", view.text];
            }
        }
        doThisNext();
    } repeats:NO];
}

- (void)refreshFrame
{
    self.frameCount++;
    
    if (self.fixationCrossWasHidden != self.fixationCross.hidden)
    {
        self.fixationCrossWasHidden = self.fixationCross.hidden;
        [self.eventTimings addObject:[NSString stringWithFormat:
        @"%f\t%ld\tfixationCross\t%@", [self.timeTrialStarted timeIntervalSinceNow] * -1000.0, (long)self.frameCount, self.fixationCrossWasHidden ? @"hide" : @"show"]];
    }
    if (self.stimulusTopWasHidden != self.stimulusTop.hidden)
    {
        self.stimulusTopWasHidden = self.stimulusTop.hidden;
        [self.eventTimings addObject:[NSString stringWithFormat:
        @"%f\t%ld\tstimulusTop\t%@", [self.timeTrialStarted timeIntervalSinceNow] * -1000.0, (long)self.frameCount, self.stimulusTopWasHidden ? @"hide" : @"show"]];
    }
    if (self.stimulusBottomWasHidden != self.stimulusBottom.hidden)
    {
        self.stimulusBottomWasHidden = self.stimulusBottom.hidden;
        [self.eventTimings addObject:[NSString stringWithFormat:
        @"%f\t%ld\tstimulusBottom\t%@", [self.timeTrialStarted timeIntervalSinceNow] * -1000.0, (long)self.frameCount, self.stimulusBottomWasHidden ? @"hide" : @"show"]];
    }
    if (self.cueTopWasHidden != self.cueTop.hidden)
    {
        self.cueTopWasHidden = self.cueTop.hidden;
        [self.eventTimings addObject:[NSString stringWithFormat:
        @"%f\t%ld\tcueTop\t%@", [self.timeTrialStarted timeIntervalSinceNow] * -1000.0, (long)self.frameCount, self.cueTopWasHidden ? @"hide" : @"show"]];
    }
    if (self.cueBottomWasHidden != self.cueBottom.hidden)
    {
        self.cueBottomWasHidden = self.cueBottom.hidden;
        [self.eventTimings addObject:[NSString stringWithFormat:
        @"%f\t%ld\tcueBottom\t%@", [self.timeTrialStarted timeIntervalSinceNow] * -1000.0, (long)self.frameCount, self.cueBottomWasHidden ? @"hide" : @"show"]];
    }
    if (self.cueCenterWasHidden != self.cueCenter.hidden)
    {
        self.cueCenterWasHidden = self.cueCenter.hidden;
        [self.eventTimings addObject:[NSString stringWithFormat:
        @"%f\t%ld\tcueCenter\t%@", [self.timeTrialStarted timeIntervalSinceNow] * -1000.0, (long)self.frameCount, self.cueCenterWasHidden ? @"hide" : @"show"]];
    }
}
@end
