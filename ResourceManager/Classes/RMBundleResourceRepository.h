//
//  RMBundleResourceRepository.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-19.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMResourceRepository.h"

/**
 */
@interface RMBundleResourceRepository : RMResourceRepository

/**
 */
- (id)initWithBundle:(NSBundle*)bundle;

/**
 */
- (id)initWithPath:(NSString*)path;

/**
 */
@property (nonatomic, assign) NSTimeInterval pullingTimeInterval;

@end
