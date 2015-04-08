//
//  RMPeerDeamonBundle.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2015-04-07.
//  Copyright (c) 2015 Sebastien Morel. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RMPeerDeamonBundleDelegate

- (void)didCatchUpdateForFilesAtPath:(NSArray*)filePaths;

@end

@interface RMPeerDeamonBundle : NSObject

- (id)initWithDirectories:(NSArray*)directories delegate:(id<RMPeerDeamonBundleDelegate>)delegate;
- (void)pull;

@end
