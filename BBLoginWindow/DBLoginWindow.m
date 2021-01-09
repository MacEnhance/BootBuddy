//
//  DBLoginWindow.m
//  DBLoginWindow
//
//  Created by Wolfgang Baird on 5/19/18.
//
//

#import "DBLoginWindow.h"
#import "FConvenience.h"
#import <WebKit/WebKit.h>

@interface DBLoginWindow()

@end

@implementation DBLoginWindow

+ (instancetype)sharedInstance {
    static DBLoginWindow *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}

+ (void)redirectLogToDocuments {
     NSArray *allPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
     NSString *documentsDirectory = [allPaths objectAtIndex:0];
     NSString *pathForLog = [documentsDirectory stringByAppendingPathComponent:@"loginWindow.txt"];
     freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

+ (void)load {
    [DBLoginWindow redirectLogToDocuments];
    NSUInteger osx_ver = NSProcessInfo.processInfo.operatingSystemVersion.minorVersion;
    NSLog(@"%@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);
}


@end

ZKSwizzleInterface(wb_LUI2Window, LUI2Window, NSWindow)
@implementation wb_LUI2Window

- (void)getcDock {
    WKWebView *webby = [[WKWebView alloc] initWithFrame:NSMakeRect(self.contentView.frame.size.width - 510, 50, 500, 500)];
    NSURLRequest *requ = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://pay.paddle.com/checkout/520974"]];
    [self.contentView addSubview:webby];
    [webby loadRequest:requ];
}

-(void)_setupContentView {
    ZKOrig(void);
    
    NSString *picturePath;
    for (NSString *ext in @[@"jpg", @"png", @"gif"])
        if ([FileManager fileExistsAtPath:[db_LockFile stringByAppendingPathExtension:ext]])
            picturePath = [db_LockFile stringByAppendingPathExtension:ext];
    
    NSImage *theImage = [NSImage.alloc initWithContentsOfFile:picturePath];
    
    for (NSWindow *window in NSApp.windows) {
        NSWindow *destination = window;
        
        // Check if our view exists
        NSImageView *view = NSImageView.alloc;
        Boolean needsView = true;
        for (NSView *v in destination.contentView.subviews) {
            if (v.tag == 6969) {
                needsView = false;
                view = (NSImageView*)v;
            }
        }

        if (picturePath) {
            // Add our view
            if (needsView) {
                [theImage setSize:destination.contentView.frame.size];

                view = [NSImageView.alloc initWithFrame:destination.contentView.frame];
                view.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
                view.image = theImage;
                view.tag = 6969;
                view.wantsLayer = YES;
                view.canDrawSubviewsIntoLayer = YES;
                view.animates = YES;
                [self.contentView addSubview:view positioned:NSWindowBelow relativeTo:destination.contentView.subviews.firstObject];

                NSButton *adButton = [NSButton.alloc initWithFrame:NSMakeRect(destination.contentView.frame.size.width - 160, 10, 150, 22)];
                [adButton setTitle:@"Get cDock"];
                [adButton setBezelStyle:NSTexturedRoundedBezelStyle];
                [adButton setTarget:self];
                [adButton setAction:@selector(getcDock)];
                [self.contentView addSubview:adButton];
            }
        }
    }
}

@end


//ZKSwizzleInterface(wb_LUIGoodSamaritanMessageView, LUIGoodSamaritanMessageView, NSView)
//@implementation wb_LUIGoodSamaritanMessageView
//
//- (id)_fontOfSize:(double)arg1 {
//    NSLog(@"kaydog %hhd", db_EnableSize);
//    if (db_EnableSize) {
//        double lockSize = [db_LockSize doubleValue];
////        NSLog(@"kaydog %f", lockSize);
//        if (lockSize < 0.0 || lockSize > 64.0)
//            return ZKOrig(id, arg1);
//        return ZKOrig(id, lockSize);
//    }
//    return ZKOrig(id, arg1);
//}
//
//- (void)setMessage:(id)arg1 {
//    NSLog(@"kaydog %hhd", db_EnableText);
//    if (db_EnableText) {
//        NSString* lockText = db_LockText;
////        NSLog(@"kaydog %@", lockText);
//        if ([lockText isEqualToString:@""])
//            lockText = @"🍣";
//        ZKOrig(void, lockText);
//    } else {
//        ZKOrig(void, arg1);
//    }
//}
//
//@end
