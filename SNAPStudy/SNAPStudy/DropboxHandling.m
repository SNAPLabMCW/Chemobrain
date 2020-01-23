//
//  DropboxHandling.m
//  SNAPStudy
//
//  Created by Patryk Laurent on 9/21/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import "DropboxHandling.h"

@implementation DropboxHandling

- (instancetype) init
{
    if (self == [super init])
    {
        _filenamesToUploadAfterMetaDataArrives = [[NSMutableArray alloc] initWithCapacity:10];
        _localPathsToUploadAfterMetaDataArrives = [[NSMutableArray alloc] initWithCapacity:10];
        _filenamesToRevisionCodes = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return self;
}

- (void)setUpApp
{

}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    NSLog(@" in rest client");
    self.filenamesToRevisionCodes = [[NSMutableDictionary alloc] initWithCapacity:10];
    for (DBMetadata* file in metadata.contents) {
        [self.filenamesToRevisionCodes setValue:file.rev forKey:file.filename];
    }
    self.dbMetaData = metadata;
   //NSLog(@"METADATA REVISIONS: \n %@", self.filenamesToRevisionCodes);
    
    //NSLog(@"Uploading for overwriting anything that was queued...");
    NSString *destDir = @"/";

    for (int i = 0; i < [self.filenamesToUploadAfterMetaDataArrives count]; i++) {
        NSString* filename = [self.filenamesToUploadAfterMetaDataArrives objectAtIndex:i];
        NSString* localPath = [self.localPathsToUploadAfterMetaDataArrives objectAtIndex:i];
        NSString* parentRev = nil;
        if ([[self.filenamesToRevisionCodes allKeys] containsObject:filename]) {
            parentRev = [self.filenamesToRevisionCodes valueForKey:filename];
        }
        [self.restClient uploadFile:filename toPath:destDir withParentRev:parentRev fromPath:localPath];
    }
    [self.filenamesToUploadAfterMetaDataArrives removeAllObjects];
    [self.localPathsToUploadAfterMetaDataArrives removeAllObjects];
    
}

- (void)write:(NSString*)text toFile:(NSString*)filename alsoWriteLocally:(BOOL)writeLocal
{
    if (self.restClient == nil) {
        //NSLog(@"rest client is null");
        self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
        [self.restClient loadMetadata:@"/"];
    }
    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *localPath = [localDir stringByAppendingPathComponent:filename];
    if (writeLocal) {
        [text writeToFile:localPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }

        
   // NSLog(@"local path = %@",localPath);
    if (self.dbMetaData == nil) {
       // NSLog(@"Here");
        //NSLog(@"Data is nil, queueing for later.");
        [self.filenamesToUploadAfterMetaDataArrives addObject:filename];
        [self.localPathsToUploadAfterMetaDataArrives addObject:localPath];
    }
    else {
        NSLog(@"uploading to dropbox now");
        // Upload file to Dropbox
        NSString *destDir = @"/";
        NSString* parentRev = nil;
        if ([[self.filenamesToRevisionCodes allKeys] containsObject:filename]) {
            parentRev = [self.filenamesToRevisionCodes valueForKey:filename];
        }
        [self.restClient uploadFile:filename toPath:destDir withParentRev:parentRev fromPath:localPath];
    }
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    [self.restClient loadMetadata:@"/"];
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    NSLog(@"File upload failed with error: %@", error);
}



-(void)unlink
{
    [[DBSession sharedSession] unlinkAll];
}

- (BOOL)isLinked
{
    if ([[DBSession sharedSession] isLinked]) {
        return YES;
    } else {
        return NO;
    }
}


@end
