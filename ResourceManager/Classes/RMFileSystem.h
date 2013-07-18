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

typedef enum RMFileSystemState{
    RMFileSystemStateIdle,
    RMFileSystemStateLoadingAccount,
    RMFileSystemStatePulling,
    RMFileSystemStateDownloading,
    RMFileSystemStateNotifying
}RMFileSystemState;

@interface RMFileSystem : NSObject

@property (nonatomic, assign, readonly) RMFileSystemState currentState;
@property (nonatomic, assign) NSTimeInterval pullingTimeInterval;

- (id)initWithDropboxFolder:(NSString*)folder;

- (void)start;

/** This will return the path of the most recent file between the specified application file and the potentially downloaded file from dropbox.
 */
- (NSString*)pathForResourceAtPath:(NSString*)applicationBundlePath;

/** This will return the path of the file from dropbox that matches name ext subpath localizationName.
 */
- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext forLocalization:(NSString *)localizationName;

/** Returns the most recent paths between local cache and application bundle for files with the specified extension and the specified localization
 */
- (NSArray *)pathsForResourcesWithExtension:(NSString *)ext localization:(NSString *)localizationName;

- (NSString*) relativePathForPath:(NSString*)path;

@end
