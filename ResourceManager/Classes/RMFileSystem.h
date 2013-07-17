//
//  RMFileSystem.h
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-16.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <DropboxSDK/DropboxSDK.h>

@interface RMFileSystem : NSObject

@property (nonatomic, assign) NSTimeInterval pullingTimeInterval;

- (id)initWithDropboxFolder:(NSString*)folder;

/** This will return the path of the most recent file between the specified application file and the potentially downloaded file from dropbox.
 */
- (NSString*)pathForResourceAtPath:(NSString*)applicationBundlePath;

/** This will return the path of the file from dropbox that matches name ext subpath localizationName.
 */
- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext forLocalization:(NSString *)localizationName;

@end
