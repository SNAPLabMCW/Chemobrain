//
//  CalibrationScreenViewController.h
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/24/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CalibrationScreenViewController : UIViewController
typedef void(^VoidCallback)(void);
-(void)whenDone:(VoidCallback)callback;
@end
