//
//  RMResourceRepository.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-19.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMResourceRepository.h"
#import "RMFileSystem.h"

@interface RMResourceRepository()
@end

@implementation RMResourceRepository

- (void)setDelegate:(id<RMResourceRepositoryDelegate>)delegate{
    if(_delegate != nil){
        [self disconnect];
    }
    
    _delegate = delegate;
    
    if(_delegate != nil){
        [self connect];
    }
}

- (void)handleApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    
}

- (void)handleApplication:(UIApplication *)application openURL:(NSURL *)url{
    
}

- (void)connect{
    
}

- (void)disconnect{
    
}

- (NSString*)relativePathForResourceWithPath:(NSString*)path{
    return [RMFileSystem relativePathForResourceWithPath:path];
}

@end
