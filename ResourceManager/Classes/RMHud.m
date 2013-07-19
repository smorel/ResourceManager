//
//  RMHud.m
//  ResourceManager
//
//  Created by Sebastien Morel on 2013-07-17.
//  Copyright (c) 2013 Sebastien Morel. All rights reserved.
//

#import "RMHud.h"
#import "RMFileSystem.h"


@interface RMHud()
@property (nonatomic, retain) RMFileSystem* fileSystem;
@property (nonatomic, retain) UIView* view;
@property (nonatomic, retain) UILabel* infoLabel;
@property (nonatomic, retain) NSString* userTitle;
@end

@implementation RMHud

- (id)initWithFileSystem:(RMFileSystem*)fileSystem{
    self = [super init];
    
    self.fileSystem = fileSystem;
    
  //  [fileSystem addObserver:self forKeyPath:@"currentState" options:NSKeyValueObservingOptionNew context:nil];
    
    [self update];
    
    return self;
}

- (void)dealloc{
   // [self.fileSystem removeObserver:self forKeyPath:@"currentState" context:nil];
}

/*
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    [self update];
}
 */

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

- (void)updateTitle:(NSString*)title{
    
    if(!self.view){
        [self createView];
    }
    
    if(title){
        #ifdef DEBUG
        NSLog(@"%@",title);
        #endif
    }
    
    UIViewController* root = [[[[UIApplication sharedApplication]windows]objectAtIndex:0]rootViewController];
    NSAssert(root,@"Your application's main window has no root view controller.");
    
    UIView* parentView = root.view;
    
    self.infoLabel.text = title;
    
    self.view.hidden = (self.infoLabel.text == nil);
    [self.infoLabel sizeToFit];
    self.view.frame = CGRectMake((parentView.bounds.size.width / 2) - ((self.infoLabel.bounds.size.width + 20) / 2),
                                 0, self.infoLabel.bounds.size.width + 20, self.infoLabel.bounds.size.height + 20);
    self.infoLabel.frame = self.view.bounds;
    
    [parentView addSubview:self.view];
}

- (void)setTitle:(NSString*)title{
    self.userTitle = title;
    [self updateTitle:title];
}

- (void)setTitleFromFileSystemUpdate:(NSString*)title{
    if(self.userTitle != nil)
        return;
    
    [self updateTitle:title];
}
     
- (void)update{
   /* switch(self.fileSystem.currentState){
        case RMFileSystemStateIdle:{
            NSLog(@"IDLE...");
            [self setTitleFromFileSystemUpdate:nil];
            break;
        }
        case RMFileSystemStateDownloading:
        {
            NSString* text = nil;
            if(self.fileSystem.pendingDowloads.count == 1){
                text = [NSString stringWithFormat:@"Downloading '%@'",[[[self.fileSystem.pendingDowloads objectAtIndex:0]path]lastPathComponent]];
            }else{
                text = [NSString stringWithFormat:@"Downloading %d files", self.fileSystem.pendingDowloads.count];
            }
            [self setTitleFromFileSystemUpdate:text];
            break;
        }
        case RMFileSystemStatePulling:
        {
            NSLog(@"Pulling...");
            [self setTitleFromFileSystemUpdate:nil];
            break;
        }
        case RMFileSystemStateLoadingAccount:
        {
            [self setTitleFromFileSystemUpdate:@"Loading Account..."];
            break;
        }
        case RMFileSystemStateNotifying:
        {
            [self setTitleFromFileSystemUpdate:@"Updating Application..."];
            break;
        }
    }
    */
}

- (void)disappear{
    [self.view removeFromSuperview];
}

@end
