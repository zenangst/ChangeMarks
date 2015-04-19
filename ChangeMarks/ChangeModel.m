//
//  Change.m
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 19/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import "ChangeModel.h"

@implementation ChangeModel

+ (ChangeModel *)withRange:(NSRange)range
{
    ChangeModel *model = [[ChangeModel alloc] initWithRange:range];

    return model;
}

- (instancetype)initWithRange:(NSRange)range
{
    self = [super init];
    if (!self) return nil;

    self.location = range.location;
    self.length = range.length;

    return self;
}

@end
