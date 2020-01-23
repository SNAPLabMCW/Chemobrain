//
//  EachTimeQuestionnaireViewController.m
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/18/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import "EachTimeQuestionnaireViewController.h"
#import "AppDelegate.h"
#import "NSTimer+Blocks.h"
#import "DropboxHandling.h"

@interface EachTimeQuestionnaireViewController ()
@property (weak, nonatomic) IBOutlet UILabel *topic;
@property (weak, nonatomic) IBOutlet UILabel *question;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *optionLabels;
@property (strong, nonatomic) IBOutletCollection(UISegmentedControl) NSArray *choices;
@property (weak, nonatomic) IBOutlet UILabel *keyHintLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIButton *informationIcon;
@property (nonatomic) NSDate* timeSurveyStarted;
@property (nonatomic) NSDateFormatter* dateFormat;

@property (nonatomic) float hintDelay;
@property (nonatomic) float questionAnswerDelay;
@property (nonatomic) NSString* results;
@property (strong) AppDelegate* app;
@property (nonatomic) NSInteger currentQuestionNumber;
@end

@implementation EachTimeQuestionnaireViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (self.app.firstOneOfTheDay) {
        self.currentQuestionNumber = 0;
    } else {
        self.currentQuestionNumber = 3;
    }
//    self.currentQuestionNumber = 9;  // PAKL
    self.results = @"";
    self.timeSurveyStarted = [NSDate date];
    self.dateFormat = [[NSDateFormatter alloc] init];
    [self.dateFormat setDateFormat:@"YYYYMMdd_HHmmss"];
    self.questionAnswerDelay = 1;
    self.hintDelay = 0.1;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self hideAllOptionsAndChoices];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self showNextQuestion];
    [self.navigationController setNavigationBarHidden:YES];

}

- (IBAction)nextButtonWasPressed:(id)sender
{
    [self showNextQuestion];
}

- (void)showNextQuestion
{
    self.currentQuestionNumber += 1;
    [self showQuestion:self.currentQuestionNumber];
}

- (void)hideAllOptionsAndChoices
{
    self.topic.text = @"";
    self.question.text = @"";
    self.informationIcon.hidden = YES;
    self.nextButton.hidden = YES;
    self.keyHintLabel.text = @"";
    for (UILabel* option in self.optionLabels) {
        option.hidden = YES;
    }
    for (UISegmentedControl* choice in self.choices) {
        choice.hidden = YES;
    }
}

- (void)recordCurrentAnswers:(NSInteger)questionNumber
{
    NSString* result = [NSString stringWithFormat:@"%ld,", (long)questionNumber];
    NSString* question = [NSString stringWithFormat:@"\"%@\", ", self.question.text];
    result = [result stringByAppendingString:question];
    for (int i = 0; i < [self.optionLabels count]; i++)
    {
        NSString* option = ((UILabel*) [self.optionLabels objectAtIndex:i]).text;
        UISegmentedControl* choice = (UISegmentedControl*) [self.choices objectAtIndex:i];
        if (!choice.hidden) {
            if ([choice selectedSegmentIndex] > -1) {
            NSString* choiceText = [choice titleForSegmentAtIndex:[choice selectedSegmentIndex]];
            NSString* row = [NSString stringWithFormat:@"\"%@\"=%@,", option, choiceText];
            result = [result stringByAppendingString:row];
            } else {
                NSString* row = [NSString stringWithFormat:@"\"%@\"=?,", option];
                result = [result stringByAppendingString:row];
            }
        }
    }
    result = [result stringByAppendingString:@"\n"];
    self.results = [self.results stringByAppendingString:result];
}

