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

+ (void)initResourceManagement{
    RMSwizzleSelector([UIImage class], @selector(initWithContentsOfFile:), @selector(rm_initWithContentsOfFile:));
    RMSwizzleClassSelector([UIImage class], @selector(imageNamed:), @selector(rm_imageNamed:));
}

- (id)rm_initWithContentsOfFile:(NSString *)path{
    //register for updates here
    
    return [self rm_initWithContentsOfFile:path];
}

+ (NSURL*)urlForImageWithName:(NSString*)name{
    NSURL *imageURL = [[NSBundle mainBundle] URLForResource:[name stringByDeletingPathExtension] withExtension:[name pathExtension]];
    if (!imageURL)
        imageURL = [[NSBundle mainBundle] URLForResource:[name stringByDeletingPathExtension] withExtension:@"png"];
    if (!imageURL)
        imageURL = [[NSBundle mainBundle] URLForResource:[name stringByDeletingPathExtension] withExtension:nil];
    
    return imageURL;
}

+ (NSString*)imageFilePathWithName:(NSString*)name suffix:(NSString*)suffix extension:(NSString*)extension{
    NSString* resource = [NSString stringWithFormat:@"%@%@",name,suffix];
    
    if(extension && [extension length] > 0){
        NSString* path = [[RMResourceManager sharedManager]pathForResource:resource ofType:extension];
        return path;
    }
    
    NSString* path = [[RMResourceManager sharedManager]pathForResource:resource ofType:@"png"];
    if(path) return path;
    
    path = [[RMResourceManager sharedManager]pathForResource:resource ofType:@"jpeg"];
    return path;
}

+ (UIImage*)rm_imageNamed:(NSString *)name{
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
            filePath = [self imageFilePathWithName:imageName suffix:@"@2x" extension:extension];
        }
        
    }
    
    if(!filePath){
        if([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            filePath = [UIImage imageFilePathWithName:imageName suffix:@"~ipad" extension:extension];
        }else{
            filePath = [UIImage imageFilePathWithName:imageName suffix:@"~iphone" extension:extension];
        }
        
        if(!filePath){
            filePath = [self imageFilePathWithName:imageName suffix:@"" extension:extension];
        }
    }
    
    if(!filePath)
        return nil;
    
    return [UIImage imageWithContentsOfFile:filePath];
}

@end
