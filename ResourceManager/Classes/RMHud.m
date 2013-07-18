//
//  RMHud.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-17.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMHud.h"
#import "RMFileSystem.h"
#import "RMPermissions.h"

//private implementations

@interface RMFileSystem()

@property (nonatomic, retain) DBRestClient* dbClient;

@property (nonatomic, retain) NSMutableArray* dropboxResourcesMetadata;
@property (nonatomic, retain) NSString* rootFolder;
@property (nonatomic, assign) NSInteger metaDataRequestCount;

@property (nonatomic, retain) NSMutableArray* removeFromCacheList;
@property (nonatomic, retain) NSArray* pendingDowloads;
@property (nonatomic, assign) NSInteger pendingDownloadCount;

@property (nonatomic, retain) RMPermissions* permissions;

@property (nonatomic, assign, readwrite) RMFileSystemState currentState;

@end


@interface RMHud()
@property (nonatomic, retain) RMFileSystem* fileSystem;
@property (nonatomic, retain) UIView* view;
@property (nonatomic, retain) UILabel* infoLabel;
@end

@implementation RMHud

- (id)initWithFileSystem:(RMFileSystem*)fileSystem{
    self = [super init];
    
    self.fileSystem = fileSystem;
    
    [fileSystem addObserver:self forKeyPath:@"currentState" options:NSKeyValueObservingOptionNew context:nil];
    
    [self update];
    
    return self;
}

- (void)dealloc{
    [self.fileSystem removeObserver:self forKeyPath:@"currentState" context:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    [self update];
}

- (void)createView{
    self.view = [[UIView alloc]initWithFrame:CGRectMake(0,0,10,10)];
    self.infoLabel = [[UILabel alloc]initWithFrame:self.view.frame];
    self.infoLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.infoLabel];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.infoLabel.backgroundColor = [UIColor blackColor];
    self.infoLabel.textColor = [UIColor whiteColor];
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
}
     
- (void)update{
    if(!self.view){
        [self createView];
    }
    
    UIViewController* root = [[[[UIApplication sharedApplication]windows]objectAtIndex:0]rootViewController];
    NSAssert(root,@"Your application's main window has no root view controller.");
    
    UIView* parentView = root.view;
    self.view.hidden = NO;
    
    switch(self.fileSystem.currentState){
        case RMFileSystemStateIdle:{ break; }
        case RMFileSystemStateDownloading:
        {
            NSString* text = nil;
            if(self.fileSystem.pendingDowloads.count == 1){
                text = [NSString stringWithFormat:@"Downloading '%@'",[[[self.fileSystem.pendingDowloads objectAtIndex:0]path]lastPathComponent]];
            }else{
                text = [NSString stringWithFormat:@"Downloading %d files", self.fileSystem.pendingDowloads.count];
            }
            self.infoLabel.text = text;
            break;
        }
        case RMFileSystemStatePulling:
        {
            self.infoLabel.text = nil;//@"Pulling...";
            break;
        }
        case RMFileSystemStateLoadingAccount:
        {
            self.infoLabel.text = @"Loading Account...";
            break;
        }
        case RMFileSystemStateNotifying:
        {
            self.infoLabel.text = @"Updating Application...";
            break;
        }
    }
    
    self.view.hidden = (self.fileSystem.currentState == RMFileSystemStateIdle) || (self.infoLabel.text == nil);
    [self.infoLabel sizeToFit];
    self.view.frame = CGRectMake((parentView.bounds.size.width / 2) - ((self.infoLabel.bounds.size.width + 20) / 2),
                                 0, self.infoLabel.bounds.size.width + 20, self.infoLabel.bounds.size.height + 20);
    self.infoLabel.frame = self.view.bounds;
    
    [parentView addSubview:self.view];
}

- (void)disappear{
    [self.view removeFromSuperview];
}

@end
