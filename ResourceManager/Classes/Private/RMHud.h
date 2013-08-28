//
//  RMHud.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-17.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RMResourceRepository;

@interface RMHud : NSObject

- (void)setTitle:(NSString*)title;
- (void)disappear;

- (void)repository:(RMResourceRepository*)repository didNotifyHudWithMessage:(NSString*)message;

@end
