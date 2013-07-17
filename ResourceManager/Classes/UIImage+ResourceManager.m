//
//  RMImage.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-16.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "UIImage+ResourceManager.h"
#import "RMResourceManager.h"
#import "RMRuntime.h"

@implementation UIImage(ResourceManager)

#pragma mark Resource Path Management

+ (NSString*)imageFilePathWithName:(NSString*)name suffix:(NSString*)suffix extension:(NSString*)extension{
    NSString* resource = [NSString stringWithFormat:@"%@%@",name,suffix];
    
    if(extension && [extension length] > 0){
        NSString* path = [RMResourceManager pathForResource:resource ofType:extension];
        return path;
    }
    
    NSString* path = [RMResourceManager pathForResource:resource ofType:@"png"];
    if(path) return path;
    
    path = [RMResourceManager pathForResource:resource ofType:@"jpeg"];
    return path;
}

+ (NSString*)resoucePathForImageNamed:(NSString*)name{
    NSString* extension = [name pathExtension];
    NSString* imageName = [name stringByDeletingPathExtension];
    
    NSString* filePath = nil;
    if([[UIScreen mainScreen]scale] == 2){
        if([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            filePath = [UIImage imageFilePathWithName:imageName suffix:@"~ipad@2x" extension:extension];
        }else{
            filePath = [UIImage imageFilePathWithName:imageName suffix:@"~iphone@2x" extension:extension];
        }
        
        if(!filePath){
            filePath = [UIImage imageFilePathWithName:imageName suffix:@"@2x" extension:extension];
        }
        
    }
    
    if(!filePath){
        if([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            filePath = [UIImage imageFilePathWithName:imageName suffix:@"~ipad" extension:extension];
        }else{
            filePath = [UIImage imageFilePathWithName:imageName suffix:@"~iphone" extension:extension];
        }
        
        if(!filePath){
            filePath = [UIImage imageFilePathWithName:imageName suffix:@"" extension:extension];
        }
    }
    
    return filePath;
}

#pragma mark UIImage initializers with update

+ (UIImage*)imageNamed:(NSString *)name update:(void(^)(UIImage* image))update{
    return [[[UIImage alloc]initWithImageNamed:name update:update]autorelease];
}

+ (UIImage *)imageWithContentsOfFile:(NSString *)path update:(void(^)(UIImage* image))update{
    return [[[UIImage alloc]initWithContentsOfFile:path update:update]autorelease];
}

- (id)initWithImageNamed:(NSString*)name  update:(void(^)(UIImage* image))update{
    NSString* filePath = [UIImage resoucePathForImageNamed:name];
    return [self initWithContentsOfFile:filePath update:update];
}

- (id)initWithContentsOfFile:(NSString *)path update:(void(^)(UIImage* image))update{
    self = [self initWithContentsOfFile:path];
    [self registerPath:path forUpdate:update];
    return self;
}

#pragma mark Manages update observer

- (void)registerPath:(NSString*)path forUpdate:(void(^)(UIImage* image))update{
    if(!path || !update)
        return;
    
    [UIImage swizzleIfNeeded];
    [RMResourceManager addObserverForPath:path object:self usingBlock:^(id observer, NSString *path) {
        UIImage* image = path ? [UIImage imageWithContentsOfFile:path update:update] : nil;
        update(image);
    }];
}

- (void)rm_dealloc{
    [RMResourceManager removeObserver:self];
    [self rm_dealloc];
}

+ (void)swizzleIfNeeded{
    static BOOL kSwizzled = NO;
    if(!kSwizzled){
        RMSwizzleSelector([UIImage class], @selector(dealloc), @selector(rm_dealloc));
        kSwizzled = YES;
    }
}

@end
