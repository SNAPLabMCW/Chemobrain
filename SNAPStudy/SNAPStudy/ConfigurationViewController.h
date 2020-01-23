//
//  ConfigurationViewController.h
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/6/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SavedLogsLister.h"

@interface ConfigurationViewController : UIViewController<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet SavedLogsLister* list;

@end
