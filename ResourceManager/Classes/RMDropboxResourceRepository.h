//
//  RMDropboxResourceRepository.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-19.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMResourceRepository.h"

/**
 */
@interface RMDropboxResourceRepository : RMResourceRepository

/** Initialize a newly created resource repository object to manage sync using dropbox.
 */
- (id)initWithAppKey:(NSString*)appKey secret:(NSString*)secret rootDirectory:(NSString*)directory;

/**
 */
@property (nonatomic, assign) NSTimeInterval pullingTimeInterval;

@end
