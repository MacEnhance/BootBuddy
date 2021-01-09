//
//  AppDelegate.m
//  BootBuddy
//
//  Created by Wolfgang Baird on 8/8/20.
//

#import "AppDelegate.h"

@import AppKit;
@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;
@import LetsMove;
@import CocoaMarkdown;

@import CoreImage;
@import CoreGraphics;
@import MachO;

static NSString *path_bootColorPlist    = @"/Library/LaunchDaemons/com.macenhance.bbcolor.plist";
static NSString *path_loginImage        = @"/Library/Caches/com.apple.desktop.admin.png";

NSArray *tabViewButtons;
Boolean animateBootColor = true;

@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (NSString*)runCommand:(NSString*)command {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    NSArray *arguments = [NSArray arrayWithObjects:@"-c", [NSString stringWithFormat:@"%@", command], nil];
    [task setArguments:arguments];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    lockImagePath = nil;
    osx_ver = MECore.sharedInstance.macOS;
    
    [MSACAppCenter start:@"a431c4c1-9085-4363-a7b9-4c051f2d8abe" withServices:@[
      [MSACAnalytics class],
      [MSACCrashes class]
    ]];
    
    [self dirCheck:db_Folder];
    
    // Mojave or greater
    if (osx_ver > 13) {
        path_loginImage = [self runCommand:@"find /Library/Caches/Desktop\\ Pictures -name lockscreen.png"];
        path_loginImage = [path_loginImage stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
                
    if ([db_LockSize doubleValue] > 0) {
        [lockTextSlider setDoubleValue:[db_LockSize doubleValue]];
        [self lockTextSlider:lockTextSlider];
    } else {
        [lockTextSlider setDoubleValue:8];
    }
    
    if (db_LockText) {
        [lockTextText setStringValue:db_LockText];
    } else {
        [lockTextText setStringValue:@"🍣"];
    }
    
    [self showCurrentLock:self];
    [self showCurrentLogin:self];
    
    lockUserIcon.image = [CBIdentity identityWithName:NSUserName() authority:[CBIdentityAuthority defaultIdentityAuthority]].image;
    lockUserIcon.wantsLayer = YES;
    lockUserIcon.layer.cornerRadius = lockUserIcon.layer.frame.size.height/2;
    lockUserIcon.layer.masksToBounds = YES;
    lockUserIcon.animates = YES;
    
    loginUserIcon.image = [CBIdentity identityWithName:NSUserName() authority:[CBIdentityAuthority defaultIdentityAuthority]].image;
    loginUserIcon.wantsLayer = YES;
    loginUserIcon.layer.cornerRadius = loginUserIcon.layer.frame.size.height/2;
    loginUserIcon.layer.masksToBounds = YES;
    loginUserIcon.animates = YES;
    
    [lockTextCustomSize setState:db_EnableSize];
    [lockTextCustomText setState:db_EnableText];

    [mainWindow setMovableByWindowBackground:YES];
    [mainWindow setTitle:@""];
    
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    [appName setStringValue:[infoDict objectForKey:@"CFBundleExecutable"]];
    [appVersion setStringValue:[NSString stringWithFormat:@"Version %@ (%@)",
                                 [infoDict objectForKey:@"CFBundleShortVersionString"],
                                 [infoDict objectForKey:@"CFBundleVersion"]]];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    NSInteger year = [components year];

    [appCopyright setStringValue:[NSString stringWithFormat:@"Copyright © 2015 - %ld macEnhance", (long)year]];
    
    NSString *path = [[[NSBundle mainBundle] URLForResource:@"CHANGELOG" withExtension:@"md"] path];
    CMDocument *cmd = [[CMDocument alloc] initWithContentsOfFile:path options:CMDocumentOptionsNormalize];
    CMAttributedStringRenderer *asr = [[CMAttributedStringRenderer alloc] initWithDocument:cmd attributes:[[CMTextAttributes alloc] init]];
    [changeLog.textStorage setAttributedString:asr.render];
    
    Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
    if (vibrantClass) {
        NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:[[mainWindow contentView] bounds]];
        [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
        [[mainWindow contentView] addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
    } else {
        [mainWindow setBackgroundColor:[NSColor whiteColor]];
    }
    
    // Sidebar
    _sidebarController = MECore.new;
    _sidebarController.mainWindow = mainWindow;
    _sidebarController.mainView = tabMain;
    _sidebarController.prefWindow = _windowPreferences;
    _sidebarController.changeLog = changeLog;
    _sidebarController.preferenceViews = @[_preferencesGeneral, _preferencesAbout];
    _sidebarController.sidebarTopButtons = @[_sidebarBootColor, _sidebarBootOptions, _sidebarLoginScreen, _sidebarLockScreen];
    _sidebarController.sidebarBotButtons = @[_sidebarDiscord];
    
    [_aboutSelector setTarget:_sidebarController];
    [_aboutSelector setAction:@selector(selectAboutInfo:)];

    [_preferencesTabController setTarget:_sidebarController];
    [_preferencesTabController setAction:@selector(selectPreference:)];
    
    [_sidebarDiscord.buttonClickArea setImage:[[NSImage alloc] initByReferencingURL:[NSURL URLWithString:@"https://discordapp.com/api/guilds/608740492561219617/widget.png?style=banner2"]]];
    [_sidebarDiscord.buttonClickArea setImageScaling:NSImageScaleAxesIndependently];
    [_sidebarDiscord.buttonClickArea setAutoresizingMask:NSViewMaxYMargin];
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"prefHideDiscord"])
        [_sidebarDiscord.buttonClickArea setEnabled:false];
    
    [_sidebarController setupSidebar];
    [_sidebarController selectView:_sidebarBootColor];
    [_sidebarController selectAboutInfo:nil];
    // Sidebar
    
    
    [bootColorProgress setHidden:true];
    bootColorIndicator = [[AYProgressIndicator alloc] initWithFrame:CGRectMake(bootColorProgress.frame.origin.x, bootColorProgress.frame.origin.y, bootColorProgress.frame.size.width, bootColorProgress.frame.size.height / 4)
                                                      progressColor:[NSColor whiteColor]
                                                         emptyColor:[NSColor blackColor]
                                                           minValue:0
                                                           maxValue:100
                                                       currentValue:0];
    [bootColorIndicator setDoubleValue:33];
    [bootColorIndicator setEmptyColor:[NSColor whiteColor]];
    [bootColorIndicator setProgressColor:[NSColor blackColor]];
    [bootColorIndicator setHidden:NO];
    [bootColorIndicator setWantsLayer:YES];
    [bootColorIndicator.layer setCornerRadius:bootColorIndicator.frame.size.height/2];
    [tabBootColor addSubview:bootColorIndicator];

    NSColor *bk = [self currentBackgroundColor];
    if (![bk isEqual:NSColor.clearColor]) {
        NSString *bgs = [self currentBackgroundString];
        if ([bgs isEqualToString:@"4d1ede05-38c7-4a6a-9cc6-4bcca8b38c14:DefaultBackgroundColor=%00%00%00"]) {
            [bootColorControl setSelectedSegment:1];
        } else if ([bgs isEqualToString:@"4d1ede05-38c7-4a6a-9cc6-4bcca8b38c14:DefaultBackgroundColor=%99%99%99"]) {
            [bootColorControl setSelectedSegment:2];
        } else {
            [bootColorControl setSelectedSegment:3];
        }
        [bootColorView setColor:bk];
    } else {
        [bootColorView setColor:[NSColor grayColor]];
        [bootColorControl setSelectedSegment:0];
    }
    
    [aboutGif setImage:[NSImage.alloc initWithContentsOfURL:[NSURL URLWithString:@"https://media.giphy.com/media/3owypd1qwsPZVR5X5m/source.gif"]]];
    
    [self updateBootColorPreview];
    [self getBootOptions];
    
    [self bootPreviewAnimate];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:_sidebarController selector:@selector(systemDarkModeChange:) name:@"AppleInterfaceThemeChangedNotification" object:nil];
    PFMoveToApplicationsFolderIfNecessary();
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [self deauthorize];
    return NSTerminateNow;
}

