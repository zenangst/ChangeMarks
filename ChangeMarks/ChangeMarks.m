//
//  ChangeMarks.m
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 31/10/14.
//    Copyright (c) 2014 zenangst. All rights reserved.
//

#import <objc/objc-runtime.h>
#import "ChangeMarks.h"
#import "XcodeManager.h"

static ChangeMarks *sharedPlugin;

static NSString *const kChangeMarksEnabled = @"ChangeMarksEnabled";
static NSString *const kChangeMarksColor = @"ChangeMarkColor";

@interface ChangeMarks()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong) XcodeManager *xcodeManager;
@property (nonatomic, strong) NSMenuItem *enabledMenuItem;
@property (nonatomic, strong) NSColor *changeMarkColor;

@end

@implementation ChangeMarks

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if (![currentApplicationName isEqual:@"Xcode"]) return;

    dispatch_once(&onceToken, ^{
        sharedPlugin = [self new];
    });
}

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidFinishLaunching:)
                                                 name:NSApplicationDidFinishLaunchingNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addChangeMark:)
                                                 name:@"Add change mark"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addChangeMarkRange:)
                                                 name:@"Add change mark range"
                                               object:nil];

    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];

    if (editMenuItem) {
        NSMenu *pluginMenu = [[NSMenu alloc] initWithTitle:@"Change Marks"];

        [[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger state = [userDefaults objectForKey:kChangeMarksEnabled] ? [[userDefaults objectForKey:kChangeMarksEnabled] integerValue] : 1;

        _enabledMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Change Marks"
                                                          action:@selector(toggleChangeMarks)
                                                   keyEquivalent:@""];
        _enabledMenuItem.state = state;
        _enabledMenuItem.target = self;

        [pluginMenu addItem:_enabledMenuItem];

        [pluginMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Change Color"
                                                              action:@selector(showColorPanel)
                                                       keyEquivalent:@""];
            menuItem.target = self;
            menuItem;
        })];

        [pluginMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Clear Change Marks"
                                                              action:@selector(clearChangeMarks)
                                                       keyEquivalent:@""];
            menuItem.target = self;
            menuItem;
        })];

        NSString *versionString = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString *title = [NSString stringWithFormat:@"Change Marks (%@)", versionString];
        NSMenuItem *pluginMenuItem = [[NSMenuItem alloc] initWithTitle:title
                                                                action:nil
                                                         keyEquivalent:@""];
        pluginMenuItem.submenu = pluginMenu;

        [[editMenuItem submenu] addItem:pluginMenuItem];
    }
}

#pragma mark - Getters

- (XcodeManager *)xcodeManager
{
    if (_xcodeManager) return _xcodeManager;

    _xcodeManager = [XcodeManager new];

    return _xcodeManager;
}

- (NSColor *)changeMarkColor
{
    NSData *colorData = [[NSUserDefaults standardUserDefaults] dataForKey:kChangeMarksColor];

    if (!colorData) {
        _changeMarkColor = [NSColor colorWithCalibratedRed:1.000 green:0.976 blue:0.741 alpha:1];
    } else {
        _changeMarkColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:colorData];
    }

    return _changeMarkColor;
}

#pragma mark - Actions

- (void)adjustColor:(id)sender
{
    NSColorPanel *panel = (NSColorPanel *)sender;

    if ([[NSApp keyWindow] firstResponder] == self.xcodeManager.textView &&
        panel.color) {
        NSData *colorData = [NSArchiver archivedDataWithRootObject:panel.color];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:colorData forKey:kChangeMarksColor];
        [userDefaults synchronize];

        self.changeMarkColor = panel.color;

        [self clearChangeMarks];
    }
}

- (void)toggleChangeMarks
{
    [self clearChangeMarks];

    self.enabledMenuItem.state = (self.enabledMenuItem.state == 1) ? 0 : 1;

    if (self.enabledMenuItem.state == 0) {
        [self clearChangeMarks];
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(self.enabledMenuItem.state) forKey:kChangeMarksEnabled];
    [userDefaults synchronize];
}

- (void)showColorPanel
{
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    panel.color = self.changeMarkColor;
    panel.target = self;
    panel.action = @selector(adjustColor:);
    [panel orderFront:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(colorPanelWillClose:)
                                                 name:NSWindowWillCloseNotification object:nil];
}

- (void)clearChangeMarks
{
    NSRange range = NSMakeRange(0,[self.xcodeManager documentLength]);
    NSLayoutManager *layoutManager = [[self.xcodeManager textView] layoutManager];

    [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName
                          forCharacterRange:range];
}

#pragma mark - Notifications

- (void)addChangeMark:(NSNotification *)notification
{
    if (notification.object && [notification.object isKindOfClass:[NSString class]]) {
        NSString *newString = (NSString *)notification.object;
        NSInteger length = newString.length;
        NSInteger location  = self.xcodeManager.selectedRange.location - newString.length;
        NSRange range = NSMakeRange(location, length);

        [self colorBackgroundWithRange:range];
    }
}

- (void)addChangeMarkRange:(NSNotification *)notification
{
    if (notification.object && [notification.object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)notification.object;
        NSRange range = NSMakeRange([dictionary[@"location"] integerValue],
                                    [dictionary[@"length"] integerValue]);

        [self colorBackgroundWithRange:range];
    }
}

- (void)colorBackgroundWithRange:(NSRange)range
{
    if (self.enabledMenuItem.state == 1) {
        NSLayoutManager *layoutManager = [[self.xcodeManager textView] layoutManager];
        NSColor *color = self.changeMarkColor;
        [layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName
                                       value:color
                           forCharacterRange:range];
    }
}

- (void)colorPanelWillClose:(NSNotification *)notification
{
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    if (panel == notification.object) {
        panel.target = nil;
        panel.action = nil;

        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSWindowWillCloseNotification
                                                      object:nil];
    }
}

@end
