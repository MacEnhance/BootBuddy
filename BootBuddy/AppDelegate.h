//
//  AppDelegate.h
//  BootBuddy
//
//  Created by Wolfgang Baird on 8/8/20.
//

@import Sparkle;

#import <Cocoa/Cocoa.h>
#import <Security/Security.h>
#import <Collaboration/Collaboration.h>

#include <sys/stat.h>
#include <unistd.h>
#include <sys/mount.h>

#import "AYProgressIndicator.h"
#import "MECore.h"
#import "FConvenience.h"
#import "BXBootImageView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    // Application views
    IBOutlet NSWindow               *mainWindow;
    IBOutlet NSView                 *tabMain;
    IBOutlet NSView                 *tabBootColor;
    IBOutlet NSView                 *tabBootImage;
    IBOutlet NSView                 *tabBootOptions;
    IBOutlet NSView                 *tabLoginScreen;
    IBOutlet NSView                 *tabLockScreen;
    IBOutlet NSView                 *tabMacForge;
    
    // MacForge view
    IBOutlet NSTextView             *mfWarningText;
    
    // About view
    IBOutlet NSTextField            *appName;
    IBOutlet NSTextField            *appVersion;
    IBOutlet NSTextField            *appCopyright;
    IBOutlet NSTextView             *changeLog;
    IBOutlet NSImageView            *aboutGif;

    // Boot Color
    IBOutlet NSColorWell            *bootColorView;
    IBOutlet NSSegmentedControl     *bootColorControl;
    IBOutlet AYProgressIndicator    *bootColorIndicator;
    IBOutlet NSImageView            *bootColorApple;
    IBOutlet NSProgressIndicator    *bootColorProgress;
    NSColor                         *bootCustomColor;
    
    // Boot options
    IBOutlet NSButton               *bootAuto;
    IBOutlet NSButton               *bootAudio;
    IBOutlet NSButton               *bootSafe;
    IBOutlet NSButton               *bootVerbose;
    IBOutlet NSButton               *bootCamshell;
    IBOutlet NSButton               *bootSingle;
    IBOutlet NSButton               *bootRecovery;

    // Login screen
    IBOutlet BXBootImageView        *loginImageView;
    IBOutlet NSImageView            *loginUserIcon;
    
    // Lock screen
    IBOutlet BXBootImageView        *lockImageView;
    IBOutlet NSButton               *lockTextCustomSize;
    IBOutlet NSButton               *lockTextCustomText;
    IBOutlet NSSlider               *lockTextSlider;
    IBOutlet NSTextField            *lockTextText;
    IBOutlet NSImageView            *lockUserIcon;
    
    // ?
    IBOutlet NSButton               *sellogin;
    IBOutlet NSButton               *sellock;

    NSUInteger                      hashVal;
    NSUInteger                      osx_ver;
    AuthorizationRef                auth;
    NSURL                           *lockImagePath;
}

@property IBOutlet SUUpdater            *sparkleUpdater;
@property IBOutlet MECore               *sidebarController;
@property IBOutlet NSSegmentedControl   *aboutSelector;

// Windows
@property IBOutlet NSWindow             *windowPreferences;
@property IBOutlet NSWindow             *infoWindow;


// Preferences
@property IBOutlet NSSegmentedControl   *preferencesTabController;
@property IBOutlet NSView               *preferencesGeneral;
@property IBOutlet NSView               *preferencesAbout;
@property IBOutlet NSView               *preferencesData;

// Top sidebar items
@property IBOutlet MECoreSBButton     *sidebarBootColor;
@property IBOutlet MECoreSBButton     *sidebarBootOptions;
@property IBOutlet MECoreSBButton     *sidebarLoginScreen;
@property IBOutlet MECoreSBButton     *sidebarLockScreen;

// Bottom sidebar items
@property IBOutlet MECoreSBButton     *sidebarDiscord;

- (NSColor*)currentBackgroundColor;
- (NSColor*)currentBootColor;
- (NSColor*)defaultBootColor;
- (IBAction)clearBootColor:(id)sender;
- (void)dirCheck:(NSString *)directory;
- (NSImage*)imageFromCGImageRef:(CGImageRef)image;
- (BOOL)authorize;
- (void)deauthorize;

@end

