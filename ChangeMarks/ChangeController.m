//
//  ChangeController.m
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 19/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import "ChangeController.h"

@interface ChangeController ()

@property (nonatomic) NSMutableDictionary *changes;

@end

@implementation ChangeController

- (void)addChange:(ChangeModel *)change {
    
}

- (NSMutableDictionary *)changes
{
    if (_changes) return _changes;

    _changes = [NSMutableDictionary new];

    return _changes;
}

@end