- (void)saveAllRecordedAnswers
{
    NSLog(@"%@", self.results);
    NSString* docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    int runNumber = (int) (1 + self.app.lastRun);
    NSString* twoDigit = [NSString stringWithFormat:@"%02d", runNumber];
    NSString* filename = [@[@"survey",
                            twoDigit,
                            @"-",
                            self.app.participantID,
                            @"-",
                            [self.dateFormat stringFromDate:self.timeSurveyStarted],
                            @".csv"] componentsJoinedByString:@""];
    NSString *filepath = [docsDir stringByAppendingPathComponent:filename];
    [self.results writeToFile:filepath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    AppDelegate* app = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    DropboxHandling* dropbox = app.dropBoxHandling;
    [dropbox write:self.results toFile:filename alsoWriteLocally:NO];
}

- (void)showQuestion:(NSInteger)number
{
    if (number > 1) {
        [self recordCurrentAnswers:number-1];
    }
    [self hideAllOptionsAndChoices];
    self.nextButton.hidden = NO;
    self.nextButton.enabled = NO; // Only enabled if all choices have been made.
    self.informationIcon.hidden = YES;
    self.nextButton.hidden = YES;
    if (number == 1) {
        self.topic.text = @"Social Media";
        self.question.text = @"How many hours did you spend on social media in the last 24 hours? (Facebook, Twitter, Tumblr, MySpace, Pintrest, Snapchat, etc.)";
        [self setupLabels:@[@"Hours on social media"]];
        [self setupChoiceValues:0 minimum:0 maximum:10];
        [self setupHint:@"If you spent time, but less than 1 hour, please select 1."];
    } else
    if (number == 2) {
        self.topic.text = @"Sleep Duration";
        self.question.text = @"How many hours of sleep did you get last night?";
        [self setupLabels:@[@"Hours of sleep"]];
        [self setupChoiceValues:0 minimum:0 maximum:10];
    } else
    if (number == 3) {
        self.topic.text = @"Sleep Quality";
        self.question.text = @"How restored did you feel after your most recent night's sleep?";
        [self setupLabels:@[@"How restored?"]];
        [self setupChoiceValues:0 minimum:1 maximum:5];
        [self setupHint:@"Key:     1 = Not at all         5 = Extremely"];
    } else
    if (number == 4) {
        self.topic.text = @"Caffeine";
        self.question.text = @"How many cups of caffeine have you had within the last 30 minutes?";
        [self setupLabels:@[@"Coffee (cups)", @"Tea (cups)", @"Soda (cups)"]];
        for (int i = 0; i <= 2; i++) {
            [self setupChoiceValues:i minimum:0 maximum:5];
        }
        [self setupHint:@"Please enter the number of cups of each beverage."];
    } else
    if (number == 5) {
        self.topic.text = @"Fatigue";
        self.question.text = @"How tired are you?";
        [self setupLabels:@[@"Fatigue"]];
        [self setupChoiceValues:0 minimum:1 maximum:5];
        [self setupHint:@"Key:     1 = No Fatigue         5 = Fighting to stay awake"];
    } else
    if (number == 6) {
        self.topic.text = @"Mood";
        self.question.text = @"Please rate all positive and negative mood items.";
        [self setupLabels:@[@"Happy", @"Relaxed", @"Cheerful", @"Confident", @"Accepted by Others", @"Sad", @"Anxious", @"Stressed", @"Frustrated", @"Irritable"]];
        for (int i = 0; i < 10; i++) {
            [self setupChoiceValues:i minimum:1 maximum:5];
        }
        [self setupHint:@"Key:     1 = Not at all         5 = Extremely"];
    } else
    if (number == 7) {
        self.topic.text = @"Alcohol & Drug Use";
        self.question.text = @"Please answer the following questions about alcohol and drug use.";
        [self setupLabels:@[@"Currently under the influence of alcohol?", @"Of marijuana, cocaine, heroine, or prescription medication?", @"Have you smoked a cigarette in the last 10 minutes?"]];
        for (int i = 0; i <= 2; i++) {
            [self setupChoiceYesNo:i];
        }
    } else
    if (number == 8) {
        self.topic.text = @"Current Activity";
        self.question.text = @"Are you currently at work, school or home?  Are you with others?";
        [self setupLabels:@[@"Are you currently at:", @"Are you:"]];
        [self setupChoice:0 withStrings:@[@"Work", @"School", @"Home", @"Other"]];
        [self setupChoice:1 withStrings:@[@"Alone", @"With others"]];
        [self setupHint:@"Note: 'With others' means you are currently interacting with other people, not just in the presence of others."];
    } else
    {
        [self saveAllRecordedAnswers];
        self.nextButton.enabled = YES;
        self.topic.text = @"Thank you.";
        self.question.text = @"You are now ready to start the experiment.  Press the 'Calibrate' button below when ready to calibrate your face position.";
        [self.nextButton setTitle:@"Calibrate >>" forState:UIControlStateNormal];
        [self.nextButton addTarget:self action:@selector(startExperiment) forControlEvents:UIControlEventTouchUpInside];
        self.nextButton.hidden = NO;
    }
}

- (void)setupHint:(NSString*)hint
{
    [NSTimer scheduledTimerWithTimeInterval:self.hintDelay block:^{
        self.keyHintLabel.text = hint;
        self.informationIcon.hidden = NO;
    } repeats:NO];
}

- (void)startExperiment
{
    [self performSegueWithIdentifier:@"startCalibration" sender:self];
}

- (void)setupLabels:(NSArray*)strings
{
    [NSTimer scheduledTimerWithTimeInterval:self.questionAnswerDelay block:^{
        for (int i = 0; i < [strings count]; i++) {
            UILabel* optionLabel = (UILabel*)self.optionLabels[i];
            optionLabel.text = strings[i];
            optionLabel.hidden = NO;
        }
    } repeats:NO];

    [NSTimer scheduledTimerWithTimeInterval:self.questionAnswerDelay+0.5 block:^{
        self.nextButton.hidden = NO;
    } repeats:NO];

}

- (void)setupChoiceValues:(int)segmentedControlIndex minimum:(int)min maximum:(int)max
{
    [NSTimer scheduledTimerWithTimeInterval:self.questionAnswerDelay block:^{
        UISegmentedControl* choices = (UISegmentedControl*) self.choices[segmentedControlIndex];
        choices.hidden = NO;
        [choices removeAllSegments];
        for (int i = max; i >= min; i--) {
            NSString *title = [NSString stringWithFormat:@"%d", i];
            [choices insertSegmentWithTitle:title atIndex:0 animated:YES];
        }
    } repeats:NO];
}

/** Returns YES if all visible choices have been selected. */
- (BOOL)allChoicesMade
{
    for (int i = 0; i < [self.choices count]; i++) {
        UISegmentedControl* choice = [self.choices objectAtIndex:i];
        if (choice.hidden == NO) {
            if ([choice selectedSegmentIndex] == -1) {
                return NO;
            }
        }
    }
    return YES;
}

- (IBAction)choiceWasMade:(id)sender
{
    if ([self allChoicesMade]) {
        self.nextButton.enabled = YES;
    }
}

- (void)setupChoiceYesNo:(int)segmentedControlIndex
{
    [NSTimer scheduledTimerWithTimeInterval:self.questionAnswerDelay block:^{
        UISegmentedControl* choices = (UISegmentedControl*) self.choices[segmentedControlIndex];
        choices.hidden = NO;
        [choices removeAllSegments];
        [choices insertSegmentWithTitle:@"No" atIndex:0 animated:YES];
        [choices insertSegmentWithTitle:@"Yes" atIndex:0 animated:YES];
    } repeats:NO];
}

- (void)setupChoice:(int)segmentedControlIndex withStrings:(NSArray*)strings
{
    [NSTimer scheduledTimerWithTimeInterval:self.questionAnswerDelay block:^{
        UISegmentedControl* choices = (UISegmentedControl*) self.choices[segmentedControlIndex];
        choices.hidden = NO;
        [choices removeAllSegments];
        for (NSInteger i = [strings count]-1; i >= 0; i--) {
            NSString *title = strings[i];
            [choices insertSegmentWithTitle:title atIndex:0 animated:YES];
        }
    } repeats:NO];
}
@end
