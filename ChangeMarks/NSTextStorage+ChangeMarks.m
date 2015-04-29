//
//  NSTextStorage+ChangeMarks.m
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 05/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import "NSTextStorage+ChangeMarks.h"
#import <objc/runtime.h>

@implementation NSTextStorage (ChangeMarks)

+ (void)load {
    Method original, swizzle;

    original = class_getInstanceMethod(self, NSSelectorFromString(@"edited:range:changeInLength:"));
    swizzle = class_getInstanceMethod(self, NSSelectorFromString(@"zen_edited:range:changeInLength:"));

    method_exchangeImplementations(original, swizzle);
}

- (void)zen_edited:(NSUInteger)editedMask range:(NSRange)range changeInLength:(NSInteger)delta {
    NSDictionary *rangeDictionary = @{@"location":@(range.location),
                                      @"length":@(range.length),
                                      @"delta":@(delta)};

    if (range.location > 0 && range.length > 0 && delta >= 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kChangeMarkTiming * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeMarkAddNotification
                                                                object:rangeDictionary
             ];
        });
    } else if (range.location > 0 && delta < 0 && editedMask == 2) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kChangeMarkTiming * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeMarkRemovedCharacters
                                                                object:rangeDictionary];
        });
    }


    [self zen_edited:editedMask
               range:range
      changeInLength:delta];
}

@end