- (IBAction)resetSidebar:(id)sender {
    [_sidebarDiscord.buttonClickArea setEnabled:![NSUserDefaults.standardUserDefaults boolForKey:@"prefHideDiscord"]];
    [_sidebarController setupSidebar];
}

- (NSString *)currentBackgroundString {
    NSString* result = nil;
    if ([FileManager fileExistsAtPath:path_bootColorPlist]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path_bootColorPlist];
        NSArray* args = [dict objectForKey:@"ProgramArguments"];
        result = [args objectAtIndex:1];
    }
    return result;
}

- (NSColor *)currentBackgroundColor {
    NSColor* result = NSColor.clearColor;
    if ([FileManager fileExistsAtPath:path_bootColorPlist]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path_bootColorPlist];
        NSArray* args = [dict objectForKey:@"ProgramArguments"];
        if (args.count > 1) {
            NSString* color = [args objectAtIndex:1];
            NSArray* foo = [color componentsSeparatedByString: @"%"];
            long b = strtol([[foo objectAtIndex: 1] UTF8String], NULL, 16); // r
            long g = strtol([[foo objectAtIndex: 2] UTF8String], NULL, 16);
            long r = strtol([[foo objectAtIndex: 3] UTF8String], NULL, 16); // b
            result = [NSColor colorWithDeviceRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
        }
    }
    return result;
}

