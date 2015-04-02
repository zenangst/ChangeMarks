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

@interface ChangeMarks()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong) XcodeManager *xcodeManager;

@end

@implementation ChangeMarks

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if (![currentApplicationName isEqual:@"Xcode"]) return;

    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc] init];
    });
}

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getters

- (XcodeManager *)xcodeManager
{
    if (_xcodeManager) return _xcodeManager;

    _xcodeManager = [[XcodeManager alloc] init];

    return _xcodeManager;
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
        NSRange range = NSMakeRange([dictionary[@"location"] integerValue], [dictionary[@"length"] integerValue]);

        [self colorBackgroundWithRange:range];
    }
}

- (void)colorBackgroundWithRange:(NSRange)range
{
    NSLayoutManager *layoutManager = [[self.xcodeManager textView] layoutManager];
    NSColor *color = [NSColor colorWithRed:0.8 green:0.93 blue:0.34 alpha:0.5];
    [layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName
                                   value:color
                       forCharacterRange:range];
}

@end
