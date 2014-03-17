//
//  RMWeakLinkedDBMetadata.h
//  ResourceManager
//
//  Created by Sebastien Morel on 3/17/2014.
//  Copyright (c) 2014 Sebastien Morel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RMWeakLinkedDBMetadata : NSObject

- (id)initWithMetaData:(id)metaData;
- (BOOL)isDirectory;
- (BOOL)isDeleted;
- (NSArray*)contents;
- (NSString*)path;
- (NSDate*)lastModifiedDate;

@end
