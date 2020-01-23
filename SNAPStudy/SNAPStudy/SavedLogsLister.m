//
//  SavedLogsLister.m
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/6/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import "SavedLogsLister.h"

@interface SavedLogsLister ()
@property (nonatomic) NSMutableArray* savedFiles;
@end

@implementation SavedLogsLister

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization

        self.savedFiles = [[NSMutableArray alloc] init];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSArray* directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
        for (NSString* path in directoryContent) {
            [self.savedFiles addObject:path];
        }
        [self.tableView reloadData];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)sendEmailUsingFile:(NSString*)filename
{
    NSString *emailTitle = filename;
    NSString *messageBody = [self loadTextForFile:filename];
    [self sendEmailWithContents:messageBody andSubject:emailTitle];
}

- (void)sendEmailWithContents:(NSString*)messageBody andSubject:(NSString*)emailTitle
{
    NSArray *toRecipents = [NSArray arrayWithObject:@"agreenb@uwm.edu"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    [self presentViewController:mc animated:YES completion:NULL];
}

- (NSString*)loadTextForFile:(NSString*)filename
{
    NSString* docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    
    NSString* filepath = [docsDir stringByAppendingPathComponent:filename];
    
    NSString* data = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
    return data;
}

- (void)sendAllSurveys
{
    NSString* messageBody = [self concatenateAllWithPrefix:@"survey-"];
    NSString *emailTitle = @"Files with prefix survey-";
    [self sendEmailWithContents:messageBody andSubject:emailTitle];
}

- (void)sendAllExperimentData
{
    NSString* messageBody = [self concatenateAllWithPrefix:@"log-"];
    NSString *emailTitle = @"Files with prefix log-";
    [self sendEmailWithContents:messageBody andSubject:emailTitle];
}

- (NSString*)concatenateAllWithPrefix:(NSString*)prefix
{
    NSString* result = [NSString stringWithFormat:@"All files with prefix %@", prefix];
    for (NSString* savedFile in self.savedFiles) {
        if ([savedFile hasPrefix:prefix]) {
            NSString* contents = [self loadTextForFile:savedFile];
            result = [result stringByAppendingString:savedFile];
            result = [result stringByAppendingString:@"\n"];
            result = [result stringByAppendingString:contents];
        }
        result = [result stringByAppendingString:@"\n\n"];
    }
    return result;
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *filename = cell.textLabel.text;
    [self sendEmailUsingFile:filename];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.savedFiles count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"saveLogCell" forIndexPath:indexPath];
    
    UILabel* title = cell.textLabel;

    title.text = [self.savedFiles objectAtIndex:indexPath.row];
    [title setFont:[UIFont fontWithName:@"System" size:17]];
    title.minimumScaleFactor = 0.1f;
    title.adjustsFontSizeToFitWidth = YES;
    
    return cell;
}
@end
