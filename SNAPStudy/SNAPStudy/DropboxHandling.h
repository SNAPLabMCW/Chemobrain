//
//  DropboxHandling.h
//  SNAPStudy
//
//  Created by Patryk Laurent on 9/21/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DropboxSDK/DropboxSDK.h"

@interface DropboxHandling : NSObject <DBRestClientDelegate>

@property (nonatomic, strong) DBRestClient *restClient;
- (void)write:(NSString*)text toFile:(NSString*)filename alsoWriteLocally:(BOOL)writeLocal;
- (void)setUpApp;
- (BOOL)isLinked;
@property (nonatomic,strong) NSMutableArray* filenamesToUploadAfterMetaDataArrives;
@property (nonatomic,strong) NSMutableArray* localPathsToUploadAfterMetaDataArrives;
@property (nonatomic,strong) NSDictionary* filenamesToRevisionCodes;
@property (nonatomic,strong) DBMetadata* dbMetaData;
@end
