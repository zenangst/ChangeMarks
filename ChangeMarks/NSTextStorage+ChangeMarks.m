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

- (void)zen_edited:(NSUInteger)editedMask range:(NSRange)range changeInLength:(NSInteger)delta
{
    if (range.location > 0 && range.length > 1 && delta > 0) {
        NSDictionary *rangeDictionary = @{@"location":@(range.location),
                                          @"length":@(range.length)};

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Add change mark range"
                                                                object:rangeDictionary];
        });
    }

    [self zen_edited:editedMask range:range changeInLength:delta];
}

+ (void)load
{
    Method original, swizzle;

    original = class_getInstanceMethod(self, NSSelectorFromString(@"edited:range:changeInLength:"));
    swizzle = class_getInstanceMethod(self, NSSelectorFromString(@"zen_edited:range:changeInLength:"));

    method_exchangeImplementations(original, swizzle);
}

@end
