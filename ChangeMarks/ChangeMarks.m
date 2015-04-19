//
//  ChangeMarks.m
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 31/10/14.
//    Copyright (c) 2014 zenangst. All rights reserved.
//

#import <objc/objc-runtime.h>
#import "ChangeMarks.h"

static ChangeMarks *sharedPlugin;

static NSString *const kChangeMarksEnabled = @"ChangeMarksEnabled";
static NSString *const kChangeMarksColor = @"ChangeMarkColor";

@interface ChangeMarks()

@property (nonatomic, readwrite) NSBundle *bundle;
@property (nonatomic) NSMenuItem *enabledMenuItem;
@property (nonatomic) NSColor *changeMarkColor;
@property (nonatomic) NSString *lastInsertedString;
@property (nonatomic) NSMutableArray *changes;

@end

@implementation ChangeMarks

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if (![currentApplicationName isEqual:@"Xcode"]) return;

    dispatch_once(&onceToken, ^{
        sharedPlugin = [self new];
    });
}

+ (instancetype)sharedPlugin {
    return sharedPlugin;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidFinishLaunching:)
                                                 name:NSApplicationDidFinishLaunchingNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addChangeMark:)
                                                 name:kChangeMarkAddNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addChangeMarkRange:)
                                                 name:kChangeMarkAddRangeNotification
                                               object:nil];

    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
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

- (NSMutableArray *)changes
{
    if (_changes) return _changes;

    _changes = [NSMutableArray new];

    return _changes;
}

- (id)currentEditor {
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];

    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = (IDEWorkspaceWindowController *)currentWindowController;
        IDEEditorArea *editorArea = [workspaceController editorArea];
        IDEEditorContext *editorContext = [editorArea lastActiveEditorContext];
        return [editorContext editor];
    }

    return nil;
}

- (NSTextView *)textView {
    if ([[self currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        IDESourceCodeEditor *editor = [self currentEditor];
        return editor.textView;
    }

    if ([[self currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        IDESourceCodeComparisonEditor *editor = [self currentEditor];
        return editor.keyTextView;
    }

    return nil;
}

- (NSColor *)changeMarkColor {
    NSData *colorData = [[NSUserDefaults standardUserDefaults] dataForKey:kChangeMarksColor];

    if (!colorData) {
        _changeMarkColor = [NSColor colorWithCalibratedRed:1.000
                                                     green:0.976
                                                      blue:0.741
                                                     alpha:1];
    } else {
        _changeMarkColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:colorData];
    }

    return _changeMarkColor;
}

#pragma mark - Actions

- (void)adjustColor:(id)sender {
    NSColorPanel *panel = (NSColorPanel *)sender;

    if ([[NSApp keyWindow] firstResponder] == self.textView &&
        panel.color) {
        NSData *colorData = [NSArchiver archivedDataWithRootObject:panel.color];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:colorData forKey:kChangeMarksColor];
        [userDefaults synchronize];

        self.changeMarkColor = panel.color;

        [self clearChangeMarks];
    }
}

- (void)toggleChangeMarks {
    [self clearChangeMarks];

    self.enabledMenuItem.state = (self.enabledMenuItem.state == 1) ? 0 : 1;

    if (self.enabledMenuItem.state == 0) {
        [self clearChangeMarks];
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(self.enabledMenuItem.state) forKey:kChangeMarksEnabled];
    [userDefaults synchronize];
}

- (void)showColorPanel {
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    panel.color = self.changeMarkColor;
    panel.target = self;
    panel.action = @selector(adjustColor:);
    [panel orderFront:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(colorPanelWillClose:)
                                                 name:NSWindowWillCloseNotification object:nil];
}

- (void)clearChangeMarks {
    NSRange range;

    if ([[self textView] selectedRange].length > 0) {
        range = [[self textView] selectedRange];
    } else {
        range = NSMakeRange(0,[[[self textView] string] length]);
    }

    NSLayoutManager *layoutManager = [[self textView] layoutManager];

    [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName
                          forCharacterRange:range];
}

#pragma mark - Notifications

- (void)addChangeMark:(NSNotification *)notification {
    if (notification.object && [notification.object isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *)notification.object;
        NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *trimmedLineContents = [[self contentsOfRange:[self lineRange]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        NSRange currentRange = [[self textView] selectedRange];
        BOOL shouldTrimString = ((self.lastInsertedString.length == 1 &&
                                 [self.lastInsertedString characterAtIndex:0] == '\n'));

        if (shouldTrimString) {
            string = [string stringByReplacingOccurrencesOfString:trimmedString
                                                       withString:@""];
        }

        if (currentRange.length > 0 || [trimmedString isEqualToString:trimmedLineContents]) {
            [self colorBackgroundWithRange:[self lineRange]];
            self.lastInsertedString = nil;
        } else {
            NSInteger length = string.length;
            NSInteger location  = [self textView].selectedRange.location - string.length;
            NSRange range = NSMakeRange(location, length);
            [self colorBackgroundWithRange:range];
            self.lastInsertedString = string;
        }
    }
}

- (void)addChangeMarkRange:(NSNotification *)notification {
    if (notification.object && [notification.object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)notification.object;
        NSRange range = NSMakeRange([dictionary[@"location"] integerValue],
                                    [dictionary[@"length"] integerValue]);

        [self colorBackgroundWithRange:range];
    }
}

- (void)colorBackgroundWithRange:(NSRange)range {
    if (self.enabledMenuItem.state == 1 && [self validResponder]) {
        NSLayoutManager *layoutManager = [self.textView layoutManager];
        NSColor *color = self.changeMarkColor;
        [layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName
                                       value:color
                           forCharacterRange:range];
    }
}

#pragma mark - Private methods

- (BOOL)validResponder {
    NSResponder *firstResponder = [[NSApp keyWindow] firstResponder];
    NSString *responderClass = NSStringFromClass(firstResponder.class);
    NSArray *validClasses = @[@"DVTSourceTextView", @"IDEPlaygroundTextView"];

    return ([validClasses containsObject:responderClass]);
}

- (void)colorPanelWillClose:(NSNotification *)notification {
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    if (panel == notification.object) {
        panel.target = nil;
        panel.action = nil;

        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSWindowWillCloseNotification
                                                      object:nil];
    }
}

- (NSRange)lineRange {
    NSRange selectedRange = [[self textView] selectedRange];
    NSCharacterSet *newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
    NSUInteger location = ([[[self textView] string] rangeOfCharacterFromSet:newlineSet
                                                            options:NSBackwardsSearch
                                                              range:NSMakeRange(0,selectedRange.location)].location);

    NSUInteger length = ([[[self textView] string] rangeOfCharacterFromSet:newlineSet
                                                          options:NSCaseInsensitiveSearch
                                                            range:NSMakeRange(selectedRange.location+selectedRange.length,[[self textView] string].length-(selectedRange.location+selectedRange.length))].location);

    location = (location == NSNotFound) ? 0 : location + 1;
    length   = (location == 0) ? length+1   : (length+1) - location;

    if (length > [[[self textView] string] length]) {
        length = [[[self textView] string] length];
    }

    return NSMakeRange(location, length - 1);
}

- (NSString *)contentsOfRange:(NSRange)range {
    if (range.location + range.length > [[[self textView] string] length]) {
        return @"";
    } else {
        return [[[self textView] string] substringWithRange:range];
    }
}

@end
