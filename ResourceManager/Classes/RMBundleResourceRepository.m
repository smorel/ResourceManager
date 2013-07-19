//
//  RMBundleResourceRepository.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-19.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMBundleResourceRepository.h"

@interface RMBundleResourceRepository()
@property(nonatomic, retain) NSBundle* bundle;
@end

@implementation RMBundleResourceRepository

- (id)initWithBundle:(NSBundle*)theBundle{
    self = [super init];
    self.bundle = theBundle;
    return self;
}

- (id)initWithPath:(NSString*)path{
    NSBundle* bundleAtPath = [NSBundle bundleWithPath:path];
    return [self initWithBundle:bundleAtPath];
}

- (void)connect{
    [self pull];
    
    //trigger next pulling if needed (bundles that are not embededd in .app)
}

- (void)pull{
    //get all the resource files
    
    //call delegate shouldRepository:(RMResourceRepository*)repository updateFileAtPath:(NSString*)filePath withModificationDate:(NSDate*)modificationDate;
    
    //if YES,call delegate repository:(RMResourceRepository*)repository requestStoragePathForFileAtPath:(NSString*)filePath;
    //store this path in a set
    
    //if set is not empty, call delegate repository:(RMResourceRepository*)repository didReceiveUpdates:(NSSet*)filePaths;
}

@end
