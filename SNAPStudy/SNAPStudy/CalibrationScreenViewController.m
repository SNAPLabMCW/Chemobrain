//
//  CalibrationScreenViewController.m
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/24/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import "CalibrationScreenViewController.h"
#import "CalibrationScreen.h"

@interface CalibrationScreenViewController ()
@property (strong, nonatomic) UIImagePickerController* cameraUI;
@property (strong, nonatomic) VoidCallback doThisWhenDone;
@property (nonatomic) BOOL alreadyCalibrating;
@end

@implementation CalibrationScreenViewController

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

- (void)viewDidAppear:(BOOL)animated
{
    #if TARGET_IPHONE_SIMULATOR
        NSLog(@"Not actually doing camera calibration because running in simulator");
        [self done:nil];
    #else
    if (!self.alreadyCalibrating) {
        NSLog(@"Launching ipad camera for calibration");
        self.alreadyCalibrating = YES;
        [self startCameraControllerFromViewController];
    }
    #endif
}

- (BOOL) startCameraControllerFromViewController {
    
    if ([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera] == NO)
        return NO;
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;

    CGRect screen = [[UIScreen mainScreen] bounds];
    CGRect faceGuide = [[UIScreen mainScreen] bounds];
//    faceGuide.size.height = screen.size.width;
//    faceGuide.size.width = screen.size.height / 2;
//    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
//        faceGuide.origin.x = 0;
//    } else {
//        faceGuide.origin.x = screen.size.height / 2;
//    }
    faceGuide.size.height = screen.size.height;
    faceGuide.size.width = screen.size.width / 2;
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        faceGuide.origin.x = 0;
    } else {
        faceGuide.origin.x = screen.size.width / 2;
    }
    
    UIView *overlay = [[CalibrationScreen alloc] initWithFrame:faceGuide];
    overlay.alpha = 0.8;
    overlay.opaque = NO;
    cameraUI.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    cameraUI.modalPresentationStyle = UIModalPresentationFullScreen;
    cameraUI.showsCameraControls = NO;
    cameraUI.cameraOverlayView = overlay;
    
    UIButton* done = [[UIButton alloc] initWithFrame:CGRectMake(faceGuide.size.width/2-50, faceGuide.size.height-70, 180, 60)];
    [done setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [done setTitle:@"OK, Start Task >" forState:UIControlStateNormal];
    [done setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [done addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
    [overlay addSubview:done];

    cameraUI.allowsEditing = NO;
    
    [self.view.window.rootViewController presentViewController:cameraUI animated: YES completion:nil];
//    [self presentViewController:cameraUI animated: YES completion:nil];
    self.cameraUI = cameraUI;
    return YES;
}

- (void)whenDone:(VoidCallback)callback
{
    self.alreadyCalibrating = NO;
    self.doThisWhenDone = callback;
}

- (void)done:(id)sender
{
    [self.cameraUI dismissViewControllerAnimated:YES completion:nil];
    if (self.doThisWhenDone) {
        // If we were asked to do something (e.g., resume an experiment in mid process), do it.
        NSLog(@"Trying to pop view calib screen controller!");
        [self.navigationController popViewControllerAnimated:NO];
//        [self.navigationController dismissViewControllerAnimated:NO completion:^{}];
        self.doThisWhenDone();
    } else {
        // Default is to start running the experiment, as though called from front screen.
        [self performSegueWithIdentifier:@"startRunningExperiment" sender:self];
    }
}

@end