- (NSColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:0]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
//    return [NSColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    return [NSColor colorWithRed:(rgbValue & 0xFF)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:((rgbValue & 0xFF0000) >> 16)/255.0 alpha:1.0];
}

- (NSString *)hexStringForColor:(NSColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    CGFloat b = components[0]; //r
    CGFloat g = components[1];
    CGFloat r = components[2]; //b
    NSString *hexString=[NSString stringWithFormat:@"%%%02X%%%02X%%%02X", (int)(r * 255), (int)(g * 255), (int)(b * 255)];
    return hexString;
}

- (void)runAuthorization:(char*)tool :(char**)args {
    FILE *pipe = NULL;
    AuthorizationExecuteWithPrivileges(auth, tool, kAuthorizationFlagDefaults, args, &pipe);
}

- (NSImage*)imageFromCGImageRef:(CGImageRef)image {
    NSRect imageRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
    CGContextRef imageContext = nil;
    NSImage* newImage = nil; // Get the image dimensions.
    imageRect.size.height = CGImageGetHeight(image);
    imageRect.size.width = CGImageGetWidth(image);
    
    // Create a new image to receive the Quartz image data.
    newImage = [[NSImage alloc] initWithSize:imageRect.size];
    [newImage lockFocus];
    
    // Get the Quartz context and draw.
    imageContext = (CGContextRef)[[NSGraphicsContext currentContext] CGContext];
    CGContextDrawImage(imageContext, *(CGRect*)&imageRect, image); [newImage unlockFocus];
    return newImage;
}

- (Boolean)colorCompare:(NSColor*)a :(NSColor*)b {
    int similarities = 0;
    Boolean result = false;
    NSColor *normalizedA =  a;
    NSColor *normalizedB =  b;
    
    if (normalizedA.redComponent * 255 > normalizedB.redComponent * 255 - 10 && normalizedA.redComponent * 255 < normalizedB.redComponent * 255 + 10)
        similarities++;
    
    if (normalizedA.greenComponent * 255 > normalizedB.greenComponent * 255 - 10 && normalizedA.greenComponent * 255 < normalizedB.greenComponent * 255 + 10)
        similarities++;
    
    if (normalizedA.blueComponent * 255 > normalizedB.blueComponent * 255 - 10 && normalizedA.blueComponent * 255 < normalizedB.blueComponent * 255 + 10)
        similarities++;
    
    if (similarities >= 3)
        result = true;
    
    return result;
}

- (NSImage *)imageTintedWithColor:(NSImage *)img :(NSColor *)tint {
    NSImage *image = [img copy];
    if (tint) {
        [image lockFocus];
        [tint set];
        NSRect imageRect = {NSZeroPoint, [image size]};
        NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceAtop);
        [image unlockFocus];
    }
    return image;
}

- (BOOL)authorize {
    if (auth) return YES;
    AuthorizationItem item = { kAuthorizationRightExecute, 0, NULL, 0 };
    AuthorizationRights rights = { 1, &item };
    AuthorizationFlags flags = kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights | kAuthorizationFlagPreAuthorize;
    return AuthorizationCreate(&rights, kAuthorizationEmptyEnvironment, flags, &auth);
}

- (void)deauthorize {
    if (auth) {
        AuthorizationFree(auth, kAuthorizationFlagDefaults);
        auth = NULL;
    }
}

- (IBAction)showAbout:(id)sender {
    [_preferencesTabController setSelectedSegment:_preferencesTabController.segmentCount - 1];
    [_sidebarController selectPreference:_preferencesTabController];
}

- (IBAction)showPreferences:(id)sender {
    [_sidebarController selectPreference:_preferencesTabController];
}

