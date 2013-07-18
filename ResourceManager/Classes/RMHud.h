//
//  RMHud.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-17.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RMFileSystem;

@interface RMHud : NSObject

- (id)initWithFileSystem:(RMFileSystem*)fileSystem;
- (void)setTitle:(NSString*)title;
- (void)disappear;

@end
