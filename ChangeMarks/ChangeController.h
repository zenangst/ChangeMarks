//
//  ChangeController.h
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 26/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChangeModel.h"

@interface ChangeController : NSObject

- (void)addChange:(ChangeModel *)model;
- (NSArray *)changesForDocument:(NSString *)path;
- (void)clearChangeMarks:(NSString *)path;

@end