- (IBAction)selectImage:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseFiles:YES];
    
    if ([sender isEqual:sellogin])
        [openDlg setAllowedFileTypes:@[@"png", @"jpg"]];
    if ([sender isEqual:sellock])
        [openDlg setAllowedFileTypes:@[@"png", @"jpg", @"gif"]];

    [openDlg beginWithCompletionHandler:^(NSInteger result) {
        if(result==NSModalResponseOK) {
            NSImage * aimage = [[NSImage alloc] initWithContentsOfURL:[openDlg.URLs objectAtIndex:0]];
            if ([sender isEqual:self->sellogin])
                [self->loginImageView setImage:aimage];
            if ([sender isEqual:self->sellock]) {
                [self->lockImageView setImage:aimage];
                self->lockImageView.path = openDlg.URLs.firstObject.path;
            }
        }
    }];
}

- (void)dirCheck:(NSString *)directory {
    BOOL isDir;
    if(![FileManager fileExistsAtPath:directory isDirectory:&isDir])
        if(![FileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Dark Boot : Error : Create folder failed %@", directory);
}

- (IBAction)aboutIssue:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/macenhance/bootbuddy/issues/new"]];
}

- (IBAction)aboutDonate:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://goo.gl/DSyEFR"]];
}

- (IBAction)aboutEmail:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:support@macenhance.com"]];
}
    
- (IBAction)visitDiscord:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://discord.gg/zjCHuew"]];
}

- (IBAction)showHelp:(NSButton*)sender {
        
    NSRect frm      = mainWindow.frame;
    NSRect myfrm    = _infoWindow.frame;
    [_infoWindow setFrameOrigin:CGPointMake(frm.origin.x + frm.size.width - myfrm.size.width,
                                            frm.origin.y + frm.size.height / 2 - myfrm.size.height / 2)];
    
    // Focus the window
    [_infoWindow setIsVisible:true];
    [_infoWindow makeKeyWindow];
    [_infoWindow makeKeyAndOrderFront:self];
    [mainWindow addChildWindow:_infoWindow ordered:NSWindowBelow];
    [_infoWindow display];
    
    NSWindow *window = _infoWindow;
    [window setStyleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskTitled | NSWindowStyleMaskFullSizeContentView];
    [window setTitlebarAppearsTransparent:YES];
    [window setTitleVisibility:NSWindowTitleHidden];
    [window setShowsToolbarButton:NO];
    [window standardWindowButton:NSWindowMiniaturizeButton].hidden = YES;
    [window standardWindowButton:NSWindowCloseButton].hidden = NO;
    [window standardWindowButton:NSWindowZoomButton].hidden = YES;
    [window makeKeyWindow];
    
    _infoWindow.contentView.wantsLayer = true;
    _infoWindow.contentView.layer.cornerRadius = 10;
    _infoWindow.contentView.layer.masksToBounds   = YES;
    
    float X = _infoWindow.frame.size.width;

    NSRect frame = [window frame];

    frame.origin.x += X;
//    frame.size.height += Y;
//    frame.size.width += X;

    NSDictionary *windowResize = @{
        NSViewAnimationTargetKey: _infoWindow,
        NSViewAnimationEndFrameKey: [NSValue valueWithRect:frame]
    };
    NSDictionary *oldFadeOut = @{
        NSViewAnimationTargetKey: [NSNull null],
        NSViewAnimationEffectKey: NSViewAnimationFadeOutEffect
    };
    NSDictionary *newFadeIn = @{
        NSViewAnimationTargetKey: [NSNull null],
        NSViewAnimationEffectKey: NSViewAnimationFadeInEffect
    };

    NSArray *animations = @[windowResize, newFadeIn, oldFadeOut];
    NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations: animations];

    [animation setAnimationBlockingMode: NSAnimationBlocking];
    [animation setAnimationCurve: NSAnimationEaseIn];
    [animation setDuration:0.5];
    [animation startAnimation];
}












// BOOT COLOR

- (NSColor *)defaultBootColor {
    return [NSColor colorWithDeviceRed:191.0/255.0 green:191.0/255.0 blue:191.0/255.0 alpha:1.0];
}

- (void)updateBootColorPreview {
    NSColor *activeColor = nil;
    if (bootColorControl.selectedSegment == 0)
        activeColor = [self defaultBootColor];
    
    if (bootColorControl.selectedSegment == 1)
        activeColor = NSColor.blackColor;
    
    if (bootColorControl.selectedSegment == 2)
        activeColor = NSColor.grayColor;
    
    if (bootColorControl.selectedSegment == 3)
        activeColor = [self currentBootColor];
        
    [bootColorView setColor:activeColor];
    [self cleanupBootColorView:nil];
}

