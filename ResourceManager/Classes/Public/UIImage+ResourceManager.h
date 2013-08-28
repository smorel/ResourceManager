//
//  RMImage.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-16.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 */
@interface UIImage(ResourceManager)

/**
 */
+ (NSString*)resoucePathForImageNamed:(NSString*)name;

/**
 */
+ (UIImage*)imageNamed:(NSString *)name update:(void(^)(UIImage* image))update;

/**
 */
+ (UIImage*)imageWithContentsOfFile:(NSString *)path update:(void(^)(UIImage* image))update;

/**
 */
- (id)initWithImageNamed:(NSString*)name update:(void(^)(UIImage* image))update;

/**
 */
- (id)initWithContentsOfFile:(NSString *)path update:(void(^)(UIImage* image))update;

@end
