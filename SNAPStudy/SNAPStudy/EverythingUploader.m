//
//  EverythingUploader.m
//  SNAPStudy
//
//  Created by Patryk Laurent on 12/14/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import "EverythingUploader.h"
#import "AppDelegate.h"
#import "MyDocument.h"

@implementation EverythingUploader

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)uploadEverything
{
    NSLog(@"Uploading everything.");
    AppDelegate* app = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray* directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    for (NSString* filename in directoryContent) {
        if (![filename containsString:@"local_copy.xml"]) {
            NSLog(@"Uploading %@ to ICloud Drive", filename);
            
            NSError *err;
            NSString* filepath = [documentsDirectory stringByAppendingPathComponent:filename];
            //NSLog (@"%@", filepath);
            NSString* data = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&err];

            //Get iCloud container URL
            NSURL *ubiq = [[NSFileManager defaultManager]URLForUbiquityContainerIdentifier:nil];// in place of nil you can
            //NSLog(@"%@",ubiq);
            
           // add your container name
            //Create Document dir in iCloud container and upload/sync SampleData.zip
            NSURL *ubiquitousPackage = [[ubiq URLByAppendingPathComponent:@"Documents"]URLByAppendingPathComponent:filename];
            
            MyDocument *myDoc = [[MyDocument alloc] initWithFileURL:ubiquitousPackage];
            
            //mydoc.dataContent=data;
            myDoc.userText=data;

               [myDoc saveToURL:[myDoc fileURL] forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success)
                {
                    if (success)
                    {
                        NSLog(@"%@: Synced with icloud", filename);
                    }
                    else
                        NSLog(@"Syncing FAILED with icloud");

                }];
            
            /*
            NSError *err;
            NSString* filepath = [documentsDirectory stringByAppendingPathComponent:filename];
            
            NSString* data = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&err];
            if (err != nil) {
                NSLog(@"Error is %@", err.description);
            }
            [dropbox write:data toFile:filename alsoWriteLocally:NO];
             */
        }
    }
 
}
@end
