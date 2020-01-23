//
//  MyDocument.m
//  SNAPStudy
//
//  Created by De Pons, Jeffrey on 12/30/19.
//  Copyright © 2019 faucetEndeavors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyDocument.h"
@implementation MyDocument

-(id)contentsForType:(NSString *)typeName
               error:(NSError *__autoreleasing *)outError
{
    return [NSData dataWithBytes:[_userText UTF8String]
                          length:[_userText length]];
}

-(BOOL) loadFromContents:(id)contents
         ofType:(NSString *)typeName
         error:(NSError *__autoreleasing *)outError
{
    if ( [contents length] > 0) {
        _userText = [[NSString alloc]
          initWithBytes:[contents bytes]
          length:[contents length]
          encoding:NSUTF8StringEncoding];
    } else {
        _userText = @"";
    }
    return YES;
} 
/*

NSURL *src = [self fileURL];
  NSURL *dest = NULL;
  NSURL *ubiquityContainerURL = [[[NSFileManager defaultManager]
                                   URLForUbiquityContainerIdentifier:nil]
                                   URLByAppendingPathComponent:@"Documents"];
      if (ubiquityContainerURL == nil) {
          NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                NSLocalizedString(@"iCloud does not appear to be configured.", @""),
                                NSLocalizedFailureReasonErrorKey, nil];
          NSError *error = [NSError errorWithDomain:@"Application" code:404
                                           userInfo:dict];
          NSLog(@"error in ubiquity");
          return;
          }
          dest = [ubiquityContainerURL URLByAppendingPathComponent:
                                                            [src lastPathComponent]];
  */

@end

