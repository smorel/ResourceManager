//
//  RMPeerDeamon.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2015-04-07.
//  Copyright (c) 2015 Sebastien Morel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RMPeerDeamon : NSObject

- (id)initWithDirectories:(NSArray*)directories;
- (void)start;

@end
