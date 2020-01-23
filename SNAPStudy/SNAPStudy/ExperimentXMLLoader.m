//
//  ExperimentXMLLoader.m
//  SNAPStudy
//
//  Created by Patryk Laurent on 9/7/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import "ExperimentXMLLoader.h"
#import "XMLDictionary.h"
#import "ExperimentTrial.h"
#import "EverythingUploader.h"

@interface ExperimentXMLLoader ()
@property NSDictionary* experiment;
@end

@implementation ExperimentXMLLoader


- (instancetype) initWithURL:(NSString*)URL
{
    if (self = [super init]) {
        XMLDictionaryParser* parser = [XMLDictionaryParser sharedInstance];
        parser.alwaysUseArrays = YES;
        NSURL* url = [NSURL URLWithString:URL];
        NSError* error = nil;
        NSString* xml = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];

        if (error != nil) {
            if ([self localCopyExists]) {
                xml = [self loadTextForFile:@"local_copy.xml"];
                self.loadedOK = YES;
            } else {
                NSString *msg = [NSString stringWithFormat:@"Could not load XML Data file from URL %@ (and no local copy).", URL];
                UIAlertView* alert = [[UIAlertView alloc]
                                      initWithTitle:@"Error"
                                      message:msg
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
                
                [alert show];
                NSLog(@"Error: %@", [error description]);
            }
        } else {
            self.loadedOK = YES;
            [self saveLocalCopy:xml];
            EverythingUploader* e = [[EverythingUploader alloc] init];
            [e uploadEverything];
        }
        self.experiment = [NSDictionary dictionaryWithXMLString:xml];
        NSLog(@"Experiment loaded with %lu runs", (unsigned long)[self.experiment[@"run"] count]);

        self.numRuns = [self.experiment[@"run"] count];
        self.participantID = self.experiment[@"participant"][0][@"_id"];
        NSLog(@"Participant ID is %@", self.participantID);
    }
    return self;
}

- (void)saveLocalCopy:(NSString*)xml
{
    NSString* docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    NSString* filename = @"local_copy.xml";
    NSString *filepath = [docsDir stringByAppendingPathComponent:filename];
    [xml writeToFile:filepath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (BOOL)localCopyExists
{
    NSString* docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    NSString* filename = @"local_copy.xml";
    NSString *filepath = [docsDir stringByAppendingPathComponent:filename];
    return [[NSFileManager defaultManager] fileExistsAtPath:filepath];
}

- (NSString*)loadTextForFile:(NSString*)filename
{
    NSString* docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    NSString* filepath = [docsDir stringByAppendingPathComponent:filename];
    NSString* data = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
    return data;
}

- (NSArray*)loadRun:(NSInteger)runNumber
{
    NSMutableArray* experimentRun = [[NSMutableArray alloc] init];

    NSInteger numRuns = [self.experiment[@"run"] count];
    NSLog(@"User requested run number %ld, and we have %ld runs.", (long)runNumber, (long)numRuns);
    if (runNumber > numRuns) {
        return nil;
    }
    NSDictionary* run = self.experiment[@"run"][runNumber-1];
    NSInteger numTrials = [run[@"trials"][0][@"trial"] count];
    if ([[run allKeys] containsObject:@"_forceFirstOneOfTheDay"])
    {
        self.forceFirstOneOfTheDay = YES;
    }
    for (int i = 0; i < numTrials; i++) {
        NSDictionary* trialData = run[@"trials"][0][@"trial"][i];
        
        NSInteger initialFixationDuration = [trialData[@"_initialFixationDuration"] intValue];
        NSString* stimulusString = trialData[@"_stimulus"];
        NSString* cueConditionString = trialData[@"_cue"];
        NSString* targetLocationString = trialData[@"_target"];

        CueCondition cueCondition = [ExperimentTrial CueConditionFrom:cueConditionString];
        Stimulus stimulus = [ExperimentTrial StimulusFrom:stimulusString];
        TargetLocation targetLocation = [ExperimentTrial TargetLocationFrom:targetLocationString];
                
        ExperimentTrial* trial = [[ExperimentTrial alloc]
                          initWithInitialFixationDuration:initialFixationDuration
                          cueCondition:cueCondition
                          stimulus:stimulus
                          targetLocation:targetLocation];
        
        [experimentRun addObject:trial];
    }
    return experimentRun;
}

- (NSArray*)loadRunBreaks:(NSInteger)runNumber
{
    NSMutableArray* experimentRunBreaks = [[NSMutableArray alloc] init];
    
    NSInteger numRuns = [self.experiment[@"run"] count];
    if (runNumber > numRuns) {
        return nil;
    }
    NSDictionary* run = self.experiment[@"run"][runNumber-1];
    NSInteger numBreaks = [run[@"breaks"][0][@"break"] count];
    
    for (int i = 0; i < numBreaks; i++) {
        NSDictionary* breakData = run[@"breaks"][0][@"break"][i];
        [experimentRunBreaks addObject:breakData]; // _after_trial and _duration
    }
    return experimentRunBreaks;
}
@end