- (NSColor *)currentBootColor {
    NSDictionary *bootPlist = [NSDictionary dictionaryWithContentsOfFile:path_bootColorPlist];
    NSArray *args;
    NSString *hex;
    NSColor *res = NSColor.clearColor;
    if (bootPlist) {
        args = [bootPlist valueForKey:@"ProgramArguments"];
        hex = args.lastObject;
        if (hex.length > 60) {
            hex = [hex substringFromIndex:60];
            hex = [hex stringByReplacingOccurrencesOfString:@"%" withString:@""];
            res = [self colorFromHexString:hex];
        }
        return res;
    } else {
        return [self defaultBootColor];
    }
}

- (void)setBootColor:(NSString*)colorString {
    [self authorize];
    
    NSString* BXPlist = [[NSBundle mainBundle] pathForResource:@"com.macenhance.bbcolor" ofType:@"plist"];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:BXPlist];
    NSMutableArray* bargs = [dict objectForKey:@"ProgramArguments"];
    [bargs setObject:colorString atIndexedSubscript:1];
    [dict setObject:bargs forKey:@"ProgramArguments"];
    [dict writeToFile:@"/tmp/BXplist.plist" atomically:YES];
    
    char *tool = "/bin/mv";
    char *args0[] = { "-f", "/tmp/BXplist.plist", (char*)[path_bootColorPlist UTF8String], nil };
    [self runAuthorization:tool :args0];
    
    tool = "/usr/sbin/chown";
    char *args1[] = { "root:admin", (char*)[path_bootColorPlist UTF8String], nil };
    [self runAuthorization:tool :args1];
    
    
    // Kill old plists
    system("launchctl unload /Library/LaunchDaemons/com.macenhance.dbcolor.plist");
    system("launchctl unload /Library/LaunchDaemons/com.macenhance.bbcolor.plist");
    //
    
    system("launchctl load /Library/LaunchDaemons/com.macenhance.bbcolor.plist");
}

- (void)setupBootColor {
    if (bootColorControl.selectedSegment == 0) {
        if ([FileManager fileExistsAtPath:path_bootColorPlist])
            [self clearBootColor:nil];
    }
    
    if (bootColorControl.selectedSegment == 1) {
        [self setBootColor:@"4d1ede05-38c7-4a6a-9cc6-4bcca8b38c14:DefaultBackgroundColor=%00%00%00"];
    }
    
    if (bootColorControl.selectedSegment == 2) {
        [self setBootColor:@"4d1ede05-38c7-4a6a-9cc6-4bcca8b38c14:DefaultBackgroundColor=%99%99%99"];
    }
    
    if (bootColorControl.selectedSegment == 3) {
        if ([self currentBackgroundColor] != bootColorView.color) {
            NSString *bootColor = [self hexStringForColor:bootColorView.color];
            NSString *bootARG = [NSString stringWithFormat:@"4d1ede05-38c7-4a6a-9cc6-4bcca8b38c14:DefaultBackgroundColor=%@", bootColor];
            [self setBootColor:bootARG];
        }
    }
}

- (IBAction)clearBootColor:(id)sener {
    // Run the tool using the authorization reference
    [self authorize];
    
    char *tool1 = "/usr/sbin/chmod";
    char *args1[] = { "755", (char*)[path_bootColorPlist UTF8String], nil };
    [self runAuthorization:tool1 :args1];
    
    char *tool0 = "/bin/mv";
    char *args0[] = { "-f", (char*)[path_bootColorPlist UTF8String], "/tmp/BXplist.plist", nil };
    [self runAuthorization:tool0 :args0];
    
    char *tool = "/bin/rm";
    char *args[] = { "-f", "/tmp/BXplist.plist", nil };
    [self runAuthorization:tool :args];
    system("launchctl unload /Library/LaunchDaemons/com.macenhance.dbcolor.plist");
    system("launchctl unload /Library/LaunchDaemons/com.macenhance.bbcolor.plist");
    [bootColorView setColor:[self defaultBootColor]];
}

- (void)bootPreviewAnimate {
    if (animateBootColor) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            [context setDuration:10.0];
            [[bootColorIndicator animator] setDoubleValue:100.0];
        } completionHandler:^{
            [self->bootColorIndicator setDoubleValue:0.0];
            [self bootPreviewAnimate];
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self bootPreviewAnimate];
        });
    }
}

