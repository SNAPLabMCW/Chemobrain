//
//  SavedLogsLister.h
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/6/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface SavedLogsLister : UITableViewController<MFMailComposeViewControllerDelegate>
- (void)sendAllExperimentData;
- (void)sendAllSurveys;
@end
