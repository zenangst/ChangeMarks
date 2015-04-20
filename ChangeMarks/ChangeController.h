//
//  ChangeController.h
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 19/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChangeModel.h"

@interface ChangeController : NSObject

- (void)addChange:(ChangeModel *)change;

@end