- (IBAction)cleanupBootColorView:(id)sender {
    NSColor *activeColor = bootColorView.color;
    NSColor *primary    = NSColor.blackColor;
    NSColor *secondary  = NSColor.whiteColor;
    NSImage *drawnImage = nil;
    
    NSColor *testColor = [activeColor colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    
    Boolean useDarkBar = true;
    double a = 1 - ( 0.299 * testColor.redComponent * 255 + 0.587 * testColor.greenComponent * 255 + 0.114 * testColor.blueComponent * 255)/255;
    if (a < 0.5)
        useDarkBar = false; // bright colors - black font
    else
        useDarkBar = true; // dark colors - white font
    
    if (useDarkBar) {
        primary     = NSColor.whiteColor;
        secondary   = NSColor.blackColor;
    }
        
    if (bootColorControl.selectedSegment == 1) secondary = NSColor.grayColor;
    drawnImage = [self imageTintedWithColor:bootColorApple.image :primary];
    [bootColorIndicator setEmptyColor:secondary];
    [bootColorIndicator setProgressColor:primary];
    [bootColorApple setImage:drawnImage];
}

- (IBAction)saveBootColor:(id)sender {
    [self setupBootColor];
}

- (IBAction)colorPickerChanged:(id)sender {
    [self updateBootColorPreview];
}

//









// Boot options

- (void)getBootOptions {
    NSString *bootArgs = [self runCommand:@"nvram -p | grep boot-args"];
    bootArgs = [bootArgs stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    if (bootArgs.length > 10) bootArgs = [bootArgs substringFromIndex:10];
    bootCamshell.state = [bootArgs containsString:@"iog=0x0"];
    bootVerbose.state = [bootArgs containsString:@"-v"];
    bootSingle.state = [bootArgs containsString:@"-s"];
    bootSafe.state = [bootArgs containsString:@"-x"];
    
    bootArgs = [self runCommand:@"nvram -p | grep AutoBoot"];
    bootAuto.state = [bootArgs containsString:@"%03"];
    
    bootArgs = [self runCommand:@"nvram -p | grep BootAudio"];
    Boolean bootsound = [bootArgs containsString:@"%01"];
    if (!bootsound) {
        bootArgs = [self runCommand:@"nvram -p | grep StartupMute"];
        bootsound = [bootArgs containsString:@"%00"];
    }
    bootAudio.state = bootsound;
    
    bootRecovery.state = NSControlStateValueOff;
    bootArgs = [self runCommand:@"nvram internet-recovery-mode"];
    if ([bootArgs containsString:@"RecoveryModeNetwork"])
        bootRecovery.state = NSControlStateValueOn;
}

- (IBAction)applyBootOptions:(id)sender {
    [self authorize];
    char *tool = "/usr/sbin/nvram";
    
    NSString *bootArgs = [self runCommand:@"nvram -p | grep boot-args"];
    bootArgs = [bootArgs stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    if (bootArgs.length > 10)
        bootArgs = [bootArgs substringFromIndex:10];
    else
        bootArgs = @"";
    
    Boolean currentArg = false;
    
    // CamShell
    currentArg = [bootArgs containsString:@"iog=0x0"];
    if (bootCamshell.state == NSControlStateValueOn) {
        if (!currentArg) bootArgs = [NSString stringWithFormat:@"%@ iog=0x0", bootArgs];
    } else {
        if (currentArg) bootArgs = [bootArgs stringByReplacingOccurrencesOfString:@"iog=0x0" withString:@""];
    }
    
    // Verbose
    currentArg = [bootArgs containsString:@"-v"];
    if (bootVerbose.state == NSControlStateValueOn) {
        if (!currentArg) bootArgs = [NSString stringWithFormat:@"%@ -v", bootArgs];
    } else {
        if (currentArg) bootArgs = [bootArgs stringByReplacingOccurrencesOfString:@"-v" withString:@""];
    }
    
    // Single
    currentArg = [bootArgs containsString:@"-s"];
    if (bootSingle.state == NSControlStateValueOn) {
        if (!currentArg) bootArgs = [NSString stringWithFormat:@"%@ -s", bootArgs];
    } else {
        if (currentArg) bootArgs = [bootArgs stringByReplacingOccurrencesOfString:@"-s" withString:@""];
    }
    
    // Safe
    currentArg = [bootArgs containsString:@"-x"];
    if (bootSafe.state == NSControlStateValueOn) {
        if (!currentArg) bootArgs = [NSString stringWithFormat:@"%@ -x", bootArgs];
    } else {
        if (currentArg) bootArgs = [bootArgs stringByReplacingOccurrencesOfString:@"-x" withString:@""];
    }
    
    // Remove extra spaces
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"  +" options:NSRegularExpressionCaseInsensitive error:&error];
    bootArgs = [regex stringByReplacingMatchesInString:bootArgs options:0 range:NSMakeRange(0, [bootArgs length]) withTemplate:@" "];
    bootArgs = [NSString stringWithFormat:@"boot-args=%@", bootArgs];
    char *args00[] = { (char*)[bootArgs UTF8String], nil };
    [self runAuthorization:tool :args00];
//    NSLog(@"%@", bootArgs);
    
    // Auto
    bootArgs = [self runCommand:@"nvram -p | grep AutoBoot"];
    if (bootAuto.state == NSControlStateValueOn) {
        bootArgs = @"AutoBoot=%03";
    } else {
        bootArgs = @"AutoBoot=%00";
    }
    char *args01[] = { (char*)[bootArgs UTF8String], nil };
    [self runAuthorization:tool :args01];
//    NSLog(@"%@", bootArgs);
    
    // Audio
    bootArgs = @"BootAudio=%00";
    if (bootAudio.state == NSControlStateValueOn)
        bootArgs = @"BootAudio=%01";
    char *args02[] = { (char*)[bootArgs UTF8String], nil };
    [self runAuthorization:tool :args02];
    
    bootArgs = @"StartupMute=%01";
    if (bootAudio.state == NSControlStateValueOn)
        bootArgs = @"StartupMute=%00";
    char *args03[] = { (char*)[bootArgs UTF8String], nil };
    
    
    [self runAuthorization:tool :args03];
    
    if (bootRecovery.state == NSControlStateValueOn) {
        char *args04[] = { (char*)[@"internet-recovery-mode=RecoveryModeNetwork" UTF8String], nil };
        [self runAuthorization:tool :args04];
    } else {
        char *args04[] = { (char*)[@"-d" UTF8String], (char*)[@"internet-recovery-mode" UTF8String], nil };
        [self runAuthorization:tool :args04];
    }
}

//






//

- (NSImage *)currentLoginImage {
    // get image
    NSImage *img = [[NSImage alloc] initWithContentsOfFile:path_loginImage];
    if (img == nil) return [self defaultLoginImage];
    return img;
}

- (NSImage *)defaultLoginImage {
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/sqlite3";
    NSString *dbPath = [NSString stringWithFormat:@"%@/Library/Application Support/Dock/desktoppicture.db", NSHomeDirectory()];
    task.arguments = @[dbPath, @"select * from data"];
    task.standardOutput = pipe;
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSArray* lines = [grepOutput componentsSeparatedByString: @"\n"];
    NSString *path = @"";
    if ([lines count] > 2)
        path = [lines objectAtIndex:([lines count] - 2)];
    path = [path stringByExpandingTildeInPath];
    
    if (osx_ver > 13) {
        if (osx_ver == 14)
            path = @"/System/Library/Desktop Pictures/Mojave.heic";
        if (osx_ver == 15)
            path = @"/System/Library/Desktop Pictures/Catalina.heic";
        if (osx_ver >= 16)
            path = @"/System/Library/Desktop Pictures/Big Sur.heic";
    }
    
    return [NSImage.alloc initWithContentsOfFile:path];;
}

- (IBAction)showDefaultLogin:(id)sender {
    NSImage *theImage = [self defaultLoginImage];
    loginImageView.image = theImage;
}

- (IBAction)showCurrentLogin:(id)sender {
    NSImage *theImage = [self currentLoginImage];
    loginImageView.image = theImage;
    loginImageView.canDrawSubviewsIntoLayer = YES;
}

- (IBAction)saveLoginScreen:(id)sender {
    [self installLoginImage:loginImageView.image];
}

- (void)installLoginImage:(NSImage*)img {
    chflags([path_loginImage UTF8String], 0);
    
    CGImageSourceRef source;
    source = CGImageSourceCreateWithData((CFDataRef)[img TIFFRepresentation], NULL);
    CGImageRef maskRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef alter = CGImageCreateCopyWithColorSpace(maskRef, colorspace);
    NSImage *alterED = [self imageFromCGImageRef:alter];
        
//    NSData *imageData = [img TIFFRepresentation];
//    NSData *loginData = [[self defaultLoginImage] TIFFRepresentation];
    
//    if ([imageData isEqualToData:loginData]) {
//        [FileManager removeItemAtPath:path_loginImage error:nil];
//    } else {
//        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:[img TIFFRepresentation]];
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:[alterED TIFFRepresentation]];
        NSData *imgData2 = [rep representationUsingType:NSBitmapImageFileTypePNG properties:[[NSDictionary alloc] init]];
        [imgData2 writeToFile:path_loginImage atomically: NO];
        chflags([path_loginImage UTF8String], UF_IMMUTABLE);
//    }
}

//







// LOCK SCREEN

- (NSImage *)currentLockImage {
    NSImage *img;
    // get image
    NSString *filePath;
    for (NSString *ext in @[@"jpg", @"png", @"gif"])
        if ([FileManager fileExistsAtPath:[db_LockFile stringByAppendingPathExtension:ext]])
            filePath = [db_LockFile stringByAppendingPathExtension:ext];
    
    if (filePath.length) {
        img = [[NSImage alloc] initWithContentsOfFile:filePath];
        lockImageView.path = filePath;
        if (img == nil) return [self defaultLoginImage];
    } else {
        img = [self defaultLoginImage];
        hashVal = img.hash;
    }
    return img;
}

- (IBAction)showDefaultLock:(id)sender {
    NSImage *theImage = [self defaultLoginImage];
    hashVal = theImage.hash;
    lockImageView.path = @"";
    lockImageView.image = theImage;
}

- (IBAction)showCurrentLock:(id)sender {
    NSImage *theImage = [self currentLockImage];
    lockImageView.image = theImage;
    lockImageView.animates = YES;
    lockImageView.canDrawSubviewsIntoLayer = YES;
}

- (IBAction)lockTextTextEdit:(id)sender {
    [Defaults setObject:lockTextText.stringValue forKey:@"lock_text"];
}

- (IBAction)lockTextSlider:(id)sender {
    NSSlider *s = sender;
    NSFont *f = [NSFont fontWithName:lockTextText.font.fontName size:s.doubleValue/2];
    [lockTextText setFont:f];
    [Defaults setObject:[NSNumber numberWithDouble:s.doubleValue] forKey:@"lock_size"];
}

- (IBAction)toggleCustomLockText:(id)sender {
    [Defaults setObject:[NSNumber numberWithBool:[sender state]] forKey:@"custom_text"];
}

- (IBAction)toggleCustomLockSize:(id)sender {
    [Defaults setObject:[NSNumber numberWithBool:[sender state]] forKey:@"custom_size"];
}

- (IBAction)saveLockScreen:(id)sender {
    [self installLockImage:lockImageView.image];
}

- (void)installLockImage:(NSImage*)img {
    for (NSString *ext in @[@"jpg", @"png", @"gif"])
        if ([FileManager fileExistsAtPath:[db_LockFile stringByAppendingPathExtension:ext]])
            [FileManager removeItemAtPath:[db_LockFile stringByAppendingPathExtension:ext] error:nil];
    
    if ([FileManager isReadableFileAtPath:lockImageView.path]) {
        NSError *err;
        [FileManager copyItemAtURL:[NSURL fileURLWithPath:lockImageView.path]
                             toURL:[NSURL fileURLWithPath:[db_LockFile stringByAppendingPathExtension:lockImageView.path.pathExtension]]
                             error:&err];
        if (err != nil) NSLog(@"%@", err);
    } else {
        if ((long)hashVal != lockImageView.hashValue) {
            NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:[img TIFFRepresentation]];
            NSNumber *frames = [rep valueForProperty:@"NSImageFrameCount"];
            NSData *imgData2;;
            if (frames != nil) {   // bitmapRep is a Gif imageRep
                imgData2 = [rep representationUsingType:NSBitmapImageFileTypeGIF
                                             properties:[[NSDictionary alloc] init]];
                [imgData2 writeToFile:[db_LockFile stringByAppendingPathComponent:@"gif"] atomically:NO];
            } else {
                imgData2 = [rep representationUsingType:NSBitmapImageFileTypePNG
                                             properties:[[NSDictionary alloc] init]];
                [imgData2 writeToFile:[db_LockFile stringByAppendingPathComponent:@"png"] atomically:NO];
            }
        }
    }
}

//

@end
