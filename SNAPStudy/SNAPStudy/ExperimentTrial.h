//
//  ExperimentTrial.h
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/3/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExperimentTrial : NSObject


typedef NS_ENUM(NSInteger, CueCondition) {
    CueConditionNone,
    CueConditionCenter,
    CueConditionDouble,
    CueConditionSpatialUp,
    CueConditionSpatialDown
};


typedef NS_ENUM(NSInteger, Stimulus) {
    StimulusNeutralLeft,
    StimulusNeutralRight,
    StimulusCongruentLeft,
    StimulusCongruentRight,
    StimulusIncongruentLeft,
    StimulusIncongruentRight
};

typedef NS_ENUM(NSInteger, TargetLocation) {
    TargetLocationUp,
    TargetLocationDown
};

@property (readonly) NSInteger initialFixationDuration;
@property (readonly) NSInteger cueDuration;
@property (readonly) NSInteger postCueDelayDuration;
@property (readonly) NSInteger maxTargetDuration;
@property (readonly) NSInteger totalTrialDuration;
@property (readonly) CueCondition cueCondition;
@property (readonly) Stimulus stimulus;
@property (readonly) TargetLocation targetLocation;
@property (readwrite) CFTimeInterval RT; // from onset of trial
@property (readwrite) NSString* response;
@property (readonly) NSMutableArray* eventLog;
@property (readwrite) CFTimeInterval absoluteTargetShowTime;
@property (readwrite) CFTimeInterval absoluteFirstResponseTime;

- (NSInteger)timeRemainingTillEndOfTrial;
- (instancetype)initWithInitialFixationDuration:(NSInteger)d1 cueCondition:(CueCondition)cueCondition stimulus:(Stimulus)stimulus targetLocation:(TargetLocation)targetLocation;
- (void)log:(NSString*)event, ...;
- (void)start:(NSInteger)labelWithNumber;
- (void)respondRight;
- (void)respondLeft;
- (NSString*)header;
- (NSString*)summary;

+ (NSDictionary*)CueConditionString;
+ (NSDictionary*)TargetLocationString;
+ (NSDictionary*)StimulusString;
+ (TargetLocation)TargetLocationFrom:(NSString*)string;
+ (Stimulus)StimulusFrom:(NSString*)string;
+ (CueCondition)CueConditionFrom:(NSString*)string;

@end
